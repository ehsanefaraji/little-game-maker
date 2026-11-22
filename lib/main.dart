import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'game_audio.dart';
import 'game_models.dart';

const purple = Color(0xFF7657D5);
const ink = Color(0xFF332B4D);

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const LittleGameMaker());
}

class LittleGameMaker extends StatelessWidget {
  const LittleGameMaker({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'بازی‌ساز کوچولو',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: purple),
          scaffoldBackgroundColor: const Color(0xFFF7F4FF),
          appBarTheme: const AppBarTheme(backgroundColor: Color(0xFFF7F4FF), foregroundColor: ink),
        ),
        home: const HomePage(),
      );
}

class ProjectStore {
  static const _key = 'little_game_maker_projects_v2';
  static const _legacyKey = 'lgm_projects_v1';
  static Future<List<GameProject>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key) ?? prefs.getString(_legacyKey);
    if (raw == null) return [];
    try {
      final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
      return list.map(GameProject.fromJson).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> save(List<GameProject> projects) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(projects.map((e) => e.toJson()).toList()));
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<GameProject> projects = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final result = await ProjectStore.load();
    if (mounted) setState(() { projects = result; loading = false; });
  }

  Future<void> _create(GameType type) async {
    final controller = TextEditingController(text: 'بازی ' + type.title + ' من');
    final name = await showDialog<String>(
      context: context,
      builder: (d) => AlertDialog(
        title: Text('ساخت ' + type.title),
        content: TextField(controller: controller, autofocus: true, maxLength: 28, decoration: const InputDecoration(labelText: 'نام بازی')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d), child: const Text('انصراف')),
          FilledButton(onPressed: () => Navigator.pop(d, controller.text.trim()), child: const Text('ساخت بازی')),
        ],
      ),
    );
    controller.dispose();
    if (name == null) return;
    await _openEditor(GameProject.create(type, name.isEmpty ? 'بازی من' : name));
  }

  Future<void> _openEditor(GameProject project) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => EditorPage(project: project.copy())));
    await _refresh();
  }

  Future<void> _delete(GameProject project) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: const Text('حذف بازی'),
        content: Text('«' + project.name + '» حذف شود؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('نه')),
          FilledButton(onPressed: () => Navigator.pop(d, true), child: const Text('حذف')),
        ],
      ),
    );
    if (yes != true) return;
    projects.removeWhere((e) => e.id == project.id);
    await ProjectStore.save(projects);
    if (mounted) setState(() {});
  }

  void _showHelp() {
    showDialog<void>(context: context, builder: (d) => AlertDialog(
      title: const Text('راهنمای بازی‌ساز 🌟'),
      content: const Text('۱. یک قالب بازی انتخاب کن.\n۲. با ابزارهای طراحی، خانه‌های مرحله را بچین.\n۳. شخصیت و پس‌زمینه را انتخاب کن.\n۴. ذخیره را بزن و بازی را امتحان کن.\n\nبازی‌ها روی همین دستگاه ذخیره می‌شوند و برای ویرایش و بازی‌کردن به اینترنت نیاز ندارند.'),
      actions: [FilledButton(onPressed: () => Navigator.pop(d), child: const Text('فهمیدم'))],
    ));
  }

  @override
  Widget build(BuildContext context) => Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          body: loading
              ? const Center(child: CircularProgressIndicator())
              : CustomScrollView(
                  slivers: [
                    SliverAppBar(
                      pinned: true,
                      title: const Text('بازی‌ساز کوچولو 🎮', style: TextStyle(fontWeight: FontWeight.w900)),
                      actions: [IconButton(tooltip: 'راهنما', onPressed: _showHelp, icon: const Icon(Icons.help_outline_rounded)), const SizedBox(width: 6)],
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
                        child: Container(
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [Color(0xFF9A82F0), Color(0xFF6046BE)], begin: Alignment.topRight, end: Alignment.bottomLeft),
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [BoxShadow(color: purple.withOpacity(.22), blurRadius: 20, offset: const Offset(0, 9))],
                          ),
                          child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text('سلام، بازی‌ساز کوچولو! 🌈', style: TextStyle(color: Colors.white, fontSize: 23, fontWeight: FontWeight.w900)),
                            SizedBox(height: 8),
                            Text('یک دنیا بازی بساز؛ شخصیتت را انتخاب کن، مرحله را طراحی کن و نتیجه را بازی کن.', style: TextStyle(color: Colors.white, height: 1.6, fontSize: 14)),
                          ]),
                        ),
                      ),
                    ),
                    const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.fromLTRB(18, 0, 18, 10), child: Text('از کجا شروع کنیم؟', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: ink)))),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: SliverGrid(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final type = GameType.values[index];
                          final colors = [const Color(0xFFE7E0FF), const Color(0xFFFFE9C8), const Color(0xFFDDF5E6), const Color(0xFFFFDFE8)];
                          return InkWell(
                            borderRadius: BorderRadius.circular(22),
                            onTap: () => _create(type),
                            child: Ink(
                              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22), border: Border.all(color: colors[index]), boxShadow: [BoxShadow(color: colors[index].withOpacity(.5), blurRadius: 12, offset: const Offset(0, 5))]),
                              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                                Container(width: 58, height: 58, decoration: BoxDecoration(color: colors[index], borderRadius: BorderRadius.circular(18)), alignment: Alignment.center, child: Text(type.emoji, style: const TextStyle(fontSize: 32))),
                                const SizedBox(height: 9),
                                Text(type.title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: ink)),
                                Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: Text(type.description, textAlign: TextAlign.center, maxLines: 2, style: const TextStyle(fontSize: 10, color: Colors.black54))),
                              ]),
                            ),
                          );
                        }, childCount: GameType.values.length),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.17),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(18, 26, 18, 10),
                        child: Row(children: [
                          const Expanded(child: Text('بازی‌های من', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: ink))),
                          Text(projects.length.toString() + ' بازی', style: const TextStyle(color: Colors.black54)),
                        ]),
                      ),
                    ),
                    if (projects.isEmpty)
                      const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.fromLTRB(16, 0, 16, 28), child: Card(child: Padding(padding: EdgeInsets.all(22), child: Text('هنوز بازی نساخته‌ای. یکی از چهار قالب بالا را انتخاب کن! ✨', textAlign: TextAlign.center)))))
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
                        sliver: SliverList(delegate: SliverChildBuilderDelegate((context, index) {
                          final project = projects[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 9),
                            color: Colors.white,
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                              leading: CircleAvatar(backgroundColor: const Color(0xFFECE6FF), child: Text(project.type.emoji, style: const TextStyle(fontSize: 23))),
                              title: Text(project.name, style: const TextStyle(fontWeight: FontWeight.w800)),
                              subtitle: Text(project.type.title + ' • ' + backgroundNames[project.background]),
                              onTap: () => _openEditor(project),
                              trailing: PopupMenuButton<String>(
                                onSelected: (value) {
                                  if (value == 'edit') _openEditor(project);
                                  if (value == 'play') Navigator.push(context, MaterialPageRoute(builder: (_) => GamePage(project: project.copy())));
                                  if (value == 'delete') _delete(project);
                                },
                                itemBuilder: (_) => const [
                                  PopupMenuItem(value: 'play', child: ListTile(dense: true, leading: Icon(Icons.play_arrow), title: Text('بازی کن'))),
                                  PopupMenuItem(value: 'edit', child: ListTile(dense: true, leading: Icon(Icons.edit), title: Text('ویرایش مرحله'))),
                                  PopupMenuItem(value: 'delete', child: ListTile(dense: true, leading: Icon(Icons.delete_outline), title: Text('حذف'))),
                                ],
                              ),
                            ),
                          );
                        }, childCount: projects.length)),
                      ),
                  ],
                ),
        ),
      );
}

