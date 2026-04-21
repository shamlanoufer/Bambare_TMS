import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/booking_background.dart';
import '../../models/inbox_message.dart';
import '../../services/inbox_service.dart';

/// Lists admin messages from Firestore `users/{uid}/notifications`.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _inbox = InboxService();

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
      case 'booking_cancelled':
        return 'Booking Cancelled';
      case 'tour_reminder':
        return 'Tour Reminder';
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

  _CardStyle _styleFor(String type) {
    switch (type) {
      case 'booking_cancelled':
        return const _CardStyle(
          border: Color(0xFFEF9A9A),
          bg: Color(0xFFFFEBEE),
          titleColor: Color(0xFFC62828),
          iconBg: Color(0xFFE53935),
          icon: Icons.cancel_outlined,
          iconFg: Colors.white,
        );
      case 'tour_reminder':
        return const _CardStyle(
          border: Color(0xFF90CAF9),
          bg: Color(0xFFE3F2FD),
          titleColor: Color(0xFF1565C0),
          iconBg: Color(0xFF42A5F5),
          icon: Icons.directions_bus_filled_outlined,
          iconFg: Color(0xFFFFEB3B),
        );
      case 'booking_confirmed':
        return const _CardStyle(
          border: Color(0xFFA5D6A7),
          bg: Color(0xFFE8F5E9),
          titleColor: Color(0xFF2E7D32),
          iconBg: Color(0xFF66BB6A),
          icon: Icons.check_circle_outline,
          iconFg: Colors.white,
        );
      case 'special_offer':
        return const _CardStyle(
          border: Color(0xFFFFE082),
          bg: Color(0xFFFFFDE7),
          titleColor: Color(0xFF8D6E63),
          iconBg: Color(0xFFFFCA28),
          icon: Icons.celebration_outlined,
          iconFg: Color(0xFF5D4037),
        );
      case 'payment_reminder':
        return const _CardStyle(
          border: Color(0xFFFFB74D),
          bg: Color(0xFFFFF3E0),
          titleColor: Color(0xFFE65100),
          iconBg: Color(0xFFFF9800),
          icon: Icons.credit_card_outlined,
          iconFg: Color(0xFF0D47A1),
        );
      default:
        return const _CardStyle(
          border: Color(0xFFBDBDBD),
          bg: Color(0xFFF5F5F5),
          titleColor: Color(0xFF424242),
          iconBg: Color(0xFF9E9E9E),
          icon: Icons.notifications_outlined,
          iconFg: Colors.white,
        );
    }
  }

  String _formatTime(DateTime t) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(t.year, t.month, t.day);
    var h = t.hour;
    final m = t.minute.toString().padLeft(2, '0');
    final ap = h >= 12 ? 'PM' : 'AM';
    if (h == 0) {
      h = 12;
    } else if (h > 12) {
      h -= 12;
    }
    final timeStr = '$h:$m $ap';
    if (d == today) return 'Today - $timeStr';
    final yest = today.subtract(const Duration(days: 1));
    if (d == yest) return 'Yesterday - $timeStr';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[t.month - 1]} ${t.day} - $timeStr';
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
                    constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
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
                  if (snap.connectionState == ConnectionState.waiting &&
                      !snap.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(color: Color(0xFFE8B800)),
                    );
                  }
                  if (snap.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'Could not load notifications.\n${snap.error}',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            color: Colors.black54,
                          ),
                        ),
                      ),
                    );
                  }
                  final list = snap.data ?? [];
                  if (list.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Text(
                          'No messages yet.\n\nWhen your tour operator sends an update, it will appear here.',
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
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 14),
                    itemBuilder: (context, i) {
                      final msg = list[i];
                      final st = _styleFor(msg.type);
                      final title = msg.title.isNotEmpty
                          ? msg.title
                          : _defaultTitle(msg.type);
                      return _NotificationCard(
                        style: st,
                        title: title,
                        body: msg.body,
                        timeLabel: _formatTime(msg.createdAt.toLocal()),
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
}

class _CardStyle {
  const _CardStyle({
    required this.border,
    required this.bg,
    required this.titleColor,
    required this.iconBg,
    required this.icon,
    required this.iconFg,
  });

  final Color border;
  final Color bg;
  final Color titleColor;
  final Color iconBg;
  final IconData icon;
  final Color iconFg;
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.style,
    required this.title,
    required this.body,
    required this.timeLabel,
  });

  final _CardStyle style;
  final String title;
  final String body;
  final String timeLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: style.bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: style.border, width: 1.2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: style.iconBg,
            child: Icon(style.icon, color: style.iconFg, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: style.titleColor,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  body,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    height: 1.4,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  timeLabel,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.black45,
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
