// lib/screens/auth/login_screen.dart
import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../services/auth_service.dart';
import '../main_shell.dart';
import 'phone_otp_screen.dart';
import 'forgot/forgot_screen.dart';
import 'signup/signup_controller.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _auth = AuthService();

  // Email mode
  final _emailCtrl = TextEditingController();
  final _emailPassCtrl = TextEditingController();

  // Phone mode
  final _phoneCtrl = TextEditingController();
  final _phonePassCtrl = TextEditingController();

  bool _obscure = true;
  bool _loading = false;
  bool _isPhoneMode = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _emailPassCtrl.dispose();
    _phoneCtrl.dispose();
    _phonePassCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_isPhoneMode) {
      final rawPhone = _phoneCtrl.text.trim();
      final pass = _phonePassCtrl.text;
      if (rawPhone.isEmpty || pass.isEmpty) {
        showMsg(context, 'Please enter Phone number and Password');
        return;
      }
      setState(() => _loading = true);
      // Actual implementation might differ if login with phone+password is supported directly by auth_service
      // Assuming phone login requires OTP for this template
      final phone = AuthService.formatPhone(rawPhone);
      await _auth.sendPhoneLoginOtp(
        phone: phone,
        onSent: (verificationId) {
          if (!mounted) return;
          setState(() => _loading = false);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PhoneOtpScreen(
                verificationId: verificationId,
                phone: phone,
                mode: OtpMode.phoneLogin,
              ),
            ),
          );
        },
        onError: (e) {
          if (mounted) {
            setState(() => _loading = false);
            showMsg(context, parseFirebaseError(e));
          }
        },
      );
    } else {
      final email = _emailCtrl.text.trim();
      final pass = _emailPassCtrl.text;
      if (email.isEmpty || pass.isEmpty) {
        showMsg(context, 'Please enter Email and Password');
        return;
      }
      setState(() => _loading = true);
      try {
        await _auth.loginWithEmail(email: email, password: pass);
        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const MainShell()),
          (_) => false,
        );
      } catch (e) {
        if (mounted) showMsg(context, parseFirebaseError(e.toString()));
      }
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _socialLogin(String provider) async {
    setState(() => _loading = true);
    try {
      if (provider == 'Google') {
        final ok = await _auth.signInWithGoogle();
        if (!ok || !mounted) return; // user cancelled Google dialog
      } else if (provider == 'Apple') {
        await _auth.signInWithApple();
      }
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const MainShell()),
        (_) => false,
      );
    } catch (e) {
      if (mounted) showMsg(context, parseFirebaseError(e.toString()));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _buildToggleInput() {
    if (_isPhoneMode) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PhoneField(
            controller: _phoneCtrl,
            hint: 'Enter your phone',
          ),
          const SizedBox(height: 14),
          DarkField(
            controller: _phonePassCtrl,
            hint: 'Password',
            obscure: _obscure,
            suffix: IconButton(
              icon: Icon(
                _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: AppTheme.grey,
                size: 20,
              ),
              onPressed: () => setState(() => _obscure = !_obscure),
            ),
          ),
        ],
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DarkField(
            controller: _emailCtrl,
            hint: 'Email Address',
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 14),
          DarkField(
            controller: _emailPassCtrl,
            hint: 'Password',
            obscure: _obscure,
            suffix: IconButton(
              icon: Icon(
                _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: AppTheme.grey,
                size: 20,
              ),
              onPressed: () => setState(() => _obscure = !_obscure),
            ),
          ),
        ],
      );
    }
  }

  Widget _buildSocialBtn(String text, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: Container(
          width: double.infinity,
          height: 54,
          decoration: BoxDecoration(
            color: const Color(0xFF2C2C2E),
            borderRadius: BorderRadius.circular(28),
          ),
          alignment: Alignment.center,
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.white,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            const BeeHeader(),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: AppTheme.cardDark,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(28, 36, 28, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text('Welcome! 👋', style: AppTheme.heading),
                      const SizedBox(height: 32),
                      
                      _buildToggleInput(),
                      
                      const SizedBox(height: 6),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const ForgotScreen()),
                          ),
                          style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                          child: const Text('Forgot Password?',
                              style: TextStyle(color: AppTheme.grey, fontSize: 13, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      PrimaryBtn(
                          label: 'Sign In', onTap: _login, loading: _loading),
                          
                      const SizedBox(height: 24),
                      
                      Row(
                        children: [
                          const Expanded(child: Divider(color: Color(0xFF4A4A4C), thickness: 0.5)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text('OR CONTINUE WITH', style: TextStyle(color: AppTheme.grey.withValues(alpha: 0.7), fontSize: 10, letterSpacing: 1.0)),
                          ),
                          const Expanded(child: Divider(color: Color(0xFF4A4A4C), thickness: 0.5)),
                        ],
                      ),
                      const SizedBox(height: 24),
                      
                      _buildSocialBtn(
                        _isPhoneMode ? 'Continue with email' : 'Continue with phone',
                        () => setState(() => _isPhoneMode = !_isPhoneMode),
                      ),
                      _buildSocialBtn('Continue with Google', () => _socialLogin('Google')),
                      _buildSocialBtn('Continue with Apple', () => _socialLogin('Apple')),
                      
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text("Don't have an account? ",
                              style: TextStyle(color: AppTheme.grey, fontSize: 13)),
                          GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const SignupController()),
                            ),
                            child: const Text('Sign Up',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
