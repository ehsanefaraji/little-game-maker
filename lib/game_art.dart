import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'game_models.dart';

/// Lightweight vector artwork: crisp at every screen density and requires no
/// downloaded images or network access.
class GameTileArt extends StatelessWidget {
  const GameTileArt({
    super.key,
    required this.type,
    required this.value,
    this.character = 0,
    this.isPlayer = false,
  });

  final GameType type;
  final int value;
  final int character;
  final bool isPlayer;

  @override
  Widget build(BuildContext context) => CustomPaint(
        painter: _GameTilePainter(
          type: type,
          value: value,
          character: character,
          isPlayer: isPlayer,
        ),
        child: const SizedBox.expand(),
      );
}

class _GameTilePainter extends CustomPainter {
  _GameTilePainter({
    required this.type,
    required this.value,
    required this.character,
    required this.isPlayer,
  }) : _paint = Paint()..isAntiAlias = true;

  final GameType type;
  final int value;
  final int character;
  final bool isPlayer;

  final Paint _paint;

  void _fill(Color color) => _paint
    ..color = color
    ..style = PaintingStyle.fill;

  void _round(Canvas canvas, Rect rect, double radius, Color color) {
    _fill(color);
    canvas.drawRRect(RRect.fromRectAndRadius(rect, Radius.circular(radius)), _paint);
  }

  void _circle(Canvas canvas, Offset center, double radius, Color color) {
    _fill(color);
    canvas.drawCircle(center, radius, _paint);
  }

  void _stroke(Canvas canvas, Path path, Color color, double width) {
    _paint
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, _paint);
    _paint.style = PaintingStyle.fill;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final scale = size.shortestSide / 48;
    canvas.save();
    canvas.scale(scale);
    final w = size.width / scale;
    final h = size.height / scale;

