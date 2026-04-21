import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await _ensureSignedIn();
  runApp(const MyApp());
}

/// Anonymous sign-in so each install has a stable [User.uid] for `bookings` rules.
Future<void> _ensureSignedIn() async {
  final auth = FirebaseAuth.instance;
  if (auth.currentUser != null) return;
  try {
    await auth.signInAnonymously();
  } catch (e, st) {
    debugPrint('Anonymous sign-in failed (enable Anonymous in Firebase Auth): $e\n$st');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bambare Travels',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFFE8B800),
        scaffoldBackgroundColor: const Color(0xFFFFFBF0),
        fontFamily: 'Roboto',
      ),
      home: const HomeScreen(),
    );
  }
}