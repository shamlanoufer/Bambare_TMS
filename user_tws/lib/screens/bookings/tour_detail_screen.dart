import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';

import '../../core/booking_background.dart';
import '../../models/tour.dart';
import '../../models/tour_guest_review.dart';
import '../../services/saved_tours_service.dart';
import '../../services/tour_guest_review_service.dart';
import 'booking_screen.dart';

class TourDetailScreen extends StatefulWidget {
  const TourDetailScreen({super.key, required this.tour});

  final Tour tour;

  @override
  State<TourDetailScreen> createState() => _TourDetailScreenState();
}

class _TourDetailScreenState extends State<TourDetailScreen>
    with TickerProviderStateMixin {
  late final TabController _tabController;
  final _scrollCtrl = ScrollController();
  bool _headerCollapsed = false;
  bool _isSaved = false;
  StreamSubscription<bool>? _savedSub;

  final _savedService = SavedToursService();

  static const _accent = Color(0xFFE8B800);
  static const _bg = Color(0xFFFFFBF0);

  void _onTourTabChanged() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_onTourTabChanged);
    _wireSavedState();
    _scrollCtrl.addListener(() {
      final collapsed = _scrollCtrl.offset > 160;
      if (collapsed != _headerCollapsed) {
        setState(() => _headerCollapsed = collapsed);
      }
    });
  }

  Future<void> _wireSavedState() async {
    // Listen via service (supports local fallback when Firebase is blocked).
    _savedSub?.cancel();
    _savedSub = _savedService.isSavedStream(widget.tour.id).listen((v) {
      if (!mounted) return;
      setState(() => _isSaved = v);
    });
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTourTabChanged);
    _tabController.dispose();
    _scrollCtrl.dispose();
    _savedSub?.cancel();
    super.dispose();
  }

  LatLng _mapCenter(Tour tour) {
    final m = tour.mapInfo;
    if (m != null) {
      return LatLng(m.centerLat, m.centerLng);
    }
    return _getLatLng(tour.title);
  }

  /// Get the appropriate coordinates for any tour
  LatLng _getLatLng(String title) {
    if (title.contains('Sigiriya')) return const LatLng(7.9572, 80.7600);
    if (title.contains('Yala')) return const LatLng(6.3728, 81.5219);
    if (title.contains('Mirissa')) return const LatLng(5.9483, 80.4512);
    if (title.contains('Ella')) return const LatLng(6.8667, 81.0469);
    if (title.contains('Marble')) return const LatLng(8.5874, 81.2152);
    if (title.contains('Piduruthalagala')) return const LatLng(6.9977, 80.7726);
    if (title.contains('Kandy')) return const LatLng(7.2906, 80.6337);
    if (title.contains('Udunuwara')) return const LatLng(7.2667, 80.5167);
    return const LatLng(7.8731, 80.7718); // Sri Lanka centre
  }

  String _heroImageForTab(Tour tour) {
    const itineraryTabIndex = 1;
    const reviewTabIndex = 2;
    const mapTabIndex = 3;
    if (_tabController.index == itineraryTabIndex) {
      final u = tour.itineraryTabImageUrl?.trim() ?? '';
      if (u.isNotEmpty) return u;
    }
    if (_tabController.index == reviewTabIndex) {
      final u = tour.reviewTabImageUrl?.trim() ?? '';
      if (u.isNotEmpty) return u;
    }
    if (_tabController.index == mapTabIndex) {
      final u = tour.mapTabImageUrl?.trim() ?? '';
      if (u.isNotEmpty) return u;
    }
    return tour.imageUrl;
  }

  @override
  Widget build(BuildContext context) {
    final tour = widget.tour;
    final bottomPad = MediaQuery.paddingOf(context).bottom;
    final tourLatLng = _mapCenter(tour);
    final isSigiriya = tour.title.contains('Sigiriya');
    final heroImage = _heroImageForTab(tour);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: BookingBackgroundLayer(
        child: Stack(
        children: [
          NestedScrollView(
            controller: _scrollCtrl,
            headerSliverBuilder: (context, _) => [
              // Hero image sliver
              SliverAppBar(
                expandedHeight: 280,
                pinned: true,
                backgroundColor: Colors.black87,
                leading: Padding(
                  padding: const EdgeInsets.all(8),
                  child: _CircleButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    onTap: () => Navigator.pop(context),
                  ),
                ),
                actions: [
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: _CircleButton(
                      icon: _isSaved
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      onTap: () async {
                        try {
                          await _savedService.toggleSaved(tourId: tour.id);
                        } on FirebaseAuthException catch (e) {
                          if (!context.mounted) return;
                          final msg = e.code == 'operation-not-allowed'
                              ? 'Save is disabled. Enable Anonymous sign-in in Firebase Auth.'
                              : 'Could not save right now. (${e.code}) ${e.message ?? ''}'.trim();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(msg)),
                          );
                        } on FirebaseException catch (e) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Could not save right now. (${e.code}) ${e.message ?? ''}'.trim(),
                              ),
                            ),
                          );
                        } catch (e) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Could not save right now. $e'),
                            ),
                          );
                        }
                      },
                    ),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      _TourHeroImage(source: heroImage),
                      // gradient overlay
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.15),
                              Colors.black.withValues(alpha: 0.55),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Title + meta info section
              SliverToBoxAdapter(
                child: Container(
                  color: _bg,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tour.title,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: Colors.black87,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.location_on,
                              color: Colors.redAccent, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            tour.locationLabel.isNotEmpty
                                ? tour.locationLabel
                                : (isSigiriya
                                    ? 'Kandy, Centrel Province'
                                    : _getLocationForTour(tour.title)),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Stats row
                      Row(
                        children: [
                          _MetaChip(
                            icon: Icons.group_outlined,
                            label: 'Max ${tour.maxCapacity}',
                            sub: 'Group',
                          ),
                          const SizedBox(width: 10),
                          _MetaChip(
                            icon: Icons.wb_sunny_outlined,
                            label: tour.weatherNote?.trim().isNotEmpty == true
                                ? tour.weatherNote!.trim()
                                : '34 °C',
                            sub: 'Weather',
                            iconColor: Colors.orange,
                          ),
                          const SizedBox(width: 10),
                          _MetaChip(
                            icon: Icons.attach_money_rounded,
                            label: '${tour.price.round()}',
                            sub: 'per person',
                            iconColor: const Color(0xFFB8860B),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Tab bar
              SliverPersistentHeader(
                pinned: true,
                delegate: _TabHeaderDelegate(
                  tabController: _tabController,
                  accent: _accent,
                  bg: _bg,
                ),
              ),
            ],
            body: TabBarView(
              controller: _tabController,
              children: [
                _OverviewTab(tour: tour),
                _ItineraryTab(tour: tour, isSigiriya: isSigiriya),
                _ReviewTab(tour: tour),
                _MapTab(tour: tour, fallbackCenter: tourLatLng, isSigiriya: isSigiriya),
              ],
            ),
          ),

          // Floating Book Now button
          Positioned(
            left: 20,
            right: 20,
            bottom: bottomPad + 16,
            child: _BookNowButton(tour: tour),
          ),
        ],
      ),
      ),
    );
  }

  String _getLocationForTour(String title) {
    if (title.contains('Yala')) return 'Yala National Park';
    if (title.contains('Mirissa')) return 'Mirissa, Southern Province';
    if (title.contains('Ella')) return 'Ella, Uva Province';
    if (title.contains('Marble')) return 'Trincomalee';
    if (title.contains('Piduruthalagala')) return 'Nuwara Eliya';
    if (title.contains('Kandy')) return 'Kandy, Central Province';
    if (title.contains('Udunuwara')) return 'Udunuwara, Kandy';
    return 'Sri Lanka';
  }
}