class EditorPage extends StatefulWidget {
  const EditorPage({super.key, required this.project});
  final GameProject project;
  @override
  State<EditorPage> createState() => _EditorPageState();
}

class _EditorPageState extends State<EditorPage> {
  late GameProject project;
  int selected = 1;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    project = widget.project;
    if (project.cells.length != project.columns * project.rows) project.cells = List<int>.filled(project.columns * project.rows, 0);
  }

  List<int> get tools => switch (project.type) {
        GameType.maze => [0, 1, 2, 4, 5],
        GameType.platformer => [0, 1, 2, 3, 4, 5],
        GameType.memory => [0, 1, 2, 3, 4, 5, 6, 7, 8],
        GameType.driving => [0, 2, 3],
      };

  String toolLabel(int value) => switch (project.type) {
        GameType.maze => {0: 'پاک‌کن', 1: 'دیوار', 2: 'گوهر', 4: 'پایان', 5: 'شروع'}[value]!,
        GameType.platformer => {0: 'پاک‌کن', 1: 'سکو', 2: 'سکه', 3: 'دشمن', 4: 'پایان', 5: 'شروع'}[value]!,
        GameType.memory => value == 0 ? 'پاک‌کن' : 'کارت ' + value.toString(),
        GameType.driving => {0: 'خالی', 2: 'جایزه', 3: 'مانع'}[value]!,
      };

  Future<void> _save() async {
    setState(() => saving = true);
    final all = await ProjectStore.load();
    final index = all.indexWhere((p) => p.id == project.id);
    if (index < 0) {
      all.insert(0, project.copy());
    } else {
      all[index] = project.copy();
    }
    await ProjectStore.save(all);
    if (!mounted) return;
    setState(() => saving = false);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('مرحله با موفقیت ذخیره شد 💾')));
  }

  Widget _tool(int value) {
    final selectedNow = selected == value;
    Widget chip() => Container(
      width: 74,
      padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 5),
      decoration: BoxDecoration(
        color: selectedNow ? const Color(0xFFE9E1FF) : const Color(0xFFF8F6FC),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: selectedNow ? purple : Colors.black12, width: selectedNow ? 2 : 1),
      ),
      child: Column(children: [
        Text(tileEmoji(project.type, value), style: const TextStyle(fontSize: 23)),
        const SizedBox(height: 3),
        Text(toolLabel(value), maxLines: 1, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
      ]),
    );
    return Draggable<int>(
      data: value,
      feedback: Material(color: Colors.transparent, child: Transform.scale(scale: 1.08, child: chip())),
      childWhenDragging: Opacity(opacity: .35, child: InkWell(onTap: () => setState(() => selected = value), child: chip())),
      child: InkWell(onTap: () => setState(() => selected = value), borderRadius: BorderRadius.circular(13), child: chip()),
    );
  }

  @override
  Widget build(BuildContext context) => Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          appBar: AppBar(
            title: Text(project.name, style: const TextStyle(fontWeight: FontWeight.w800)),
            actions: [
              IconButton(tooltip: 'پیش‌نمایش بازی', onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => GamePage(project: project.copy()))), icon: const Icon(Icons.play_circle_fill_rounded, color: purple)),
              IconButton(tooltip: 'ذخیره', onPressed: saving ? null : _save, icon: const Icon(Icons.save_rounded)),
            ],
          ),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(14, 4, 14, 18),
              children: [
                Container(padding: const EdgeInsets.all(13), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)), child: Row(children: [
                  Text(project.type.emoji, style: const TextStyle(fontSize: 29)),
                  const SizedBox(width: 10),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('طراحی مرحله ' + project.type.title, style: const TextStyle(fontWeight: FontWeight.w900)), const Text('ابزار را انتخاب کن و روی خانه‌های صفحه بزن.', style: TextStyle(fontSize: 11, color: Colors.black54))])),
                  Text(project.columns.toString() + ' × ' + project.rows.toString(), style: const TextStyle(fontWeight: FontWeight.bold, color: purple)),
                ])),
                const SizedBox(height: 12),
                _buildBoard(),
                const SizedBox(height: 14),
                _sectionTitle('ابزارهای طراحی'),
                const SizedBox(height: 8),
                Wrap(spacing: 7, runSpacing: 7, children: tools.map(_tool).toList()),
                const SizedBox(height: 16),
                _sectionTitle('شخصیت بازی'),
                const SizedBox(height: 8),
                SizedBox(height: 58, child: ListView(scrollDirection: Axis.horizontal, children: List.generate(characterOptions.length, (i) => GestureDetector(
                  onTap: () => setState(() => project.character = i),
                  child: AnimatedContainer(duration: const Duration(milliseconds: 150), width: 54, margin: const EdgeInsets.only(left: 8), decoration: BoxDecoration(color: project.character == i ? const Color(0xFFE9E1FF) : Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: project.character == i ? purple : Colors.black12, width: project.character == i ? 2 : 1)), alignment: Alignment.center, child: Text(characterOptions[i], style: const TextStyle(fontSize: 29))),
                )))),
                const SizedBox(height: 15),
                _sectionTitle('پس‌زمینه کارتونی'),
                const SizedBox(height: 8),
                SizedBox(height: 82, child: ListView(scrollDirection: Axis.horizontal, children: List.generate(backgroundNames.length, (i) => GestureDetector(
                  onTap: () => setState(() => project.background = i),
                  child: AnimatedContainer(duration: const Duration(milliseconds: 160), width: 122, margin: const EdgeInsets.only(left: 9), decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(backgroundTop[i]), Color(backgroundBottom[i])]), borderRadius: BorderRadius.circular(16), border: Border.all(color: project.background == i ? purple : Colors.transparent, width: 3)), alignment: Alignment.center, child: Text(backgroundNames[i], style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: ink))),
                )))),
                const SizedBox(height: 10),
                SwitchListTile(contentPadding: EdgeInsets.zero, value: project.soundEnabled, onChanged: (v) => setState(() => project.soundEnabled = v), secondary: const Icon(Icons.volume_up_rounded, color: purple), title: const Text('صداهای بازی', style: TextStyle(fontWeight: FontWeight.w700)), subtitle: const Text('صدای جمع‌آوری جایزه و برخورد')),
                SwitchListTile(contentPadding: EdgeInsets.zero, value: project.musicEnabled, onChanged: (v) => setState(() => project.musicEnabled = v), secondary: const Icon(Icons.music_note_rounded, color: purple), title: const Text('موسیقی پس‌زمینه', style: TextStyle(fontWeight: FontWeight.w700)), subtitle: const Text('موسیقی شاد ساخته‌شده برای بازی')),
                const SizedBox(height: 8),
                FilledButton.icon(onPressed: saving ? null : _save, icon: const Icon(Icons.save), label: Text(saving ? 'در حال ذخیره...' : 'ذخیره بازی')),
                const SizedBox(height: 8),
                OutlinedButton.icon(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => GamePage(project: project.copy()))), icon: const Icon(Icons.sports_esports), label: const Text('اجرای بازی')),
              ],
            ),
          ),
        ),
      );

  Widget _sectionTitle(String text) => Text(text, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: ink));

  Widget _buildBoard() => Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: purple.withOpacity(.08), blurRadius: 12)]),
        child: AspectRatio(
          aspectRatio: project.columns / project.rows,
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            itemCount: project.cells.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: project.columns, crossAxisSpacing: 3, mainAxisSpacing: 3),
            itemBuilder: (context, index) => DragTarget<int>(
              onAcceptWithDetails: (details) => setState(() => project.cells[index] = details.data),
              builder: (context, candidates, rejected) => GestureDetector(
                onTap: () => setState(() => project.cells[index] = selected),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 100),
                  decoration: BoxDecoration(color: candidates.isNotEmpty ? Colors.amber : tileColor(project.type, project.cells[index]), borderRadius: BorderRadius.circular(5), border: Border.all(color: Colors.black.withOpacity(.07))),
                  alignment: Alignment.center,
                  child: FittedBox(child: Text(tileEmoji(project.type, project.cells[index]), style: const TextStyle(fontSize: 19))),
                ),
              ),
            ),
          ),
        ),
      );
}

