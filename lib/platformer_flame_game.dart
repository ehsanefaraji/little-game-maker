import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/sprite.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/material.dart';

import 'game_audio.dart';
import 'game_models.dart';
import 'game_art.dart';

const double _cellSize = 2.2;

/// A real-time platform game powered by Flame's game loop and Forge2D bodies.
class PlatformerPhysicsGame extends Forge2DGame<Forge2DWorld> {
  PlatformerPhysicsGame({
    required this.project,
    this.onScore,
    this.onLives,
    this.onFinished,
  }) : super(gravity: Vector2(0, 30));

  final GameProject project;
  final ValueChanged<int>? onScore;
  final ValueChanged<int>? onLives;
  final ValueChanged<bool>? onFinished;

  late PlatformerPlayer player;
  final List<Rect> _solidBounds = [];
  final List<_Pickup> _coins = [];
  final List<_Pickup> _enemies = [];
  int score = 0;
  int lives = 3;
  int _direction = 0;
  int _airJumps = 0;
  double _invulnerable = 0;
  double _enemyClock = 0;
  double _jumpBuffer = 0;
  double _coyoteTimer = 0;
  bool _finished = false;
  bool _pausedByUser = false;
  bool _playerCreated = false;

  double get _worldWidth => project.columns * _cellSize;
  double get _worldHeight => project.rows * _cellSize;

  @override
  Color backgroundColor() => const Color(0x00000000);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    camera.viewfinder.zoom = 18.0;

    final startIndex = project.cells.indexOf(5);
    final startColumn = startIndex < 0 ? 0 : startIndex % project.columns;
    final startRow = startIndex < 0 ? project.rows - 2 : startIndex ~/ project.columns;
    final start = Vector2(
      (startColumn + .5) * _cellSize,
      (startRow + .42) * _cellSize,
    );

    // The level is built from static Forge2D bodies. The visual components are
    // separate so the physics shapes stay simple and inexpensive.
    for (var row = 0; row < project.rows; row++) {
      for (var col = 0; col < project.columns; col++) {
        final value = project.cells[row * project.columns + col];
        final center = Vector2((col + .5) * _cellSize, (row + .82) * _cellSize);
        if (value == 1) {
          final size = Vector2(_cellSize, .48);
          _solidBounds.add(Rect.fromCenter(
            center: Offset(center.x, center.y),
            width: size.x,
            height: size.y,
          ));
          world.add(_PlatformBody(center, size));
        } else if (value == 2) {
          final pickup = _Pickup(center, enemy: false);
          _coins.add(pickup);
          add(pickup);
        } else if (value == 3) {
          final enemy = _Pickup(center, enemy: true);
          _enemies.add(enemy);
          add(enemy);
        } else if (value == 4) {
          add(_GoalVisual(center));
        }
      }
    }

    // A continuous floor and invisible side walls keep the player in the level.
    final floorY = _worldHeight - .18;
    final floorCenter = Vector2(_worldWidth / 2, floorY);
    final floorSize = Vector2(_worldWidth + 2, .55);
    _solidBounds.add(Rect.fromCenter(
      center: Offset(floorCenter.x, floorCenter.y),
      width: floorSize.x,
      height: floorSize.y,
    ));
    world.add(_PlatformBody(floorCenter, floorSize));
    world.add(_PlatformBody(Vector2(-.4, _worldHeight / 2), Vector2(.8, _worldHeight * 2)));
    world.add(_PlatformBody(Vector2(_worldWidth + .4, _worldHeight / 2), Vector2(.8, _worldHeight * 2)));

    final spriteImage = await images.load('fox_animations.png');
    final spriteSheet = SpriteSheet(image: spriteImage, srcSize: Vector2(64, 64));
    final characterRow = project.character.clamp(0, characterOptions.length - 1).toInt() * 3;
    final idleAnimation = spriteSheet.createAnimation(row: characterRow, stepTime: .24, to: 4);
    final runAnimation = spriteSheet.createAnimation(row: characterRow + 1, stepTime: .105, to: 4);
    final jumpAnimation = spriteSheet.createAnimation(row: characterRow + 2, stepTime: .16, to: 4);
    player = PlatformerPlayer(start, idleAnimation, runAnimation, jumpAnimation);
    _playerCreated = true;
    world.add(player);

