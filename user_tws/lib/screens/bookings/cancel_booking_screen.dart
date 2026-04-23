import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/booking_background.dart';
import '../../models/booking.dart';
import '../../services/booking_service.dart';
import 'booking_cancelled_screen.dart';

/// Reason + policy; on success, opens [BookingCancelledScreen] (replaces this route).
class CancelBookingScreen extends StatefulWidget {
  const CancelBookingScreen({super.key, required this.booking});

  final Booking booking;

  @override
  State<CancelBookingScreen> createState() => _CancelBookingScreenState();
}

enum _CancelReason {
  changePlans,
  emergency,
  weather,
  betterOption,
  other,
}

class _CancelBookingScreenState extends State<CancelBookingScreen> {
  static const _accent = Color(0xFFE8B800);
  static const _ink = Color(0xFF4E342E);

  final _bookingService = BookingService();

  _CancelReason _reason = _CancelReason.changePlans;
  bool _submitting = false;

  String _longTravelDate(DateTime d) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  int _daysUntilTravel() {
    final t = DateTime(
      widget.booking.travelDate.year,
      widget.booking.travelDate.month,
      widget.booking.travelDate.day,
    );
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return t.difference(today).inDays;
  }

  String _policyCalloutText() {
    final d = _daysUntilTravel();
    final travel = widget.booking.travelDate;
    final freeUntil = DateTime(travel.year, travel.month, travel.day)
        .subtract(const Duration(days: 7));
    const monthsShort = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final untilStr =
        '${monthsShort[freeUntil.month - 1]} ${freeUntil.day}, ${freeUntil.year}';

    if (d > 7) {
      return 'Cancellation Policy Applies. Free cancellation until $untilStr. After that, 50% fee may apply.';
    }
    if (d >= 3) {
      return 'Cancellation Policy Applies. You are in the 3–7 day window — 50% fee applies.';
    }
    return 'Cancellation Policy Applies. Less than 3 days before travel — no refund.';
  }

  String _reasonStorageLabel(_CancelReason r) {
    switch (r) {
      case _CancelReason.changePlans:
        return 'change_of_travel_plans';
      case _CancelReason.emergency:
        return 'emergency_or_illness';
      case _CancelReason.weather:
        return 'weather_concerns';
      case _CancelReason.betterOption:
        return 'found_better_option';
      case _CancelReason.other:
        return 'other';
    }
  }

  String _reasonTitle(_CancelReason r) {
    switch (r) {
      case _CancelReason.changePlans:
        return 'Change of travel plans';
      case _CancelReason.emergency:
        return 'Emergency / Illness';
      case _CancelReason.weather:
        return 'Weather concerns';
      case _CancelReason.betterOption:
        return 'Found a better option';
      case _CancelReason.other:
        return 'Other reason';
    }
  }

  Future<void> _onConfirmCancellation() async {
    if (_submitting) return;
    setState(() => _submitting = true);
    try {
      await _bookingService.cancelBooking(
        widget.booking.id,
        cancellationReason: _reasonStorageLabel(_reason),
      );
      if (!mounted) return;
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => BookingCancelledScreen(booking: widget.booking),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not cancel: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.paddingOf(context).bottom;
    final b = widget.booking;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: BookingBackgroundLayer(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(20, MediaQuery.paddingOf(context).top + 12, 20, bottomPad + 24),
                child: _buildReasonStep(b),
              ),
            ),
            _buildReasonFooter(bottomPad),
          ],
        ),
      ),
    );
  }

  Widget _buildReasonStep(Booking b) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87),
              onPressed: () => Navigator.pop(context),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      b.tourTitle,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.calendar_today_rounded, size: 16, color: Colors.amber.shade800),
                        const SizedBox(width: 8),
                        Text(
                          _longTravelDate(b.travelDate),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.black54,
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
        const SizedBox(height: 20),
        Text(
          'Cancel This Booking?',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Please select a reason for cancellation.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            height: 1.45,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'REASON FOR CANCELLATION',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1,
            color: Colors.black45,
          ),
        ),
        const SizedBox(height: 12),
        ..._CancelReason.values.map((r) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _ReasonTile(
                title: _reasonTitle(r),
                selected: _reason == r,
                accent: _accent,
                onTap: () => setState(() => _reason = r),
              ),
            )),
        const SizedBox(height: 8),
        _PolicyCallout(text: _policyCalloutText()),
      ],
    );
  }

  Widget _buildReasonFooter(double bottomPad) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, bottomPad + 20),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 54,
            child: FilledButton(
              onPressed: _submitting ? null : _onConfirmCancellation,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              ),
              child: _submitting
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(
                      'Confirm Cancellation',
                      style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800),
                    ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: OutlinedButton(
              onPressed: _submitting ? null : () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: _ink,
                side: const BorderSide(color: _accent, width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              ),
              child: Text(
                'Go Back',
                style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReasonTile extends StatelessWidget {
  const _ReasonTile({
    required this.title,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  final String title;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF6D5).withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? accent : accent.withValues(alpha: 0.45),
              width: selected ? 2 : 1.2,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: accent, width: 2),
                  color: selected ? accent : Colors.transparent,
                ),
                child: selected
                    ? const Icon(Icons.check, size: 14, color: Colors.black87)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF4E342E),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PolicyCallout extends StatelessWidget {
  const _PolicyCallout({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(14),
        border: const Border(
          left: BorderSide(color: Color(0xFFFF9800), width: 4),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.orange.shade800, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                height: 1.45,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
