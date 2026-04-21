import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'center_action_screen.dart';
import 'explore_dashboard_screen.dart';
import 'placeholder_tab_screen.dart';

/// Landing shell: off-white body + notched bottom bar (HOME default).
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tabIndex = 0;

  static const _accentYellow = Color(0xFFE8B800);
  static const _bg = Color(0xFFFFFBF0);
  static const _inactiveGrey = Color(0xFF9E9E9E);

  void _onTab(int index) {
    setState(() => _tabIndex = index);
  }

  Future<void> _openCenterAction() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => const CenterActionScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      extendBody: true,
      body: Column(
        children: [
          Expanded(
            child: IndexedStack(
              index: _tabIndex,
              children: const [
                _HomeTabBody(),
                ExploreDashboardScreen(),
                PlaceholderTabScreen(
                  title: 'Map',
                  message: 'Map view will appear here.',
                ),
                PlaceholderTabScreen(
                  title: 'Profile',
                  message: 'Account and settings will appear here.',
                ),
              ],
            ),
          ),
          _NotchedBottomBar(
            tabIndex: _tabIndex,
            onTab: _onTab,
            onCenterTap: _openCenterAction,
            accentYellow: _accentYellow,
            inactiveGrey: _inactiveGrey,
          ),
        ],
      ),
    );
  }
}

class _HomeTabBody extends StatelessWidget {
  const _HomeTabBody();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Color(0xFFFFFBF0),
      child: SizedBox.expand(),
    );
  }
}

class _NotchedBottomBar extends StatelessWidget {
  const _NotchedBottomBar({
    required this.tabIndex,
    required this.onTab,
    required this.onCenterTap,
    required this.accentYellow,
    required this.inactiveGrey,
  });

  final int tabIndex;
  final ValueChanged<int> onTab;
  final VoidCallback onCenterTap;
  final Color accentYellow;
  final Color inactiveGrey;

  static const double _barHeight = 78;
  static const double _notchRadius = 40;
  static const double _fabSize = 58;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return SizedBox(
      height: _barHeight + bottomInset + 12,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            top: 12,
            child: CustomPaint(
              painter: _NotchedBarPainter(notchRadius: _notchRadius),
              child: const SizedBox.expand(),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: bottomInset,
            height: _barHeight,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: _NavItem(
                      label: 'HOME',
                      selected: tabIndex == 0,
                      selectedIcon: Icons.home,
                      unselectedIcon: Icons.home_outlined,
                      onTap: () => onTab(0),
                      selectedColor: accentYellow,
                      inactiveColor: inactiveGrey,
                    ),
                  ),
                  Expanded(
                    child: _NavItem(
                      label: 'BOOKINGS',
                      selected: tabIndex == 1,
                      selectedIcon: Icons.menu_book_rounded,
                      unselectedIcon: Icons.menu_book_outlined,
                      onTap: () => onTab(1),
                      selectedColor: accentYellow,
                      inactiveColor: inactiveGrey,
                    ),
                  ),
                  const SizedBox(width: _fabSize + 8),
                  Expanded(
                    child: _NavItem(
                      label: 'MAP',
                      selected: tabIndex == 2,
                      selectedIcon: Icons.map,
                      unselectedIcon: Icons.map_outlined,
                      onTap: () => onTab(2),
                      selectedColor: accentYellow,
                      inactiveColor: inactiveGrey,
                    ),
                  ),
                  Expanded(
                    child: _NavItem(
                      label: 'PROFILE',
                      selected: tabIndex == 3,
                      selectedIcon: Icons.person,
                      unselectedIcon: Icons.person_outline,
                      onTap: () => onTab(3),
                      selectedColor: accentYellow,
                      inactiveColor: inactiveGrey,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 0,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onCenterTap,
                child: Ink(
                  width: _fabSize,
                  height: _fabSize,
                  decoration: BoxDecoration(
                    color: accentYellow,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: accentYellow.withValues(alpha: 0.45),
                        blurRadius: 14,
                        spreadRadius: 1,
                        offset: const Offset(0, 4),
                      ),
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: _BeeGlyph(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BeeGlyph extends StatelessWidget {
  const _BeeGlyph();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(26, 22),
      painter: _BeePainter(),
    );
  }
}

class _BeePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final body = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;
    final wing = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final cx = size.width / 2;
    final cy = size.height / 2;
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy), width: 10, height: 14),
      body,
    );
    final hex = Path();
    const r = 5.0;
    for (var i = 0; i < 6; i++) {
      final a = (i * math.pi / 3) - math.pi / 6;
      final x = cx + r * math.cos(a);
      final y = cy + r * math.sin(a) * 0.55 - 2;
      if (i == 0) {
        hex.moveTo(x, y);
      } else {
        hex.lineTo(x, y);
      }
    }
    hex.close();
    canvas.drawPath(hex, wing);
    final hex2 = Path();
    for (var i = 0; i < 6; i++) {
      final a = (i * math.pi / 3) - math.pi / 6;
      final x = cx + r * math.cos(a);
      final y = cy + r * math.sin(a) * 0.55 + 4;
      if (i == 0) {
        hex2.moveTo(x, y);
      } else {
        hex2.lineTo(x, y);
      }
    }
    hex2.close();
    canvas.drawPath(hex2, wing);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _NotchedBarPainter extends CustomPainter {
  _NotchedBarPainter({required this.notchRadius});

  final double notchRadius;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final r = notchRadius;

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(cx - r, 0)
      ..addArc(
        Rect.fromCircle(center: Offset(cx, 0), radius: r),
        math.pi,
        math.pi,
      )
      ..lineTo(w, 0)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();

    canvas.drawShadow(path, Colors.black26, 6, false);
    canvas.drawPath(path, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant _NotchedBarPainter oldDelegate) =>
      oldDelegate.notchRadius != notchRadius;
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.label,
    required this.selected,
    required this.selectedIcon,
    required this.unselectedIcon,
    required this.onTap,
    required this.selectedColor,
    required this.inactiveColor,
  });

  final String label;
  final bool selected;
  final IconData selectedIcon;
  final IconData unselectedIcon;
  final VoidCallback onTap;
  final Color selectedColor;
  final Color inactiveColor;

  @override
  Widget build(BuildContext context) {
    final color = selected ? selectedColor : inactiveColor;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: Colors.black12,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 10, top: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Icon(
                selected ? selectedIcon : unselectedIcon,
                color: color,
                size: 26,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
