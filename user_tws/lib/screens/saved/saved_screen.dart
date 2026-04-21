import 'package:flutter/material.dart';
import '../../core/theme.dart';

/// Bookmark tab — saved tours / favourites (placeholder).
class SavedScreen extends StatelessWidget {
  const SavedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.bookmark_border_rounded,
                  size: 56,
                  color: AppTheme.grey.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Saved',
                  style: TextStyle(
                    color: AppTheme.black,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Places you save will appear here.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppTheme.grey,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