class GamePage extends StatefulWidget {
  const GamePage({super.key, required this.project});
  final GameProject project;
  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  late final GameProject project;
  late List<int> cells;
  final random = Random();
  Timer? ticker;
  int score = 0, moves = 0, lives = 3;
  bool paused = false, finished = false;
  int player = 0, playerX = 0, playerY = 0, jumpTicks = 0, lane = 1, roadTick = 0;
  final List<int> roadObjects = [];
  final Set<int> revealed = {}, matched = {};
  int? firstCard;
  bool checkingCards = false;
  late List<int> memoryCards;

  @override
  void initState() {
    super.initState();
    project = widget.project;
    cells = List<int>.from(project.cells);
    GameAudio.instance.configure(sound: project.soundEnabled, music: project.musicEnabled);
    if (project.type == GameType.maze) {
      player = cells.indexOf(5);
      if (player < 0) player = 12;
    } else if (project.type == GameType.platformer) {
      playerX = 0;
      playerY = project.rows - 2;
      ticker = Timer.periodic(const Duration(milliseconds: 190), (_) => _platformTick());
    } else if (project.type == GameType.memory) {
      _makeMemoryCards();
    } else if (project.type == GameType.driving) {
      _resetRoadObjects();
      ticker = Timer.periodic(const Duration(milliseconds: 530), (_) => _driveTick());
    }
  }

