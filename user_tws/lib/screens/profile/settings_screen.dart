import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../core/theme.dart';
import '../../services/auth_service.dart';
import '../auth/login_screen.dart';
import '../bookings/my_bookings_screen.dart';
import '../bookings/notifications_screen.dart';
import '../bookings/saved_places_screen.dart';
import '../expenses/monthly_report_screen.dart';
import '../travel_documents/travel_documents_screen.dart';
import 'language_region_screen.dart';
import 'privacy_security_screen.dart';
import 'travel_preferences_screen.dart';

class SettingsScreen extends StatelessWidget {
  SettingsScreen({super.key});

  final _auth = AuthService();

  Future<void> _signOut(BuildContext context) async {
    await _auth.signOut();
    if (!context.mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F0),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Settings',
          style: TextStyle(
            color: AppTheme.black,
            fontWeight: FontWeight.w800,
          ),
        ),
        iconTheme: const IconThemeData(color: AppTheme.black),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 6),
            _sectionLabel('ACCOUNT'),
            _buildMenuCard([
              _menuTile(
                context,
                '📋',
                'My Bookings',
                '3 upcoming',
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MyBookingsScreen()),
                ),
              ),
              _divider(),
              _menuTile(
                context,
                '📍',
                'Saved Places',
                '12 saved tours',
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SavedPlacesScreen()),
                ),
              ),
              _divider(),
              _menuTile(
                context,
                '💰',
                'Expense Reports',
                'View history',
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MonthlyReportScreen()),
                ),
              ),
              _divider(),
              _menuTile(
                context,
                '🪪',
                'Travel Documents',
                'Passport, visa',
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TravelDocumentsScreen()),
                ),
              ),
            ]),
            const SizedBox(height: 18),
            _sectionLabel('PREFERENCES'),
            _buildMenuCard([
              _menuTile(
                context,
                '🔔',
                'Notifications',
                'Manage alerts',
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const NotificationsScreen(),
                  ),
                ),
              ),
              _divider(),
              _menuTile(
                context,
                '🔒',
                'Privacy & Security',
                '2FA enabled · Biometric on',
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PrivacySecurityScreen()),
                ),
              ),
              _divider(),
              _menuTile(
                context,
                '🌟',
                'Travel Preferences',
                'Cultural, Food, Beach',
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const TravelPreferencesScreen(),
                  ),
                ),
              ),
              _divider(),
              _menuTile(
                context,
                '🌐',
                'Language & Region',
                'English · LKR',
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LanguageRegionScreen()),
                ),
              ),
            ]),
            const SizedBox(height: 24),

            // ── Sign Out (moved from profile) ─────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GestureDetector(
                onTap: () => _signOut(context),
                child: Container(
                  width: double.infinity,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppTheme.yellow,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.yellow.withValues(alpha: 0.4),
                        blurRadius: 14,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    FirebaseAuth.instance.currentUser == null
                        ? 'Sign in'
                        : 'Sign out',
                    style: const TextStyle(
                      color: AppTheme.black,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: AppTheme.grey,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }

  Widget _buildMenuCard(List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(children: children),
      ),
    );
  }

  Widget _menuTile(
    BuildContext context,
    String emoji,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Text(emoji, style: const TextStyle(fontSize: 22)),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppTheme.black,
        ),
      ),
      subtitle: subtitle.isNotEmpty
          ? Text(subtitle,
              style: const TextStyle(fontSize: 11, color: AppTheme.grey))
          : null,
      trailing: const Icon(Icons.chevron_right_rounded,
          color: AppTheme.grey, size: 20),
    );
  }

  Widget _divider() {
    return const Divider(
      height: 1,
      indent: 56,
      endIndent: 16,
      color: Color(0xFFF0F0F0),
    );
  }
}

