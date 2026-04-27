import 'package:flutter/material.dart';

import 'admin_theme_colors.dart';

class AppThemes {
  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF6A1B9A),
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: AdminThemeColors.light.pageBackground,
      extensions: const [AdminThemeColors.light],
    );
  }

  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF6A1B9A),
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: AdminThemeColors.dark.pageBackground,
      extensions: const [AdminThemeColors.dark],
    );
  }
}
