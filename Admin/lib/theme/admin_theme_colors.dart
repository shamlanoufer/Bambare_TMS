import 'package:flutter/material.dart';

/// Semantic colors for the admin panel (light / dark).
@immutable
class AdminThemeColors extends ThemeExtension<AdminThemeColors> {
  const AdminThemeColors({
    required this.pageBackground,
    required this.sidebarBackground,
    required this.surface,
    required this.border,
    required this.muted,
    required this.textPrimary,
    required this.textBody,
    required this.inputFill,
    required this.chipBg,
    required this.topBarBackground,
    required this.dialogBackground,
  });

  final Color pageBackground;
  final Color sidebarBackground;
  final Color surface;
  final Color border;
  final Color muted;
  final Color textPrimary;
  final Color textBody;
  final Color inputFill;
  final Color chipBg;
  final Color topBarBackground;
  final Color dialogBackground;

  static const dark = AdminThemeColors(
    pageBackground: Color(0xFF0D1117),
    sidebarBackground: Color(0xFF161B22),
    surface: Color(0xFF161B22),
    border: Color(0xFF2A3244),
    muted: Color(0xFF8B949E),
    textPrimary: Color(0xFFFFFFFF),
    textBody: Color(0xFFE6EDF3),
    inputFill: Color(0xFF1C2330),
    chipBg: Color(0xFF1C2330),
    topBarBackground: Color(0xFF161B22),
    dialogBackground: Color(0xFF1C2330),
  );

  static const light = AdminThemeColors(
    pageBackground: Color(0xFFF2F4F8),
    sidebarBackground: Color(0xFFFFFFFF),
    surface: Color(0xFFFFFFFF),
    border: Color(0xFFD0D7DE),
    muted: Color(0xFF57606A),
    textPrimary: Color(0xFF24292F),
    textBody: Color(0xFF24292F),
    inputFill: Color(0xFFF6F8FA),
    chipBg: Color(0xFFE6EDF3),
    topBarBackground: Color(0xFFFFFFFF),
    dialogBackground: Color(0xFFFFFFFF),
  );

  @override
  AdminThemeColors copyWith({
    Color? pageBackground,
    Color? sidebarBackground,
    Color? surface,
    Color? border,
    Color? muted,
    Color? textPrimary,
    Color? textBody,
    Color? inputFill,
    Color? chipBg,
    Color? topBarBackground,
    Color? dialogBackground,
  }) {
    return AdminThemeColors(
      pageBackground: pageBackground ?? this.pageBackground,
      sidebarBackground: sidebarBackground ?? this.sidebarBackground,
      surface: surface ?? this.surface,
      border: border ?? this.border,
      muted: muted ?? this.muted,
      textPrimary: textPrimary ?? this.textPrimary,
      textBody: textBody ?? this.textBody,
      inputFill: inputFill ?? this.inputFill,
      chipBg: chipBg ?? this.chipBg,
      topBarBackground: topBarBackground ?? this.topBarBackground,
      dialogBackground: dialogBackground ?? this.dialogBackground,
    );
  }

  @override
  AdminThemeColors lerp(ThemeExtension<AdminThemeColors>? other, double t) {
    if (other is! AdminThemeColors) return this;
    return AdminThemeColors(
      pageBackground: Color.lerp(pageBackground, other.pageBackground, t)!,
      sidebarBackground:
          Color.lerp(sidebarBackground, other.sidebarBackground, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      border: Color.lerp(border, other.border, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textBody: Color.lerp(textBody, other.textBody, t)!,
      inputFill: Color.lerp(inputFill, other.inputFill, t)!,
      chipBg: Color.lerp(chipBg, other.chipBg, t)!,
      topBarBackground:
          Color.lerp(topBarBackground, other.topBarBackground, t)!,
      dialogBackground:
          Color.lerp(dialogBackground, other.dialogBackground, t)!,
    );
  }
}

extension AdminPalette on BuildContext {
  AdminThemeColors get adminColors =>
      Theme.of(this).extension<AdminThemeColors>() ?? AdminThemeColors.dark;
}