  void _makeMemoryCards() {
    final symbols = cells.where((e) => e > 0).toSet().toList();
    while (symbols.length < 8) symbols.add(symbols.length + 1);
    final chosen = symbols.take(8).toList();
    memoryCards = [...chosen, ...chosen]..shuffle(random);
  }

  void _resetRoadObjects() {
    roadObjects.clear();
    for (var i = 0; i < cells.length; i++) {
      if (cells[i] == 3) roadObjects.add((i ~/ project.columns) * 3 + i % 3);
    }
    if (roadObjects.isEmpty) roadObjects.add(1);
  }

  @override
  void dispose() {
    ticker?.cancel();
    GameAudio.instance.configure(sound: project.soundEnabled, music: false);
    super.dispose();
  }

  void _moveMaze(int delta) {
    if (paused || finished) return;
    final next = player + delta;
    if (next < 0 || next >= cells.length) return;
    if ((delta == 1 || delta == -1) && next ~/ project.columns != player ~/ project.columns) return;
    if (cells[next] == 1) { GameAudio.instance.bump(); return; }
    final collected = cells[next] == 2;
    setState(() {
      player = next;
      moves++;
      if (collected) { cells[next] = 0; score++; }
    });
    if (collected) GameAudio.instance.collect();
    if (cells[next] == 4) _finish(true, 'از هزارتو بیرون آمدی و ' + score.toString() + ' گوهر جمع کردی!');
  }

