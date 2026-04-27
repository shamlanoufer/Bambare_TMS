import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/booking_background.dart';
import '../../models/booking.dart';
import '../../models/inbox_message.dart';
import '../../services/inbox_service.dart';
import 'booking_details_screen.dart';
import 'cancelled_booking_details_screen.dart';

/// Bookings/Home notifications list (old page).
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key, this.onlyAdminPanel = false});

  /// If true, show only `source == admin_panel` notifications (home inbox).
  final bool onlyAdminPanel;

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _inbox = InboxService();
  final _db = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _ensureAnonymousAuth();
  }

  Future<void> _ensureAnonymousAuth() async {
    if (FirebaseAuth.instance.currentUser != null) return;
    try {
      await FirebaseAuth.instance.signInAnonymously();
    } catch (_) {}
    if (mounted) setState(() {});
  }

  String _defaultTitle(String type) {
    switch (type) {
      case 'booking_cancellation_approved':
        return 'Cancellation Approved';
      case 'booking_cancellation_rejected':
        return 'Cancellation Rejected';
      case 'booking_cancelled':
        return 'Booking Cancelled';
      case 'tour_reminder':
        return 'Trip Reminder';
      case 'booking_confirmed':
        return 'Booking Confirmed';
      case 'special_offer':
        return 'Special Offer';
      case 'payment_reminder':
        return 'Payment Reminder';
      default:
        return 'Notification';
    }
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.paddingOf(context).top;
    final bottomPad = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: BookingBackgroundLayer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(8, topPad + 12, 20, 16),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded),
                    color: Colors.black87,
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 44, minHeight: 44),
                    tooltip: 'Back',
                  ),
                  Expanded(
                    child: Text(
                      '🔔 Notifications',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: StreamBuilder<List<InboxMessage>>(
                stream: _inbox.myMessagesStream(),
                builder: (context, snap) {
                  if (!snap.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(color: Color(0xFFE8B800)),
                    );
                  }
                  final list = snap.data ?? const <InboxMessage>[];
                  final filtered = widget.onlyAdminPanel
                      ? list.where((m) => m.source == 'admin_panel').toList()
                      : list;
                  if (filtered.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Text(
                          'No notifications yet.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            height: 1.45,
                            color: Colors.black54,
                          ),
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: EdgeInsets.fromLTRB(20, 0, 20, bottomPad + 24),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 14),
                    itemBuilder: (context, i) {
                      final msg = filtered[i];
                      final title = msg.title.isNotEmpty
                          ? msg.title
                          : _defaultTitle(msg.type);
                      return _NotificationCard(
                        title: title,
                        body: msg.body,
                        time: _compactTime(msg.createdAt.toLocal()),
                        onTap: () => _onTapMessage(context, msg, title),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _compactTime(DateTime t) {
    final diff = DateTime.now().difference(t);
    final mins = diff.inMinutes;
    if (mins < 1) return 'now';
    if (mins < 60) return '${mins}m ago';
    final hrs = diff.inHours;
    if (hrs < 24) return '${hrs}h ago';
    final days = diff.inDays;
    return '${days}d ago';
  }

  Future<void> _showMessage(
    BuildContext context,
    String title,
    String body,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          title,
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w900),
        ),
        content: Text(body, style: GoogleFonts.plusJakartaSans(height: 1.45)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  bool _isBookingNotification(InboxMessage msg) {
    if (msg.bookingId.isNotEmpty) return true;
    final t = msg.type.trim().toLowerCase();
    return t.startsWith('booking_') || t == 'tour_reminder';
  }

  bool _shouldShowDialogFirst(InboxMessage msg) {
    // UX request: on tap, go straight to details page (no dialog).
    return false;
  }

  Future<void> _onTapMessage(
    BuildContext context,
    InboxMessage msg,
    String title,
  ) async {
    // Keep old behavior for non-booking notifications (just show message dialog).
    if (!_isBookingNotification(msg)) {
      await _showMessage(context, title, msg.body);
      return;
    }

    // For cancellation-related notifications, show the same dialog first (like the reference),
    // then open the booking details page.
    if (_shouldShowDialogFirst(msg)) {
      await _showMessage(context, title, msg.body);
      if (!context.mounted) return;
    }

    try {
      final booking = await _loadBookingForNotification(msg);
      if (booking == null) {
        if (!context.mounted) return;
        await _showMessage(context, title, 'Booking not found for this notification.');
        return;
      }
      if (!context.mounted) return;

      final isCancelled = booking.isCancelled ||
          msg.type.trim().toLowerCase() == 'booking_cancellation_approved' ||
          msg.type.trim().toLowerCase() == 'booking_cancellation_rejected';

      if (isCancelled) {
        await _showCancelledDetailsDialog(context, booking);
        return;
      }

      Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) => BookingDetailsScreen(booking: booking),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      await _showMessage(context, title, 'Could not open booking: $e');
    }
  }

  Future<void> _showCancelledDetailsDialog(BuildContext context, Booking booking) async {
    final sz = MediaQuery.sizeOf(context);
    final topPad = MediaQuery.paddingOf(context).top;
    final bottomPad = MediaQuery.paddingOf(context).bottom;

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (ctx) {
        return Dialog(
          insetPadding: EdgeInsets.zero,
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Center(
            child: FractionallySizedBox(
              widthFactor: 0.98,
              heightFactor: 0.98,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: SizedBox(
                    width: sz.width,
                    height: sz.height,
                    child: CancelledBookingDetailsContent(
                      booking: booking,
                      topPad: topPad,
                      bottomPad: bottomPad,
                      mode: CancelledBookingDetailsContentMode.dialog,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<Booking?> _loadBookingForNotification(InboxMessage msg) async {
    final directId = msg.bookingId.trim();
    if (directId.isNotEmpty) {
      final snap = await _db.collection('bookings').doc(directId).get();
      if (!snap.exists) return null;
      return Booking.fromDoc(snap);
    }

    // Fallback: parse a reference like "BR-396007" from title/body and query Firestore.
    final blob = '${msg.title}\n${msg.body}';
    final ref = _extractReference(blob);
    if (ref == null || ref.trim().isEmpty) return null;

    final q = await _db
        .collection('bookings')
        .where('reference', isEqualTo: ref.trim())
        .limit(1)
        .get();
    if (q.docs.isEmpty) return null;
    return Booking.fromDoc(q.docs.first);
  }

  String? _extractReference(String text) {
    final t = text.trim();
    if (t.isEmpty) return null;

    // Common patterns:
    // - "Reference: BR-396007"
    // - "Ref BR-396007"
    // - "BR-396007"
    final m = RegExp(r'\b([A-Z]{1,4}-\d{3,})\b').firstMatch(t);
    return m?.group(1);
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.title,
    required this.body,
    required this.time,
    required this.onTap,
  });

  final String title;
  final String body;
  final String time;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 14,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.notifications_rounded, color: Colors.black54),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    body,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      height: 1.35,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    time,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.black54,
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