// ─── Tab header persistent delegate ─────────────────────────────────────────

class _TabHeaderDelegate extends SliverPersistentHeaderDelegate {
  const _TabHeaderDelegate({
    required this.tabController,
    required this.accent,
    required this.bg,
  });

  final TabController tabController;
  final Color accent;
  final Color bg;

  @override
  double get minExtent => 48;
  @override
  double get maxExtent => 48;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: bg,
      child: TabBar(
        controller: tabController,
        labelColor: Colors.black87,
        unselectedLabelColor: Colors.black45,
        indicatorColor: accent,
        indicatorWeight: 3,
        labelStyle: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        tabs: const [
          Tab(text: 'Overview'),
          Tab(text: 'Itinerary'),
          Tab(text: 'Review'),
          Tab(text: 'Map'),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _TabHeaderDelegate oldDelegate) => false;
}

// ─── Overview Tab ────────────────────────────────────────────────────────────

class _OverviewTab extends StatelessWidget {
  const _OverviewTab({required this.tour});
  final Tour tour;

  static const double _maxBodyWidth = 560;
  static const double _maxGalleryImageWidth = 380;

  @override
  Widget build(BuildContext context) {
    final isSigiriya = tour.title.contains('Sigiriya');
    final overview = tour.overviewBody?.trim();
    final inclusionItems =
        tour.inclusions.isNotEmpty ? tour.inclusions : _inclusions(isSigiriya);
    final bgUrl = tour.overviewBackgroundImageUrl?.trim() ?? '';
    final hasBg = bgUrl.isNotEmpty;

    final scroll = SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 100),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _maxBodyWidth),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  overview != null && overview.isNotEmpty
                      ? overview
                      : (isSigiriya
                          ? 'Sigiriya Rock Fortress is one of Sri Lanka\'s most iconic historical landmarks and a UNESCO World Heritage Site. Built in the 5th century by King Kashyapa, this ancient palace complex rises nearly 200 metres above the surrounding plains.\n\nThe site is famous for its impressive rock frescoes, the Mirror Wall, landscaped royal gardens, and the massive Lion\'s Paw entrance carved into the rock. At the summit, visitors can explore the ruins of the royal palace while enjoying breathtaking panoramic views.\n\nSigiriya stands as a remarkable example of ancient Sri Lankan engineering, architecture, and artistry, making it a must-visit cultural and historical destination.'
                          : 'Discover the breathtaking beauty of ${tour.title}, one of Sri Lanka\'s most stunning destinations. This expertly guided tour offers an unforgettable experience of the island\'s natural and cultural wonders.'),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Colors.black54,
                    height: 1.7,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  "What's included",
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 14),
                ...inclusionItems.map((item) => _InclusionItem(label: item)),
                if (tour.galleryUrls.isNotEmpty) ...[
                  const SizedBox(height: 28),
                  Text(
                    'Gallery',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...tour.galleryUrls.map(
                    (url) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxWidth: _maxGalleryImageWidth,
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: AspectRatio(
                              aspectRatio: 16 / 10,
                              child: Image.network(
                                url,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  color: Colors.black12,
                                  alignment: Alignment.center,
                                  child:
                                      const Icon(Icons.broken_image_outlined),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );

    if (!hasBg) return scroll;

    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(
          child: Image.network(
            bgUrl,
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
            errorBuilder: (_, __, ___) =>
                const ColoredBox(color: Color(0xFFFFFBF0)),
          ),
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withValues(alpha: 0.88),
                  Colors.white.withValues(alpha: 0.82),
                  const Color(0xFFFFFBF0).withValues(alpha: 0.9),
                ],
              ),
            ),
          ),
        ),
        scroll,
      ],
    );
  }

  static List<String> _inclusions(bool isSigiriya) {
    if (isSigiriya) {
      return [
        'Expert licensed guide throughout',
        'AC transport from Colombo',
        '1-night hotel accommodation',
        'All entrance fees & tickets',
        'Welcome dinner on arrival',
      ];
    }
    return [
      'Professional guide throughout',
      'Comfortable transport',
      'All entrance fees & tickets',
      'Light refreshments',
    ];
  }
}