    camera.viewfinder.position = start;
  }

  void setDirection(int direction) => _direction = direction.clamp(-1, 1).toInt();

  /// Buffers a jump briefly so a tap just before landing is not lost.
  void jump() {
    if (_finished || _pausedByUser || !_playerCreated || !player.isLoaded) return;
    _jumpBuffer = .16;
  }

  void setPaused(bool value) {
    _pausedByUser = value;
    if (value) {
      pauseEngine();
      _direction = 0;
    } else {
      resumeEngine();
    }
  }

  bool _isGrounded() {
    final bodyPosition = player.body.position;
    final foot = bodyPosition.y + .52;
    for (final platform in _solidBounds) {
      if ((foot - platform.top).abs() < .24 &&
          bodyPosition.x >= platform.left - .32 &&
          bodyPosition.x <= platform.right + .32 &&
          player.body.linearVelocity.y >= -.25) {
        return true;
      }
    }
    return false;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_finished || _pausedByUser || !_playerCreated || !player.isLoaded) return;

    final velocity = player.body.linearVelocity;
    final grounded = _isGrounded();
    if (grounded) {
      _airJumps = 0;
      _coyoteTimer = .12;
    } else {
      _coyoteTimer = math.max(0.0, _coyoteTimer - dt);
    }
    _jumpBuffer = math.max(0.0, _jumpBuffer - dt);
    if (_jumpBuffer > 0 && (_airJumps == 0 ? (grounded || _coyoteTimer > 0) : _airJumps < 2)) {
      _airJumps++;
      player.body.linearVelocity = Vector2(velocity.x, _airJumps == 1 ? -13.2 : -11.4);
      _jumpBuffer = 0;
      _coyoteTimer = 0;
      if (project.soundEnabled) GameAudio.instance.effect(frequency: 610, durationMs: 75);
    }
    // Smooth acceleration and deceleration feel much more responsive than
    // snapping the body to a new horizontal velocity every frame.
    final targetVelocityX = _direction * 7.4;
    final response = math.min(1.0, dt * 14.0).toDouble();
    player.body.linearVelocity = Vector2(
      velocity.x + (targetVelocityX - velocity.x) * response,
      player.body.linearVelocity.y,
    );
    if (velocity.y.abs() > 1.1) {
      player.setMotion('jump');
    } else if (_direction != 0) {
      player.setMotion('run');
    } else {
      player.setMotion('idle');
    }
    player.setFacingLeft(_direction < 0);

    _invulnerable = math.max(0.0, _invulnerable - dt);
    player.setHurtBlink(_invulnerable <= 0 || (_invulnerable * 12).floor().isEven);
    _enemyClock += dt;
    for (var i = 0; i < _enemies.length; i++) {
      final enemy = _enemies[i];
      enemy.position.x = enemy._homeX + math.sin(_enemyClock * 1.8 + i) * .72;
    }

    // Keep the camera centered on the player without changing the physics world.
    camera.viewfinder.position = Vector2(
      player.body.position.x,
      _worldHeight / 2,
    );

    for (final coin in List<_Pickup>.from(_coins)) {
      if ((coin.position - player.body.position).length < .95) {
        _coins.remove(coin);
        coin.removeFromParent();
        score += 10 + project.coinBonusScore;
        if (project.extraLifeOnCoin) { lives = math.min(5, lives + 1).toInt(); onLives?.call(lives); }
        onScore?.call(score);
        if (project.soundEnabled) GameAudio.instance.collect();
      }
    }

    if (_invulnerable <= 0) {
      for (final enemy in _enemies) {
        if ((enemy.position - player.body.position).length < .95) {
          _takeHit();
          break;
        }
      }
    }

    final goal = project.cells.indexOf(4);
    if (goal >= 0) {
      final goalPosition = Vector2(
        ((goal % project.columns) + .5) * _cellSize,
        ((goal ~/ project.columns) + .82) * _cellSize,
      );
      if ((goalPosition - player.body.position).length < 1.15) {
        _finish(true);
      }
    } else if (player.body.position.x > _worldWidth - .8) {
      _finish(true);
    }

    if (player.body.position.y > _worldHeight + 3) _takeHit();
  }

  void _takeHit() {
    if (_invulnerable > 0 || _finished) return;
    lives--;
    onLives?.call(lives);
    _invulnerable = 1.25;
    if (project.soundEnabled) GameAudio.instance.bump();
    if (lives <= 0) {
      _finish(false);
      return;
    }
    final startIndex = project.cells.indexOf(5);
    final col = startIndex < 0 ? 0 : startIndex % project.columns;
    final row = startIndex < 0 ? project.rows - 2 : startIndex ~/ project.columns;
    player.body.setTransform(
      Vector2((col + .5) * _cellSize, (row + .42) * _cellSize),
      Rot.identity(),
    );
    player.body.linearVelocity = Vector2.zero();
    _airJumps = 0;
    _jumpBuffer = 0;
    _coyoteTimer = 0;
  }

  void _finish(bool success) {
    if (_finished) return;
    _finished = true;
    _direction = 0;
    pauseEngine();
    if (project.soundEnabled) {
      if (success) {
        GameAudio.instance.success();
      } else {
        GameAudio.instance.bump();
      }
    }
    onFinished?.call(success);
  }
}