    if (type == GameType.driving) {
      _paintRoadCell(canvas, w, h);
    } else if (type == GameType.platformer && value == 1) {
      _paintPlatform(canvas, w, h);
    } else if (type == GameType.maze && value == 1) {
      _paintWall(canvas, w, h);
    } else if (type == GameType.memory && value > 0) {
      _paintMemoryAnimal(canvas, w, h);
    } else if (isPlayer) {
      _paintHero(canvas, w, h);
    } else if (value == 2) {
      _paintGem(canvas, w, h);
    } else if (value == 3) {
      _paintEnemy(canvas, w, h);
    } else if (value == 4) {
      _paintGoal(canvas, w, h);
    } else if (value == 5) {
      _paintStart(canvas, w, h);
    }
    canvas.restore();
  }

  void _paintWall(Canvas canvas, double w, double h) {
    _round(canvas, Rect.fromLTWH(3, 7, w - 6, h - 10), 7, const Color(0xFF9279C9));
    _round(canvas, Rect.fromLTWH(4, 5, w - 8, h * .35), 5, const Color(0xFFBBA9EC));
    _fill(const Color(0xFF8067B8));
    canvas.drawLine(Offset(w * .5, 6), Offset(w * .5, h * .37), _paint..strokeWidth = 2);
    canvas.drawLine(Offset(4, h * .65), Offset(w - 4, h * .65), _paint..strokeWidth = 2);
  }

  void _paintPlatform(Canvas canvas, double w, double h) {
    _round(canvas, Rect.fromLTWH(1, 9, w - 2, h - 10), 5, const Color(0xFF95613E));
    _round(canvas, Rect.fromLTWH(1, 5, w - 2, 13), 5, const Color(0xFF65B95E));
    _fill(const Color(0xFF9BDB71));
    for (var x = 8.0; x < w; x += 13) {
      canvas.drawCircle(Offset(x, 9), 3, _paint);
    }
  }

  void _paintGem(Canvas canvas, double w, double h) {
    final path = Path()
      ..moveTo(w * .5, h * .08)
      ..lineTo(w * .88, h * .38)
      ..lineTo(w * .68, h * .9)
      ..lineTo(w * .32, h * .9)
      ..lineTo(w * .12, h * .38)
      ..close();
    _fill(const Color(0xFF22B9D7));
    canvas.drawPath(path, _paint);
    _fill(const Color(0xFF9CF5F5));
    canvas.drawPath(Path()..moveTo(w * .5, h * .08)..lineTo(w * .48, h * .72)..lineTo(w * .12, h * .38)..close(), _paint);
    _fill(const Color(0xFF5DE0E7));
    canvas.drawPath(Path()..moveTo(w * .5, h * .08)..lineTo(w * .88, h * .38)..lineTo(w * .52, h * .72)..close(), _paint);
  }

  void _paintEnemy(Canvas canvas, double w, double h) {
    _circle(canvas, Offset(w * .5, h * .55), w * .34, const Color(0xFFE66C87));
    _circle(canvas, Offset(w * .25, h * .28), w * .13, const Color(0xFFE66C87));
    _circle(canvas, Offset(w * .75, h * .28), w * .13, const Color(0xFFE66C87));
    _circle(canvas, Offset(w * .38, h * .49), 2.8, Colors.white);
    _circle(canvas, Offset(w * .62, h * .49), 2.8, Colors.white);
    _circle(canvas, Offset(w * .39, h * .5), 1.2, const Color(0xFF332B4D));
    _circle(canvas, Offset(w * .63, h * .5), 1.2, const Color(0xFF332B4D));
    final mouth = Path()..moveTo(w * .38, h * .68)..quadraticBezierTo(w * .5, h * .78, w * .63, h * .67);
    _stroke(canvas, mouth, const Color(0xFF8B354C), 1.8);
  }

  void _paintGoal(Canvas canvas, double w, double h) {
    _round(canvas, Rect.fromLTWH(w * .22, h * .16, w * .56, h * .76), 7, const Color(0xFF8C5BBD));
    _round(canvas, Rect.fromLTWH(w * .3, h * .25, w * .4, h * .67), 5, const Color(0xFFFFD36A));
    _circle(canvas, Offset(w * .62, h * .6), 2, const Color(0xFF8C5BBD));
    _circle(canvas, Offset(w * .5, h * .12), 4, const Color(0xFFFFE89A));
  }

  void _paintStart(Canvas canvas, double w, double h) {
    _round(canvas, Rect.fromLTWH(w * .17, h * .2, w * .66, h * .68), 5, const Color(0xFF4DAD82));
    _fill(Colors.white);
    for (var row = 0; row < 3; row++) {
      for (var col = 0; col < 3; col++) {
        if ((row + col).isEven) {
          canvas.drawRect(Rect.fromLTWH(w * (.25 + col * .17), h * (.3 + row * .17), w * .17, h * .17), _paint);
        }
      }
    }
  }

  void _paintHero(Canvas canvas, double w, double h) {
    final palette = [
      const Color(0xFF5B8FE8), const Color(0xFFE985A6), const Color(0xFFEC9B4E),
      const Color(0xFF64BFA2), const Color(0xFFEA8C52), const Color(0xFF8C91A8),
      const Color(0xFFB27BD7), const Color(0xFF55B9C9),
    ];
    final skin = const Color(0xFFFFD2AE);
    final fur = palette[character.clamp(0, palette.length - 1).toInt()];
    // Soft shadow and compact body.
    _circle(canvas, Offset(w * .5, h * .86), w * .28, const Color(0x22000000));
    _round(canvas, Rect.fromLTWH(w * .25, h * .52, w * .5, h * .37), 9, fur);
    // Ears vary subtly by selected character.
    if (character >= 2) {
      _circle(canvas, Offset(w * .29, h * .28), w * .16, fur);
      _circle(canvas, Offset(w * .71, h * .28), w * .16, fur);
      _circle(canvas, Offset(w * .29, h * .28), w * .08, const Color(0xFFFFC5D7));
      _circle(canvas, Offset(w * .71, h * .28), w * .08, const Color(0xFFFFC5D7));
    } else {
      _round(canvas, Rect.fromLTWH(w * .31, h * .08, w * .38, h * .2), 7, const Color(0xFF674C3B));
    }
    _circle(canvas, Offset(w * .5, h * .39), w * .3, skin);
    _circle(canvas, Offset(w * .39, h * .38), 2.2, const Color(0xFF342B43));
    _circle(canvas, Offset(w * .61, h * .38), 2.2, const Color(0xFF342B43));
    _circle(canvas, Offset(w * .5, h * .48), 2, const Color(0xFFCE7184));
    final smile = Path()..moveTo(w * .42, h * .5)..quadraticBezierTo(w * .5, h * .58, w * .58, h * .5);
    _stroke(canvas, smile, const Color(0xFF9C5663), 1.5);
  }

  void _paintMemoryAnimal(Canvas canvas, double w, double h) {
    final colors = [0xFF5B8FE8, 0xFF64BFA2, 0xFFEA8C52, 0xFFB27BD7, 0xFFE985A6, 0xFF55B9C9, 0xFFD6A64E, 0xFF8C91A8];
    final color = Color(colors[(value - 1).clamp(0, colors.length - 1).toInt()]);
    _circle(canvas, Offset(w * .5, h * .54), w * .34, color);
    _circle(canvas, Offset(w * .28, h * .29), w * .13, color);
    _circle(canvas, Offset(w * .72, h * .29), w * .13, color);
    _circle(canvas, Offset(w * .39, h * .49), 2.5, Colors.white);
    _circle(canvas, Offset(w * .61, h * .49), 2.5, Colors.white);
    _circle(canvas, Offset(w * .39, h * .49), 1.2, inkColor);
    _circle(canvas, Offset(w * .61, h * .49), 1.2, inkColor);
  }

  static const inkColor = Color(0xFF332B4D);

  void _paintRoadCell(Canvas canvas, double w, double h) {
    if (isPlayer) {
      _round(canvas, Rect.fromLTWH(w * .23, h * .12, w * .54, h * .76), 9, const Color(0xFF3988E8));
      _round(canvas, Rect.fromLTWH(w * .31, h * .22, w * .38, h * .25), 6, const Color(0xFFBCEBFF));
      _round(canvas, Rect.fromLTWH(w * .31, h * .61, w * .38, h * .16), 4, const Color(0xFF1D4D8E));
      _round(canvas, Rect.fromLTWH(w * .17, h * .2, w * .1, h * .2), 3, const Color(0xFF242A3A));
      _round(canvas, Rect.fromLTWH(w * .73, h * .2, w * .1, h * .2), 3, const Color(0xFF242A3A));
      _round(canvas, Rect.fromLTWH(w * .17, h * .62, w * .1, h * .2), 3, const Color(0xFF242A3A));
      _round(canvas, Rect.fromLTWH(w * .73, h * .62, w * .1, h * .2), 3, const Color(0xFF242A3A));
    } else if (value == 3) {
      _round(canvas, Rect.fromLTWH(w * .25, h * .22, w * .5, h * .58), 5, const Color(0xFFF1A83C));
      _round(canvas, Rect.fromLTWH(w * .32, h * .28, w * .36, h * .13), 3, const Color(0xFFFFE9B2));
      _round(canvas, Rect.fromLTWH(w * .32, h * .6, w * .36, h * .12), 3, const Color(0xFFCE6A3B));
    } else if (value == 2) {
      _circle(canvas, Offset(w * .5, h * .5), w * .22, const Color(0xFFFFD34E));
      _circle(canvas, Offset(w * .5, h * .5), w * .15, const Color(0xFFFFF0A5));
    }
  }

  @override
  bool shouldRepaint(covariant _GameTilePainter oldDelegate) =>
      oldDelegate.type != type || oldDelegate.value != value ||
      oldDelegate.character != character || oldDelegate.isPlayer != isPlayer;
}

