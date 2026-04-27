import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/booking_background.dart';
import '../../models/booking.dart';
import 'cancel_booking_screen.dart';
import 'submit_tour_review_screen.dart';

/// Details for any booking (all tours).
/// [Request Cancellation] → [CancelBookingScreen].
class BookingDetailsScreen extends StatelessWidget {
  const BookingDetailsScreen({super.key, required this.booking});

  final Booking booking;

  static const _ink = Colors.black87;

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.paddingOf(context).top;
    final bottomPad = MediaQuery.paddingOf(context).bottom;
    final isCancelled = booking.isCancelled;
    final isCancelRequested = booking.isCancelRequested;
    final isCompleted = booking.isCompleted;
    final isConfirmed = booking.status.trim().toLowerCase() == 'confirmed';

    final badge = _statusBadge(
      status: booking.status,
      isCancelled: isCancelled,
      isCancelRequested: isCancelRequested,
      isConfirmed: isConfirmed,
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: BookingBackgroundLayer(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(8, topPad + 12, 20, 16),
              child: Row(
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
                      booking.tourTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: _ink,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(16, 0, 16, bottomPad + 24),
                child: Column(
                  children: [
                    _InfoCard(
                      booking: booking,
                      badge: badge,
                    ),
                    const SizedBox(height: 16),
                    _TimelineCard(booking: booking),
                    if (isCompleted) ...[
                      const SizedBox(height: 18),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Review',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Share your experience to help other travellers.',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            height: 1.4,
                            color: Colors.black54,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: FilledButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute<bool>(
                                builder: (_) => SubmitTourReviewScreen(booking: booking),
                              ),
                            );
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFFE8B800),
                            foregroundColor: Colors.black87,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                          child: Text(
                            'Leave a Review',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ],
                    if (!isCancelled && !isCompleted) ...[
                      const SizedBox(height: 18),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Cancel Booking',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFFE53935),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Free cancellation until 7 days before travel. After that, fees may apply.',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            height: 1.4,
                            color: Colors.black54,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: FilledButton(
                          onPressed: isCancelRequested
                              ? null
                              : () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute<void>(
                                      builder: (_) => CancelBookingScreen(booking: booking),
                                    ),
                                  );
                                },
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFFFFCDD2),
                            foregroundColor: Colors.red.shade800,
                            disabledBackgroundColor: Colors.black12,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                          ),
                          child: Text(
                            isCancelRequested ? 'Cancel Request Pending' : 'Request Cancellation',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
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

  static ({String label, Color bg, Color fg}) _statusBadge({
    required String status,
    required bool isCancelled,
    required bool isCancelRequested,
    required bool isConfirmed,
  }) {
    if (isCancelled) {
      return (
        label: 'Cancelled',
        bg: const Color(0xFFFFCDD2),
        fg: const Color(0xFFC62828),
      );
    }
    if (isCancelRequested) {
      return (
        label: 'Cancel Request Pending',
        bg: const Color(0xFFFFF3CD),
        fg: const Color(0xFFB26A00),
      );
    }
    if (isConfirmed) {
      return (
        label: 'Confirmed',
        bg: const Color(0xFFA5D6A7),
        fg: const Color(0xFF2E7D32),
      );
    }
    return (
      label: status.trim().isEmpty ? 'Pending' : status.trim(),
      bg: const Color(0xFFFFF6D5),
      fg: const Color(0xFFB8860B),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.booking, required this.badge});

  final Booking booking;
  final ({String label, Color bg, Color fg}) badge;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _Row(
            label: 'Booking Status',
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: badge.bg,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                badge.label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: badge.fg,
                ),
              ),
            ),
          ),
          const Divider(height: 1, color: Colors.black12),
          _Row(label: 'Reference', value: booking.reference),
          const Divider(height: 1, color: Colors.black12),
          _Row(label: 'Travel', value: booking.travelDateLabelShort()),
        ],
      ),
    );
  }
}

class _TimelineCard extends StatelessWidget {
  const _TimelineCard({required this.booking});

  final Booking booking;

  String _dateTimeShort(DateTime d) {
    String two(int v) => v < 10 ? '0$v' : '$v';
    final local = d.toLocal();
    return '${local.year}-${two(local.month)}-${two(local.day)} ${two(local.hour)}:${two(local.minute)}:${two(local.second)}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'BOOKING TIMELINE',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          _TimelineItem(
            icon: '✅',
            title: 'Booking confirmed',
            subtitle: _dateTimeShort(booking.createdAt),
            isLast: false,
          ),
          _TimelineItem(
            icon: '📧',
            title: 'Confirmation email',
            subtitle: booking.email,
            isLast: false,
          ),
          _TimelineItem(
            icon: '📱',
            title: 'Contact',
            subtitle: booking.phone,
            isLast: false,
            dim: true,
          ),
          _TimelineItem(
            icon: '🚕',
            title: 'Tour starts',
            subtitle: booking.travelDateLabelShort(),
            isLast: true,
            dim: true,
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, this.value, this.trailing});

  final String label;
  final String? value;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
            ),
          ),
          const Spacer(),
          if (trailing != null) trailing!,
          if (value != null)
            Text(
              value!,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black54,
              ),
            ),
        ],
      ),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  const _TimelineItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isLast,
    this.dim = false,
  });

  final String icon;
  final String title;
  final String subtitle;
  final bool isLast;
  final bool dim;

  @override
  Widget build(BuildContext context) {
    final fg = dim ? Colors.black45 : Colors.black87;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              SizedBox(
                width: 22,
                height: 22,
                child: Center(
                  child: Text(icon, style: const TextStyle(fontSize: 16)),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: Colors.black12,
                  ),
                )
              else
                const SizedBox(height: 10),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: fg,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      height: 1.35,
                      color: dim ? Colors.black38 : Colors.black54,
                    ),
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
