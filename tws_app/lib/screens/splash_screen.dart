// lib/screens/splash_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme.dart';
import 'onboarding_screen.dart';
import 'main_shell.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  static const String _beeAsset = 'image/bee_logo.png';
  /// Slightly smaller on screen (was 160).
  static const double _beeLogoSize = 118;
  /// Darken the asset a touch so outlines / blacks read richer on white.
  static const ColorFilter _beeDarkenFilter = ColorFilter.matrix(<double>[
    0.88, 0, 0, 0, 0,
    0, 0.88, 0, 0, 0,
    0, 0, 0.88, 0, 0,
    0, 0, 0, 1, 0,
  ]);

  late final AnimationController _beeController;
  late final AnimationController _textController;
  late final AnimationController _hoverController;

  late final Animation<Offset> _flyAnim;
  late final Animation<double> _beeFadeAnim;
  late final Animation<double> _beeScaleAnim;
  late final Animation<double> _textFadeAnim;
  late final Animation<double> _hoverY;
  late final Animation<double> _hoverRotation;

  @override
  void initState() {
    super.initState();

    _beeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _hoverController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    );

    _flyAnim = Tween<Offset>(
      begin: const Offset(-0.12, -1.65),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _beeController, curve: Curves.easeOutCubic),
    );

    _beeFadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _beeController,
        curve: const Interval(0, 0.4, curve: Curves.easeOut),
      ),
    );

    _beeScaleAnim = Tween<double>(begin: 0.82, end: 1).animate(
      CurvedAnimation(parent: _beeController, curve: Curves.easeOutBack),
    );

    _textFadeAnim = CurvedAnimation(
      parent: _textController,
      curve: Curves.easeOut,
    );

    // Hovering flight oscillation (up/down + slight rotation)
    _hoverY = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0, end: -6),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: -6, end: 0),
        weight: 50,
      ),
    ]).animate(
      CurvedAnimation(parent: _hoverController, curve: Curves.easeInOutSine),
    );

    _hoverRotation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0, end: 0.038),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.038, end: -0.038),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: -0.038, end: 0),
        weight: 25,
      ),
    ]).animate(
      CurvedAnimation(parent: _hoverController, curve: Curves.easeInOutSine),
    );

    _beeController.forward().then((_) {
      if (mounted) {
        _textController.forward();
        _hoverController.repeat(); // Loop the flying hover!
      }
    });

    // Bee flight + tagline + short hold, then route
    Future.delayed(const Duration(milliseconds: 3600), _navigate);
  }

  void _navigate() {
    if (!mounted) return;
    final user = FirebaseAuth.instance.currentUser;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) =>
            user != null ? const MainShell() : const OnboardingScreen(),
        transitionDuration: const Duration(milliseconds: 600),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  @override
  void dispose() {
    _beeController.dispose();
    _textController.dispose();
    _hoverController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SlideTransition(
              position: _flyAnim,
              child: FadeTransition(
                opacity: _beeFadeAnim,
                child: ScaleTransition(
                  scale: _beeScaleAnim,
                  child: AnimatedBuilder(
                    animation: _hoverController,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, _hoverY.value),
                        child: Transform.rotate(
                          angle: _hoverRotation.value,
                          child: child,
                        ),
                      );
                    },
                    child: ColorFiltered(
                      colorFilter: _beeDarkenFilter,
                      child: Image.asset(
                        _beeAsset,
                        width: _beeLogoSize,
                        height: _beeLogoSize,
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.high,
                        errorBuilder: (_, __, ___) => _beeFallback(),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 28),
            FadeTransition(
              opacity: _textFadeAnim,
              child: Text(
                'Roam Free, Bee Wild.',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  color: AppTheme.black,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Shown only if `image/bee_logo.png` is missing — replace with your asset file.
  Widget _beeFallback() {
    return Container(
      width: _beeLogoSize,
      height: _beeLogoSize,
      decoration: BoxDecoration(
        color: AppTheme.yellow,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.yellow.withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: const Icon(
        Icons.travel_explore_rounded,
        size: 52,
        color: AppTheme.black,
      ),
    );
  }
}