class _InclusionItem extends StatelessWidget {
  const _InclusionItem({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(Icons.check, color: Color(0xFF2E7D32), size: 14),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Itinerary Tab ───────────────────────────────────────────────────────────

class _ItineraryTab extends StatelessWidget {
  const _ItineraryTab({required this.tour, required this.isSigiriya});
  final Tour tour;
  final bool isSigiriya;

  static const double _maxBodyWidth = 560;

  static List<Map<String, dynamic>> _eventsForDay(Map<String, dynamic> day) {
    final ev = day['events'];
    if (ev is! List) return const [];
    return ev
        .map((e) => e is Map ? Map<String, dynamic>.from(e) : <String, dynamic>{})
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final days = tour.itineraryDays.isNotEmpty
        ? tour.itineraryDays
        : (isSigiriya ? _sigiriyaDays : _genericDays);
    final footer = tour.exclusions.isNotEmpty ? 1 : 0;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _maxBodyWidth),
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
          itemCount: days.length + footer,
          itemBuilder: (context, di) {
            if (di >= days.length) {
              return _NotIncludedSection(items: tour.exclusions);
            }
            final day = days[di];
            final events = _eventsForDay(day);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Day header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8B800),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'DAY ${di + 1}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        day['title'] as String? ?? '',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.only(left: 14),
                  child: Text(
                    day['subtitle'] as String? ?? '',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: Colors.black45,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Timeline events
                ...events.map((e) => _TimelineEvent(event: e)),
                const SizedBox(height: 28),
              ],
            );
          },
        ),
      ),
    );
  }

  static final _sigiriyaDays = [
    {
      'title': 'Colombo → Sigiriya',
      'subtitle': 'March 8 Departure & Arrival',
      'events': [
        {
          'time': '5.30 AM',
          'icon': '🏨',
          'title': 'Hotel Pickup',
          'location': 'Colombo Fort',
          'desc': 'AC coach departs from Colombo Fort. Light snack & water provided on board for the journey.',
          'tag': 'Transport included',
          'duration': '3.5 hrs',
        },
        {
          'time': '9.00 AM',
          'icon': '🏨',
          'title': 'Check-in',
          'location': 'Sigiriya Village',
          'desc': 'Check into your room, freshen up. The hotel overlooks the Sigiriya Rock with stunning views.',
          'tag': '1-nightstay included',
          'duration': null,
        },
        {
          'time': '10.00 AM',
          'icon': '🪨',
          'title': 'Sigiriya Rock Climb',
          'location': null,
          'desc': 'Ascend the iconic Lion Rock with your expert guide. Discover 5th-century frescoes, the Mirror Wall, and breathtaking views from the 200m summit plateau.',
          'tag': 'Transport included',
          'duration': '3.5 hrs',
        },
      ],
    },
    {
      'title': 'Sigiriya → Dambulla',
      'subtitle': 'March 9 Exploration Day',
      'events': [
        {
          'time': '7.00 AM',
          'icon': '🍽️',
          'title': 'Breakfast',
          'location': 'Sigiriya Village Hotel',
          'desc': 'Traditional Sri Lankan breakfast at the hotel.',
          'tag': 'Meals included',
          'duration': null,
        },
        {
          'time': '9.00 AM',
          'icon': '🕌',
          'title': 'Dambulla Cave Temple',
          'location': 'Dambulla',
          'desc': 'Visit the magnificent cave temples with golden Buddha statues and ancient murals.',
          'tag': 'Entrance included',
          'duration': '2 hrs',
        },
        {
          'time': '2.00 PM',
          'icon': '🚌',
          'title': 'Return Journey',
          'location': 'Colombo Fort',
          'desc': 'Comfortable AC coach back to Colombo. Arrive by evening.',
          'tag': 'Transport included',
          'duration': '3.5 hrs',
        },
      ],
    },
  ];

  static final _genericDays = [
    {
      'title': 'Departure Day',
      'subtitle': 'Day 1 – Arrival & Orientation',
      'events': [
        {
          'time': '6.00 AM',
          'icon': '🚌',
          'title': 'Hotel Pickup',
          'location': 'Colombo Fort',
          'desc': 'Comfortable AC transport picks you up from your hotel.',
          'tag': 'Transport included',
          'duration': '2 hrs',
        },
        {
          'time': '9.00 AM',
          'icon': '🎯',
          'title': 'Arrival',
          'location': 'Destination',
          'desc': 'Arrive at your destination, meet your guide and begin.',
          'tag': null,
          'duration': null,
        },
      ],
    },
  ];
}

