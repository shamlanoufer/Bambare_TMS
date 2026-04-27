import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'screens/splash_screen.dart';
import 'theme/app_themes.dart';
import 'theme/theme_controller.dart';
import 'theme/theme_scope.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const BambareAdminApp());
}

class BambareAdminApp extends StatefulWidget {
  const BambareAdminApp({super.key});

  @override
  State<BambareAdminApp> createState() => _BambareAdminAppState();
}

class _BambareAdminAppState extends State<BambareAdminApp> {
  final ThemeController _themeController = ThemeController();

  @override
  void initState() {
    super.initState();
    _themeController.load();
  }

  @override
  void dispose() {
    _themeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _themeController,
      builder: (context, _) {
        return ThemeScope(
          notifier: _themeController,
          child: MaterialApp(
            title: 'Bambare Travel',
            debugShowCheckedModeBanner: false,
            theme: AppThemes.light,
            darkTheme: AppThemes.dark,
            themeMode: _themeController.themeMode,
            home: const SplashScreen(),
          ),
        );
      },
    );
  }
}