  void _platformMove(int dx) {
    if (paused || finished) return;
    final nextX = (playerX + dx).clamp(0, project.columns - 1).toInt();
    final target = playerY * project.columns + nextX;
    if (cells[target] == 1) { GameAudio.instance.bump(); return; }
    setState(() { playerX = nextX; moves++; _checkPlatformCell(); });
  }

  void _jump() {
    if (paused || finished || jumpTicks > 0 || playerY < project.rows - 2) return;
    setState(() { jumpTicks = 3; playerY = max(0, playerY - 2); moves++; _checkPlatformCell(); });
    GameAudio.instance.effect(frequency: 520, durationMs: 90);
  }

  void _platformTick() {
    if (!mounted || paused || finished) return;
    setState(() {
      if (jumpTicks > 0) {
        jumpTicks--;
        if (jumpTicks == 0) playerY = project.rows - 2;
      } else {
        playerY = project.rows - 2;
      }
      _checkPlatformCell();
    });
  }

  void _checkPlatformCell() {
    final index = playerY * project.columns + playerX;
    if (index < 0 || index >= cells.length) return;
    if (cells[index] == 2) {
      cells[index] = 0; score++; GameAudio.instance.collect();
    } else if (cells[index] == 3) {
      lives--; GameAudio.instance.bump(); playerX = 0;
      if (lives <= 0) _finish(false, 'این بار دشمن‌ها قوی‌تر بودند. دوباره تلاش کن!');
    } else if (cells[index] == 4 || playerX == project.columns - 1) {
      _finish(true, 'به خط پایان رسیدی! امتیاز تو: ' + score.toString());
    }
  }

  void _driveTick() {
    if (!mounted || paused || finished) return;
    setState(() {
      roadTick++;
      for (var i = 0; i < roadObjects.length; i++) { roadObjects[i] += 3; }
      roadObjects.removeWhere((v) => v >= 24);
      if (random.nextDouble() < .62) {
        final newLane = random.nextInt(3);
        final busy = roadObjects.any((v) => v < 3 && v % 3 == newLane);
        if (!busy) roadObjects.add(newLane);
      }
      final collision = roadObjects.any((v) => v >= 21 && v < 24 && v % 3 == lane);
      if (collision) {
        lives--;
        roadObjects.removeWhere((v) => v >= 21 && v < 24 && v % 3 == lane);
        GameAudio.instance.bump();
        if (lives <= 0) _finish(false, 'ماشینت سه بار به مانع خورد. امتیاز: ' + score.toString());
      } else {
        score++;
        if (roadTick % 4 == 0) GameAudio.instance.collect();
      }
    });
  }

  void _changeLane(int delta) {
    if (paused || finished) return;
    setState(() { lane = (lane + delta).clamp(0, 2).toInt(); moves++; });
  }