class GameBackdropPainter extends CustomPainter {
  const GameBackdropPainter(this.background, {this.phase = 0});
  final int background;
  final double phase;

  @override
  void paint(Canvas canvas, Size size) {
    final tops = [const Color(0xFFB8E6C1), const Color(0xFF9EDCF5), const Color(0xFF202A64), const Color(0xFFFFC6D8)];
    final bottoms = [const Color(0xFFECF8C9), const Color(0xFFFFE7A8), const Color(0xFF7357A6), const Color(0xFFFFE5A8)];
    final index = background.clamp(0, tops.length - 1).toInt();
    final rect = Offset.zero & size;
    final p = Paint()
      ..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [tops[index], bottoms[index]]).createShader(rect);
    canvas.drawRect(rect, p);

    final night = index == 2;
    final sunPaint = Paint()..color = (night ? const Color(0xFFFFE9A8) : const Color(0xFFFFF1B5)).withOpacity(.88);
    final sunCenter = Offset(size.width * .78, size.height * .18);
    canvas.drawCircle(sunCenter, size.shortestSide * .075, sunPaint);
    canvas.drawCircle(sunCenter, size.shortestSide * .105, Paint()..color = sunPaint.color.withOpacity(.16));

    // Three independently moving cloud groups create a lightweight parallax effect.
    final cloudPaint = Paint()..color = Colors.white.withOpacity(night ? .18 : .48);
    for (var i = 0; i < 5; i++) {
      final speed = .018 + (i % 3) * .012;
      final rawX = size.width * (i * .27 + .03) + phase * size.width * speed;
      final x = rawX % (size.width + 100) - 50;
      final y = size.height * (.12 + (i % 3) * .105);
      final r = size.shortestSide * (.035 + (i % 2) * .012);
      canvas.drawCircle(Offset(x, y), r, cloudPaint);
      canvas.drawCircle(Offset(x + r * .9, y + r * .12), r * .78, cloudPaint);
      canvas.drawCircle(Offset(x - r * .82, y + r * .2), r * .68, cloudPaint);
    }