class _NotIncludedSection extends StatelessWidget {
  const _NotIncludedSection({required this.items});
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'NOT INCLUDED',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 14),
        ...items.map((label) => _ExclusionItem(label: label)),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _ExclusionItem extends StatelessWidget {
  const _ExclusionItem({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: const Color(0xFFFFEBEE),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(Icons.close, color: Color(0xFFC62828), size: 14),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineEvent extends StatelessWidget {
  const _TimelineEvent({required this.event});
  final Map<String, dynamic> event;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timeline line
          SizedBox(
            width: 32,
            child: Column(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE8B800),
                    shape: BoxShape.circle,
                  ),
                ),
                Expanded(
                  child: Container(
                    width: 2,
                    color: const Color(0xFFE8B800).withValues(alpha: 0.3),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event['time'] as String,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.black45,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        event['icon'] as String? ?? '📍',
                        style: const TextStyle(fontSize: 18),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              event['title'] as String,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: Colors.black87,
                              ),
                            ),
                            if (event['location'] != null)
                              Text(
                                event['location'] as String,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  color: Colors.black45,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    event['desc'] as String,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: Colors.black54,
                      height: 1.5,
                    ),
                  ),
                  if ((event['image_url'] as String?)?.trim().isNotEmpty ==
                      true) ...[
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: AspectRatio(
                        aspectRatio: 16 / 10,
                        child: Image.network(
                          (event['image_url'] as String).trim(),
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: Colors.black12,
                            alignment: Alignment.center,
                            child: const Icon(Icons.broken_image_outlined),
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  if (event['tag'] != null || event['duration'] != null)
                    Row(
                      children: [
                        if (event['tag'] != null)
                          _Tag(
                            label: event['tag'] as String,
                            color: const Color(0xFFFFF9E0),
                            textColor: Colors.black87,
                          ),
                        if (event['duration'] != null) ...[
                          const SizedBox(width: 8),
                          _Tag(
                            label: event['duration'] as String,
                            color: const Color(0xFFE8B800)
                                .withValues(alpha: 0.15),
                            textColor: const Color(0xFFB8860B),
                          ),
                        ],
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

class _Tag extends StatelessWidget {
  const _Tag(
      {required this.label, required this.color, required this.textColor});
  final String label;
  final Color color;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
    );
  }
}

// ─── Review Tab ──────────────────────────────────────────────────────────────

String _guestReviewRelativeDate(DateTime d) {
  final diff = DateTime.now().difference(d);
  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
  if (diff.inHours < 24) return '${diff.inHours} hr ago';
  if (diff.inDays < 7) return '${diff.inDays} days ago';
  if (diff.inDays < 30) return '${(diff.inDays / 7).floor()} wk ago';
  return '${(diff.inDays / 30).floor()} mo ago';
}

class _ReviewTab extends StatelessWidget {
  const _ReviewTab({required this.tour});
  final Tour tour;

  static const double _maxBodyWidth = 560;

  static final _guestReviewSvc = TourGuestReviewService();

  @override
  Widget build(BuildContext context) {
    final rating = tour.rating;
    final reviewCount = tour.reviewDisplayCount ?? 124;
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 100),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _maxBodyWidth),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
          // Summary
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    rating.toStringAsFixed(1),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 52,
                      fontWeight: FontWeight.w900,
                      color: Colors.black87,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: List.generate(5, (i) {
                      final filled = i < rating.floor();
                      return Icon(
                        filled ? Icons.star_rounded : Icons.star_outline_rounded,
                        color: const Color(0xFFE8B800),
                        size: 20,
                      );
                    }),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$reviewCount reviews',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: Colors.black45,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 24),
              const Expanded(
                child: Column(
                  children: [
                    _RatingBar(label: '5', fraction: 0.75),
                    _RatingBar(label: '4', fraction: 0.15),
                    _RatingBar(label: '3', fraction: 0.05),
                    _RatingBar(label: '2', fraction: 0.03),
                    _RatingBar(label: '1', fraction: 0.02),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Category tags
          const Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _CategoryTag(label: 'Guide Quality'),
              _CategoryTag(label: 'Value for Money'),
              _CategoryTag(label: 'Transport'),
              _CategoryTag(label: 'Accommodation'),
            ],
          ),
          const SizedBox(height: 24),
          if (tour.reviewMarketingGalleryUrls.isNotEmpty) ...[
            Text(
              'Photos',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 76,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: tour.reviewMarketingGalleryUrls.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final u = tour.reviewMarketingGalleryUrls[i];
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: Image.network(
                        u,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: Colors.black12,
                          child: const Icon(Icons.broken_image_outlined),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
          ],
          Text(
            'Guest Reviews',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          StreamBuilder<List<TourGuestReview>>(
            stream: _guestReviewSvc.approvedReviewsStream(tour.id),
            builder: (context, snap) {
              if (snap.hasError) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    'Could not load reviews.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: Colors.black45,
                    ),
                  ),
                );
              }
              if (snap.connectionState == ConnectionState.waiting &&
                  !snap.hasData) {
                return const Padding(
                  padding: EdgeInsets.only(bottom: 24),
                  child: Center(
                    child: SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFFE8B800),
                      ),
                    ),
                  ),
                );
              }
              final list = snap.data ?? const <TourGuestReview>[];
              if (list.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    'No guest reviews yet.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: Colors.black45,
                    ),
                  ),
                );
              }
              return Column(
                children: list
                    .map((r) => _GuestReviewCard(review: r))
                    .toList(growable: false),
              );
            },
          ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RatingBar extends StatelessWidget {
  const _RatingBar({required this.label, required this.fraction});
  final String label;
  final double fraction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: Colors.black45,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: fraction,
                backgroundColor: Colors.black.withValues(alpha: 0.07),
                color: const Color(0xFFE8B800),
                minHeight: 6,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${(fraction * 100).round()}%',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              color: Colors.black45,
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryTag extends StatelessWidget {
  const _CategoryTag({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.black12),
      ),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
    );
  }
}