  void _flipCard(int index) {
    if (paused || finished || checkingCards || revealed.contains(index) || matched.contains(index)) return;
    setState(() => revealed.add(index));
    GameAudio.instance.effect(frequency: 560, durationMs: 65);
    if (firstCard == null) { firstCard = index; return; }
    final first = firstCard!;
    if (memoryCards[first] == memoryCards[index]) {
      setState(() { matched.add(first); matched.add(index); firstCard = null; score += 10; });
      GameAudio.instance.collect();
      if (matched.length == memoryCards.length) _finish(true, 'همه جفت‌ها را پیدا کردی! امتیاز: ' + score.toString());
    } else {
      checkingCards = true;
      Future.delayed(const Duration(milliseconds: 850), () {
        if (!mounted) return;
        setState(() { revealed.remove(first); revealed.remove(index); firstCard = null; checkingCards = false; });
      });
    }
  }

  void _finish(bool success, String message) {
    if (finished || !mounted) return;
    finished = true;
    ticker?.cancel();
    if (success) { GameAudio.instance.success(); } else { GameAudio.instance.bump(); }
    Future.delayed(const Duration(milliseconds: 180), () {
      if (!mounted) return;
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (d) => AlertDialog(
          title: Text(success ? 'آفرین، قهرمان! 🏆' : 'تلاش خوبی بود! 💪'),
          content: Text(message),
          actions: [
            TextButton(onPressed: () { Navigator.pop(d); Navigator.pop(context); }, child: const Text('بازگشت به ویرایشگر')),
            FilledButton(onPressed: () { Navigator.pop(d); _restart(); }, child: const Text('دوباره بازی کن')),
          ],
        ),
      );
    });
  }

  void _restart() {
    ticker?.cancel();
    setState(() {
      cells = List<int>.from(project.cells);
      score = 0; moves = 0; lives = 3; paused = false; finished = false;
      revealed.clear(); matched.clear(); firstCard = null; checkingCards = false;
      player = cells.indexOf(5); if (player < 0) player = 12;
      playerX = 0; playerY = project.rows - 2; jumpTicks = 0; lane = 1; roadTick = 0;
      _resetRoadObjects();
      if (project.type == GameType.memory) _makeMemoryCards();
    });
    if (project.type == GameType.platformer) ticker = Timer.periodic(const Duration(milliseconds: 190), (_) => _platformTick());
    if (project.type == GameType.driving) ticker = Timer.periodic(const Duration(milliseconds: 530), (_) => _driveTick());
  }

  @override
  Widget build(BuildContext context) => Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          appBar: AppBar(
            title: Text(project.name, style: const TextStyle(fontWeight: FontWeight.w900)),
            actions: [
              IconButton(tooltip: paused ? 'ادامه' : 'مکث', onPressed: finished ? null : () => setState(() => paused = !paused), icon: Icon(paused ? Icons.play_arrow_rounded : Icons.pause_rounded)),
              IconButton(tooltip: 'شروع دوباره', onPressed: _restart, icon: const Icon(Icons.refresh_rounded)),
            ],
          ),
          body: Stack(children: [
            GameBackdrop(background: project.background),
            SafeArea(child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 5, 12, 14),
              child: Column(children: [
                _scoreBar(),
                const SizedBox(height: 10),
                Expanded(child: _gameBoard()),
                const SizedBox(height: 10),
                if (paused)
                  FilledButton.icon(onPressed: () => setState(() => paused = false), icon: const Icon(Icons.play_arrow), label: const Text('ادامه بازی'))
                else
                  _controls(),
              ]),
            )),
            if (paused) Positioned.fill(child: Container(color: Colors.black38, alignment: Alignment.center, child: Container(padding: const EdgeInsets.all(22), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22)), child: const Text('⏸ بازی متوقف شده', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900))))),
          ]),
        ),
      );

  Widget _scoreBar() => Row(children: [
        _pill('⭐ ' + score.toString(), const Color(0xFFFFF0BD)),
        const SizedBox(width: 7),
        _pill('حرکت ' + moves.toString(), Colors.white),
        const Spacer(),
        _pill('❤️ ' + lives.toString(), const Color(0xFFFFE0E6)),
      ]);

  Widget _pill(String text, Color color) => Container(padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8), decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)), child: Text(text, style: const TextStyle(fontWeight: FontWeight.w900, color: ink)));

  Widget _gameBoard() {
    switch (project.type) {
      case GameType.maze: return _mazeBoard();
      case GameType.platformer: return _platformBoard();
      case GameType.memory: return _memoryBoard();
      case GameType.driving: return _drivingBoard();
    }
  }

  Widget _mazeBoard() => Center(child: AspectRatio(
    aspectRatio: 1,
    child: Container(
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(color: Colors.white.withOpacity(.85), borderRadius: BorderRadius.circular(20)),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        itemCount: cells.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: project.columns, crossAxisSpacing: 2, mainAxisSpacing: 2),
        itemBuilder: (context, i) {
          final isPlayer = i == player;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            decoration: BoxDecoration(color: cells[i] == 1 ? const Color(0xFF6D5A9E) : cells[i] == 4 ? const Color(0xFFFFD96B) : const Color(0xFFEAF5DF), borderRadius: BorderRadius.circular(4)),
            alignment: Alignment.center,
            child: FittedBox(child: Text(isPlayer ? characterOptions[project.character] : cells[i] == 2 ? '💎' : cells[i] == 4 ? '🚪' : cells[i] == 5 ? '🏁' : '', style: const TextStyle(fontSize: 22))),
          );
        },
      ),
    ),
  ));

  Widget _platformBoard() => Center(child: AspectRatio(
    aspectRatio: 1.2,
    child: Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: Colors.white.withOpacity(.85), borderRadius: BorderRadius.circular(20)),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        itemCount: cells.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: project.columns, crossAxisSpacing: 3, mainAxisSpacing: 3),
        itemBuilder: (context, i) {
          final row = i ~/ project.columns, col = i % project.columns;
          final isPlayer = row == playerY && col == playerX;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            decoration: BoxDecoration(color: cells[i] == 1 ? const Color(0xFF9B7A53) : const Color(0xFFDDF2FF), borderRadius: BorderRadius.circular(5)),
            alignment: Alignment.center,
            child: FittedBox(child: Text(isPlayer ? characterOptions[project.character] : cells[i] == 2 ? '🪙' : cells[i] == 3 ? '👾' : cells[i] == 4 ? '🏆' : cells[i] == 1 ? '🟫' : '', style: const TextStyle(fontSize: 21))),
          );
        },
      ),
    ),
  ));

  Widget _memoryBoard() => Center(child: AspectRatio(
    aspectRatio: 1,
    child: GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 16,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, crossAxisSpacing: 9, mainAxisSpacing: 9),
      itemBuilder: (context, i) {
        final visible = revealed.contains(i) || matched.contains(i);
        return InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: () => _flipCard(i),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: visible ? [Colors.white, const Color(0xFFFFF3C7)] : [const Color(0xFF8D76D8), const Color(0xFF6046B9)]),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: matched.contains(i) ? Colors.green : Colors.white, width: 2),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(.08), blurRadius: 5, offset: const Offset(0, 3))],
            ),
            alignment: Alignment.center,
            child: AnimatedSwitcher(duration: const Duration(milliseconds: 180), child: Text(visible ? tileEmoji(GameType.memory, memoryCards[i]) : '❔', key: ValueKey('$i-$visible'), style: const TextStyle(fontSize: 30))),
          ),
        );
      },
    ),
  ));

  Widget _drivingBoard() => Center(child: AspectRatio(
    aspectRatio: .72,
    child: Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: const Color(0xFF44475A), borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white, width: 4)),
      child: Column(children: List.generate(8, (row) => Expanded(child: Row(children: List.generate(3, (col) {
        final object = roadObjects.any((v) => v ~/ 3 == row && v % 3 == col);
        final car = row == 7 && col == lane;
        return Expanded(child: Container(
          margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(color: col == 1 ? const Color(0xFF656879) : const Color(0xFF55596B), borderRadius: BorderRadius.circular(5)),
          alignment: Alignment.center,
          child: Text(car ? characterOptions[project.character] : object ? '🚧' : randomRoadCoin(row, col) ? '🪙' : row.isEven ? '┊' : '', style: TextStyle(fontSize: car ? 31 : 23, color: Colors.white)),
        ));
      }))))),
    ),
  ));

  bool randomRoadCoin(int row, int col) => (row * 7 + col * 3 + project.id.length) % 11 == 0;

  Widget _controls() {
    switch (project.type) {
      case GameType.maze:
        return Column(children: [
          _controlButton(Icons.keyboard_arrow_up_rounded, () => _moveMaze(-project.columns)),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            _controlButton(Icons.keyboard_arrow_right_rounded, () => _moveMaze(-1)),
            const SizedBox(width: 14),
            _controlButton(Icons.keyboard_arrow_down_rounded, () => _moveMaze(project.columns)),
            const SizedBox(width: 14),
            _controlButton(Icons.keyboard_arrow_left_rounded, () => _moveMaze(1)),
          ]),
        ]);
      case GameType.platformer:
        return Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          _controlButton(Icons.arrow_back_rounded, () => _platformMove(-1)),
          FilledButton.icon(onPressed: _jump, icon: const Icon(Icons.arrow_upward), label: const Text('پرش'), style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16))),
          _controlButton(Icons.arrow_forward_rounded, () => _platformMove(1)),
        ]);
      case GameType.memory:
        return const Padding(padding: EdgeInsets.all(12), child: Text('دو کارت را باز کن و شکل‌های یکسان را پیدا کن.', style: TextStyle(fontWeight: FontWeight.w800)));
      case GameType.driving:
        return Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          _controlButton(Icons.arrow_back_rounded, () => _changeLane(-1)),
          FilledButton.icon(onPressed: () { if (!paused && !finished) setState(() { lane = 1; moves++; }); }, icon: const Icon(Icons.sports_score), label: const Text('مسیر وسط')),
          _controlButton(Icons.arrow_forward_rounded, () => _changeLane(1)),
        ]);
    }
  }

  Widget _controlButton(IconData icon, VoidCallback onPressed) => SizedBox(width: 58, height: 52, child: FilledButton(onPressed: onPressed, style: FilledButton.styleFrom(padding: EdgeInsets.zero, backgroundColor: purple), child: Icon(icon, size: 30)));
}

