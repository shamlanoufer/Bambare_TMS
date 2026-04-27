// lib/screens/home/home_screen.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../core/nav_insets.dart';
import '../../models/tour.dart';
import '../../services/tour_service.dart';
import '../bookings/discover_tours_screen.dart';
import '../bookings/tour_detail_screen.dart';
import 'activity_detail_screen.dart';

/// Vertical strip in `images/home/` — scroll down to move through the composite background.
abstract final class _HomeBackground {
  static const List<String> assets = [
    'images/home/1.png',
    'images/home/2.png',
    'images/home/3.png',
  ];

  static String get lastAsset => assets.last;
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          if (w <= 0) {
            return const SizedBox.shrink();
          }
          final bottomPad = FloatingNavLayout.scrollBottomPadding(context);

          // Full-bleed underlay so “empty” scroll space (and short viewports) show photo, not a black band.
          return Stack(
            fit: StackFit.expand,
            children: [
              Positioned.fill(
                child: Image.asset(
                  _HomeBackground.lastAsset,
                  fit: BoxFit.cover,
                  alignment: Alignment.bottomCenter,
                  filterQuality: FilterQuality.low,
                  gaplessPlayback: true,
                ),
              ),
              SingleChildScrollView(
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                child: Stack(
                  children: [
                    // Scrolling background images
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final path in _HomeBackground.assets)
                          Image.asset(
                            path,
                            width: w,
                            fit: BoxFit.fitWidth,
                            alignment: Alignment.topCenter,
                            filterQuality: FilterQuality.high,
                            gaplessPlayback: true,
                          ),
                        SizedBox(height: bottomPad),
                      ],
                    ),
                    // Dashboard Content Overlay
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: 40),
                            const _HomeGreeting(),
                            const SizedBox(height: 32),
                            const _HomeSearchBar(),
                            const SizedBox(height: 48),
                            const _SectionHeader(title: 'Featured Tours'),
                            const SizedBox(height: 20),
                            const _FeaturedToursList(),
                            const SizedBox(height: 18),
                            const _SectionHeader(title: 'Activities'),
                            const SizedBox(height: 20),
                            const _ActivitiesList(),
                            const SizedBox(height: 80),
                            const _AboutBambareSection(),
                            const SizedBox(height: 48),
                            const _SriLankaTipsSection(),
                            const SizedBox(height: 48),
                            const _TestimonialsSection(),
                            const SizedBox(height: 48),
                            const _ContactBambareSection(),
                            SizedBox(
                              height: FloatingNavLayout.scrollBottomPadding(
                                context,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _HomeGreeting extends StatelessWidget {
  const _HomeGreeting();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'ආයුබෝවන්',
          textAlign: TextAlign.center,
          style: GoogleFonts.notoSansSinhala(
            fontSize: 60,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: [
              const Shadow(
                color: Colors.black45,
                blurRadius: 15,
                offset: Offset(0, 4),
              ),
            ],
          ),
        ),
        Text(
          'Ayubowan!',
          textAlign: TextAlign.center,
          style: GoogleFonts.pinyonScript(
            fontSize: 48,
            color: Colors.white,
            shadows: [
              const Shadow(
                color: Colors.black45,
                blurRadius: 15,
                offset: Offset(0, 4),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HomeSearchBar extends StatefulWidget {
  const _HomeSearchBar();

  @override
  State<_HomeSearchBar> createState() => _HomeSearchBarState();
}

class _HomeSearchBarState extends State<_HomeSearchBar> {
  final _ctrl = TextEditingController();
  final _speech = stt.SpeechToText();
  bool _listening = false;
  bool _voiceNavigationDone = false;
  bool _speechReady = false;

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    final available = await _speech.initialize(
      debugLogging: true,
      onStatus: (status) {
        if (!mounted) return;
        if (status == 'notListening' || status == 'done') {
          setState(() => _listening = false);
          if (!_voiceNavigationDone && _ctrl.text.trim().isNotEmpty) {
            _voiceNavigationDone = true;
            _openDiscover();
          }
        }
      },
      onError: (err) {
        if (!mounted) return;
        setState(() => _listening = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Voice search error: ${err.errorMsg}')),
        );
      },
    );
    if (!mounted) return;
    setState(() => _speechReady = available);
  }

  @override
  void dispose() {
    _speech.stop();
    _ctrl.dispose();
    super.dispose();
  }

  void _openDiscover() {
    final q = _ctrl.text.trim();
    if (q.isEmpty) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DiscoverToursScreen(
          initialQuery: q.isEmpty ? null : q,
        ),
      ),
    );
  }

  Future<void> _startVoiceSearch() async {
    if (_listening) {
      await _speech.stop();
      if (mounted) setState(() => _listening = false);
      return;
    }
    _voiceNavigationDone = false;
    if (!_speechReady) {
      await _initSpeech();
    }
    if (!_speechReady) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Voice search unavailable. Allow mic permission in browser/site settings.')),
      );
      return;
    }
    if (!mounted) return;
    setState(() => _listening = true);
    await _speech.listen(
      onResult: (res) {
        if (!mounted) return;
        setState(() => _ctrl.text = res.recognizedWords);
        if (res.finalResult && !_voiceNavigationDone) {
          _voiceNavigationDone = true;
          _openDiscover();
        }
      },
      listenMode: stt.ListenMode.search,
      listenFor: const Duration(seconds: 20),
      pauseFor: const Duration(seconds: 4),
      partialResults: true,
      cancelOnError: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.35),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.search, color: Colors.white70),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _ctrl,
                  onSubmitted: (_) => _openDiscover(),
                  textInputAction: TextInputAction.search,
                  style: GoogleFonts.outfit(
                    color: Colors.white.withValues(alpha: 0.92),
                    fontSize: 16,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search tours, destinations...',
                    hintStyle: GoogleFonts.outfit(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 16,
                    ),
                    border: InputBorder.none,
                    isCollapsed: true,
                  ),
                ),
              ),
              IconButton(
                onPressed: _startVoiceSearch,
                icon: Icon(_listening ? Icons.mic : Icons.mic_none_rounded, color: Colors.white70),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      textAlign: TextAlign.center,
      style: GoogleFonts.outfit(
        fontSize: 34,
        fontWeight: FontWeight.bold,
        color: Colors.white,
        shadows: [
          const Shadow(
            color: Colors.black38,
            blurRadius: 12,
            offset: Offset(0, 2),
          ),
        ],
      ),
    );
  }
}

