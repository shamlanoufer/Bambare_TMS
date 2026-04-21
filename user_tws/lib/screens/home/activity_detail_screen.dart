import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/tour.dart';
import '../../services/tour_service.dart';
import '../bookings/tour_detail_screen.dart';

/// Six home activities — each opens [ActivityDetailScreen] with copy + background.
enum HomeActivity {
  hiking,
  cycling,
  trekking,
  tukTukRide,
  jeepRide,
  cookerySession,
}

extension HomeActivityPlacementId on HomeActivity {
  /// Matches admin `visibility.activity_*` keys via [TourService.toursForActivityId].
  String get placementId {
    switch (this) {
      case HomeActivity.hiking:
        return 'hiking';
      case HomeActivity.cycling:
        return 'cycling';
      case HomeActivity.trekking:
        return 'trekking';
      case HomeActivity.tukTukRide:
        return 'tuk_tuk';
      case HomeActivity.jeepRide:
        return 'jeep';
      case HomeActivity.cookerySession:
        return 'cookery';
    }
  }
}

extension HomeActivityX on HomeActivity {
  /// Hero title (short, like the reference “HIKE”).
  String get heroTitle {
    switch (this) {
      case HomeActivity.hiking:
        return 'HIKE';
      case HomeActivity.cycling:
        return 'CYCLING';
      case HomeActivity.trekking:
        return 'TREKKING';
      case HomeActivity.tukTukRide:
        return 'TUK TUK RIDE';
      case HomeActivity.jeepRide:
        return 'JEEP RIDE';
      case HomeActivity.cookerySession:
        return 'COOKERY';
    }
  }

  /// Home “Activities” row only — small strip cards under `images/booking/Activity/`.
  String get carouselAssetPath {
    switch (this) {
      case HomeActivity.hiking:
        return 'images/booking/Activity/Hikings.jpg';
      case HomeActivity.cycling:
        return 'images/booking/Activity/cycling.jpg';
      case HomeActivity.trekking:
        return 'images/booking/Activity/trekking.jpg';
      case HomeActivity.tukTukRide:
        return 'images/booking/Activity/tuk tuk ride.jpg';
      case HomeActivity.jeepRide:
        return 'images/booking/Activity/jeep ride.jpg';
      case HomeActivity.cookerySession:
        return 'images/booking/Activity/cookery session.jpg';
    }
  }

  /// Activity detail page full-bleed only — `images/booking/Activity Background img/` (unchanged when carousel images change).
  String get backgroundAssetPath {
    switch (this) {
      case HomeActivity.hiking:
        return 'images/booking/Activity Background img/Hiking Background.jpg';
      case HomeActivity.cycling:
        return 'images/booking/Activity Background img/cycling background.jpg';
      case HomeActivity.trekking:
        return 'images/booking/Activity Background img/trekking background.jpg';
      case HomeActivity.tukTukRide:
        return 'images/booking/Activity Background img/tuk tuk ride background.jpg';
      case HomeActivity.jeepRide:
        return 'images/booking/Activity Background img/jeep ride background.jpg';
      case HomeActivity.cookerySession:
        return 'images/booking/Activity Background img/cookery session background.jpg';
    }
  }

  String get bodyText {
    switch (this) {
      case HomeActivity.hiking:
        return "Discover the beauty of Sri Lanka's hills through our guided hiking experiences. From scenic mountain trails to hidden forest paths, Bambare offers adventures that connect you with nature, culture, and breathtaking views. Whether you're seeking peaceful walks or challenging climbs, our hiking journeys are designed to give you an unforgettable outdoor experience.";
      case HomeActivity.cycling:
        return "Explore scenic routes on two wheels and enjoy the fresh air of Sri Lanka's countryside. From peaceful village roads to challenging hill tracks, Bambare cycling tours offer a perfect mix of relaxation and adventure while connecting you with nature and local life.";
      case HomeActivity.trekking:
        return "Step beyond the usual paths and discover untouched landscapes through guided trekking experiences. Whether it's misty mountains or dense forests, Bambare trekking takes you deeper into nature with thrilling routes and unforgettable views.";
      case HomeActivity.tukTukRide:
        return 'Experience Sri Lanka like a local with exciting tuk tuk rides through vibrant streets and hidden gems. From cultural landmarks to scenic coastal roads, Bambare offers fun and authentic journeys filled with color, life, and adventure.';
      case HomeActivity.jeepRide:
        return 'Get ready for an off-road adventure with our thrilling jeep rides. Travel through rugged terrains, rivers, and wildlife-rich areas while enjoying the raw beauty of nature. Bambare jeep safaris bring excitement and exploration together.';
      case HomeActivity.cookerySession:
        return 'Discover the rich flavors of Sri Lankan cuisine through hands-on cookery sessions. Learn traditional recipes, local ingredients, and authentic cooking techniques while enjoying a delicious cultural experience with Bambare.';
    }
  }
}