class GameBackdrop extends StatelessWidget {
  const GameBackdrop({super.key, required this.background});
  final int background;
  @override
  Widget build(BuildContext context) {
    final index = background.clamp(0, backgroundTop.length - 1);
    return Positioned.fill(
      child: DecoratedBox(
        decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(backgroundTop[index]), Color(backgroundBottom[index])])),
        child: Stack(children: [
          Positioned(top: 45, right: 22, child: _bubble(70, Colors.white.withOpacity(.18))),
          Positioned(top: 130, left: 18, child: _bubble(42, Colors.white.withOpacity(.2))),
          Positioned(bottom: 70, right: 30, child: _bubble(55, Colors.white.withOpacity(.18))),
          Positioned(bottom: 25, left: 45, child: _bubble(28, Colors.white.withOpacity(.24))),
          Positioned(top: 28, left: 28, child: Text(
            ['🦋  🌿', '☀️  🐚', '🌙  🪐', '🌈  🍭'][index],
            style: const TextStyle(fontSize: 25),
          )),
          Positioned(bottom: 12, right: 12, child: Text(
            ['🌳  🍄', '🏝️  🌊', '🚀  ⭐', '🍬  🍡'][index],
            style: const TextStyle(fontSize: 27),
          )),
        ]),
      ),
    );
  }

  Widget _bubble(double size, Color color) => Container(width: size, height: size, decoration: BoxDecoration(color: color, shape: BoxShape.circle));
}

