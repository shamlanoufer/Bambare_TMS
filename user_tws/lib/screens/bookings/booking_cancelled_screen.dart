import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/booking_background.dart';
import '../../core/main_shell_tab.dart';
import '../../models/booking.dart';

/// Shown after a successful cancel. "Back to Home" pops to [MainShell] and selects Home.
class BookingCancelledScreen extends StatelessWidget {
  const BookingCancelledScreen({super.key, required this.booking});

  final Booking booking;

  static const _accent = Color(0xFFE8B800);

  int _daysUntilTravel() {
    final t = DateTime(
      booking.travelDate.year,
      booking.travelDate.month,
      booking.travelDate.day,
    );
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return t.difference(today).inDays;
  }

  /// Same tiers as [CancelBookingScreen] policy copy.
  ({String refundLine, String refundKind}) _refundInfo() {
    final d = _daysUntilTravel();
    final curr = booking.currency;
    final total = booking.totalPrice.round();
    if (d > 7) {
      return (
        refundLine: '$curr ${_commaInt(total)} (Full)',
        refundKind: 'Full',
      );
    }
    if (d >= 3) {
      final half = (booking.totalPrice * 0.5).round();
      return (
        refundLine: '$curr ${_commaInt(half)} (50%)',
        refundKind: '50%',
      );
    }
    return (
      refundLine: '$curr 0 (No refund)',
      refundKind: 'None',
    );
  }

  static String _commaInt(int n) {
    final s = n.abs().toString();
    final buf = StringBuffer(n < 0 ? '-' : '');
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  void _goHome(BuildContext context) {
    // Pop back to [MainShell], then switch bottom nav to Home on the next frame
    // so tab state applies after the route stack has settled (avoids staying on Bookings).
    Navigator.of(context, rootNavigator: true).popUntil((route) => route.isFirst);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      MainShellTab.goHome();
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.paddingOf(context).bottom;
    final info = _refundInfo();
    final isGreenRefund = info.refundKind != 'None';

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: BookingBackgroundLayer(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(24, 20, 24, bottomPad + 24),
            child: Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 88,
                  height: 88,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE53935),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close_rounded, size: 52, color: Colors.white),
                ),
                const SizedBox(height: 24),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: 'Cancel ',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: Colors.black87,
                        ),
                      ),
                      TextSpan(
                        text: 'Request Sent',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: Colors.red.shade700,
                        ),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 14),
                Text(
                  'Your cancellation request for ${booking.tourTitle} has been sent for review. '
                  'An admin will verify and approve your request shortly.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    height: 1.45,
                    color: Colors.brown.shade700,
                  ),
                ),
                const SizedBox(height: 28),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEBEE),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFEF9A9A)),
                  ),
                  child: Column(
                    children: [
                      _DetailRow(label: 'Tour', value: booking.tourTitle, valueBold: true),
                      const SizedBox(height: 12),
                      _DetailRow(label: 'Ref', value: booking.reference, valueBold: true),
                      const SizedBox(height: 12),
                      _DetailRow(
                        label: 'Status',
                        value: 'Cancel Request Sent',
                        valueColor: Colors.red.shade700,
                        valueBold: true,
                      ),
                      const SizedBox(height: 12),
                      _DetailRow(
                        label: 'Refund',
                        value: info.refundLine,
                        valueColor: isGreenRefund ? const Color(0xFF2E7D32) : Colors.black54,
                        valueBold: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(14),
                    border: const Border(
                      left: BorderSide(color: Color(0xFF43A047), width: 4),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.mark_email_unread_rounded, color: Colors.purple.shade400, size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Request Received',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Our team will process your request. Once approved, your booking will move to the Cancelled tab.',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                height: 1.4,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: FilledButton(
                    onPressed: () => _goHome(context),
                    style: FilledButton.styleFrom(
                      backgroundColor: _accent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    ),
                    child: Text(
                      'Back to Home',
                      style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _accent,
                      side: const BorderSide(color: _accent, width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    ),
                    child: Text(
                      'Back',
                      style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.valueBold = false,
  });

  final String label;
  final String value;
  final Color? valueColor;
  final bool valueBold;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 72,
          child: Text(
            '$label:',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black54,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: valueBold ? FontWeight.w800 : FontWeight.w600,
              color: valueColor ?? Colors.black87,
            ),
          ),
        ),
      ],
    );
  }
}