class _PlatformBody extends BodyComponent<PlatformerPhysicsGame> {
  _PlatformBody(Vector2 center, Vector2 size)
      : _size = size,
        super(
          bodyDef: BodyDef(position: center, type: BodyType.static),
          shapeSpecs: [
            ShapeSpec(
              Polygon.box(size.x / 2, size.y / 2, radius: .08),
              ShapeDef(material: SurfaceMaterial(friction: .88)),
            ),
          ],
          renderBody: false,
        );

  final Vector2 _size;

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final rect = Rect.fromCenter(
      center: Offset.zero,
      width: _size.x,
      height: _size.y,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(.13)),
      Paint()..color = const Color(0xFF8B633F),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(rect.left, rect.top, rect.width, .17),
        const Radius.circular(.08),
      ),
      Paint()..color = const Color(0xFF70C96C),
    );
  }
}

class PlatformerPlayer extends BodyComponent<PlatformerPhysicsGame> {
  PlatformerPlayer(
    Vector2 position,
    SpriteAnimation idleAnimation,
    SpriteAnimation runAnimation,
    SpriteAnimation jumpAnimation,
  )   : _idleAnimation = idleAnimation,
        _runAnimation = runAnimation,
        _jumpAnimation = jumpAnimation,
        super(
          bodyDef: BodyDef(
            type: BodyType.dynamic,
            position: position,
            fixedRotation: true,
            linearDamping: .4,
            isBullet: true,
          ),
          shapeSpecs: [
            ShapeSpec(
              Polygon.box(.38, .48, radius: .16),
              ShapeDef(material: SurfaceMaterial(friction: .25, restitution: 0)),
            ),
          ],
          renderBody: false,
        );

  final SpriteAnimation _idleAnimation;
  final SpriteAnimation _runAnimation;
  final SpriteAnimation _jumpAnimation;
  late SpriteAnimationComponent _sprite;
  String _motion = 'idle';
  bool _hurtVisible = true;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _sprite = SpriteAnimationComponent(
      animation: _idleAnimation,
      size: Vector2(1.35, 1.45),
      anchor: Anchor.center,
      position: Vector2(0, -.08),
    );
    add(_sprite);
  }

  void setMotion(String motion) {
    if (!isLoaded || motion == _motion) return;
    _motion = motion;
    _sprite.animation = switch (motion) {
      'run' => _runAnimation,
      'jump' => _jumpAnimation,
      _ => _idleAnimation,
    };
  }

  void setFacingLeft(bool value) {
    if (isLoaded && _sprite.isFlippedHorizontally != value) {
      _sprite.flipHorizontally();
    }
  }

  void setHurtBlink(bool visible) {
    if (!isLoaded || visible == _hurtVisible) return;
    _hurtVisible = visible;
    _sprite.setOpacity(visible ? 1 : .38);
  }
}