class _FeaturedToursList extends StatelessWidget {
  const _FeaturedToursList();

  @override
  Widget build(BuildContext context) {
    final svc = TourService();
    return SizedBox(
      height: 250,
      child: StreamBuilder<List<Tour>>(
        stream: svc.homeFeaturesToursStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Failed to load.',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  shadows: const [
                    Shadow(
                      color: Colors.black38,
                      blurRadius: 12,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
              ),
            );
          }
          final tours = snapshot.data ?? const <Tour>[];
          if (tours.isEmpty) {
            return Center(
              child: Text(
                'No featured tours yet.',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  shadows: const [
                    Shadow(
                      color: Colors.black38,
                      blurRadius: 12,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
              ),
            );
          }
          return ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 10),
            itemCount: tours.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, i) {
              return _TourCard(tour: tours[i]);
            },
          );
        },
      ),
    );
  }
}

/// Home strip images: `images/booking/Activity/` ([HomeActivity.carouselAssetPath]). Detail pages use [HomeActivity.backgroundAssetPath].
class _ActivitiesList extends StatefulWidget {
  const _ActivitiesList();

  @override
  State<_ActivitiesList> createState() => _ActivitiesListState();
}

class _ActivitiesListState extends State<_ActivitiesList> {
  /// Touch / keyboard selection (mobile).
  int? _selectedIndex;

  /// Desktop / web pointer hover (no hover on most phones).
  int? _hoverIndex;

  static const List<_ActivityAsset> _items = [
    _ActivityAsset('HIKING', HomeActivity.hiking),
    _ActivityAsset('CYCLING', HomeActivity.cycling),
    _ActivityAsset('TREKKING', HomeActivity.trekking),
    _ActivityAsset('TUK TUK RIDE', HomeActivity.tukTukRide),
    _ActivityAsset('JEEP RIDE', HomeActivity.jeepRide),
    _ActivityAsset('COOKERY SESSION', HomeActivity.cookerySession),
  ];

