import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/booking.dart';
import '../models/tour.dart';
import '../services/booking_service.dart';
import '../services/tour_service.dart';
import 'discover_tours_screen.dart';
import 'my_bookings_screen.dart';
import 'tour_detail_screen.dart';

/// Explore dashboard (Bookings tab) — matches travel discovery mockup.
class ExploreDashboardScreen extends StatelessWidget {
  const ExploreDashboardScreen({super.key});

  static final _tourService = TourService();

  static const _bg = Color(0xFFFFFBF0);
  static const _accent = Color(0xFFE8B800);
  static const _searchFill = Color(0xFFF2F0EB);
  static const _statCardBg = Color(0xFFF5F0E6);



  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.paddingOf(context).top;
    final bottomSafe = MediaQuery.paddingOf(context).bottom;

    return ColoredBox(
      color: _bg,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, topPad + 12, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  '☀️',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 16,
                                    height: 1.2,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Good morning, Sarah',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black54,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            GestureDetector(
                              onLongPress: () async {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Wait, seeding data...')),
                                );
                                await _seedDummyTours();
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Done! Data seeded into Database.')),
                                  );
                                }
                              },
                              child: Text(
                                'Where are you exploring today?',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 23,
                                  fontWeight: FontWeight.w700,
                                  height: 1.2,
                                  letterSpacing: -0.3,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Material(
                        color: _accent.withValues(alpha: 0.35),
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: () {},
                          child: const Padding(
                            padding: EdgeInsets.all(11),
                            child: Icon(
                              Icons.notifications_outlined,
                              color: Color(0xFFB8860B),
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const _SearchBar(),
                  const SizedBox(height: 20),
                  const _QuickStatsRow(),
                  const SizedBox(height: 26),
                  Text(
                    'Explore Categories',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const _CategoryRow(),
                  const SizedBox(height: 28),
                  Row(
                    children: [
                      Text(
                        '🔥 Popular Tours',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const DiscoverToursScreen(),
                            ),
                          );
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          backgroundColor: _accent.withValues(alpha: 0.1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'See all',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: _accent,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 10,
                              color: _accent,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  StreamBuilder<List<Tour>>(
                    stream: _tourService.featuredToursStream(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting &&
                          !snapshot.hasData) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 48),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFFE8B800),
                              strokeWidth: 2,
                            ),
                          ),
                        );
                      }
                      if (snapshot.hasError) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Text(
                            'Could not load tours: ${snapshot.error}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              color: Colors.black54,
                            ),
                          ),
                        );
                      }
                      final displayTours = snapshot.data ?? [];

                      if (displayTours.isEmpty) {
                        return const _PopularToursMessage(
                          icon: Icons.travel_explore_outlined,
                          text: 'No tours yet.',
                          detail:
                              'Add documents to the "tours" collection in Firebase (admin).',
                        );
                      }

                      return Column(
                        children: [
                          for (var i = 0; i < displayTours.length; i++) ...[
                            if (i > 0) const SizedBox(height: 20),
                            _TourCard(tour: displayTours[i]),
                          ],
                        ],
                      );
                    },
                  ),
                  SizedBox(height: 28 + bottomSafe),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ExploreDashboardScreen._searchFill,
      borderRadius: BorderRadius.circular(18),
      elevation: 0,
      child: TextField(
        readOnly: true,
        onTap: () {},
        style: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          color: Colors.black87,
        ),
        decoration: InputDecoration(
          hintText: 'Search tours, destinations...',
          hintStyle: GoogleFonts.plusJakartaSans(
            color: Colors.black38,
            fontSize: 14,
          ),
          prefixIcon: const Icon(Icons.search, color: Colors.black45, size: 22),
          suffixIcon: IconButton(
            icon: const Icon(Icons.mic_none_rounded, color: Colors.black45),
            onPressed: () {},
          ),
          filled: true,
          fillColor: ExploreDashboardScreen._searchFill,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 4,
            vertical: 14,
          ),
        ),
      ),
    );
  }
}

class _QuickStatsRow extends StatelessWidget {
  const _QuickStatsRow();