class _GuestReviewCard extends StatelessWidget {
  const _GuestReviewCard({required this.review});
  final TourGuestReview review;

  static Widget _starRow(double rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final idx = i + 1;
        if (rating >= idx) {
          return const Icon(Icons.star_rounded,
              color: Color(0xFFE8B800), size: 14);
        }
        if (rating >= idx - 0.5) {
          return const Icon(Icons.star_half_rounded,
              color: Color(0xFFE8B800), size: 14);
        }
        return const Icon(Icons.star_outline_rounded,
            color: Color(0xFFE8B800), size: 14);
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final photo = review.userPhotoUrl.trim();
    final hasPhoto = photo.startsWith('http') || photo.startsWith('data:');
    final trimmedName = review.userName.trim();
    final initial = trimmedName.isEmpty
        ? '?'
        : trimmedName.substring(0, 1).toUpperCase();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF9F0),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: hasPhoto
                    ? Image.network(
                        photo,
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 40,
                          height: 40,
                          color: const Color(0xFFF5F0E6),
                          alignment: Alignment.center,
                          child: Text(
                            initial,
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      )
                    : Container(
                        width: 40,
                        height: 40,
                        color: const Color(0xFFE3F2FD),
                        alignment: Alignment.center,
                        child: Text(
                          initial,
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w800,
                            color: Colors.black87,
                          ),
                        ),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.userName,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    _starRow(review.rating),
                  ],
                ),
              ),
              Text(
                _guestReviewRelativeDate(review.createdAt),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: Colors.black38,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            review.commentText,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: Colors.black54,
              height: 1.6,
            ),
          ),
          if (review.reviewImageUrl.isNotEmpty) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.network(
                  review.reviewImageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: Colors.black12,
                    alignment: Alignment.center,
                    child: const Icon(Icons.broken_image_outlined),
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.thumb_up_outlined,
                  color: Colors.black45, size: 16),
              const SizedBox(width: 6),
              Text(
                'Helpful (${review.helpfulCount})',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.black45,
                ),
              ),
              const Spacer(),
              Text(
                'Reply',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFB8860B),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Map Tab ─────────────────────────────────────────────────────────────────

