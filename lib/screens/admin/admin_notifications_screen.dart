import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../services/activity_log_service.dart';
import '../../theme/admin_theme_colors.dart';
import '../../theme/brand_colors.dart';
import '../../widgets/admin_profile_bar.dart';

class AdminNotificationsScreen extends StatefulWidget {
  const AdminNotificationsScreen({super.key});

  @override
  State<AdminNotificationsScreen> createState() =>
      _AdminNotificationsScreenState();
}

class _AdminNotificationsScreenState extends State<AdminNotificationsScreen> {
  final _uidCtrl = TextEditingController();
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  final _bookingIdCtrl = TextEditingController();

  String _type = 'general';
  bool _sending = false;
  String _sentFilter = 'all';
  String _audience = 'all'; // 'all' | 'user'

  static const _quickTemplates = <({String label, String type, String titleHint, String bodyHint})>[
    (label: 'Tour Offer', type: 'special_offer', titleHint: 'Special Offer', bodyHint: 'Limited-time deal on select tours.'),
    (label: 'Booking Confirmed', type: 'booking_confirmed', titleHint: 'Booking Confirmed', bodyHint: 'Your booking is confirmed.'),
    (label: 'Cancellation', type: 'booking_cancellation_approved', titleHint: 'Cancellation Approved', bodyHint: 'Your cancellation request has been approved.'),
    (label: 'Trip Reminder', type: 'tour_reminder', titleHint: 'Trip Reminder', bodyHint: 'Your tour starts soon. Get ready!'),
    (label: 'Tour Update', type: 'general', titleHint: 'Tour Update', bodyHint: 'We have an important update for your tour.'),
    (label: 'Promo Code', type: 'special_offer', titleHint: 'Promo Code', bodyHint: 'Use code BAMBARE10 for 10% off.'),
    (label: 'Review Request', type: 'general', titleHint: 'Rate your trip', bodyHint: 'How was your tour? Leave a review.'),
    (label: 'Payment Alert', type: 'payment_reminder', titleHint: 'Payment Reminder', bodyHint: 'Payment received / pending update.'),
  ];

