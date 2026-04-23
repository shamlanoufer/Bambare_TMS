// lib/screens/main_shell.dart
import 'package:flutter/material.dart';
import '../core/main_shell_tab.dart';
import 'home/home_screen.dart';
import 'bookings/explore_dashboard_screen.dart';
import 'map/map_screen.dart';
import 'profile/profile_screen.dart';
import 'expenses/expenses_home_screen.dart';

/// Navigation bar design constants matching the provided image.
abstract final class _NavStyle {
  static const Color barWhite = Colors.white;
  static const Color barBlack = Color(0xFF1A1A1A);
  
  static const Color activeIcon = Color(0xFF1A1A1A);
  static const Color inactiveIcon = Color(0xFF9E9E9E);
  static const Color activeLabel = Color(0xFF1A1A1A);
  static const Color inactiveLabel = Color(0xFF9E9E9E);

  static const double barHeight = 85;
  static const double indicatorSize = 60;
  static const double notchWidth = 100;
  static const double notchHeight = 42;
  static const double cornerRadius = 35;
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  late final AnimationController _navigationController;
  late Animation<double> _notchAnimation;

  static const List<Widget> _pages = [
    HomeScreen(),
    ExploreDashboardScreen(),
    ExpensesHomeScreen(),
    MapScreen(),
    ProfileScreen(),
  ];

  static const List<({IconData icon, String label})> _tabs = [
    (icon: Icons.home_rounded, label: 'Home'),
    (icon: Icons.receipt_long_rounded, label: 'Bookings'),
    (icon: Icons.account_balance_wallet_rounded, label: 'Expenses'),
    (icon: Icons.map_rounded, label: 'Map'),
    (icon: Icons.person_rounded, label: 'Profile'),
  ];

  @override
  void initState() {
    super.initState();
    MainShellTab.selectTab = (int index) {
      if (!mounted) return;
      if (index < 0 || index >= _pages.length) return;
      // Programmatic switch (e.g. after cancel) — same as tapping the tab.
      _onTabTapped(index);
    };
    _navigationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _notchAnimation = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(parent: _navigationController, curve: Curves.easeInOutCubic),
    );
  }

  @override
  void dispose() {
    MainShellTab.selectTab = null;
    _navigationController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    if (index == _currentIndex) return;

    final start = _currentIndex.toDouble();
    final end = index.toDouble();

    setState(() => _currentIndex = index);

    _notchAnimation = Tween<double>(begin: start, end: end).animate(
      CurvedAnimation(parent: _navigationController, curve: Curves.easeInOutCubic),
    );
    _navigationController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: IndexedStack(
              index: _currentIndex,
              children: _pages,
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: MediaQuery.paddingOf(context).bottom + 12,
            child: AnimatedBuilder(
              animation: _notchAnimation,
              builder: (context, child) {
                return _LiquidNavBar(
                  currentIndex: _currentIndex,
                  animationValue: _notchAnimation.value,
                  onTap: _onTabTapped,
                  tabs: _tabs,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _LiquidNavBar extends StatelessWidget {
  final int currentIndex;
  final double animationValue;
  final ValueChanged<int> onTap;
  final List<({IconData icon, String label})> tabs;

  const _LiquidNavBar({
    required this.currentIndex,
    required this.animationValue,
    required this.onTap,
    required this.tabs,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width - 30;
    final tabWidth = w / tabs.length;
    final notchX = (animationValue + 0.5) * tabWidth;

    return SizedBox(
      height: _NavStyle.barHeight + 20,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          CustomPaint(
            size: Size(w, _NavStyle.barHeight),
            painter: _LiquidNotchPainter(
              notchX: notchX,
              isDark: Theme.of(context).brightness == Brightness.dark,
            ),
          ),
          // Active Indicator
          Positioned(
            left: notchX - _NavStyle.indicatorSize / 2,
            bottom: _NavStyle.barHeight - _NavStyle.notchHeight + 2,
            child: Container(
              width: _NavStyle.indicatorSize,
              height: _NavStyle.indicatorSize,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 12,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(
                tabs[currentIndex].icon,
                size: 30,
                color: _NavStyle.activeIcon,
              ),
            ),
          ),
          // Tab Items
          Row(
            children: [
              for (var i = 0; i < tabs.length; i++)
                Expanded(
                  child: _NavTab(
                    icon: tabs[i].icon,
                    label: tabs[i].label,
                    selected: currentIndex == i,
                    onTap: () => onTap(i),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NavTab extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavTab({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // If selected, we hide the icon here because it's floating above
          Opacity(
            opacity: selected ? 0 : 1,
            child: Icon(
              icon,
              size: 26,
              color: _NavStyle.inactiveIcon,
            ),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                color: selected ? _NavStyle.activeLabel : _NavStyle.inactiveLabel,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LiquidNotchPainter extends CustomPainter {
  final double notchX;
  final bool isDark;

  _LiquidNotchPainter({required this.notchX, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    const r = _NavStyle.cornerRadius;
    const nw = _NavStyle.notchWidth;
    const nh = _NavStyle.notchHeight;

    final path = Path();
    path.moveTo(0, r);
    path.quadraticBezierTo(0, 0, r, 0);

    // Notch start
    path.lineTo(notchX - nw * 0.6, 0);
    
    // Smooth transition into notch (Cubic Bezier for liquid effect)
    path.cubicTo(
      notchX - nw * 0.35, 0,
      notchX - nw * 0.35, nh,
      notchX, nh,
    );
    
    // Smooth transition out of notch
    path.cubicTo(
      notchX + nw * 0.35, nh,
      notchX + nw * 0.35, 0,
      notchX + nw * 0.6, 0,
    );

    path.lineTo(w - r, 0);
    path.quadraticBezierTo(w, 0, w, r);
    path.lineTo(w, h - r);
    path.quadraticBezierTo(w, h, w - r, h);
    path.lineTo(r, h);
    path.quadraticBezierTo(0, h, 0, h - r);
    path.close();

    final paint = Paint()
      ..color = isDark ? _NavStyle.barBlack : _NavStyle.barWhite
      ..style = PaintingStyle.fill;

    canvas.drawShadow(path, Colors.black.withValues(alpha: 0.15), 10, false);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _LiquidNotchPainter oldDelegate) {
    return oldDelegate.notchX != notchX || oldDelegate.isDark != isDark;
  }
}