class _MapTab extends StatelessWidget {
  const _MapTab({
    required this.tour,
    required this.fallbackCenter,
    required this.isSigiriya,
  });
  final Tour tour;
  final LatLng fallbackCenter;
  final bool isSigiriya;

  static bool _useCustomStats(TourMapInfo? m) {
    if (m == null) return false;
    return m.statDistance.isNotEmpty ||
        m.statDrive.isNotEmpty ||
        m.statPeak.isNotEmpty ||
        m.statRoute.isNotEmpty;
  }

  static List<Map<String, dynamic>> _stopsForTour(
    Tour tour,
    LatLng fallbackCenter,
    bool isSigiriya,
  ) {
    final m = tour.mapInfo;
    if (m != null && m.stops.isNotEmpty) {
      return m.stops.map((s) {
        final lat = (s['lat'] as num?)?.toDouble();
        final lng = (s['lng'] as num?)?.toDouble();
        final ll = lat != null && lng != null
            ? LatLng(lat, lng)
            : fallbackCenter;
        return {
          'icon': s['icon'] ?? '📍',
          'title': s['title'] ?? '',
          'time': s['time'] ?? '',
          'coords':
              '⬆ ${ll.latitude.toStringAsFixed(2)}°, ${ll.longitude.toStringAsFixed(2)}°',
          'latlng': ll,
        };
      }).toList();
    }
    return isSigiriya ? _sigiriyaStops : _genericStops(fallbackCenter);
  }

