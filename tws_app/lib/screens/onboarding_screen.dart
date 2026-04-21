// lib/screens/onboarding_screen.dart
// Onboarding: top hero image + white panel; local images in /image/ folder
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'auth/login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageCtrl = PageController();
  int _currentPage = 0;

  static const List<String> _fallbackUrls = [
    'https://images.unsplash.com/photo-1542382257-80da9d2859c2?auto=format&fit=crop&q=80&w=800&h=1200',
    'https://images.unsplash.com/photo-1501504905252-473c47e087f8?auto=format&fit=crop&q=80&w=800&h=1200',
    'https://images.unsplash.com/photo-1516483638261-f40af5afca07?auto=format&fit=crop&q=80&w=800&h=1200',
  ];

  final List<_OnboardData> _pages = const [
    _OnboardData(
      title: 'Explore the new to\nfind good place',
      subtitle: 'Travel around the world with just a tap and enjoy\nyour best holiday',
    ),
    _OnboardData(
      title: 'Plan your trip\nwith ease',
      subtitle:
          'Book tours, hotels and activities all in one place with amazing deals',
    ),
    _OnboardData(
      title: 'Collect memories\nthat last forever',
      subtitle:
          'Rate your experiences, save favourites and share your journey',
    ),
  ];

  void _next() {
    if (_currentPage < _pages.length - 1) {
      _pageCtrl.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _goToLogin();
    }
  }

  /// Skip onboarding → go to login
  void _skip() {
    _goToLogin();
  }

  void _goToLogin() {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const LoginScreen(),
        transitionDuration: const Duration(milliseconds: 500),
        transitionsBuilder: (_, a, __, child) =>
            FadeTransition(opacity: a, child: child),
      ),
    );
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        fit: StackFit.expand,
        children: [
          PageView.builder(
            controller: _pageCtrl,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemCount: _pages.length,
            itemBuilder: (_, i) => _OnboardPage(
              data: _pages[i],
              pageIndex: i,
              fallbackUrl: _fallbackUrls[i],
            ),
          ),

          // Bottom controls (fixed)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              color: Colors.white,
              padding: EdgeInsets.fromLTRB(28, 8, 28, 24 + bottomPad),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _BarPageIndicator(
                    count: _pages.length,
                    currentIndex: _currentPage,
                    onTap: (i) {
                      _pageCtrl.animateToPage(
                        i,
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeInOut,
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  if (_currentPage == _pages.length - 1) ...[
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _goToLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                        ),
                        child: const Text(
                          'Get Start',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: _skip,
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: Colors.black,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.chevron_left,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Skip',
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.black,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: _next,
                        child: Row(
                          children: [
                            Text(
                              _currentPage == _pages.length - 1
                                  ? 'Start'
                                  : 'Next',
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.black,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: Colors.black,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _currentPage == _pages.length - 1
                                    ? Icons.check
                                    : Icons.chevron_right,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Long bar = active page, short bars = inactive (like your mockup)
class _BarPageIndicator extends StatelessWidget {
  final int count;
  final int currentIndex;
  final ValueChanged<int>? onTap;

  const _BarPageIndicator({
    required this.count,
    required this.currentIndex,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final active = i == currentIndex;
        return GestureDetector(
          onTap: () => onTap?.call(i),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            height: 4,
            width: active ? 36 : 14,
            decoration: BoxDecoration(
              color: active ? Colors.black : const Color(0xFFBDBDBD),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }
}

/// Tries several common names so your files in `image/` load even if not exactly `onboarding_1.png`.
List<String> _candidateAssetPaths(int pageIndex) {
  final n = pageIndex + 1;
  return [
    'image/onboarding_$n.png',
    'image/onboarding_$n.jpg',
    'image/onboarding_$n.jpeg',
    'image/onboarding_$n.webp',
    'image/$n.png',
    'image/$n.jpg',
    'image/$n.jpeg',
    'image/img$n.png',
    'image/img_$n.png',
    'image/image$n.png',
    'image/image_$n.png',
    'image/screen_$n.png',
    'image/slide_$n.png',
  ];
}

class _OnboardPage extends StatelessWidget {
  final _OnboardData data;
  final int pageIndex;
  final String fallbackUrl;

  const _OnboardPage({
    required this.data,
    required this.pageIndex,
    required this.fallbackUrl,
  });

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;
    final imageHeight = h * 0.58;

    return Column(
      children: [
        SizedBox(
          height: imageHeight,
          width: double.infinity,
          child: ClipRRect(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(48),
              bottomRight: Radius.circular(48),
            ),
            child: _OnboardResolvedImage(
              candidates: _candidateAssetPaths(pageIndex),
              fallbackUrl: fallbackUrl,
            ),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(28, 28, 28, 200),
            child: Column(
              children: [
                Text(
                  data.title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.black,
                    fontSize: 35,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                    letterSpacing: -1.0,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  data.subtitle,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    color: const Color(0xFF616161),
                    fontSize: 16,
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Picks first asset path that exists in bundle (so wrong filename still works if one matches).
class _OnboardResolvedImage extends StatefulWidget {
  final List<String> candidates;
  final String fallbackUrl;

  const _OnboardResolvedImage({
    required this.candidates,
    required this.fallbackUrl,
  });

  @override
  State<_OnboardResolvedImage> createState() => _OnboardResolvedImageState();
}

class _OnboardResolvedImageState extends State<_OnboardResolvedImage> {
  String? _assetPath;
  bool _resolved = false;

  @override
  void initState() {
    super.initState();
    _pickAsset();
  }

  Future<void> _pickAsset() async {
    for (final path in widget.candidates) {
      try {
        await rootBundle.load(path);
        if (mounted) {
          setState(() {
            _assetPath = path;
            _resolved = true;
          });
        }
        return;
      } catch (_) {
        // try next
      }
    }
    if (mounted) setState(() => _resolved = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_resolved) {
      return Container(
        color: const Color(0xFFE8E8E8),
        child: const Center(
          child: SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }
    if (_assetPath != null) {
      return Image.asset(
        _assetPath!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, __, ___) => _networkFallback(),
      );
    }
    return _networkFallback();
  }

  Widget _networkFallback() {
    return Image.network(
      widget.fallbackUrl,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      loadingBuilder: (_, child, prog) {
        if (prog == null) return child;
        return Container(
          color: const Color(0xFFE0E0E0),
          child: const Center(
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        );
      },
      errorBuilder: (_, __, ___) => Container(
        color: const Color(0xFFE0E0E0),
        child: const Center(
          child: Icon(Icons.landscape, size: 64, color: Colors.grey),
        ),
      ),
    );
  }
}

class _OnboardData {
  final String title;
  final String subtitle;
  const _OnboardData({
    required this.title,
    required this.subtitle,
  });
}
