import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/booking_background.dart';
import '../../models/booking.dart';
import '../../services/booking_service.dart';
import 'booking_details_screen.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  static const _accent = Color(0xFFE8B800);
  static const _ink = Colors.black87;

  final _bookingService = BookingService();

  @override
  void initState() {
    super.initState();
    _ensureAnonymousAuth();
  }

  /// Same anonymous user as booking flow so `user_id` matches Firestore.
  Future<void> _ensureAnonymousAuth() async {
    if (FirebaseAuth.instance.currentUser != null) return;
    try {
      await FirebaseAuth.instance.signInAnonymously();
    } catch (_) {
      /* UI still loads; BookingService will retry on write */
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.paddingOf(context).top;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: BookingBackgroundLayer(
          child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(8, topPad + 16, 20, 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded),
                    color: _ink,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                    tooltip: 'Back',
                  ),
                  Expanded(
                    child: Text(
                      'My Bookings',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: _ink,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Colors.black.withValues(alpha: 0.12),
                    width: 2,
                  ),
                ),
              ),
              child: TabBar(
                labelColor: _ink,
                unselectedLabelColor: Colors.black54,
                labelStyle: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700),
                unselectedLabelStyle: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w500),
                indicatorColor: _ink,
                indicatorWeight: 3,
                tabs: const [
                  Tab(text: 'Upcoming'),
                  Tab(text: 'Completed'),
                  Tab(text: 'Cancelled'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<List<Booking>>(
                stream: _bookingService.myBookingsStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting &&
                      !snapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(color: _accent),
                    );
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'Could not load bookings.\n${snapshot.error}',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            color: Colors.black54,
                          ),
                        ),
                      ),
                    );
                  }
                  final all = snapshot.data ?? <Booking>[];
                  final upcoming =
                      all.where((b) => b.isUpcoming).toList(growable: false);
                  final completed =
                      all.where((b) => b.isCompleted).toList(growable: false);
                  final cancelled =
                      all.where((b) => b.isCancelled).toList(growable: false);
                  return TabBarView(
                    children: [
                      _BookingList(
                        bookings: upcoming,
                        emptyMessage: _emptyUpcoming(all.length, upcoming.length),
                      ),
                      _BookingList(
                        bookings: completed,
                        emptyMessage: _emptyCompleted(all.length),
                      ),
                      _BookingList(
                        bookings: cancelled,
                        emptyMessage: _emptyCancelled(all.length),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  String _emptyUpcoming(int totalCount, int upcomingCount) {
    if (totalCount > 0 && upcomingCount == 0) {
      return 'No upcoming trips.\n\nYour travel date may already be in the past — open the Completed tab.\nOr you cancelled — open Cancelled.';
    }
    return 'No upcoming bookings.\n\nAfter you book, it appears here if the trip is today or later.\n\nTip: Bookings follow this browser (anonymous). Another device or cleared cookies = empty list.';
  }

  String _emptyCompleted(int totalCount) {
    if (totalCount == 0) {
      return 'No completed trips yet.\n\nPast trips (travel date before today) show here.\nBook first from Discover, then refresh.';
    }
    return 'No completed trips in this list.\n\nTrips move here when the travel date has passed or status is Completed in Firebase.';
  }

  String _emptyCancelled(int totalCount) {
    if (totalCount == 0) {
      return 'No cancelled bookings.\n\nCancel from booking Details → Request Cancellation.';
    }
    return 'No cancelled bookings.';
  }
}

class _BookingList extends StatelessWidget {
  const _BookingList({
    required this.bookings,
    required this.emptyMessage,
  });

  final List<Booking> bookings;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    if (bookings.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Text(
            emptyMessage,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              height: 1.45,
              color: Colors.black45,
            ),
          ),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
      itemCount: bookings.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, i) {
        return _BookingCard(booking: bookings[i]);
      },
    );
  }
}

class _BookingCard extends StatelessWidget {
  const _BookingCard({required this.booking});

  final Booking booking;

  @override
  Widget build(BuildContext context) {
    final status = booking.status;
    final isConfirmed = status == 'Confirmed';
    final isCancelled = booking.isCancelled;
    final isDone = booking.isCompleted;

    Color badgeBg;
    Color badgeFg;
    if (isCancelled) {
      badgeBg = const Color(0xFFFFCDD2);
      badgeFg = const Color(0xFFC62828);
    } else if (isDone) {
      badgeBg = const Color(0xFFE3F2FD);
      badgeFg = const Color(0xFF1565C0);
    } else {
      badgeBg = isConfirmed ? const Color(0xFFA5D6A7) : const Color(0xFFFFF6D5);
      badgeFg = isConfirmed ? const Color(0xFF2E7D32) : const Color(0xFFB8860B);
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 80,
              height: 110,
              child: _BookingImage(source: booking.tourImageUrl),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: badgeBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    status,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: badgeFg,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  booking.tourTitle,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 12, color: Colors.redAccent),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        booking.location,
                        style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.black87),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  booking.travelDateLabelShort(),
                  style: GoogleFonts.plusJakartaSans(fontSize: 11, color: Colors.black54),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      booking.formattedTotalPrice,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF4CAF50),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => BookingDetailsScreen(booking: booking),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8B800),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Details',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BookingImage extends StatelessWidget {
  const _BookingImage({required this.source});

  final String source;

  @override
  Widget build(BuildContext context) {
    if (source.isEmpty) {
      return Container(
        color: Colors.grey.shade300,
        child: const Icon(Icons.image_not_supported),
      );
    }
    if (source.startsWith('http')) {
      return Image.network(
        source,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(color: Colors.grey.shade300),
      );
    }
    return Image.asset(
      source,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(color: Colors.grey.shade300),
    );
  }
}
