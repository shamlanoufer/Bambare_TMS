
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/booking_background.dart';
import '../../core/theme.dart';
import '../../models/privacy_security_prefs.dart';
import '../../services/auth_service.dart';
import '../../services/data_export_service.dart';
import '../../services/privacy_security_service.dart';
import '../../utils/pdf_save.dart';

class PrivacySecurityScreen extends StatefulWidget {
  const PrivacySecurityScreen({super.key});

  @override
  State<PrivacySecurityScreen> createState() => _PrivacySecurityScreenState();
}

class _PrivacySecurityScreenState extends State<PrivacySecurityScreen> {
  final _svc = PrivacySecurityService();
  final _auth = AuthService();
  final _export = DataExportService();

  bool _saving = false;
  bool _exporting = false;
  bool _deleting = false;

  @override
  void initState() {
    super.initState();
    _ensureAnonymousAuth();
  }

  Future<void> _ensureAnonymousAuth() async {
    if (FirebaseAuth.instance.currentUser != null) return;
    try {
      await FirebaseAuth.instance.signInAnonymously();
    } catch (_) {}
    if (mounted) setState(() {});
  }

  Future<void> _save(PrivacySecurityPrefs next) async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await _svc.upsert(next);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _downloadMyData() async {
    if (_exporting) return;
    setState(() => _exporting = true);
    try {
      final bytes = await _export.generateMyDataPdf();
      final now = DateTime.now();
      final name =
          'my_data_${now.year}_${now.month.toString().padLeft(2, '0')}_${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}';
      final savedTo = await savePdfBytes(bytes: bytes, baseName: name);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            savedTo == null
                ? 'Could not save PDF on this device'
                : 'PDF saved: $savedTo',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Download failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _deleteAccountFlow() async {
    if (_deleting) return;
    final emailCtrl = TextEditingController(
      text: FirebaseAuth.instance.currentUser?.email ?? '',
    );
    final passCtrl = TextEditingController();

    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        final w = MediaQuery.sizeOf(context).width;
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          child: Container(
            width: w < 520 ? w - 32 : 520,
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
            decoration: BoxDecoration(
              color: const Color(0xFFF6EFE6),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Confirm Deletion',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.black,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Enter your credentials to permanently delete your account and all data.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    height: 1.35,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.grey,
                  ),
                ),
                const SizedBox(height: 14),
                _input(
                  controller: emailCtrl,
                  label: 'Email Address',
                  icon: Icons.mail_outline,
                ),
                const SizedBox(height: 10),
                _input(
                  controller: passCtrl,
                  label: 'Password',
                  icon: Icons.lock_outline,
                  obscure: true,
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 10),
                    FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFEF4444),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Confirm Delete'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (confirm != true) {
      emailCtrl.dispose();
      passCtrl.dispose();
      return;
    }

    setState(() => _deleting = true);
    try {
      await _auth.deleteAccountWithEmailPassword(
        email: emailCtrl.text.trim(),
        password: passCtrl.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account deleted.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Delete failed: $e')),
      );
    } finally {
      emailCtrl.dispose();
      passCtrl.dispose();
      if (mounted) setState(() => _deleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.paddingOf(context).top;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: BookingBackgroundLayer(
        child: StreamBuilder<PrivacySecurityPrefs>(
          stream: _svc.myPrefsStream(),
          builder: (context, snap) {
            final prefs = snap.data ?? PrivacySecurityPrefs.defaults;
            return ListView(
              padding: EdgeInsets.fromLTRB(18, topPad + 10, 18, 18),
              children: [
                Row(
                  children: [
                    Material(
                      color: Colors.black.withValues(alpha: 0.10),
                      shape: const CircleBorder(),
                      child: IconButton(
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: const Icon(Icons.arrow_back_ios_new_rounded),
                        iconSize: 18,
                        color: AppTheme.black,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Privacy & Security',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.black,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _section('Security'),
                _card([
                  _toggleRow(
                    icon: Icons.security_rounded,
                    title: 'Two-Factor Authentication',
                    sub: 'Extra layer of security',
                    value: prefs.twoFactorAuth,
                    onChanged: (v) => _save(prefs.copyWith(twoFactorAuth: v)),
                  ),
                  _divider(),
                  _toggleRow(
                    icon: Icons.remove_red_eye_outlined,
                    title: 'Public Profile',
                    sub: 'Others can find your profile',
                    value: prefs.publicProfile,
                    onChanged: (v) => _save(prefs.copyWith(publicProfile: v)),
                  ),
                ]),
                const SizedBox(height: 18),
                _section('Security'),
                _card([
                  _toggleRow(
                    icon: Icons.location_on_outlined,
                    title: 'Location Sharing',
                    sub: 'Share location with guides',
                    value: prefs.locationSharing,
                    onChanged: (v) => _save(prefs.copyWith(locationSharing: v)),
                  ),
                  _divider(),
                  _toggleRow(
                    icon: Icons.bar_chart_outlined,
                    title: 'Analytics & Improvements',
                    sub: 'Help improve the app',
                    value: prefs.analyticsImprovements,
                    onChanged: (v) =>
                        _save(prefs.copyWith(analyticsImprovements: v)),
                  ),
                ]),
                const SizedBox(height: 18),
                _section('Data Management'),
                _card([
                  _navRow(
                    icon: Icons.download_rounded,
                    title: 'Download My Data',
                    sub: 'Get a copy of your data',
                    trailing: _exporting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.chevron_right_rounded),
                    onTap: _exporting ? null : _downloadMyData,
                  ),
                  _divider(),
                  _navRow(
                    icon: Icons.delete_outline_rounded,
                    title: 'Delete Account',
                    sub: 'Permanently remove everything',
                    titleColor: const Color(0xFFEF4444),
                    onTap: _deleting ? null : _deleteAccountFlow,
                  ),
                ]),
                if (_saving)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(
                      'Saving…',
                      textAlign: TextAlign.right,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.grey,
                      ),
                    ),
                  ),
                const SizedBox(height: 24),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _section(String t) => Padding(
        padding: const EdgeInsets.only(left: 6, bottom: 10),
        child: Text(
          t,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            color: AppTheme.black,
          ),
        ),
      );

  Widget _card(List<Widget> children) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.10),
              blurRadius: 16,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(children: children),
      );

  Widget _divider() => Divider(
        height: 16,
        color: Colors.black.withValues(alpha: 0.12),
      );

  Widget _toggleRow({
    required IconData icon,
    required String title,
    required String sub,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
        Icon(icon, color: Colors.black87),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.black,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                sub,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.grey,
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          activeThumbColor: Colors.black,
          activeTrackColor: Colors.black.withValues(alpha: 0.25),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _navRow({
    required IconData icon,
    required String title,
    required String sub,
    Widget? trailing,
    Color? titleColor,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: titleColor ?? Colors.black87),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: titleColor ?? AppTheme.black,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  sub,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.grey,
                  ),
                ),
              ],
            ),
          ),
          trailing ?? const Icon(Icons.chevron_right_rounded),
        ],
      ),
    );
  }
}

Widget _input({
  required TextEditingController controller,
  required String label,
  required IconData icon,
  bool obscure = false,
}) {
  return TextField(
    controller: controller,
    obscureText: obscure,
    decoration: InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.12)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.12)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppTheme.black, width: 1.5),
      ),
    ),
  );
}

