import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/booking_background.dart';
import '../../models/booking.dart';
import 'cancel_booking_screen.dart';
import 'submit_tour_review_screen.dart';

/// Details for any booking (all tours). [Request Cancellation] → [CancelBookingScreen].
class BookingDetailsScreen extends StatelessWidget {
  const BookingDetailsScreen({super.key, required this.booking});

  final Booking booking;

  static const _bg = Color(0xFFFFFBF0);

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.paddingOf(context).top;
    final bottomPad = MediaQuery.paddingOf(context).bottom;
    final bool isConfirmed = booking.status == 'Confirmed';
    final title = booking.tourTitle;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: BookingBackgroundLayer(
        child: Column(
        children: [
          Stack(
            children: [
              Container(
                height: topPad + 100,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.orange.shade100.withValues(alpha: 0.8),
                      _bg,
                    ],
                  ),
                ),
              ),
              Positioned(
                bottom: 20,
                left: 10,
                right: 20,
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded),
                      color: Colors.black87,
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: Text(
                        title,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(20, 10, 20, bottomPad + 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Column(
                      children: [
                        _StatusRow(
                          label: 'Booking Status',
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: isConfirmed ? const Color(0xFFA5D6A7) : const Color(0xFFFFF6D5),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              booking.status,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: isConfirmed ? const Color(0xFF2E7D32) : const Color(0xFFB8860B),
                              ),
                            ),
                          ),
                        ),
                        const Divider(height: 1, color: Colors.black12),
                        _StatusRow(
                          label: 'Reference',
                          value: booking.reference,
                        ),
                        const Divider(height: 1, color: Colors.black12),
                        _StatusRow(
                          label: 'Travel',
                          value: booking.travelDateLabelShort(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'BOOKING TIMELINE',
                          style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 0.5, color: Colors.black87),
                        ),
                        const SizedBox(height: 20),
                        _TimelineItem(
                          iconPath: '✅',
                          title: 'Booking confirmed\n${booking.createdAt.toLocal()}',
                          isLast: false,
                          isCompleted: true,
                        ),
                        _TimelineItem(
                          iconPath: '📧',
                          title: 'Confirmation email\n${booking.email}',
                          isLast: false,
                          isCompleted: true,
                        ),
                        _TimelineItem(
                          iconPath: '📱',
                          title: 'Contact\n${booking.phone}',
                          isLast: false,
                          isCompleted: false,
                        ),
                        _TimelineItem(
                          iconPath: '🚖',
                          title: 'Tour starts\n${booking.travelDateLabelShort()}',
                          isLast: true,
                          isCompleted: false,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 48),
                  if (booking.isCompleted &&
                      booking.tourId.isNotEmpty) ...[
                    Text(
                      'Your review',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Share feedback from this completed trip. It appears on the tour after admin approves it.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        height: 1.4,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 52,
                      child: FilledButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) =>
                                  SubmitTourReviewScreen(booking: booking),
                            ),
                          );
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFE8B800),
                          foregroundColor: Colors.black87,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                        child: Text(
                          'Write review',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                  if (!booking.isCancelled) ...[
                    Text(
                      'Cancel Booking',
                      style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.redAccent),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Free cancellation until 7 days before travel. After that, fees may apply.',
                      style: GoogleFonts.plusJakartaSans(fontSize: 13, height: 1.4, color: Colors.black87),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 54,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push<void>(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) => CancelBookingScreen(booking: booking),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFCDD2),
                          foregroundColor: Colors.red.shade800,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        ),
                        child: Text(
                          'Request Cancellation',
                          style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  final String label;
  final String? value;
  final Widget? child;

  const _StatusRow({required this.label, this.value, this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.black87)),
          if (child != null) child!,
          if (value != null)
            Flexible(
              child: Text(
                value!,
                textAlign: TextAlign.right,
                style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black54),
              ),
            ),
        ],
      ),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  final String iconPath;
  final String title;
  final bool isLast;
  final bool isCompleted;

  const _TimelineItem({
    required this.iconPath,
    required this.title,
    required this.isLast,
    required this.isCompleted,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              Container(
                width: 20,
                height: 20,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isCompleted ? Colors.white : Colors.transparent,
                ),
                child: Text(iconPath, style: const TextStyle(fontSize: 16)),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: Colors.black12,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                  ),
                )
              else
                const SizedBox(height: 20),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 24),
              child: Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                  color: isCompleted ? Colors.black87 : Colors.black54,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
