import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/services.dart';
import 'features/more/more_screen.dart';
import 'features/prayer/prayer_screen.dart';
import 'features/qibla/qibla_screen.dart';
import 'features/quran/surah_list_screen.dart';
import 'theme/ornament.dart';
import 'theme/palette.dart';
import 'theme/theme.dart';

class AlBukhariApp extends StatelessWidget {
  const AlBukhariApp({super.key, required this.services, this.home});
  final Services services;

  /// Overrides the first screen (used by screenshot tests).
  final Widget? home;

  @override
  Widget build(BuildContext context) {
    return AppScope(
      services: services,
      child: MaterialApp(
        title: 'Al Bukhari',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        builder: (context, child) => AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle.light.copyWith(
            statusBarColor: Colors.transparent,
            systemNavigationBarColor: Palette.paper,
            systemNavigationBarIconBrightness: Brightness.dark,
          ),
          child: child!,
        ),
        home: home ?? const HomeShell(),
      ),
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key, this.initialTab = 0});
  final int initialTab;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  late int _tab = widget.initialTab;

  static const _tabs = [
    ('Quran', Icons.menu_book_outlined, Icons.menu_book_rounded),
    ('Qibla', Icons.explore_outlined, Icons.explore_rounded),
    ('Prayer', Icons.schedule_outlined, Icons.schedule_rounded),
    ('More', Icons.more_horiz, Icons.more_horiz),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Only the open tab is built, so the compass and timers rest when hidden.
      body: switch (_tab) {
        0 => const SurahListScreen(),
        1 => const QiblaScreen(),
        2 => const PrayerScreen(),
        _ => const MoreScreen(),
      },
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          color: Palette.paper,
          border: Border(top: BorderSide(color: Palette.tan)),
        ),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              for (final (i, (label, icon, filled)) in _tabs.indexed)
                Expanded(
                  child: _TabButton(
                    label: label,
                    icon: i == _tab ? filled : icon,
                    selected: i == _tab,
                    onTap: () => setState(() => _tab = i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? Palette.greenDeep : Palette.inkSoft;
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 3),
            Text(
              label,
              style: T.label.copyWith(
                fontSize: 12,
                color: color,
                fontVariations: [FontVariation('wght', selected ? 600 : 500)],
              ),
            ),
            const SizedBox(height: 4),
            // The active tab carries the small eight-pointed star.
            CustomPaint(
              size: const Size(8, 8),
              painter: _StarDot(visible: selected),
            ),
            const SizedBox(height: 6),
          ],
        ),
      ),
    );
  }
}

class _StarDot extends CustomPainter {
  const _StarDot({required this.visible});
  final bool visible;

  @override
  void paint(Canvas canvas, Size size) {
    if (!visible) return;
    canvas.drawPath(
      starPath(size.center(Offset.zero), size.width / 2),
      Paint()..color = Palette.green,
    );
  }

  @override
  bool shouldRepaint(_StarDot oldDelegate) => oldDelegate.visible != visible;
}