    void hill(double baseline, double amplitude, double shift, Color color) {
      final path = Path()..moveTo(0, size.height * baseline);
      for (var i = 0; i <= 8; i++) {
        final x = size.width * i / 8;
        final wave = math.sin((i / 8 * math.pi * 2) + shift) * amplitude;
        final y = size.height * (baseline + wave);
        if (i == 0) {
          path.lineTo(x, y);
        } else {
          path.quadraticBezierTo(x - size.width / 16, y - size.height * .035, x, y);
        }
      }
      path..lineTo(size.width, size.height)..lineTo(0, size.height)..close();
      canvas.drawPath(path, Paint()..color = color);
    }

    final far = night ? const Color(0xFF48427F) : const Color(0xFF8BC9A0);
    final middle = night ? const Color(0xFF38376F) : const Color(0xFF65B77F);
    final near = night ? const Color(0xFF292B5A) : const Color(0xFF438E63);
    hill(.68, .035, phase * .35, far.withOpacity(.72));
    hill(.77, .045, phase * .7 + 1.4, middle.withOpacity(.82));
    hill(.88, .035, phase * 1.1 + 2.2, near.withOpacity(.94));

    // Small foreground flowers and grass tufts add scale without heavy textures.
    final flowerColors = [const Color(0xFFFFE28A), const Color(0xFFFFAFC6), const Color(0xFFFFFFFF)];
    for (var i = 0; i < 12; i++) {
      final x = size.width * (i + .5) / 12;
      final y = size.height * (.91 + (i % 3) * .018);
      final color = flowerColors[i % flowerColors.length];
      canvas.drawLine(Offset(x, y + 8), Offset(x, y - 3), Paint()..color = const Color(0xFF347B55)..strokeWidth = 2);
      canvas.drawCircle(Offset(x, y - 4), 3.2, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(covariant GameBackdropPainter oldDelegate) =>
      oldDelegate.background != background || oldDelegate.phase != phase;
}
