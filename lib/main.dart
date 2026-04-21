import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/expense_tracking_screen.dart';
import 'screens/all_expenses_screen.dart';
import 'screens/monthly_report_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));
  runApp(const TravelExpenseApp());
}

class TravelExpenseApp extends StatelessWidget {
  const TravelExpenseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Travel Expense Tracker',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const MainNavigationWrapper(),
    );
  }
}

class AppTheme {
  static const Color cyan        = Color(0xFF00C9D4);
  static const Color yellow      = Color(0xFFF7CE45);
  static const Color yellowLight = Color(0xFFFFEEB9);
  static const Color green       = Color(0xFF92C687);
  static const Color blue        = Color(0xFF42BFF4);
  static const Color orange      = Color(0xFFFF9000);
  static const Color pink        = Color(0xFFF775C1);
  static const Color red         = Color(0xFFEA523E);
  static const Color lightGray   = Color(0xFFD9D9D9);
  static const Color bgGray      = Color(0xFFD3D3D3);

  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: cyan),
    scaffoldBackgroundColor: Colors.white,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      iconTheme: IconThemeData(color: Colors.black),
    ),
  );
}

class MainNavigationWrapper extends StatefulWidget {
  const MainNavigationWrapper({super.key});

  @override
  State<MainNavigationWrapper> createState() => _MainNavigationWrapperState();
}

class _MainNavigationWrapperState extends State<MainNavigationWrapper> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final screens = [
      const ExpenseTrackingScreen(),
      const AllExpensesScreen(),
      const MonthlyReportScreen(),
      const MonthlyReportScreen(), // Profile placeholder
    ];

    return Scaffold(
      body: screens[_currentIndex],
      bottomNavigationBar: _BottomNavBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}

class _BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  const _BottomNavBar({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    const items = [
      [Icons.home_outlined, 'HOME'],
      [Icons.list_alt_outlined, 'EXPENSES'],
      [Icons.bar_chart_outlined, 'REPORT'],
      [Icons.person_outline, 'PROFILE'],
    ];

    return Container(
      height: 72,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFEEEEEE))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(items.length, (i) {
          final isActive = i == currentIndex;
          return GestureDetector(
            onTap: () => onTap(i),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(items[i][0] as IconData,
                    color: isActive ? AppTheme.cyan : Colors.grey, size: 24),
                const SizedBox(height: 4),
                Text(items[i][1] as String,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                      color: isActive ? AppTheme.cyan : Colors.grey,
                    )),
              ],
            ),
          );
        }),
      ),
    );
  }
}