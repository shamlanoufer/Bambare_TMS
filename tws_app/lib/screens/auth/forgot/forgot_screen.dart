// lib/screens/auth/forgot/forgot_screen.dart
// ─────────────────────────────────────────────────────────────────
// REAL Firebase flows:
//   EMAIL  → Firebase sends password reset link to email
//   PHONE  → Firebase sends OTP → PhoneOtpScreen → ResetPasswordScreen
// ─────────────────────────────────────────────────────────────────
import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/theme.dart';
import '../../../core/widgets.dart';
import '../../../services/auth_service.dart';
import '../phone_otp_screen.dart';

class ForgotScreen extends StatefulWidget {
  const ForgotScreen({super.key});

  @override
  State<ForgotScreen> createState() => _ForgotScreenState();
}

class _ForgotScreenState extends State<ForgotScreen> {
  bool _loading = false;
  final _auth = AuthService();
  final _identifierCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  bool _isPhoneMode = false;
  Timer? _phoneOtpTimeout;

  @override
  void dispose() {
    _phoneOtpTimeout?.cancel();
    _identifierCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  bool _isEmail(String input) =>
      input.trim().contains('@') && input.trim().contains('.');

  Future<void> _sendReset() async {
    final input = _isPhoneMode ? _phoneCtrl.text.trim() : _identifierCtrl.text.trim();
    if (input.isEmpty) {
      showMsg(context, 'Please enter your ${_isPhoneMode ? "phone number" : "email"}');
      return;
    }

    setState(() => _loading = true);

    try {
      if (!_isPhoneMode && _isEmail(input)) {
        // ── EMAIL: Firebase sends reset link (real OTP not used for email)
        await _auth.sendEmailPasswordReset(input);
        if (!mounted) return;
        setState(() => _loading = false);
        showMsg(
          context,
          'Check your email for the password reset link',
          isError: false,
        );
      } else {
        // ── PHONE: Firebase sends real OTP to phone
        final phone = AuthService.formatPhone(input);
        _phoneOtpTimeout?.cancel();
        _phoneOtpTimeout = Timer(const Duration(seconds: 130), () {
          if (!mounted || !_loading) return;
          setState(() => _loading = false);
          showMsg(
            context,
            'OTP request timed out. Add SHA-1 in Firebase Console — see FIREBASE_PHONE_OTP.md',
          );
        });
        _auth.sendForgotPasswordOtp(
          phone: phone,
          onSent: (verificationId) {
            _phoneOtpTimeout?.cancel();
            if (!mounted) return;
            setState(() => _loading = false);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PhoneOtpScreen(
                  verificationId: verificationId,
                  phone: phone,
                  mode: OtpMode.forgotPassword,
                ),
              ),
            );
          },
          onError: (error) {
            _phoneOtpTimeout?.cancel();
            if (!mounted) return;
            setState(() => _loading = false);
            showMsg(context, parseFirebaseError(error));
          },
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        showMsg(context, parseFirebaseError(e.toString()));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.white,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back_ios_rounded,
                            size: 18, color: AppTheme.black),
                        padding: EdgeInsets.zero,
                      ),
                      const Spacer(),
                      const Text('BeeTravel',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.black)),
                      const Spacer(),
                      const SizedBox(width: 36),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Icon(Icons.travel_explore_rounded,
                      color: AppTheme.yellow, size: 40),
                  const SizedBox(height: 8),
                  const Text('Sign in to continue your adventure',
                      style: TextStyle(fontSize: 12, color: AppTheme.grey)),
                  const SizedBox(height: 16),
                ],
              ),
            ),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: AppTheme.cardDark,
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(32)),
                ),
                child: _Step1Request(
                  emailController: _identifierCtrl,
                  phoneController: _phoneCtrl,
                  isPhoneMode: _isPhoneMode,
                  loading: _loading,
                  onSend: _sendReset,
                  onToggleMode: () => setState(() => _isPhoneMode = !_isPhoneMode),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────
// REQUEST RESET (Email → link | Phone → OTP)
// ──────────────────────────────────────────────────────────────────
class _Step1Request extends StatelessWidget {
  final TextEditingController emailController;
  final TextEditingController phoneController;
  final bool isPhoneMode;
  final bool loading;
  final VoidCallback onSend;
  final VoidCallback onToggleMode;

  const _Step1Request({
    required this.emailController,
    required this.phoneController,
    required this.isPhoneMode,
    required this.loading,
    required this.onSend,
    required this.onToggleMode,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 36, 28, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text('Forgot password?',
              style: AppTheme.heading, textAlign: TextAlign.center),
          const SizedBox(height: 24),
          Text(
            isPhoneMode
                ? 'Enter your registered phone number to receive an OTP.'
                : 'Enter your registered email to receive a reset link.',
            style: AppTheme.subText,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          if (isPhoneMode)
            PhoneField(controller: phoneController)
          else
            DarkField(
              controller: emailController,
              hint: 'Email address',
              textAlign: TextAlign.center,
              keyboardType: TextInputType.emailAddress,
            ),
          const SizedBox(height: 16),
          OutlinePillButton(
            label: isPhoneMode ? 'Use Email instead' : 'Use Phone instead',
            onPressed: onToggleMode,
          ),
          const SizedBox(height: 48),
          PrimaryBtn(
            label: 'Send',
            onTap: onSend,
            loading: loading,
          ),
        ],
      ),
    );
  }
}
