/// Set by [MainShell] so routes above the shell can switch the bottom tab
/// (e.g. Home after booking cancellation).
abstract final class MainShellTab {
  /// [MainShell] bottom index for the home tab ([HomeScreen]).
  static const int homeIndex = 0;

  static void Function(int index)? selectTab;

  /// Selects the home tab — call after [Navigator.popUntil] to the shell.
  static void goHome() => selectTab?.call(homeIndex);
}