class _Pickup extends PositionComponent {
  _Pickup(Vector2 point, {required this.enemy})
      : super(position: point, size: Vector2.all(.72), anchor: Anchor.center);

  final bool enemy;
  double _phase = 0;
  late final double _homeX = position.x;

  @override
  void update(double dt) {
    super.update(dt);
    _phase += dt * 4;
    if (!enemy) angle = math.sin(_phase) * .18;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    if (enemy) {
      canvas.drawCircle(Offset.zero, .34, Paint()..color = const Color(0xFF8E63D7));
      canvas.drawCircle(const Offset(-.12, -.07), .055, Paint()..color = Colors.white);
      canvas.drawCircle(const Offset(.12, -.07), .055, Paint()..color = Colors.white);
      canvas.drawCircle(const Offset(-.12, -.07), .025, Paint()..color = const Color(0xFF29213D));
      canvas.drawCircle(const Offset(.12, -.07), .025, Paint()..color = const Color(0xFF29213D));
      final mouth = Paint()..color = const Color(0xFF29213D)..strokeWidth = .035..style = PaintingStyle.stroke;
      canvas.drawArc(const Rect.fromLTWH(-.13, .02, .26, .17), 0, math.pi, false, mouth);
    } else {
      canvas.drawCircle(Offset.zero, .29, Paint()..color = const Color(0xFFFFD34E));
      canvas.drawCircle(Offset.zero, .19, Paint()..color = const Color(0xFFFFF1A6));
      canvas.drawCircle(const Offset(-.07, -.07), .035, Paint()..color = Colors.white);
    }
  }
}

class _GoalVisual extends PositionComponent {
  _GoalVisual(Vector2 point)
      : super(position: point, size: Vector2(1.3, 1.5), anchor: Anchor.center);

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final pole = Paint()..color = const Color(0xFF7856A8)..strokeWidth = .09;
    canvas.drawLine(const Offset(-.38, .58), const Offset(-.38, -.62), pole);
    final flag = Path()
      ..moveTo(-.34, -.6)
      ..lineTo(.48, -.36)
      ..lineTo(-.34, -.08)
      ..close();
    canvas.drawPath(flag, Paint()..color = const Color(0xFFFFD34E));
    canvas.drawCircle(const Offset(-.38, -.65), .11, Paint()..color = const Color(0xFF8D72C8));
  }
}

class PlatformerGameScreen extends StatefulWidget {
  const PlatformerGameScreen({super.key, required this.project});
  final GameProject project;

  @override
  State<PlatformerGameScreen> createState() => _PlatformerGameScreenState();
}

class _PlatformerGameScreenState extends State<PlatformerGameScreen> with SingleTickerProviderStateMixin {
  late GameProject project;
  late PlatformerPhysicsGame game;
  int score = 0;
  int lives = 3;
  bool paused = false;
  bool _dialogOpen = false;
  late final AnimationController _ambience;

  @override
  void initState() {
    super.initState();
    project = widget.project.copy();
    _ambience = AnimationController(vsync: this, duration: const Duration(seconds: 48))..repeat();
    _createGame();
    GameAudio.instance.configure(sound: project.soundEnabled, music: project.musicEnabled);
  }

  void _createGame() {
    game = PlatformerPhysicsGame(
      project: project,
      onScore: (value) { if (mounted) setState(() => score = value); },
      onLives: (value) { if (mounted) setState(() => lives = value); },
      onFinished: _showResult,
    );
  }

