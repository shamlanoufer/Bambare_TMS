// lib/screens/auth/forgot/reset_password_screen.dart
// ─────────────────────────────────────────────────────────────────
// RESET PASSWORD SCREEN
// Called after OTP verified in forgot password phone flow.
// This screen:
//   1. User enters new password
//   2. Calls resetPasswordWithPhoneOtp()
//   3. Firebase Auth password is updated
//   4. Firestore passwordUpdatedAt is updated
//   5. Sign out → go to login screen
// ─────────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';
import '../../../core/theme.dart';
import '../../../core/widgets.dart';
import '../../../services/auth_service.dart';
import '../login_screen.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String verificationId;
  final String otp;

  const ResetPasswordScreen({
    super.key,
    required this.verificationId,
    required this.otp,
  });

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _auth = AuthService();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscurePass = true;
  bool _obscureConfirm = true;
  bool _loading = false;

  @override
  void dispose() {
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    final pass = _passCtrl.text;
    final confirm = _confirmCtrl.text;

    // Validations
    if (pass.isEmpty || confirm.isEmpty) {
      showMsg(context, 'Please enter Password');
      return;
    }
    if (pass.length < 8) {
      showMsg(context, 'Password must be at least 8 characters');
      return;
    }
    if (!RegExp(r'^(?=.*[A-Z])(?=.*\d)').hasMatch(pass)) {
      showMsg(context,
          'Password must contain at least 1 capital letter and 1 number');
      return;
    }
    if (pass != confirm) {
      showMsg(context, 'Passwords do not match');
      return;
    }

    setState(() => _loading = true);

    try {
      // This method:
      // 1. Signs in with phone OTP (verificationId + otp)
      // 2. Updates Firebase Auth password
      // 3. Updates Firestore passwordUpdatedAt field
      await _auth.resetPasswordWithPhoneOtp(
        verificationId: widget.verificationId,
        otp: widget.otp,
        newPassword: pass,
      );

      if (!mounted) return;

      showMsg(
        context,
        '✅ Password changed! Please login with your new password',
        isError: false,
      );

      await _auth.signOut();
      await Future.delayed(const Duration(seconds: 1));

      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    } catch (e) {
      if (mounted) {
        showMsg(context, parseFirebaseError(e.toString()));
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.white,
      body: SafeArea(
        child: Column(
          children: [
            const BeeHeader(),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: AppTheme.cardDark,
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(32)),
                ),
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Reset password', style: AppTheme.heading),
                    const SizedBox(height: 8),
                    const Text(
                      'Your new password must be different from previous used passwords.',
                      style: AppTheme.subText,
                    ),
                    const SizedBox(height: 28),

                    // ── New Password ─────────────────────────────
                    const FieldLabel('Password'),
                    DarkField(
                      controller: _passCtrl,
                      hint: 'New password',
                      obscure: _obscurePass,
                      suffix: IconButton(
                        icon: Icon(
                          _obscurePass
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: AppTheme.grey,
                          size: 20,
                        ),
                        onPressed: () =>
                            setState(() => _obscurePass = !_obscurePass),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'At least 8 characters, 1 capital letter, 1 number',
                      style: TextStyle(color: AppTheme.grey, fontSize: 11),
                    ),
                    const SizedBox(height: 16),

                    // ── Confirm Password ─────────────────────────
                    const FieldLabel('Confirm Password'),
                    DarkField(
                      controller: _confirmCtrl,
                      hint: 'Confirm new password',
                      obscure: _obscureConfirm,
                      suffix: IconButton(
                        icon: Icon(
                          _obscureConfirm
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: AppTheme.grey,
                          size: 20,
                        ),
                        onPressed: () =>
                            setState(() => _obscureConfirm = !_obscureConfirm),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Both passwords must be the same',
                      style: TextStyle(color: AppTheme.grey, fontSize: 11),
                    ),

                    const Spacer(),

                    PrimaryBtn(
                      label: 'Reset Password',
                      onTap: _resetPassword,
                      loading: _loading,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
