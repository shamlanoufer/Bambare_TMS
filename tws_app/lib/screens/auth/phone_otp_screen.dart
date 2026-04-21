// lib/screens/auth/phone_otp_screen.dart
// ─────────────────────────────────────────────────────────────────
// SHARED OTP SCREEN
// Used for 3 different flows:
//   OtpMode.phoneLogin      → verify → go home
//   OtpMode.forgotPassword  → verify → reset password screen
//   OtpMode.register        → verify + create account → go home
// ─────────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../services/auth_service.dart';
import '../../models/user_model.dart';
import '../main_shell.dart';
import 'forgot/reset_password_screen.dart';

enum OtpMode { phoneLogin, forgotPassword, register }

class PhoneOtpScreen extends StatefulWidget {
  final String verificationId;
  final String phone;
  final OtpMode mode;
  // Used only for register mode
  final UserModel? userModel;
  final String? email;
  final String? password;
  final dynamic photoFile;

  const PhoneOtpScreen({
    super.key,
    required this.verificationId,
    required this.phone,
    required this.mode,
    this.userModel,
    this.email,
    this.password,
    this.photoFile,
  });

  @override
  State<PhoneOtpScreen> createState() => _PhoneOtpScreenState();
}

class _PhoneOtpScreenState extends State<PhoneOtpScreen> {
  final _auth = AuthService();
  late String _verificationId; // Updated on resend
  final List<TextEditingController> _ctrs =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _nodes = List.generate(6, (_) => FocusNode());
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _verificationId = widget.verificationId;
  }

  String get _otp => _ctrs.map((c) => c.text).join();

  @override
  void dispose() {
    for (var c in _ctrs) {
      c.dispose();
    }
    for (var n in _nodes) {
      n.dispose();
    }
    super.dispose();
  }

  // ── Verify OTP based on mode ─────────────────────────────
  Future<void> _verify() async {
    if (_otp.length != 6) {
      showMsg(context, 'Please enter 6 digit OTP');
      return;
    }

    setState(() => _loading = true);

    try {
      switch (widget.mode) {
        // ── Phone Login ─────────────────────────────────────
        case OtpMode.phoneLogin:
          await _auth.verifyPhoneLoginOtp(
            verificationId: _verificationId,
            otp: _otp,
          );
          if (!mounted) return;
          _goHome();

        // ── Forgot Password ─────────────────────────────────
        // Don't verify yet here — pass verificationId + otp to reset screen
        // ResetPasswordScreen will call resetPasswordWithPhoneOtp()
        case OtpMode.forgotPassword:
          setState(() => _loading = false);
          if (!mounted) return;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ResetPasswordScreen(
                verificationId: _verificationId,
                otp: _otp,
              ),
            ),
          );

        // ── Register ────────────────────────────────────────
        case OtpMode.register:
          await _auth.registerWithPhoneVerification(
            verificationId: _verificationId,
            otp: _otp,
            email: widget.email!,
            password: widget.password!,
            userData: widget.userModel!,
            photoFile: widget.photoFile,
          );
          if (!mounted) return;
          showMsg(
            context,
            '✅ Account created! Email verification sent.',
            isError: false,
          );
          _goHome();
      }
    } catch (e) {
      if (mounted) {
        showMsg(context, parseFirebaseError(e.toString()));
        setState(() => _loading = false);
      }
    }
  }

  // ── Resend OTP ───────────────────────────────────────────
  Future<void> _resend() async {
    for (var c in _ctrs) {
      c.clear();
    }
    _nodes.first.requestFocus();

    void onSent(String verificationId) {
      setState(() => _verificationId = verificationId);
      if (mounted) showMsg(context, 'OTP resent', isError: false);
    }
    void onError(String e) => showMsg(context, parseFirebaseError(e));

    if (widget.mode == OtpMode.phoneLogin) {
      _auth.sendPhoneLoginOtp(
          phone: widget.phone, onSent: onSent, onError: onError);
    } else if (widget.mode == OtpMode.forgotPassword) {
      _auth.sendForgotPasswordOtp(
          phone: widget.phone, onSent: onSent, onError: onError);
    } else {
      _auth.sendRegisterOtp(
          phone: widget.phone, onSent: onSent, onError: onError);
    }
  }

  void _goHome() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const MainShell()),
      (_) => false,
    );
  }

  String get _title {
    switch (widget.mode) {
      case OtpMode.phoneLogin:
        return 'Mobile Verification';
      case OtpMode.forgotPassword:
        return 'Verification';
      case OtpMode.register:
        return 'Phone Verification';
    }
  }

  String get _subtitle {
    switch (widget.mode) {
      case OtpMode.phoneLogin:
        return 'OTP sent to your ${widget.phone} number';
      case OtpMode.forgotPassword:
        return 'OTP sent to your registered phone number';
      case OtpMode.register:
        return 'Account will be created after phone verification.\n${widget.phone}';
    }
  }

  String get _btnLabel {
    switch (widget.mode) {
      case OtpMode.phoneLogin:
        return 'Verify & Sign In';
      case OtpMode.forgotPassword:
        return 'Verify';
      case OtpMode.register:
        return 'Verify & Create Account';
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
                    Text(_title, style: AppTheme.heading),
                    const SizedBox(height: 8),
                    Text(_subtitle, style: AppTheme.subText),
                    const SizedBox(height: 40),

                    // ── OTP Boxes (Firebase sends 6-digit OTP) ──
                    OtpBoxes(
                      controllers: _ctrs,
                      focusNodes: _nodes,
                      length: 6,
                      onComplete: _verify,
                    ),

                    const SizedBox(height: 24),
                    Center(
                      child: TextButton(
                        onPressed: _resend,
                        child: RichText(
                          text: const TextSpan(children: [
                            TextSpan(
                                text: "Didn't receive code? ",
                                style:
                                    TextStyle(color: AppTheme.grey, fontSize: 13)),
                            TextSpan(
                                text: 'Resend code',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold)),
                          ]),
                        ),
                      ),
                    ),

                    const Spacer(),

                    PrimaryBtn(
                        label: _btnLabel,
                        onTap: _verify,
                        loading: _loading),

                    if (widget.mode == OtpMode.register) ...[
                      const SizedBox(height: 14),
                      Center(
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: RichText(
                            text: const TextSpan(children: [
                              TextSpan(
                                  text: 'Already have an account? ',
                                  style: TextStyle(
                                      color: AppTheme.grey, fontSize: 13)),
                              TextSpan(
                                  text: 'Sign in',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold)),
                            ]),
                          ),
                        ),
                      ),
                    ],
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
