import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/admin_theme_colors.dart';
import '../theme/theme_scope.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _emailController = TextEditingController(text: 'admin@gmail.com');
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _loading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter email and password')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final uid = cred.user?.uid;
      if (uid == null) {
        throw FirebaseAuthException(
          code: 'null-user',
          message: 'Sign-in did not return a user.',
        );
      }

      final adminDoc = await FirebaseFirestore.instance
          .collection('admins')
          .doc(uid)
          .get();

      if (!adminDoc.exists) {
        await FirebaseAuth.instance.signOut();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Signed in, but this user is not in the admins collection in Firestore.',
            ),
          ),
        );
        return;
      }

      final active = adminDoc.data()?['active'];
      if (active == false) {
        await FirebaseAuth.instance.signOut();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Admin account deactivated.')),
        );
        return;
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Welcome, admin')),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Login failed')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.adminColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF000000) : c.pageBackground;
    final cardColor = isDark ? const Color(0xFF121212) : c.surface;
    final glowColor = isDark ? const Color(0xFF1A1A40) : const Color(0xFFB8C5D6);

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          // Background Glows
          Positioned.fill(
            child: _GlowBackground(glowColor: glowColor, isDark: isDark),
          ),
          Positioned(
            top: 12,
            left: 12,
            child: IconButton(
              onPressed: () => Navigator.of(context).maybePop(),
              icon: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 20,
                color: isDark ? Colors.white70 : c.muted,
              ),
              tooltip: 'Back',
            ),
          ),
          Positioned(
            top: 12,
            right: 12,
            child: IconButton(
              onPressed: () => ThemeScope.of(context).toggle(),
              icon: Icon(
                isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
              ),
              color: isDark ? Colors.white70 : c.muted,
              tooltip: isDark ? 'Light mode' : 'Dark mode',
            ),
          ),

          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Container(
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(
                      color: isDark ? Colors.white10 : c.border,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (isDark ? Colors.black : Colors.black26)
                            .withValues(alpha: isDark ? 0.5 : 0.12),
                        blurRadius: 40,
                        offset: const Offset(0, 20),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 60),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Bambare',
                        style: GoogleFonts.poppins(
                          fontSize: 42,
                          fontWeight: FontWeight.w700,
                          color: c.textPrimary,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'BeeTravel - Bambare Travel Management System',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          height: 1.6,
                          color: c.muted,
                        ),
                      ),
                      const SizedBox(height: 48),

                      // Email input
                      _buildInput(
                        context,
                        controller: _emailController,
                        hint: 'Enter your email address',
                        icon: Icons.mail_outline_rounded,
                      ),
                      const SizedBox(height: 20),

                      // Password input
                      _buildInput(
                        context,
                        controller: _passwordController,
                        hint: 'Enter your password',
                        icon: Icons.lock_outline_rounded,
                        obscure: _obscurePassword,
                        isPassword: true,
                        onToggle: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                      const SizedBox(height: 64),
                      // Log in button
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: TextButton(
                          onPressed: _loading ? null : _submit,
                          style: TextButton.styleFrom(
                            backgroundColor:
                                isDark ? const Color(0xFF1F1F1F) : c.chipBg,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: _loading
                              ? SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: c.textPrimary,
                                  ),
                                )
                              : Text(
                                  'Log in',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: c.textPrimary,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInput(
    BuildContext context, {
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    bool isPassword = false,
    VoidCallback? onToggle,
  }) {
    final c = context.adminColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0D0D0D) : c.inputFill,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : c.border,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        style: GoogleFonts.inter(color: c.textPrimary, fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.inter(
            color: c.muted.withValues(alpha: 0.85),
            fontSize: 13,
          ),
          icon: Icon(icon, color: c.muted, size: 18),
          border: InputBorder.none,
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                    color: const Color(0xFF007BFF),
                    size: 18,
                  ),
                  onPressed: onToggle,
                )
              : null,
        ),
      ),
    );
  }
}

class _GlowBackground extends StatelessWidget {
  const _GlowBackground({required this.glowColor, required this.isDark});

  final Color glowColor;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: -100,
          left: -100,
          child: Container(
            width: 400,
            height: 400,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: glowColor.withOpacity(0.15),
            ),
          ),
        ),
        Positioned(
          bottom: -150,
          right: -150,
          child: Container(
            width: 500,
            height: 500,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: glowColor.withOpacity(0.12),
            ),
          ),
        ),
        Center(
          child: Container(
            width: 600,
            height: 600,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: glowColor.withOpacity(0.1),
                  blurRadius: 100,
                  spreadRadius: 20,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
