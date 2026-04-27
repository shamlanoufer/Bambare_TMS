import 'package:flutter/material.dart';

import 'theme_controller.dart';

class ThemeScope extends InheritedNotifier<ThemeController> {
  const ThemeScope({
    required ThemeController super.notifier,
    required super.child,
    super.key,
  });

  static ThemeController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<ThemeScope>();
    assert(scope != null, 'ThemeScope not found');
    return scope!.notifier!;
  }
}