Color tileColor(GameType type, int value) {
  if (value == 0) return const Color(0xFFF8F8FF);
  if (type == GameType.maze) return value == 1 ? const Color(0xFFB9A9E8) : value == 2 ? const Color(0xFFFFE9A9) : const Color(0xFFD7F2D6);
  if (type == GameType.platformer) return value == 1 ? const Color(0xFFC9A77D) : value == 2 ? const Color(0xFFFFE9A9) : value == 3 ? const Color(0xFFFFD8D8) : const Color(0xFFDDF2FF);
  if (type == GameType.driving) return value == 3 ? const Color(0xFFFFD8D8) : value == 2 ? const Color(0xFFFFE9A9) : const Color(0xFFE7E7EF);
  return const Color(0xFFE9E1FF);
}

String tileEmoji(GameType type, int value) {
  if (value == 0) return '▫️';
  if (type == GameType.maze) return {1: '🧱', 2: '💎', 4: '🚪', 5: '🏁'}[value] ?? '';
  if (type == GameType.platformer) return {1: '🟫', 2: '🪙', 3: '👾', 4: '🏆', 5: '🏁'}[value] ?? '';
  if (type == GameType.driving) return {2: '🪙', 3: '🚧'}[value] ?? '';
  return {1: '🐱', 2: '🐸', 3: '🦊', 4: '🐼', 5: '🐵', 6: '🐰', 7: '🐻', 8: '🦄'}[value] ?? '';
}