  @override
  Widget build(BuildContext context) {
    final m = tour.mapInfo;
    final center =
        m != null ? LatLng(m.centerLat, m.centerLng) : fallbackCenter;
    final stops = _stopsForTour(tour, fallbackCenter, isSigiriya);
    final customStats = _useCustomStats(m);

    return Column(
      children: [
        // Stats bar
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: customStats && m != null
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _MapStat(
                      value:
                          m.statDistance.isNotEmpty ? m.statDistance : '—',
                      label: 'Distance',
                    ),
                    const _MapStatDivider(),
                    _MapStat(
                      value: m.statDrive.isNotEmpty ? m.statDrive : '—',
                      label: 'Drive time',
                    ),
                    const _MapStatDivider(),
                    _MapStat(
                      value: m.statPeak.isNotEmpty ? m.statPeak : '—',
                      label: 'Peak / height',
                    ),
                    const _MapStatDivider(),
                    _MapStat(
                      value: m.statRoute.isNotEmpty ? m.statRoute : '—',
                      label: 'Route',
                    ),
                  ],
                )
              : const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _MapStat(value: '167 km', label: 'from Colombo'),
                    _MapStatDivider(),
                    _MapStat(value: '3.5h', label: 'Drive Time'),
                    _MapStatDivider(),
                    _MapStat(value: '200m', label: 'Rock Height'),
                    _MapStatDivider(),
                    _MapStat(value: 'A9', label: 'highway'),
                  ],
                ),
        ),

        // Real map
        Expanded(
          flex: 5,
          child: FlutterMap(
            options: MapOptions(
              initialCenter: center,
              initialZoom: 13,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.bambare.book_tws',
                maxZoom: 19,
              ),
              MarkerLayer(
                markers: stops
                    .map(
                      (s) => Marker(
                        point: s['latlng'] as LatLng,
                        width: 36,
                        height: 36,
                        child: GestureDetector(
                          onTap: () {},
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8B800),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.25),
                                  blurRadius: 6,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                s['icon'] as String? ?? '📍',
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),

        // Stops list
        Expanded(
          flex: 4,
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
            itemCount: stops.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final s = stops[i];
              return _MapStopCard(stop: s);
            },
          ),
        ),
      ],
    );
  }

  static final _sigiriyaStops = [
    {
      'icon': '🚉',
      'title': 'Colombo Fort Station',
      'time': 'Pickup : 5:30 AM departure',
      'coords': '⬆ 6.18°N, 80.63°E',
      'latlng': const LatLng(6.9347, 79.8497),
    },
    {
      'icon': '🪨',
      'title': 'Sigiriya Rock Fortress',
      'time': 'Pickup : 5:30 AM departure',
      'coords': '⬆ 8.18°N, 80.63°E',
      'latlng': const LatLng(7.9572, 80.7600),
    },
    {
      'icon': '🏨',
      'title': 'Sigiriya Village Hotel',
      'time': 'Pickup : 5:30 AM departure',
      'coords': '⬆ 8.18°N, 80.63°E',
      'latlng': const LatLng(7.9500, 80.7550),
    },
    {
      'icon': '🕌',
      'title': 'Pidurangala Cave Temple',
      'time': 'Pickup : 5:30 AM departure',
      'coords': '⬆ 8.18°N, 80.63°E',
      'latlng': const LatLng(7.9640, 80.7580),
    },
    {
      'icon': '💧',
      'title': 'Sigiriya Water Garden',
      'time': 'Pickup : 5:30 AM departure',
      'coords': '⬆ 8.18°N, 80.63°E',
      'latlng': const LatLng(7.9560, 80.7620),
    },
  ];

  static List<Map<String, dynamic>> _genericStops(LatLng center) {
    return [
      {
        'icon': '🚉',
        'title': 'Starting Point',
        'time': 'Pickup : 6:00 AM departure',
        'coords': '⬆ ${center.latitude.toStringAsFixed(2)}°N, ${center.longitude.toStringAsFixed(2)}°E',
        'latlng': LatLng(center.latitude - 0.01, center.longitude - 0.01),
      },
      {
        'icon': '🎯',
        'title': 'Main Destination',
        'time': 'Arrive : 9:00 AM',
        'coords': '⬆ ${center.latitude.toStringAsFixed(2)}°N, ${center.longitude.toStringAsFixed(2)}°E',
        'latlng': center,
      },
    ];
  }
}

