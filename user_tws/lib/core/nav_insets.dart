// lib/core/nav_insets.dart
import 'package:flutter/material.dart';

/// Must match [MainShell] / [_LiquidNavBar]: `SizedBox(height: barHeight + 20)` and
/// `Positioned(bottom: MediaQuery.padding.bottom + 10)`.
abstract final class FloatingNavLayout {
  /// Same as `_NavStyle.barHeight` in `main_shell.dart` (liquid bar paint height).
  static const double barPaintHeight = 85;
  /// Extra stack space above the bar for the floating orb (`+ 20` in `_LiquidNavBar`).
  static const double stackExtension = 20;
  /// Same as the `+ 12` in `Positioned(bottom: … + 12)`.
  static const double shellBottomGap = 12;
  /// Extra space so the last list row / button clears the nav comfortably.
  static const double scrollBreathingRoom = 20;

  /// Total height taken by the floating nav block from the bottom of the screen.
  static double get navBlockHeight =>
      barPaintHeight + stackExtension + shellBottomGap;

  /// Bottom inset for scroll views so content is not hidden under the pill bar.
  static double scrollBottomPadding(BuildContext context) {
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    return navBlockHeight + safeBottom + scrollBreathingRoom;
  }
}