  static final _bookingService = BookingService();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const MyBookingsScreen()));
            },
            child: StreamBuilder<List<Booking>>(
              stream: _bookingService.myBookingsStream(),
              builder: (context, snapshot) {
                final list = snapshot.data ?? [];
                final n = list.where((b) => b.isUpcoming).length;
                return _StatCard(
                  icon: Icons.description_outlined,
                  value: '$n',
                  label: 'Bookings',
                );
              },
            ),
          ),
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: _StatCard(
            icon: Icons.location_on_outlined,
            value: '12',
            label: 'Saved',
          ),
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: _StatCard(
            icon: Icons.wallet_outlined,
            value: '50K',
            label: 'Spent',
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: ExploreDashboardScreen._statCardBg,
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
        children: [
          Icon(icon, size: 24, color: const Color(0xFFB8860B).withValues(alpha: 0.7)),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow();

  @override
  Widget build(BuildContext context) {
    final items = [
      _CatData('Cultural', Icons.account_balance_outlined, const Color(0xFFFFF9E0)),
      _CatData('Beach', Icons.waves_outlined, const Color(0xFFE3F2FD)),
      _CatData('Wildlife', Icons.pets_outlined, const Color(0xFFFFF3E0)),
      _CatData('Mountain', Icons.landscape_outlined, const Color(0xFFE8F5E9)),
      _CatData('Food', Icons.restaurant_outlined, const Color(0xFFFCE4EC)),
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: items.map((c) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5.0),
            child: Column(
              children: [
                AspectRatio(
                  aspectRatio: 1,
                  child: Material(
                    color: c.bg,
                    borderRadius: BorderRadius.circular(18),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DiscoverToursScreen(initialCategory: c.name),
                          ),
                        );
                      },
                      child: Icon(c.icon, color: Colors.black54, size: 30),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    c.name,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _CatData {
  _CatData(this.name, this.icon, this.bg);
  final String name;
  final IconData icon;
  final Color bg;
}

class _PopularToursMessage extends StatelessWidget {
  const _PopularToursMessage({
    required this.icon,
    required this.text,
    required this.detail,
  });

  final IconData icon;
  final String text;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Icon(icon, size: 40, color: Colors.black38),
          const SizedBox(height: 12),
          Text(
            text,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            detail,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: Colors.black38,
            ),
          ),
        ],
      ),
    );
  }
}

class _TourImage extends StatelessWidget {
  const _TourImage({required this.source});

  final String source;

  @override
  Widget build(BuildContext context) {
    if (source.isEmpty) {
      return Container(
        color: Colors.grey.shade300,
        alignment: Alignment.center,
        child: const Icon(Icons.image_not_supported_outlined),
      );
    }
    if (source.startsWith('http')) {
      return Image.network(
        source,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Container(
            color: Colors.grey.shade200,
            alignment: Alignment.center,
            child: const CircularProgressIndicator(
              strokeWidth: 2,
              color: Color(0xFFE8B800),
            ),
          );
        },
        errorBuilder: (_, __, ___) => Container(
          color: Colors.grey.shade300,
          alignment: Alignment.center,
          child: const Icon(Icons.broken_image_outlined),
        ),
      );
    }
    return Image.asset(
      source,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        color: Colors.grey.shade300,
        alignment: Alignment.center,
        child: const Icon(Icons.image_not_supported_outlined),
      ),
    );
  }
}

class _TourCard extends StatelessWidget {
  const _TourCard({required this.tour});