/// Full-bleed activity story — title, drop-cap paragraph, cream top scrim (black text).
class ActivityDetailScreen extends StatelessWidget {
  const ActivityDetailScreen({super.key, required this.activity});

  final HomeActivity activity;

  static const double _maxBodyWidth = 560;

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: Image.asset(
              activity.backgroundAssetPath,
              fit: BoxFit.cover,
              alignment: Alignment.center,
              errorBuilder: (_, __, ___) => const ColoredBox(
                color: Color(0xFF2C2C2C),
                child: Center(
                  child: Icon(Icons.image_not_supported_outlined,
                      color: Colors.white54, size: 48),
                ),
              ),
            ),
          ),
          // Warm top scrim + fade — keeps black title/body readable (reference layout).
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: MediaQuery.sizeOf(context).height * 0.55,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFFFFF6E0).withValues(alpha: 0.94),
                    const Color(0xFFFFF6E0).withValues(alpha: 0.55),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.42, 1.0],
                ),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 4, 16, 0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded),
                      color: Colors.black87,
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Text(
                    activity.heroTitle,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.cormorantGaramond(
                      fontSize: 44,
                      fontWeight: FontWeight.w700,
                      fontStyle: FontStyle.italic,
                      height: 1.05,
                      color: Colors.black87,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(28, 0, 28, 24 + bottomPad),
                    physics: const BouncingScrollPhysics(),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: _maxBodyWidth),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _DropCapParagraph(text: activity.bodyText),
                            const SizedBox(height: 28),
                            _ActivityLinkedTours(activity: activity),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityLinkedTours extends StatelessWidget {
  const _ActivityLinkedTours({required this.activity});

  final HomeActivity activity;

  static const double _cardWidth = 260;

  @override
  Widget build(BuildContext context) {
    final svc = TourService();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tours for this activity',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 10),
        StreamBuilder<List<Tour>>(
          stream: svc.toursForActivityId(activity.placementId),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting &&
                !snap.hasData) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              );
            }
            final tours = snap.data ?? const <Tour>[];
            if (tours.isEmpty) {
              return Text(
                'No tour packages are linked to this activity yet. Tick the matching activity in Admin → Publish.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  height: 1.5,
                  color: Colors.black54,
                ),
              );
            }
            return Column(
              children: tours.map((t) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Center(
                    child: SizedBox(
                      width: _cardWidth,
                      child: _ActivityTourCard(tour: t),
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}

class _ActivityTourCard extends StatefulWidget {
  const _ActivityTourCard({required this.tour});

  final Tour tour;

  @override
  State<_ActivityTourCard> createState() => _ActivityTourCardState();
}

class _ActivityTourCardState extends State<_ActivityTourCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final tour = widget.tour;
    final imageUrl = tour.imageUrl.trim();
    final title = tour.title.trim();
    final location = tour.locationLabel.trim();

    const radius = 28.0;
    final lift = _hovered ? -10.0 : 0.0;
    final shadowAlpha = _hovered ? 0.20 : 0.12;
    final blur = _hovered ? 22.0 : 14.0;
    final y = _hovered ? 14.0 : 6.0;

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
                    AspectRatio(
                      aspectRatio: 16 / 10,
                      child: imageUrl.isNotEmpty
                          ? Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  const ColoredBox(color: Colors.black12),
                            )
                          : const ColoredBox(color: Colors.black12),
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
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.1,
                              color: Colors.black87,
                            ),
                          ),
                          if (location.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              location,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                color: Colors.black54,
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

class _DropCapParagraph extends StatelessWidget {
  const _DropCapParagraph({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final t = text.trim();
    if (t.isEmpty) return const SizedBox.shrink();
    final first = t[0];
    final rest = t.length > 1 ? t.substring(1) : '';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 10, top: 2),
          child: Text(
            first,
            style: GoogleFonts.cormorantGaramond(
              fontSize: 58,
              fontWeight: FontWeight.w700,
              height: 0.95,
              color: Colors.black87,
            ),
          ),
        ),
        Expanded(
          child: Text(
            rest,
            textAlign: TextAlign.left,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              height: 1.65,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }
}
