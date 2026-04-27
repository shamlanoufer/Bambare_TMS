// lib/core/widgets.dart
// ─────────────────────────────────────────────────────────────────
// Shared UI components used across all auth screens
// ─────────────────────────────────────────────────────────────────
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'theme.dart';

// ── Bambare Travel Logo Header ───────────────────────────────────
class BeeHeader extends StatelessWidget {
  const BeeHeader({super.key});

  static const String _logoAsset = 'images/main/logo w name.png';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 22),
      child: Column(
        children: [
          const Text(
            'Bambare Travel',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppTheme.black,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 10),
          Image.asset(
            _logoAsset,
            width: 190,
            height: 72,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
          ),
          const SizedBox(height: 10),
          const Text(
            'Sign in to continue your adventure',
            style: TextStyle(color: AppTheme.grey, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

// ── Dark Card Container (bottom sheet style) ─────────────────────
class DarkCard extends StatelessWidget {
  final Widget child;
  const DarkCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          color: AppTheme.cardDark,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
          child: child,
        ),
      ),
    );
  }
}

// ── Dark Text Field ──────────────────────────────────────────────
class DarkField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool obscure;
  final TextInputType? keyboardType;
  final Widget? suffix;
  final Widget? prefix;
  final TextAlign textAlign;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;

  const DarkField({
    super.key,
    required this.controller,
    required this.hint,
    this.obscure = false,
    this.keyboardType,
    this.suffix,
    this.prefix,
    this.textAlign = TextAlign.start,
    this.validator,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      textAlign: textAlign,
      style: const TextStyle(color: Colors.white, fontSize: 15),
      validator: validator,
      onChanged: onChanged,
      decoration: AppTheme.inputDecoration(
        hint: hint,
        suffixIcon: suffix,
        prefixIcon: prefix,
      ),
    );
  }
}

// ── Phone Input Field ───────────────────────────────────────────
class PhoneField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final String? countryCode;

  const PhoneField({
    super.key,
    required this.controller,
    this.hint = 'Enter your phone',
    this.countryCode = '+94',
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          height: 54,
          width: 76,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppTheme.inputDark,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Text(
            countryCode ?? '+94',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: DarkField(
            controller: controller,
            hint: hint,
            keyboardType: TextInputType.phone,
          ),
        ),
      ],
    );
  }
}

// ── Primary White Button ─────────────────────────────────────────
class PrimaryBtn extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool loading;

  const PrimaryBtn({
    super.key,
    required this.label,
    required this.onTap,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: loading ? null : onTap,
        style: AppTheme.primaryBtn,
        child: loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: AppTheme.black,
                  strokeWidth: 2.5,
                ),
              )
            : Text(label),
      ),
    );
  }
}

// ── Outlined pill (email ↔ phone toggles on dark cards) ───────────
class OutlinePillButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const OutlinePillButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: Colors.transparent,
        side: const BorderSide(color: Colors.white, width: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        minimumSize: const Size(0, 48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
        textStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          letterSpacing: 0.2,
        ),
      ),
      child: Text(label),
    );
  }
}

// ── Dark Social / Secondary Button ───────────────────────────────
class DarkBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final IconData? icon;

  const DarkBtn({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton.icon(
        onPressed: onTap,
        style: AppTheme.darkBtn,
        icon: icon != null
            ? Icon(icon, size: 18, color: Colors.white)
            : const SizedBox.shrink(),
        label: Text(label),
      ),
    );
  }
}

// ── OR Divider ───────────────────────────────────────────────────
class OrDivider extends StatelessWidget {
  const OrDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(child: Divider(color: Color(0xFF3A3A3C))),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'OR CONTINUE WITH',
            style: TextStyle(
              color: Color(0xFF636366),
              fontSize: 11,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Expanded(child: Divider(color: Color(0xFF3A3A3C))),
      ],
    );
  }
}

// ── 6-Box OTP Input ──────────────────────────────────────────────
class OtpBoxes extends StatelessWidget {
  final List<TextEditingController> controllers;
  final List<FocusNode> focusNodes;
  final int length;
  final void Function()? onComplete;

  const OtpBoxes({
    super.key,
    required this.controllers,
    required this.focusNodes,
    this.length = 5,
    this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(length, (i) {
        return SizedBox(
          width: 46,
          height: 56,
          child: TextField(
            controller: controllers[i],
            focusNode: focusNodes[i],
            textAlign: TextAlign.center,
            maxLength: 1,
            keyboardType: TextInputType.number,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
            decoration: InputDecoration(
              counterText: '',
              filled: true,
              fillColor: const Color(0xFF2C2C2E),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: AppTheme.yellow, width: 2),
              ),
            ),
            onChanged: (v) {
              if (v.isNotEmpty) {
                if (i < length - 1) {
                  focusNodes[i + 1].requestFocus();
                } else {
                  focusNodes[i].unfocus();
                  onComplete?.call();
                }
              } else if (v.isEmpty && i > 0) {
                focusNodes[i - 1].requestFocus();
              }
            },
          ),
        );
      }),
    );
  }
}