  final Tour tour;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TourDetailScreen(tour: tour),
          ),
        );
      },
      child: Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: 16 / 10,
            child: Stack(
              fit: StackFit.expand,
              children: [
                _TourImage(source: tour.imageUrl),
                // Category Tag
                Positioned(
                  left: 16,
                  bottom: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFBE697).withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      tour.category,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
                // Rating
                Positioned(
                  right: 16,
                  top: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          color: Color(0xFFFFD54F),
                          size: 17,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          tour.ratingLabel,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              children: [
                Text(
                  tour.title.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                    height: 1.25,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  tour.formattedPrice,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF2E7D32),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '/person',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.black38,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }
}

Future<void> _seedDummyTours() async {
  final db = FirebaseFirestore.instance;
  final toursCol = db.collection('tours');
  final snap = await toursCol.get();
  if (snap.docs.isNotEmpty) {
    for (var doc in snap.docs) {
      await doc.reference.delete();
    }
  }

  final batch = db.batch();
  final tours = [
    {
      'title': 'Sigiriya Rock Fortress',
      'image_url': 'https://images.unsplash.com/photo-1588258524388-3e4e963bc1ba?q=80&auto=format&fit=crop',
      'rating': 4.9,
      'category': 'CULTURAL',
      'price': 8500,
      'currency': 'LKR',
      'location': 'Dabulla',
      'featured': true,
      'featured_rank': 1,
      'sort_order': 1,
    },
    {
      'title': 'Yala Safari Experience',
      'image_url': 'https://images.unsplash.com/photo-1624823183578-831d102046ff?q=80&auto=format&fit=crop',
      'rating': 4.9,
      'category': 'WILDLIFE',
      'price': 18500,
      'currency': 'LKR',
      'location': 'Yala',
      'featured': false,
      'featured_rank': 0,
      'sort_order': 2,
    },
    {
      'title': 'Mirissa Whale Watching',
      'image_url': 'https://images.unsplash.com/photo-1549643444-245bd0cbb6ab?q=80&auto=format&fit=crop',
      'rating': 4.8,
      'category': 'BEACH',
      'price': 20500,
      'currency': 'LKR',
      'location': 'Mirissa',
      'featured': false,
      'featured_rank': 0,
      'sort_order': 3,
    },
    {
      'title': 'Ella Train Experience',
      'image_url': 'https://images.unsplash.com/photo-1577789454049-3ae8e6840d2d?q=80&auto=format&fit=crop',
      'rating': 4.9,
      'category': 'MOUNTAIN',
      'price': 25000,
      'currency': 'LKR',
      'location': 'Ella',
      'featured': false,
      'featured_rank': 0,
      'sort_order': 4,
    },
    {
      'title': 'Marble Beach',
      'image_url': 'https://images.unsplash.com/photo-1629731637777-b844f2b1cde4?q=80&auto=format&fit=crop',
      'rating': 4.7,
      'category': 'BEACH',
      'price': 30500,
      'currency': 'LKR',
      'location': 'Trincomalee',
      'featured': false,
      'featured_rank': 0,
      'sort_order': 5,
    },
    {
      'title': 'Piduruthalagala Hiking',
      'image_url': 'https://images.unsplash.com/photo-1518182170546-076616fdac37?q=80&auto=format&fit=crop',
      'rating': 4.6,
      'category': 'MOUNTAIN',
      'price': 8500,
      'currency': 'LKR',
      'location': 'Piduruthalagala',
      'featured': false,
      'featured_rank': 0,
      'sort_order': 6,
    },
    {
      'title': 'Kandy Heritage City',
      'image_url': 'https://images.unsplash.com/photo-1586521995568-39abaa0c2311?q=80&auto=format&fit=crop',
      'rating': 4.9,
      'category': 'CULTURAL',
      'price': 8500,
      'currency': 'LKR',
      'location': 'Kandy',
      'featured': true,
      'featured_rank': 2,
      'sort_order': 7,
    },
    {
      'title': 'Udunuwara Village',
      'image_url': 'https://images.unsplash.com/photo-1616089352934-8c0147cb2320?q=80&auto=format&fit=crop',
      'rating': 4.9,
      'category': 'CULTURAL',
      'price': 8500,
      'currency': 'LKR',
      'location': 'Udunuwara',
      'featured': true,
      'featured_rank': 3,
      'sort_order': 8,
    },
    {
      'title': 'Sri Lankan Food',
      'image_url': 'https://images.unsplash.com/photo-1546549032-9571cd6b27df?q=80&auto=format&fit=crop',
      'rating': 4.8,
      'category': 'FOOD',
      'price': 8500,
      'currency': 'LKR',
      'location': 'Kandy',
      'featured': false,
      'featured_rank': 0,
      'sort_order': 9,
    },
  ];

  for (var t in tours) {
    batch.set(toursCol.doc(), {
      ...t,
      'published': true,
    });
  }

  await batch.commit();
}
