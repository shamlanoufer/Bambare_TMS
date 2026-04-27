import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/booking_background.dart';
import '../../models/booking.dart';
import 'cancel_booking_screen.dart';
import 'submit_tour_review_screen.dart';

<<<<<<< HEAD
/// Details for any booking (all tours).
/// [Request Cancellation] → [CancelBookingScreen].
=======
/// Details for any booking (all tours). [Request Cancellation] → [CancelBookingScreen].
>>>>>>> a28bf1f775365ea426a204b88ca42cc04604a505
class BookingDetailsScreen extends StatelessWidget {
  const BookingDetailsScreen({super.key, required this.booking});

  final Booking booking;

<<<<<<< HEAD
  static const _ink = Colors.black87;
=======
  static const _bg = Color(0xFFFFFBF0);
>>>>>>> a28bf1f775365ea426a204b88ca42cc04604a505

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.paddingOf(context).top;
    final bottomPad = MediaQuery.paddingOf(context).bottom;
<<<<<<< HEAD
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
=======
    final bool isConfirmed = booking.status == 'Confirmed';
    final title = booking.tourTitle;
>>>>>>> a28bf1f775365ea426a204b88ca42cc04604a505

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: BookingBackgroundLayer(
        child: Column(
<<<<<<< HEAD
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
=======
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
>>>>>>> a28bf1f775365ea426a204b88ca42cc04604a505
      ),
    );
  }
}

<<<<<<< HEAD
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
=======
class _StatusRow extends StatelessWidget {
  final String label;
  final String? value;
  final Widget? child;

  const _StatusRow({required this.label, this.value, this.child});
>>>>>>> a28bf1f775365ea426a204b88ca42cc04604a505

  @override
  Widget build(BuildContext context) {
    return Padding(
<<<<<<< HEAD
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
=======
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
>>>>>>> a28bf1f775365ea426a204b88ca42cc04604a505
              ),
            ),
        ],
      ),
    );
  }
}

class _TimelineItem extends StatelessWidget {
<<<<<<< HEAD
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
=======
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
>>>>>>> a28bf1f775365ea426a204b88ca42cc04604a505
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
<<<<<<< HEAD
              SizedBox(
                width: 22,
                height: 22,
                child: Center(
                  child: Text(icon, style: const TextStyle(fontSize: 16)),
                ),
=======
              Container(
                width: 20,
                height: 20,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isCompleted ? Colors.white : Colors.transparent,
                ),
                child: Text(iconPath, style: const TextStyle(fontSize: 16)),
>>>>>>> a28bf1f775365ea426a204b88ca42cc04604a505
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
<<<<<<< HEAD
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
=======
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
>>>>>>> a28bf1f775365ea426a204b88ca42cc04604a505
              ),
            ),
          ),
        ],
      ),
    );
  }
}
