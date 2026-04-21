// lib/screens/main_shell.dart
import 'package:flutter/material.dart';
import '../core/theme.dart';
import 'home/home_screen.dart';
import 'bookings/bookings_screen.dart';
import 'map/map_screen.dart';
import 'profile/profile_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  // 5 tabs but index 2 is the centre bee button (no separate screen)
  static const List<Widget> _pages = [
    HomeScreen(),
    BookingsScreen(),
    SizedBox.shrink(), // placeholder – centre button has no tab
    MapScreen(),
    ProfileScreen(),
  ];

  void _onTabTapped(int index) {
    // Centre bee button shows a snack / future action
    if (index == 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🐝 Coming soon – your BeeTravel hub!'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppTheme.black,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.white,
      // IndexedStack keeps all pages alive so state isn't lost
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: _buildBottomBar(),
      floatingActionButton: _buildBeeButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildBottomBar() {
    return BottomAppBar(
      color: Colors.white,
      elevation: 12,
      shadowColor: Colors.black.withValues(alpha: 0.12),
      notchMargin: 8,
      shape: const CircularNotchedRectangle(),
      child: SizedBox(
        height: 60,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _navItem(icon: Icons.home_rounded, label: 'HOME', index: 0),
            _navItem(icon: Icons.bookmark_border_rounded, label: 'BOOKINGS', index: 1),
            // Centre spacer for FAB notch
            const SizedBox(width: 56),
            _navItem(icon: Icons.map_outlined, label: 'MAP', index: 3),
            _navItem(icon: Icons.person_outline_rounded, label: 'PROFILE', index: 4),
          ],
        ),
      ),
    );
  }

  Widget _navItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final bool isActive = _currentIndex == index;
    return GestureDetector(
      onTap: () => _onTabTapped(index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 22,
              color: isActive ? AppTheme.black : AppTheme.grey,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                color: isActive ? AppTheme.black : AppTheme.grey,
                letterSpacing: 0.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBeeButton() {
    return GestureDetector(
      onTap: () => _onTabTapped(2),
      child: Container(
        width: 58,
        height: 58,
        decoration: BoxDecoration(
          color: AppTheme.yellow,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppTheme.yellow.withValues(alpha: 0.45),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Image.asset(
            'image/bee_logo.png',
            width: 32,
            height: 32,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Icon(
              Icons.travel_explore_rounded,
              size: 28,
              color: AppTheme.black,
            ),
          ),
        ),
      ),
    );
  }
}