  Future<bool> _currentUserIsActiveAdmin() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return false;
    final snap =
        await FirebaseFirestore.instance.collection('admins').doc(uid).get();
    final d = snap.data();
    if (d == null) return false;
    if ((d['role'] as String?) != 'admin') return false;
    if (d['active'] == false) return false;
    return true;
  }

  @override
  void dispose() {
    _uidCtrl.dispose();
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    _bookingIdCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_sending) return;
    final title = _titleCtrl.text.trim();
    final body = _bodyCtrl.text.trim();
    final bookingId = _bookingIdCtrl.text.trim();
    final targetUid = _uidCtrl.text.trim();

    if (body.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Message is required.')),
      );
      return;
    }

    if (_audience == 'user' && targetUid.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User UID is required for "One User".')),
      );
      return;
    }

    setState(() => _sending = true);
    try {
      final ok = await _currentUserIsActiveAdmin();
      if (!ok) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Admin access required. Check `admins/{uid}` has role=admin and active=true.',
            ),
          ),
        );
        return;
      }

      final payload = <String, dynamic>{
        'type': _type,
        'title': title,
        'body': body,
        'source': 'admin_panel',
        'read': false,
        'created_at': FieldValue.serverTimestamp(),
        if (bookingId.isNotEmpty) 'booking_id': bookingId,
      };

      // Log one sent notification (admin UI right panel)
      try {
        final adminUid = FirebaseAuth.instance.currentUser!.uid;
        await FirebaseFirestore.instance
            .collection('admins')
            .doc(adminUid)
            .collection('sent_notifications')
            .add({
          ...payload,
          'audience': _audience == 'all' ? 'all_users' : 'user',
          if (_audience == 'user') 'target_uid': targetUid,
        });
      } catch (_) {
        // If history is blocked, still try to deliver to users.
      }

      if (_audience == 'user') {
        final ref = FirebaseFirestore.instance
            .collection('users')
            .doc(targetUid)
            .collection('notifications')
            .doc();
        await ref.set(payload);

        await ActivityLogService.log(
          type: 'notification',
          message: 'Notification sent to one user',
        );
      } else {
        // Broadcast to all known users. We take ids from `users` collection
        // and also `bookings.user_id` (covers anonymous users without a profile doc).
        final ids = <String>{};

        final usersSnap =
            await FirebaseFirestore.instance.collection('users').get();
        for (final u in usersSnap.docs) {
          ids.add(u.id);
        }

        final bookingsSnap =
            await FirebaseFirestore.instance.collection('bookings').get();
        for (final b in bookingsSnap.docs) {
          final d = b.data();
          final bid = (d['user_id'] as String? ?? '').trim();
          if (bid.isNotEmpty) ids.add(bid);
        }

        final all = ids.toList();
        // Batch writes (limit 500).
        for (var i = 0; i < all.length; i += 450) {
          final chunk = all.sublist(i, (i + 450).clamp(0, all.length));
          final batch = FirebaseFirestore.instance.batch();
          for (final id in chunk) {
            final ref = FirebaseFirestore.instance
                .collection('users')
                .doc(id)
                .collection('notifications')
                .doc();
            batch.set(ref, payload);
          }
          await batch.commit();
        }

        await ActivityLogService.log(
          type: 'notification',
          message: 'Broadcast notification sent',
        );
      }

      if (!mounted) return;
      _titleCtrl.clear();
      _bodyCtrl.clear();
      _bookingIdCtrl.clear();
      if (_audience == 'user') _uidCtrl.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _audience == 'user'
                ? 'Notification sent to user.'
                : 'Notification broadcast sent.',
          ),
        ),
      );
    } on FirebaseException catch (e) {
      if (!mounted) return;
      if (e.code == 'permission-denied') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Send failed: permission denied. Deploy updated Firestore rules and ensure you are logged in as an active admin.',
            ),
          ),
        );
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Send failed: $e')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Send failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.adminColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
          decoration: BoxDecoration(
            color: c.topBarBackground,
            border: Border(
              bottom: BorderSide(color: c.border, width: 1),
            ),
          ),
          child: Row(
            children: [
              Text(
                '⚠️ Notification Center',
                style: GoogleFonts.dmSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: c.textPrimary,
                ),
              ),
              const Spacer(),
              const AdminProfileBar(),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _statRow(c),
                        const SizedBox(height: 14),
                        _composeCard(c),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  flex: 2,
                  child: _sentPanel(c),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _statRow(AdminThemeColors c) {
    Stream<int> countSent() => FirebaseFirestore.instance
        .collection('admin_notifications')
        .snapshots()
        .map((s) => s.size);

    Stream<int> countUsers() => FirebaseFirestore.instance
        .collection('users')
        .snapshots()
        .map((s) => s.size);

    return Row(
      children: [
        Expanded(
          child: StreamBuilder<int>(
            stream: countSent(),
            builder: (_, snap) => _StatCard(
              label: 'Total Sent',
              value: '${snap.data ?? 0}',
              sub: 'All time',
              color: BrandColors.accent,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: StreamBuilder<int>(
            stream: countUsers(),
            builder: (_, snap) => _StatCard(
              label: 'Reached Users',
              value: '${snap.data ?? 0}',
              sub: 'Users collection',
              color: const Color(0xFF58A6FF),
            ),
          ),
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: _StatCard(
            label: 'Open Rate',
            value: '—',
            sub: 'Not tracked',
            color: Color(0xFF2EA043),
          ),
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: _StatCard(
            label: 'Scheduled',
            value: '0',
            sub: 'Pending',
            color: Color(0xFFF0A94A),
          ),
        ),
      ],
    );
  }

  Widget _composeCard(AdminThemeColors c) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Compose Notification',
            style: GoogleFonts.dmSans(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: c.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Writes to Firestore `users/{uid}/notifications`. Select template or compose manually.',
            style: GoogleFonts.dmSans(fontSize: 11, color: c.muted),
          ),
          const SizedBox(height: 14),
          Text(
            'QUICK TEMPLATES',
            style: GoogleFonts.dmSans(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.3,
              color: c.muted,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _quickTemplates.map((t) {
              return _TemplateChip(
                label: t.label,
                onTap: () {
                  setState(() {
                    _type = t.type;
                    if (_titleCtrl.text.trim().isEmpty) {
                      _titleCtrl.text = t.titleHint;
                    }
                    if (_bodyCtrl.text.trim().isEmpty) {
                      _bodyCtrl.text = t.bodyHint;
                    }
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          Text(
            'SEND TO',
            style: GoogleFonts.dmSans(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.3,
              color: c.muted,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _AudienceChip(
                label: 'All Users',
                active: _audience == 'all',
                onTap: () => setState(() => _audience = 'all'),
              ),
              const SizedBox(width: 8),
              _AudienceChip(
                label: 'One User',
                active: _audience == 'user',
                onTap: () => setState(() => _audience = 'user'),
              ),
            ],
          ),
          if (_audience == 'user') ...[
            const SizedBox(height: 12),
            _Field(
              label: 'User UID *',
              controller: _uidCtrl,
              hint: 'Paste the Firebase Auth UID',
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _Field(
                  label: 'Title (optional)',
                  controller: _titleCtrl,
                  hint: 'e.g. Special Offer',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _TypePicker(
                  value: _type,
                  onChanged: (v) => setState(() => _type = v),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _Field(
            label: 'Message *',
            controller: _bodyCtrl,
            hint: 'Type the notification body…',
            maxLines: 4,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _Field(
                  label: 'Booking ID (optional)',
                  controller: _bookingIdCtrl,
                  hint: 'Firestore booking doc id',
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'LIVE PREVIEW — USER APP',
            style: GoogleFonts.dmSans(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.3,
              color: c.muted,
            ),
          ),
          const SizedBox(height: 10),
          _PreviewCard(
            title: _titleCtrl.text.trim().isEmpty ? 'Notification Title' : _titleCtrl.text.trim(),
            body: _bodyCtrl.text.trim().isEmpty ? 'Your notification message will appear here.' : _bodyCtrl.text.trim(),
            audience: _audience == 'user' ? 'One User' : 'All Users',
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 44,
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _sending ? null : _send,
              style: ElevatedButton.styleFrom(
                backgroundColor: BrandColors.accent,
                foregroundColor: BrandColors.onAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_sending)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: BrandColors.onAccent,
                      ),
                    )
                  else
                    const Icon(Icons.send_rounded, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    _sending ? 'Sending…' : 'Send Notification',
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
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

  Widget _sentPanel(AdminThemeColors c) {
    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.border),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Sent Notifications',
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: c.textPrimary,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => setState(() => _sentFilter = 'all'),
                  child: Text(
                    'All',
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: _sentFilter == 'all' ? BrandColors.accent : c.muted,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => setState(() => _sentFilter = 'booking'),
                  child: Text(
                    'Booking',
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: _sentFilter == 'booking' ? BrandColors.accent : c.muted,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => setState(() => _sentFilter = 'general'),
                  child: Text(
                    'General',
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: _sentFilter == 'general' ? BrandColors.accent : c.muted,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: c.border),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('admins')
                  .doc(FirebaseAuth.instance.currentUser?.uid)
                  .collection('sent_notifications')
                  .orderBy('created_at', descending: true)
                  .limit(25)
                  .snapshots(),
              builder: (context, snap) {
                if (snap.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Text(
                        'Could not load sent notifications.\n${snap.error}\n\nIf you see permission-denied: deploy Firestore rules and ensure you are logged in as an active admin.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          height: 1.4,
                          color: c.muted,
                        ),
                      ),
                    ),
                  );
                }
                if (!snap.hasData) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(18),
                      child: CircularProgressIndicator(
                        color: BrandColors.accent,
                        strokeWidth: 2,
                      ),
                    ),
                  );
                }
                final docs = snap.data?.docs ?? const [];
                final filtered = docs.where((d) {
                  if (_sentFilter == 'all') return true;
                  final type = (d.data()['type'] ?? '').toString();
                  if (_sentFilter == 'booking') {
                    return type.contains('booking');
                  }
                  if (_sentFilter == 'general') {
                    return !type.contains('booking');
                  }
                  return true;
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Text(
                        'No sent notifications yet.\n\nIf you just sent one and it did not appear, check the Firestore rules for `admin_notifications` (admin read/create).',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.dmSans(fontSize: 12, color: c.muted),
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    final d = filtered[i].data();
                    final title = (d['title'] ?? '').toString().trim();
                    final body = (d['body'] ?? '').toString().trim();
                    final type = (d['type'] ?? '').toString().trim();
                    final audience = (d['audience'] ?? '').toString().trim();
                    return _SentCard(
                      title: title.isEmpty ? type : title,
                      body: body,
                      tag: audience == 'all_users' ? 'All Users' : 'User',
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.sub,
    required this.color,
  });

  final String label;
  final String value;
  final String sub;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final c = context.adminColors;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.dmSans(fontSize: 11, color: c.muted)),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.dmSans(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: c.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            sub,
            style: GoogleFonts.dmSans(fontSize: 10, color: color),
          ),
        ],
      ),
    );
  }
}

class _TemplateChip extends StatelessWidget {
  const _TemplateChip({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.adminColors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: c.inputFill,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: c.border),
        ),
        child: Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: c.textPrimary,
          ),
        ),
      ),
    );
  }
}

class _AudienceChip extends StatelessWidget {
  const _AudienceChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.adminColors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: active ? BrandColors.accent.withOpacity(0.18) : c.inputFill,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: active ? BrandColors.accent : c.border,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: active ? BrandColors.accent : c.textPrimary,
          ),
        ),
      ),
    );
  }
}