// ── Field Label ──────────────────────────────────────────────────
class FieldLabel extends StatelessWidget {
  final String text;
  const FieldLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text, style: AppTheme.labelStyle),
    );
  }
}

// ── Helper: show snackbar ─────────────────────────────────────────
void showMsg(BuildContext context, String msg, {bool isError = true}) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(msg),
    backgroundColor:
        isError ? const Color(0xFFFF3B30) : const Color(0xFF34C759),
    behavior: SnackBarBehavior.floating,
    duration: const Duration(seconds: 5),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    margin: const EdgeInsets.all(16),
  ));
}

// ── Helper: parse Firebase error messages ─────────────────────────
String parseFirebaseError(String raw) {
  final s = raw.toLowerCase();

  if (s.contains('wrong-password') || s.contains('invalid-credential')) {
    return 'Incorrect Email or Password';
  }
  if (s.contains('user-not-found')) return 'Account not found';
  if (s.contains('email-already-in-use')) {
    return 'This Email is already in use';
  }
  if (s.contains('weak-password')) return 'Password is too weak';
  if (s.contains('invalid-email')) return 'Invalid Email format';
  if (s.contains('too-many-requests')) {
    return 'Too many requests. Please try again later';
  }
  if (s.contains('invalid-verification-code')) return 'Invalid OTP';
  if (s.contains('session-expired')) {
    return 'OTP expired. Please resend';
  }
  if (s.contains('requires-recent-login')) {
    return 'Please sign in again to change password';
  }
  if (s.contains('network-request-failed') || s.contains('network error')) {
    return 'No internet connection';
  }
  if (s.contains('invalid-phone-number')) {
    return 'Invalid phone number format';
  }
  // Flutter Web: SMS phone auth needs device app
  if (raw.contains('[web]')) {
    return 'Phone OTP is not supported in browser. Please run the app on an Android device or use the APK.';
  }
  // Phone Auth: SHA-1 not configured in Firebase Console
  if (s.contains('missing-client-identifier') ||
      s.contains('app-not-authorized') ||
      s.contains('not_authorized')) {
    return 'Firebase setup needed: Add SHA-1 & SHA-256 in Firebase Console '
        '(Project Settings → Your apps → Android). Run: cd android && gradlew signingReport';
  }
  if (s.contains('invalid-recipient-email') || s.contains('invalid-sender')) {
    return 'Email configuration issue. Check Firebase Auth email templates';
  }
  // Google Sign-In Android: SHA-1 / OAuth
  if (raw.contains('DEVELOPER_ERROR')) {
    return 'Google sign-in: Enable Google in Firebase Auth + add SHA-1 (Project settings → Android).';
  }
  // Google / Apple / providers
  if (s.contains('operation-not-allowed')) {
    return 'This sign-in is turned off in Firebase. Go to Authentication → Sign-in method and enable Google or Apple.';
  }
  if (s.contains('account-exists-with-different-credential')) {
    return 'An account already exists with this email using another sign-in method.';
  }
  if (s.contains('credential-already-in-use')) {
    return 'This phone/email is already linked to another account.';
  }
  if (s.contains('user-disabled')) {
    return 'This account has been disabled.';
  }
  if (s.contains('popup-closed-by-user') ||
      s.contains('popup_blocked') ||
      s.contains('sign_in_canceled') ||
      s.contains('sign_in_cancelled') ||
      s.contains('canceled') && s.contains('sign')) {
    return 'Sign-in was cancelled.';
  }
  if (s.contains('invalid-api-key') || s.contains('api-key-not-valid')) {
    return 'Invalid Firebase API key. Check google-services.json / firebase_options.';
  }
  if (s.contains('internal-error') || s.contains('internal error')) {
    return 'Firebase temporary error. Try again in a minute.';
  }
  if (s.contains('quota-exceeded')) {
    return 'Firebase quota exceeded. Try again later.';
  }

  // Debug: show real error so you can fix Firebase / config
  if (kDebugMode) {
    final t = raw.trim();
    if (t.length > 200) {
      return 'Error (debug): ${t.substring(0, 200)}…';
    }
    return 'Error (debug): $t';
  }
  return 'Something went wrong. Please try again. If it continues, enable Google/Apple in Firebase Console and add SHA-1 for Android.';
}