  @override
  Widget build(BuildContext context) {
    // Match Home "Featured Tours" card sizing (width: 260, height: 250),
    // while staying responsive on narrow screens.
    final screenW = MediaQuery.sizeOf(context).width;
    const parentPad = 24.0;
    const baseCardW = 260.0; // same as _TourCard width
    const baseCardH = 250.0; // same as _FeaturedToursList height
    final trackW = (screenW - parentPad * 2).clamp(0.0, double.infinity);

    // On small screens, shrink but keep side gap.
    final cardW = baseCardW.clamp(168.0, trackW * 0.92);
    final cardH = baseCardH * (cardW / baseCardW);

    // Match Featured Tours row: each item is exactly [cardW] wide + 12px separator.
    // (Do not inflate slot width — that made the gap between activity cards much
    // larger than between featured tour cards.)
    final slotW = cardW;
    final slotH = cardH * 1.12;
    final rowH = (slotH + 28).clamp(320.0, 560.0);

    return SizedBox(
      height: rowH,
      child: ListView.separated(
        clipBehavior: Clip.none,
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 10),
        itemCount: _items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final item = _items[index];
          final elevated = _hoverIndex == index || _selectedIndex == index;
          return MouseRegion(
            cursor: SystemMouseCursors.click,
            onEnter: (_) => setState(() => _hoverIndex = index),
            onExit: (_) {
              setState(() {
                if (_hoverIndex == index) _hoverIndex = null;
              });
            },
            child: _ActivityCardSlot(
              elevated: elevated,
              slotWidth: slotW,
              slotHeight: slotH,
              child: _ActivityImageCard(
                width: cardW,
                height: cardH,
                assetPath: item.activity.carouselAssetPath,
                label: item.label,
                elevated: elevated,
                onTap: () {
                  setState(() => _selectedIndex = index);
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => ActivityDetailScreen(activity: item.activity),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ActivityAsset {
  const _ActivityAsset(this.label, this.activity);
  final String label;
  final HomeActivity activity;
}

/// Fixed slot so scaled “hover / tap” card does not clip neighbours.
class _ActivityCardSlot extends StatelessWidget {
  const _ActivityCardSlot({
    required this.elevated,
    required this.slotWidth,
    required this.slotHeight,
    required this.child,
  });

  final bool elevated;
  final double slotWidth;
  final double slotHeight;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: slotWidth,
      height: slotHeight,
      // Left-align so each activity card lines up like Featured Tours (same
      // track width + 12px [ListView.separated] gap).
      child: Align(
        alignment: Alignment.centerLeft,
        child: AnimatedSlide(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          offset: elevated ? const Offset(0, -0.055) : Offset.zero,
          child: child,
        ),
      ),
    );
  }
}

class _ActivityImageCard extends StatelessWidget {
  const _ActivityImageCard({
    required this.width,
    required this.height,
    required this.assetPath,
    required this.label,
    required this.elevated,
    required this.onTap,
  });

  final double width;
  final double height;
  final String assetPath;
  final String label;
  final bool elevated;
  final VoidCallback onTap;

  // Same subtle hover scale as [_TourCard] on Featured Tours (1.03).
  static const double _hoverScale = 1.03;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: AnimatedScale(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            scale: elevated ? _hoverScale : 1.0,
            alignment: Alignment.bottomCenter,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              width: width,
              height: height,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: elevated ? 0.28 : 0.10),
                    blurRadius: elevated ? 28 : 10,
                    spreadRadius: elevated ? 0.5 : 0,
                    offset: Offset(0, elevated ? 14 : 4),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: Image.asset(
                      assetPath,
                      fit: BoxFit.cover,
                      gaplessPlayback: true,
                      errorBuilder: (_, __, ___) => ColoredBox(
                        color: Colors.grey.shade300,
                        child: Icon(
                          Icons.image_not_supported_outlined,
                          color: Colors.grey.shade600,
                          size: 36,
                        ),
                      ),
                    ),
                  ),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
                    color: Colors.white,
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.7,
                        color: Colors.black87,
                        height: 1.15,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// About block: no local full-bleed photo — uses the home scroll background underlay.
/// Circle image: asset under `images/home/` (swap file if you use another name).
class _AboutBambareSection extends StatelessWidget {
  const _AboutBambareSection();

  static const String _circleAsset =
      'images/home/Screenshot 2026-04-10 230005.png';

  static const String _bodyRest =
      'is a passionate travel agency based in the central hills of Sri Lanka, dedicated '
      'to promoting sustainable tourism and authentic local experiences. We specialize in '
      'curated cycling and hiking adventures that allow travelers to explore breathtaking '
      'landscapes, rich culture, and traditional Sri Lankan cuisine. Driven by our love for '
      'our country, we aim to provide unforgettable journeys, warm hospitality, and '
      'exceptional service to every traveler who chooses Bambare.';

  static const List<Shadow> _titleShadow = [
    Shadow(
      color: Color(0xB3000000),
      blurRadius: 24,
      offset: Offset(0, 5),
    ),
    Shadow(
      color: Color(0x66000000),
      blurRadius: 10,
      offset: Offset(0, 2),
    ),
  ];

  static const List<Shadow> _bodyShadow = [
    Shadow(
      color: Color(0x80000000),
      blurRadius: 6,
      offset: Offset(0, 1),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.sizeOf(context).width;
    final titleSize = (screenW * 0.184).clamp(60.0, 78.0);
    final bodySize = (screenW * 0.051).clamp(18.0, 21.5);
    final bodyLeadSize = bodySize + 3.0;
    final circleDiameter = (screenW * 0.395).clamp(152.0, 172.0);
    final boxMinH = screenW * 0.78;

    Widget circlePhoto() {
      return Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 4),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.38),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipOval(
          child: Image.asset(
            _circleAsset,
            width: circleDiameter,
            height: circleDiameter,
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
            errorBuilder: (_, __, ___) => Container(
              width: circleDiameter,
              height: circleDiameter,
              color: const Color(0xFF3D3D3D),
              child: const Icon(Icons.person, color: Colors.white54, size: 52),
            ),
          ),
        ),
      );
    }

    return Transform.translate(
      offset: const Offset(-24, 0),
      child: SizedBox(
        width: screenW,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 56, 22, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: double.infinity,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'ABOUT',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: titleSize,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: titleSize * 0.042,
                        height: 0.88,
                        shadows: _titleShadow,
                      ),
                    ),
                    Text(
                      'BAMBARE',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: titleSize,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: titleSize * 0.052,
                        height: 1.02,
                        shadows: _titleShadow,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: titleSize * 0.36 + 8),
              Stack(
                clipBehavior: Clip.none,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(34),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minHeight: boxMinH),
                        child: Container(
                          width: double.infinity,
                          padding: EdgeInsets.fromLTRB(
                            26,
                            circleDiameter * 0.4 + 12,
                            circleDiameter * 0.58 + 22,
                            30,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.48),
                            borderRadius: BorderRadius.circular(34),
                          ),
                          child: RichText(
                            textAlign: TextAlign.left,
                            text: TextSpan(
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: bodySize,
                                fontWeight: FontWeight.w600,
                                height: 1.58,
                                shadows: _bodyShadow,
                              ),
                              children: [
                                TextSpan(
                                  text: 'Bambare ',
                                  style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontSize: bodyLeadSize,
                                    fontWeight: FontWeight.w900,
                                    height: 1.58,
                                    shadows: _bodyShadow,
                                  ),
                                ),
                                const TextSpan(text: _bodyRest),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: -(circleDiameter * 0.3),
                    right: 6,
                    child: circlePhoto(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Travel tips block — placed below About Bambare; copy matches design reference.
class _SriLankaTipsSection extends StatelessWidget {
  const _SriLankaTipsSection();

  static const List<Shadow> _titleShadow = [
    Shadow(
      color: Color(0xB3000000),
      blurRadius: 24,
      offset: Offset(0, 5),
    ),
    Shadow(
      color: Color(0x66000000),
      blurRadius: 10,
      offset: Offset(0, 2),
    ),
  ];

  static const List<Shadow> _bodyShadow = [
    Shadow(
      color: Color(0x80000000),
      blurRadius: 6,
      offset: Offset(0, 1),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.sizeOf(context).width;
    // Slightly smaller so the title stays to 3 lines (no extra wrapping).
    final titleSize = (screenW * 0.135).clamp(44.0, 60.0);
    final introSize = (screenW * 0.042).clamp(15.0, 17.5);
    final cardTitleSize = (screenW * 0.04).clamp(15.0, 17.0);
    final cardBodySize = (screenW * 0.038).clamp(14.0, 16.0);

    final thinTitleStyle = GoogleFonts.outfit(
      fontSize: titleSize,
      fontWeight: FontWeight.w500,
      color: Colors.white,
      letterSpacing: titleSize * 0.045,
      height: 0.95,
      shadows: _titleShadow,
    );
    final emphTitleStyle = GoogleFonts.outfit(
      fontSize: titleSize,
      fontWeight: FontWeight.w900,
      color: Colors.white,
      letterSpacing: titleSize * 0.045,
      height: 0.95,
      shadows: _titleShadow,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: double.infinity,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text.rich(
                  textAlign: TextAlign.center,
                  TextSpan(
                    children: [
                      TextSpan(text: 'TIPS ', style: emphTitleStyle),
                      TextSpan(text: 'FOR YOUR', style: thinTitleStyle),
                    ],
                  ),
                ),
              ),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text.rich(
                  textAlign: TextAlign.center,
                  TextSpan(
                    children: [
                      TextSpan(text: 'PERFECT ', style: emphTitleStyle),
                      TextSpan(text: 'TRIP', style: thinTitleStyle),
                    ],
                  ),
                ),
              ),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text.rich(
                  textAlign: TextAlign.center,
                  TextSpan(
                    children: [
                      TextSpan(text: 'IN ', style: thinTitleStyle),
                      TextSpan(text: 'SRILANKA', style: emphTitleStyle),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Get ready for your journey with essential travel tips on weather, clothing, safety, local customs, and what to carry for your adventure with Bambare.',
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            fontSize: introSize,
            fontWeight: FontWeight.w600,
            color: Colors.white,
            height: 1.45,
            shadows: _bodyShadow,
          ),
        ),
        const SizedBox(height: 28),
        _TipCard(
          title: 'What to Carry',
          body:
              'Comfortable shoes | water bottle | sunscreen | hat | light jacket |Power banks',
          titleSize: cardTitleSize,
          bodySize: cardBodySize,
        ),
        const SizedBox(height: 16),
        _TipCard(
          title: 'Weather Tips',
          body:
              'Mountain weather can change quickly, so be prepared for rain, wind, and cool temperatures.',
          titleSize: cardTitleSize,
          bodySize: cardBodySize,
        ),
        const SizedBox(height: 16),
        _TipCard(
          title: 'Money & Payments',
          body:
              'Carry some cash for small local purchases, although digital payments may be available in towns.',
          titleSize: cardTitleSize,
          bodySize: cardBodySize,
        ),
        const SizedBox(height: 16),
        _TipCard(
          title: 'Local Etiquette',
          body:
              'Respect local culture, keep nature clean, and dress appropriately when visiting villages or sacred places.',
          titleSize: cardTitleSize,
          bodySize: cardBodySize,
        ),
        const SizedBox(height: 16),
        _TipCard(
          title: 'Photography Tips',
          body:
              'Bring a fully charged phone or camera and keep your devices protected from rain.',
          titleSize: cardTitleSize,
          bodySize: cardBodySize,
        ),
        const SizedBox(height: 16),
        _TipCard(
          title: 'Safety!',
          body:
              'Always check weather conditions, stay with your group, and follow the guide during hikes and outdoor tours.',
          titleSize: cardTitleSize,
          bodySize: cardBodySize,
        ),
      ],
    );
  }
}

/// Horizontal testimonial carousel — same copy as design reference; quote size matches
/// About Bambare body ([_AboutBambareSection] `bodySize`) + 2.
class _TestimonialsSection extends StatelessWidget {
  const _TestimonialsSection();

  static const List<({
    String imageUrl,
    String quote,
    String name,
    String role,
  })> _items = [
    (
      imageUrl:
          'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?q=80&w=400&auto=format&fit=crop',
      quote:
          'Traveling through Sri Lanka with Bambare was an unforgettable experience. Every destination was beautifully planned, and as a photographer, I found endless moments worth capturing',
      name: 'Daniel Perera',
      role: 'Travel Photographer',
    ),
    (
      imageUrl:
          'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?q=80&w=400&auto=format&fit=crop',
      quote:
          'Bambare made my trip feel effortless and exciting at the same time. From the scenic hikes to the warm hospitality, every part of the journey was thoughtfully planned. It was more than a vacation — it was an experience I\'ll always remember.',
      name: 'Luka',
      role: 'Adventure Traveler',
    ),
    (
      imageUrl:
          'https://images.unsplash.com/photo-1560250097-0b93528c311a?q=80&w=400&auto=format&fit=crop',
      quote:
          'As a solo traveler, I was looking for an experience that felt safe, well-organized, and memorable. Bambare exceeded my expectations with their professionalism, local knowledge, and genuine care. It was the perfect way to explore Sri Lanka with confidence.',
      name: 'Liam Fernando',
      role: 'Solo Explorer',
    ),
    (
      imageUrl:
          'https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?q=80&w=400&auto=format&fit=crop',
      quote:
          'What I loved most about Bambare was how they blended adventure with authentic Sri Lankan culture. The guides were friendly, the locations were breathtaking, and the entire journey felt personal and unique. I would gladly travel with them again.',
      name: 'Nathan Silva',
      role: 'Travel Blogger',
    ),
    (
      imageUrl:
          'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?q=80&w=400&auto=format&fit=crop',
      quote:
          'Bambare gave me the opportunity to discover places I would never have found on my own. The views, the activities, and the local experiences were all exceptional. Every moment felt worth capturing and sharing.',
      name: 'Achintha Perera',
      role: 'Travel Photographer',
    ),
  ];

  static const List<Shadow> _headerShadow = [
    Shadow(
      color: Colors.black38,
      blurRadius: 12,
      offset: Offset(0, 2),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.sizeOf(context).width;
    final bodySize = (screenW * 0.051).clamp(18.0, 21.5);
    final quoteSize = (bodySize - 4.0).clamp(14.0, 18.0);
    final cardWidth = (screenW * 0.76).clamp(260.0, 340.0);
    final cardHeight = (screenW * 0.82).clamp(300.0, 380.0);
    final headerSize = (screenW * 0.184).clamp(60.0, 78.0); // About Bambare title size

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 56,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Divider(
                      color: Colors.white.withValues(alpha: 0.45),
                      thickness: 1,
                      height: 1,
                    ),
                    const SizedBox(height: 6),
                    Divider(
                      color: Colors.white.withValues(alpha: 0.45),
                      thickness: 1,
                      height: 1,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'TESTIMONIALS',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: headerSize,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: headerSize * 0.045,
                      height: 0.95,
                      shadows: _headerShadow,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        SizedBox(
          height: cardHeight,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            itemCount: _items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              final item = _items[index];
              return SizedBox(
                width: cardWidth,
                child: _TestimonialCard(
                  imageUrl: item.imageUrl,
                  quote: item.quote,
                  name: item.name,
                  role: item.role,
                  quoteSize: quoteSize,
                  height: cardHeight,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _TestimonialCard extends StatelessWidget {
  const _TestimonialCard({
    required this.imageUrl,
    required this.quote,
    required this.name,
    required this.role,
    required this.quoteSize,
    required this.height,
  });

  final String imageUrl;
  final String quote;
  final String name;
  final String role;
  final double quoteSize;
  final double height;

  @override
  Widget build(BuildContext context) {
    const avatarR = 40.0;
    const topInset = 26.0; // avatarR * 0.65
    final quoteBoxH = (height * 0.50).clamp(130.0, 200.0);

    return SizedBox(
      height: height,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          Positioned(
            left: 0,
            right: 0,
            top: topInset,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(26),
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFF2CA5C),
                    Colors.white,
                  ],
                  stops: [0.0, 0.58],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.14),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(
                18,
                52,
                18,
                12,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: quoteBoxH,
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Text(
                        quote,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                          fontSize: quoteSize,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF333333),
                          height: 1.45,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '— $name',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: quoteSize,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    role,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: (quoteSize - 2).clamp(13.0, 22.0),
                      fontWeight: FontWeight.w500,
                      fontStyle: FontStyle.italic,
                      color: const Color(0xFF616161),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 0,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipOval(
                child: Image.network(
                  imageUrl,
                  width: avatarR * 2,
                  height: avatarR * 2,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: avatarR * 2,
                    height: avatarR * 2,
                    color: const Color(0xFFE0E0E0),
                    child: const Icon(Icons.person, color: Colors.white54, size: 40),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactBambareSection extends StatelessWidget {
  const _ContactBambareSection();

  static const List<Shadow> _titleShadow = [
    Shadow(
      color: Color(0xB3000000),
      blurRadius: 24,
      offset: Offset(0, 5),
    ),
    Shadow(
      color: Color(0x66000000),
      blurRadius: 10,
      offset: Offset(0, 2),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.sizeOf(context).width;

    // Match _AboutBambareSection title size exactly.
    final titleSize = (screenW * 0.184).clamp(60.0, 78.0);
    final bodySize = (screenW * 0.043).clamp(15.0, 18.0);

    Widget titleLine(String text) {
      return Text(
        text,
        textAlign: TextAlign.center,
        style: GoogleFonts.outfit(
          fontSize: titleSize,
          fontWeight: FontWeight.w900,
          color: Colors.white,
          letterSpacing: titleSize * 0.045,
          height: 0.95,
          shadows: _titleShadow,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        titleLine('CONTACT'),
        titleLine('BAMBARE'),
        const SizedBox(height: 18),
        Text(
          'We’d love to hear from you.\nWhether you’re planning a hiking trip, cycling adventure, or need help with your booking, the Bambare team is always ready to help.',
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            fontSize: bodySize,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF111111),
            height: 1.25,
          ),
        ),
        const SizedBox(height: 22),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _ContactBlock(
                title: 'Address',
                body: 'Bambaradeniya Walawwa,\nKandy Road, Weligalla',
                bodySize: bodySize,
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ContactBlock(
                    title: 'Phone',
                    body: '+94 77 367 7712',
                    bodySize: bodySize,
                  ),
                  const SizedBox(height: 14),
                  _ContactBlock(
                    title: 'Email',
                    body: 'bambare27@gmail.com',
                    bodySize: bodySize,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 26),
        Text(
          'Follow us!',
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            fontSize: (bodySize + 8).clamp(20.0, 28.0),
            fontWeight: FontWeight.w900,
            color: const Color(0xFF111111),
            height: 1.05,
          ),
        ),
        const SizedBox(height: 16),
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _FollowItem(
              icon: Icons.facebook,
              color: Color(0xFF1877F2),
              label: '@bambare',
            ),
            _FollowItem(
              icon: Icons.chat_rounded,
              color: Color(0xFF25D366),
              label: '+94 77 367 7712',
            ),
            _FollowItem(
              icon: Icons.camera_alt_rounded,
              color: Color(0xFFE1306C),
              label: '@bambare27',
            ),
          ],
        ),
      ],
    );
  }
}

class _ContactBlock extends StatelessWidget {
  const _ContactBlock({
    required this.title,
    required this.body,
    required this.bodySize,
  });

  final String title;
  final String body;
  final double bodySize;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.outfit(
            fontSize: (bodySize + 2).clamp(16.0, 20.0),
            fontWeight: FontWeight.w900,
            color: const Color(0xFF111111),
            height: 1.1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          body,
          style: GoogleFonts.outfit(
            fontSize: bodySize,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF111111),
            height: 1.15,
          ),
        ),
      ],
    );
  }
}

class _FollowItem extends StatelessWidget {
  const _FollowItem({
    required this.icon,
    required this.color,
    required this.label,
  });

  final IconData icon;
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 22,
          backgroundColor: color,
          child: Icon(icon, color: Colors.white, size: 24),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF111111),
          ),
        ),
      ],
    );
  }
}

class _TipCard extends StatelessWidget {
  const _TipCard({
    required this.title,
    required this.body,
    required this.titleSize,
    required this.bodySize,
  });

  final String title;
  final String body;
  final double titleSize;
  final double bodySize;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: titleSize,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            body,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: bodySize,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF424242),
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _TourCard extends StatefulWidget {
  const _TourCard({required this.tour});

  final Tour tour;

  @override
  State<_TourCard> createState() => _TourCardState();
}

class _TourCardState extends State<_TourCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final tour = widget.tour;
    final imageUrl = tour.imageUrl.trim();
    final title = tour.title.trim();
    final location = tour.locationLabel.trim();
    if (title.isEmpty || imageUrl.isEmpty) {
      return const SizedBox.shrink();
    }

    const radius = 28.0;
    final lift = _hovered ? -12.0 : 0.0;
    final shadowAlpha = _hovered ? 0.18 : 0.10;
    final blur = _hovered ? 22.0 : 10.0;
    final y = _hovered ? 14.0 : 4.0;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        offset: Offset(0, lift / 100),
        child: AnimatedScale(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          scale: _hovered ? 1.03 : 1.0,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(radius),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => TourDetailScreen(tour: tour),
                  ),
                );
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                width: 260,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(radius),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: shadowAlpha),
                      blurRadius: blur,
                      offset: Offset(0, y),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(radius),
                        ),
                        child: Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: Colors.grey[300],
                            child: const Icon(Icons.image),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 16,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            title.toUpperCase(),
                            textAlign: TextAlign.center,
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.1,
                            ),
                          ),
                          if (location.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              location,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
