// lib/screens/profile/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/theme.dart';
import '../../services/auth_service.dart';
import '../../models/user_model.dart';
import '../auth/login_screen.dart';
import 'edit_profile_screen.dart';
import 'dart:convert';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _auth = AuthService();
  UserModel? _user;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final uid = _auth.currentUser?.uid;
    if (uid != null) {
      final user = await _auth.getUserData(uid);
      if (mounted) {
        setState(() {
          _user = user;
          _loading = false;
        });
      }
    } else {
      if (mounted) setState(() => _loading = false);
    }
  }


  Future<void> _signOut() async {
    await _auth.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  void _editProfile() {
    if (_user == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditProfileScreen(user: _user!),
      ),
    ).then((updated) {
      if (updated == true) {
        _loadUser();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: AppTheme.white,
        body: Center(child: CircularProgressIndicator(color: AppTheme.yellow)),
      );
    }

    final name = _user?.fullName ?? 'Traveller';
    final email = _user != null && _user!.email.isNotEmpty ? _user!.email : FirebaseAuth.instance.currentUser?.email ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F0),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── Hero Header ─────────────────────────────────
            _buildHero(name, email),

            const SizedBox(height: 16),

            // ── Stats Row ────────────────────────────────────
            _buildStats(_user),

            const SizedBox(height: 20),

            // ── ACCOUNT Section ──────────────────────────────
            _sectionLabel('ACCOUNT'),
            _buildMenuCard([
              _menuTile('📋', 'My Bookings', '3 upcoming', () {}),
              _divider(),
              _menuTile('📍', 'Saved Places', '12 saved tours', () {}),
              _divider(),
              _menuTile('💰', 'Expense Reports', 'View history', () {}),
              _divider(),
              _menuTile('🪪', 'Travel Documents', 'Passport, visa', () {}),
              _divider(),
              _menuTile('⚙️', 'Settings', 'App settings, theme, and more', () {}),
            ]),

            const SizedBox(height: 20),

            // ── PREFERENCES Section ──────────────────────────
            _sectionLabel('PREFERENCES'),
            _buildMenuCard([
              _menuTile('🔔', 'Notifications', 'Manage alerts', () {}),
              _divider(),
              _menuTile('🔒', 'Privacy & Security', '2FA enabled · Biometric on', () {}),
              _divider(),
              _menuTile('🌟', 'Travel Preferences', 'Cultural, Food, Beach', () {}),
              _divider(),
              _menuTile('🌐', 'Language & Region', 'English · LKR', () {}),
            ]),

            const SizedBox(height: 24),

            // ── Sign Out ─────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GestureDetector(
                onTap: _signOut,
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
                  child: const Text(
                    'Sign out',
                    style: TextStyle(
                      color: AppTheme.black,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ── Hero Header ────────────────────────────────────────────
  Widget _buildHero(String name, String email) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFFFFF8DC),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 28),
      child: Row(
        children: [
          // Avatar
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              GestureDetector(
                onTap: _editProfile,
                child: Container(
                  width: 78,
                  height: 78,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFE0E0E0),
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    image: _user?.photoUrl != null && _user!.photoUrl.isNotEmpty
                        ? DecorationImage(
                            image: _user!.photoUrl.startsWith('data:image')
                                ? MemoryImage(base64Decode(_user!.photoUrl.split(',').last)) as ImageProvider
                                : NetworkImage(_user!.photoUrl),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: _user?.photoUrl == null || _user!.photoUrl.isEmpty
                      ? const Icon(Icons.person, size: 38, color: Colors.grey)
                      : null,
                ),
              ),
              GestureDetector(
                onTap: _editProfile,
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: const BoxDecoration(color: AppTheme.black, shape: BoxShape.circle),
                  child: const Icon(Icons.edit_rounded, size: 12, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          // Name / Email / Badge
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.black,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  email,
                  style: const TextStyle(fontSize: 12, color: AppTheme.grey),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppTheme.yellow,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Premium Member',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.black,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Stats Row ──────────────────────────────────────────────
  Widget _buildStats(UserModel? user) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _statCard('${user?.toursCount ?? 0}', 'Tours'),
          const SizedBox(width: 12),
          _statCard('★${user?.rating ?? 0.0}', 'Rating'),
          const SizedBox(width: 12),
          _statCard('${user?.savedCount ?? 0}', 'Saved'),
        ],
      ),
    );
  }

  Widget _statCard(String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
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
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.black,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: AppTheme.grey),
            ),
          ],
        ),
      ),
    );
  }

  // ── Section Label ──────────────────────────────────────────
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

  // ── Menu Card ──────────────────────────────────────────────
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

  Widget _menuTile(String emoji, String title, String subtitle, VoidCallback onTap) {
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
          ? Text(subtitle, style: const TextStyle(fontSize: 11, color: AppTheme.grey))
          : null,
      trailing: const Icon(Icons.chevron_right_rounded, color: AppTheme.grey, size: 20),
    );
  }

  Widget _divider() {
    return const Divider(height: 1, indent: 56, endIndent: 16, color: Color(0xFFF0F0F0));
  }
}