class _PreviewCard extends StatelessWidget {
  const _PreviewCard({
    required this.title,
    required this.body,
    required this.audience,
  });

  final String title;
  final String body;
  final String audience;

  @override
  Widget build(BuildContext context) {
    final c = context.adminColors;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.inputFill,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.notifications_outlined, size: 16, color: BrandColors.accent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: c.textPrimary,
                  ),
                ),
              ),
              Text(
                audience,
                style: GoogleFonts.dmSans(fontSize: 10, color: c.muted),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: GoogleFonts.dmSans(fontSize: 11, color: c.textBody, height: 1.35),
          ),
        ],
      ),
    );
  }
}

class _SentCard extends StatelessWidget {
  const _SentCard({
    required this.title,
    required this.body,
    required this.tag,
  });

  final String title;
  final String body;
  final String tag;

  @override
  Widget build(BuildContext context) {
    final c = context.adminColors;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.inputFill,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: c.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: BrandColors.accent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  tag,
                  style: GoogleFonts.dmSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: BrandColors.accent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            body,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.dmSans(fontSize: 11, color: c.muted, height: 1.35),
          ),
        ],
      ),
    );
  }
}

class _TypePicker extends StatelessWidget {
  const _TypePicker({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.adminColors;
    const items = [
      'general',
      'booking_cancellation_approved',
      'booking_cancellation_rejected',
      'booking_confirmed',
      'tour_reminder',
      'payment_reminder',
      'special_offer',
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Type',
          style: GoogleFonts.dmSans(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: c.muted,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: c.inputFill,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: c.border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              dropdownColor: c.surface,
              iconEnabledColor: c.muted,
              onChanged: (v) {
                if (v != null) onChanged(v);
              },
              items: items
                  .map(
                    (x) => DropdownMenuItem(
                      value: x,
                      child: Text(
                        x,
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          color: c.textPrimary,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
      ],
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.controller,
    required this.hint,
    this.maxLines = 1,
  });

  final String label;
  final TextEditingController controller;
  final String hint;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final c = context.adminColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: c.muted,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: GoogleFonts.dmSans(fontSize: 12, color: c.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.dmSans(fontSize: 12, color: c.muted),
            filled: true,
            fillColor: c.inputFill,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: c.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: c.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: BrandColors.accent, width: 1.2),
            ),
          ),
        ),
      ],
    );
  }
}

