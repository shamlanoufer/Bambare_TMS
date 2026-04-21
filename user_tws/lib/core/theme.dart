// lib/core/theme.dart
import 'package:flutter/material.dart';

class AppTheme {
  // ── Colors ──────────────────────────────────────────────
  static const Color black     = Color(0xFF0A0A0A);
  static const Color white     = Color(0xFFF5F5F0);
  static const Color yellow    = Color(0xFFFFCC00);
  static const Color cardDark  = Color(0xFF1A1A1A);
  static const Color inputDark = Color(0xFF2C2C2E);
  static const Color grey      = Color(0xFF8E8E93);

  // ── Text Styles ─────────────────────────────────────────
  static const TextStyle heading = TextStyle(
    color: Colors.white,
    fontSize: 26,
    fontWeight: FontWeight.bold,
    letterSpacing: -0.5,
  );

  static const TextStyle subText = TextStyle(
    color: Color(0xFF8E8E93),
    fontSize: 13,
    height: 1.5,
  );

  static const TextStyle labelStyle = TextStyle(
    color: Colors.white,
    fontSize: 13,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle hintStyle = TextStyle(
    color: Color(0xFF636366),
    fontSize: 15,
  );

  // ── Input Decoration ─────────────────────────────────────
  static InputDecoration inputDecoration({
    required String hint,
    Widget? suffixIcon,
    Widget? prefixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: hintStyle,
      suffixIcon: suffixIcon,
      prefixIcon: prefixIcon,
      filled: true,
      fillColor: inputDark,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: yellow, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.red, width: 1),
      ),
    );
  }

  // ── Button Style ─────────────────────────────────────────
  /// Primary CTA on dark cards: crisp white, dark text, light shadow so it reads as a real button.
  static final ButtonStyle primaryBtn = ElevatedButton.styleFrom(
    backgroundColor: Colors.white,
    foregroundColor: black,
    disabledBackgroundColor: Colors.white,
    disabledForegroundColor: black,
    minimumSize: const Size(double.infinity, 54),
    elevation: 3,
    shadowColor: const Color(0x40000000),
    surfaceTintColor: Colors.transparent,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(30),
    ),
    textStyle: const TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.bold,
      letterSpacing: 0.2,
    ),
  );

  static final ButtonStyle darkBtn = ElevatedButton.styleFrom(
    backgroundColor: cardDark,
    foregroundColor: Colors.white,
    minimumSize: const Size(double.infinity, 54),
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(30),
    ),
    textStyle: const TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w600,
    ),
  );

  // ── Theme Data ────────────────────────────────────────────
  static ThemeData get theme => ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: white,
        colorScheme: const ColorScheme.light(
          primary: black,
          surface: white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(style: primaryBtn),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: inputDark,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
      );
}
