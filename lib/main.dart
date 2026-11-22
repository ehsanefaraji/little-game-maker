import 'package:flutter/material.dart';

void main() => runApp(const LittleGameMakerApp());

class LittleGameMakerApp extends StatelessWidget {
  const LittleGameMakerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'بازی‌ساز کوچولو',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF7657D5)),
        fontFamily: 'Roboto',
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int stars = 12;
  final List<String> games = ['هزارتوی گنج', 'راه رسیدن به ستاره', 'ماجراجویی جنگل'];
  final List<IconData> icons = [Icons.route_rounded, Icons.star_rounded, Icons.forest_rounded];

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F4FF),
        appBar: AppBar(
          backgroundColor: const Color(0xFF7657D5),
          foregroundColor: Colors.white,
          title: const Text('بازی‌ساز کوچولو', style: TextStyle(fontWeight: FontWeight.bold)),
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Chip(
                avatar: const Icon(Icons.star, color: Colors.amber, size: 19),
                label: Text('$stars'),
                backgroundColor: Colors.white,
              ),
            )
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF9C83F5), Color(0xFF6D55C7)]),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('سلام قهرمان! 🎮', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Text('اینجا می‌تونی بازی خودت رو بسازی و باهاش سرگرم بشی.', style: TextStyle(color: Colors.white, fontSize: 15)),
                ],
              ),
            ),
            const SizedBox(height: 22),
            const Text('بازی‌های من', style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...List.generate(games.length, (i) => Card(
              elevation: 0,
              color: Colors.white,
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFFECE6FF),
                  child: Icon(icons[i], color: const Color(0xFF7657D5)),
                ),
                title: Text(games[i], style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('برای بازی کردن لمس کن'),
                trailing: const Icon(Icons.chevron_left),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MazeEditor(title: games[i]))),
              ),
            )),
            const SizedBox(height: 16),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFFF9D45),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('ساخت بازی جدید', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MazeEditor(title: 'بازی جدید'))),
            ),
            const SizedBox(height: 10),
            const Center(child: Text('بدون نیاز به اینترنت • مناسب کودکان', style: TextStyle(color: Colors.black54))),
          ],
        ),
      ),
    );
  }
}

class MazeEditor extends StatefulWidget {
  const MazeEditor({super.key, required this.title});
  final String title;

  @override
  State<MazeEditor> createState() => _MazeEditorState();
}

class _MazeEditorState extends State<MazeEditor> {
  static const int side = 7;
  final Set<int> walls = {8, 9, 10, 17, 24, 25, 26, 33, 38};
  int player = 0;
  int moves = 0;

  void move(int next) {
    if (next < 0 || next >= side * side || walls.contains(next)) return;
    setState(() { player = next; moves++; });
    if (player == side * side - 1) {
      showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('آفرین قهرمان! 🏆'),
          content: Text('گنج رو در $moves حرکت پیدا کردی!'),
          actions: [TextButton(onPressed: () { Navigator.pop(context); setState(() { player = 0; moves = 0; }); }, child: const Text('دوباره بازی کن'))],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: Text(widget.title)),
        body: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              const Text('به ستاره برس! ⭐', style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text('تعداد حرکت‌ها: $moves'),
              const SizedBox(height: 20),
              AspectRatio(
                aspectRatio: 1,
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: side * side,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: side, crossAxisSpacing: 4, mainAxisSpacing: 4),
                  itemBuilder: (context, index) {
                    final isWall = walls.contains(index);
                    final isGoal = index == side * side - 1;
                    return GestureDetector(
                      onTap: () {
                        if ((index - player).abs() == 1 && index ~/ side == player ~/ side || (index - player).abs() == side) move(index);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: index == player ? const Color(0xFFFFD166) : isWall ? const Color(0xFF7657D5) : Colors.white,
                          borderRadius: BorderRadius.circular(9),
                          border: Border.all(color: const Color(0xFFE1D9F5)),
                        ),
                        child: Center(child: Text(index == player ? '🧒' : isGoal ? '⭐' : isWall ? '' : '')),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              const Text('برای حرکت، خانه‌ی کنار شخصیت را لمس کن.', textAlign: TextAlign.center),
              const Spacer(),
              Wrap(
                spacing: 12,
                children: [
                  IconButton.filled(onPressed: () => move(player - side), icon: const Icon(Icons.keyboard_arrow_up)),
                  IconButton.filled(onPressed: () => move(player + side), icon: const Icon(Icons.keyboard_arrow_down)),
                  IconButton.filled(onPressed: () => move(player - 1), icon: const Icon(Icons.keyboard_arrow_right)),
                  IconButton.filled(onPressed: () => move(player + 1), icon: const Icon(Icons.keyboard_arrow_left)),
                ],
              ),
              TextButton.icon(onPressed: () => setState(() { player = 0; moves = 0; }), icon: const Icon(Icons.refresh), label: const Text('شروع دوباره')),
            ],
          ),
        ),
      ),
    );
  }
}