  void _showResult(bool success) {
    if (!mounted || _dialogOpen) return;
    _ambience.stop();
    _dialogOpen = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final nextAvailable = success && project.activeLevel < project.levels.length - 1;
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          title: Text(success ? 'آفرین، قهرمان! 🏆' : 'دوباره تلاش کن! 💪'),
          content: Text(success
              ? 'به پایان مرحله رسیدی. امتیاز تو: $score'
              : 'جان‌ها تمام شد. این بار می‌توانی بهتر عمل کنی.'),
          actions: [
            TextButton(
              onPressed: () { Navigator.pop(dialogContext); Navigator.pop(context); },
              child: const Text('بازگشت'),
            ),
            if (nextAvailable)
              OutlinedButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                  setState(() {
                    project.setActiveLevel(project.activeLevel + 1);
                    score = 0; lives = 3; paused = false; _dialogOpen = false;
                    _ambience.repeat();
                    _createGame();
                  });
                },
                child: const Text('مرحله بعدی'),
              ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                setState(() { score = 0; lives = 3; paused = false; _dialogOpen = false; _ambience.repeat(); _createGame(); });
              },
              child: const Text('شروع دوباره'),
            ),
          ],
        ),
      );
    });
  }

  @override
  void dispose() {
    _ambience.dispose();
    game.setDirection(0);
    game.pauseEngine();
    GameAudio.instance.configure(sound: project.soundEnabled, music: false);
    super.dispose();
  }

  Widget _directionButton(IconData icon, int direction) => Listener(
        onPointerDown: (_) => game.setDirection(direction),
        onPointerUp: (_) => game.setDirection(0),
        onPointerCancel: (_) => game.setDirection(0),
        child: SizedBox(
          width: 76,
          height: 58,
          child: FilledButton(
            onPressed: () {},
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF6E56B4), padding: EdgeInsets.zero),
            child: Icon(icon, size: 32),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) => Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          appBar: AppBar(
            title: Text(project.name, style: const TextStyle(fontWeight: FontWeight.w900)),
            actions: [
              IconButton(
                tooltip: paused ? 'ادامه' : 'مکث',
                onPressed: () {
                  setState(() => paused = !paused);
                  if (paused) { _ambience.stop(); } else { _ambience.repeat(); }
                  game.setPaused(paused);
                },
                icon: Icon(paused ? Icons.play_arrow_rounded : Icons.pause_rounded),
              ),
              IconButton(
                tooltip: 'شروع دوباره',
                onPressed: () { game.pauseEngine(); setState(() { score = 0; lives = 3; paused = false; _dialogOpen = false; _ambience.repeat(); _createGame(); }); },
                icon: const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFB9E8FF), Color(0xFFE4F7D4), Color(0xFFFFE6B5)],
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 14),
                child: Column(children: [
                  Row(children: [
                    _statusPill('⭐ $score', const Color(0xFFFFF1BE)),
                    const SizedBox(width: 8),
                    _statusPill('❤️ $lives', const Color(0xFFFFDDE4)),
                    const Spacer(),
                    _statusPill('مرحله ${project.activeLevel + 1}/${project.levels.length}', const Color(0xFFE8E0FF)),
                  ]),
                  const SizedBox(height: 10),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          AnimatedBuilder(
                            animation: _ambience,
                            builder: (context, child) => RepaintBoundary(
                              child: CustomPaint(
                                painter: GameBackdropPainter(project.background, phase: _ambience.value),
                              ),
                            ),
                          ),
                          GameWidget<PlatformerPhysicsGame>(key: ObjectKey(game), game: game),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                    _directionButton(Icons.arrow_back_rounded, -1),
                    SizedBox(
                      width: 112,
                      height: 58,
                      child: FilledButton.icon(
                        onPressed: game.jump,
                        icon: const Icon(Icons.arrow_upward_rounded),
                        label: const Text('پرش'),
                        style: FilledButton.styleFrom(backgroundColor: const Color(0xFFED9B39)),
                      ),
                    ),
                    _directionButton(Icons.arrow_forward_rounded, 1),
                  ]),
                ]),
              ),
            ),
          ),
          floatingActionButton: paused
              ? FloatingActionButton.extended(
                  onPressed: () { setState(() => paused = false); _ambience.repeat(); game.setPaused(false); },
                  icon: const Icon(Icons.play_arrow), label: const Text('ادامه'),
                )
              : null,
        ),
      );

  Widget _statusPill(String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(18)),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF3D315B))),
      );
}
