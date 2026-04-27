import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/booking_background.dart';
import '../../models/inbox_message.dart';
import '../../models/notification_prefs.dart';
import '../../services/inbox_service.dart';
import '../../services/notification_prefs_service.dart';

class NotificationPreferencesScreen extends StatefulWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  State<NotificationPreferencesScreen> createState() =>
      _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState
    extends State<NotificationPreferencesScreen> {
  final _inbox = InboxService();
  final _prefs = NotificationPrefsService();
  bool _savingPref = false;

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

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.paddingOf(context).top;
    final bottomPad = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: BookingBackgroundLayer(
        child: StreamBuilder<NotificationPrefs>(
          stream: _prefs.myPrefsStream(),
          builder: (context, prefSnap) {
            final prefs = prefSnap.data ?? NotificationPrefs.defaults;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(8, topPad + 12, 20, 10),
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
                          'Notifications',
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
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(18, 0, 18, bottomPad + 24),
                    children: [
                      _prefsCard(context, prefs),
                      const SizedBox(height: 18),
                      Text(
                        'Recent Notifications',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 12),
                      StreamBuilder<List<InboxMessage>>(
                        stream: _inbox.myMessagesStream(),
                        builder: (context, snap) {
                          final list = snap.data ?? const <InboxMessage>[];
                          if (list.isEmpty) {
                            return Padding(
                              padding: const EdgeInsets.all(18),
                              child: Text(
                                'No notifications yet.',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  color: Colors.black54,
                                ),
                              ),
                            );
                          }
                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.08),
                                  blurRadius: 14,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: list.length.clamp(0, 10),
                              separatorBuilder: (_, __) => Divider(
                                height: 1,
                                indent: 18,
                                endIndent: 18,
                                color: Colors.black.withValues(alpha: 0.06),
                              ),
                              itemBuilder: (context, i) {
                                final msg = list[i];
                                return _RecentRow(
                                  emoji: _emojiForType(msg.type),
                                  title: '${_titleForType(msg.type)}!',
                                  body: msg.body,
                                  time: _compactTime(msg.createdAt.toLocal()),
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _prefsCard(BuildContext context, NotificationPrefs prefs) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 16,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Notification Preferences',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          _prefRow(
            title: 'Booking Updates',
            sub: 'Confirmations and changes',
            value: prefs.bookingUpdates,
            onChanged: (v) => _savePrefs(prefs.copyWith(bookingUpdates: v)),
          ),
          _prefDivider(),
          _prefRow(
            title: 'Special Offers',
            sub: 'Deals and discounts',
            value: prefs.specialOffers,
            onChanged: (v) => _savePrefs(prefs.copyWith(specialOffers: v)),
          ),
          _prefDivider(),
          _prefRow(
            title: 'Trip Reminders',
            sub: 'Reminders before your trip',
            value: prefs.tripReminders,
            onChanged: (v) => _savePrefs(prefs.copyWith(tripReminders: v)),
          ),
          _prefDivider(),
          _prefRow(
            title: 'Nearby Places',
            sub: 'Attractions near your location',
            value: prefs.nearbyPlaces,
            onChanged: (v) => _savePrefs(prefs.copyWith(nearbyPlaces: v)),
          ),
          _prefDivider(),
          _prefRow(
            title: 'Review Requests',
            sub: 'Rate your experiences',
            value: prefs.reviewRequests,
            onChanged: (v) => _savePrefs(prefs.copyWith(reviewRequests: v)),
          ),
          _prefDivider(),
          _prefRow(
            title: 'Newsletter',
            sub: 'Weekly travel inspiration',
            value: prefs.newsletter,
            onChanged: (v) => _savePrefs(prefs.copyWith(newsletter: v)),
          ),
          if (_savingPref) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'Saving…',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Colors.black54,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _prefDivider() => Divider(
        height: 12,
        color: Colors.black.withValues(alpha: 0.12),
      );

  Widget _prefRow({
    required String title,
    required String sub,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                sub,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          activeThumbColor: Colors.black,
          activeTrackColor: Colors.black.withValues(alpha: 0.25),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Future<void> _savePrefs(NotificationPrefs next) async {
    setState(() => _savingPref = true);
    try {
      await _prefs.upsert(next);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save: $e')),
      );
    } finally {
      if (mounted) setState(() => _savingPref = false);
    }
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

  String _titleForType(String type) {
    switch (type) {
      case 'booking_confirmed':
        return 'Booking Confirmed';
      case 'booking_cancellation_approved':
        return 'Cancellation Approved';
      case 'booking_cancellation_rejected':
        return 'Cancellation Rejected';
      case 'tour_reminder':
        return 'Trip Reminder';
      case 'special_offer':
        return 'Special Offer';
      case 'payment_reminder':
        return 'Payment Reminder';
      default:
        return 'Notification';
    }
  }

  String _emojiForType(String type) {
    switch (type) {
      case 'booking_confirmed':
        return '🎉';
      case 'special_offer':
        return '💰';
      case 'tour_reminder':
        return '⭐';
      case 'payment_reminder':
        return '📌';
      default:
        return '🔔';
    }
  }
}

class _RecentRow extends StatelessWidget {
  const _RecentRow({
    required this.emoji,
    required this.title,
    required this.body,
    required this.time,
  });

  final String emoji;
  final String title;
  final String body;
  final String time;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  body,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    height: 1.35,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
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
    );
  }
}