class _MapStat extends StatelessWidget {
  const _MapStat({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: Colors.black87,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            color: Colors.black45,
          ),
        ),
      ],
    );
  }
}

class _MapStatDivider extends StatelessWidget {
  const _MapStatDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      width: 1,
      color: Colors.black.withValues(alpha: 0.1),
    );
  }
}

class _MapStopCard extends StatelessWidget {
  const _MapStopCard({required this.stop});
  final Map<String, dynamic> stop;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF9E0),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                stop['icon'] as String,
                style: const TextStyle(fontSize: 20),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stop['title'] as String,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  stop['time'] as String,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: Colors.black45,
                  ),
                ),
                Text(
                  stop['coords'] as String,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: const Color(0xFFB8860B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: Colors.black38),
        ],
      ),
    );
  }
}

// ─── Hero image ──────────────────────────────────────────────────────────────

class _TourHeroImage extends StatelessWidget {
  const _TourHeroImage({required this.source});
  final String source;

  @override
  Widget build(BuildContext context) {
    if (source.startsWith('http')) {
      return Image.network(source,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
              Container(color: const Color(0xFF4A4A4A)));
    }
    return Image.asset(
      source,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(color: const Color(0xFF4A4A4A)),
    );
  }
}

// ─── Circle button ───────────────────────────────────────────────────────────

class _CircleButton extends StatelessWidget {
  const _CircleButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.35),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}

// ─── Meta chip ───────────────────────────────────────────────────────────────

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.icon,
    required this.label,
    required this.sub,
    this.iconColor,
  });
  final IconData icon;
  final String label;
  final String sub;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F0E6),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Icon(icon, color: iconColor ?? Colors.black54, size: 22),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: Colors.black87,
              ),
            ),
            Text(
              sub,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                color: Colors.black45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Book Now button ─────────────────────────────────────────────────────────

class _BookNowButton extends StatelessWidget {
  const _BookNowButton({required this.tour});
  final Tour tour;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BookingScreen(tour: tour),
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFE8B800),
          foregroundColor: Colors.black87,
          elevation: 4,
          shadowColor: const Color(0xFFE8B800).withValues(alpha: 0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: Text(
          'Book Now',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }
}
