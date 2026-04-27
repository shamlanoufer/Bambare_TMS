import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/admin_theme_colors.dart';
import '../../theme/brand_colors.dart';
import '../../services/activity_log_service.dart';
import '../../widgets/admin_profile_bar.dart';

// ── Booking doc helpers (user app uses snake_case; admin dialog used camelCase) ──

String _statusKeyFromMap(Map<String, dynamic> d) {
  final s = (d['status'] ?? 'pending').toString().trim().toLowerCase();
  if (s.contains('cancel pending') || s.contains('cancel request')) return 'cancel_pending';
  if (s.contains('confirm')) return 'confirmed';
  if (s.contains('complete')) return 'completed';
  if (s.contains('cancel')) return 'cancelled';
  return 'pending';
}

String _statusForFirestore(String filterKey) {
  switch (filterKey) {
    case 'confirmed':
      return 'Confirmed';
    case 'completed':
      return 'Completed';
    case 'cancelled':
      return 'Cancelled';
    case 'pending':
    default:
      return 'Pending';
  }
}

enum _CancelRequestAction { approve, reject }

String _statusDisplayLabel(String key) {
  switch (key) {
    case 'confirmed':
      return 'Confirmed';
    case 'completed':
      return 'Completed';
    case 'cancelled':
      return 'Cancelled';
    case 'cancel_pending':
      return 'Cancel Pending';
    default:
      return 'Pending';
  }
}

bool _isCancelledStatus(String s) {
  final x = s.trim().toLowerCase();
  return x == 'cancelled' || x == 'canceled';
}

bool _isCompletedStatus(String s) {
  final x = s.trim().toLowerCase();
  if (x == 'completed') return true;
  return x.contains('complete');
}

DateTime _startOfToday() {
  final n = DateTime.now();
  return DateTime(n.year, n.month, n.day);
}

DateTime _endUpcomingWeek() => _startOfToday().add(const Duration(days: 7));

Future<List<String>> _envKeysForTour(String tourId) async {
  if (tourId.trim().isEmpty) return const [];
  final snap = await FirebaseFirestore.instance.collection('tours').doc(tourId).get();
  final d = snap.data() ?? const <String, dynamic>{};

  final out = <String>[];
  final v = d['visibility'];
  if (v is Map) {
    bool g(String k) => v[k] == true;
    if (g('environment_cultural')) out.add('Cultural');
    if (g('environment_beach')) out.add('Beach');
    if (g('environment_wildlife')) out.add('Wildlife');
    if (g('environment_mountain')) out.add('Mountain');
    if (g('environment_food')) out.add('Food');
  }
  if (out.isNotEmpty) return out;

  final cat = (d['category'] as String? ?? '').trim().toLowerCase();
  switch (cat) {
    case 'cultural':
      return const ['Cultural'];
    case 'beach':
      return const ['Beach'];
    case 'wildlife':
      return const ['Wildlife'];
    case 'mountain':
      return const ['Mountain'];
    case 'food':
      return const ['Food'];
    default:
      return const [];
  }
}

Future<void> _applyMapReportsDelta({
  required String tourId,
  required DateTime? travelDate,
  required int completedDelta,
  required int upcomingWeekDelta,
}) async {
  if (tourId.trim().isEmpty) return;
  final updates = <String, FieldValue>{};

  if (completedDelta != 0) {
    updates['completed_tour_bookings_total.$tourId'] = FieldValue.increment(completedDelta);
    final envs = await _envKeysForTour(tourId);
    for (final k in envs) {
      updates['completed_visits_by_category.$k'] = FieldValue.increment(completedDelta);
    }
  }

  if (upcomingWeekDelta != 0 && travelDate != null) {
    final d = DateTime(travelDate.year, travelDate.month, travelDate.day);
    final ok = !d.isBefore(_startOfToday()) && !d.isAfter(_endUpcomingWeek());
    if (ok) {
      updates['upcoming_week_tour_bookings_total.$tourId'] = FieldValue.increment(upcomingWeekDelta);
    }
  }

  if (updates.isEmpty) return;
  await FirebaseFirestore.instance
      .collection('public_stats')
      .doc('map_reports')
      .set(updates, SetOptions(merge: true));
}

bool _matchesStatusFilter(Map<String, dynamic>? d, String filter) {
  if (filter == 'all' || d == null) return true;
  if (filter == 'cancel requests') {
    return _statusKeyFromMap(d) == 'cancel_pending';
  }
  return _statusKeyFromMap(d) == filter;
}

DateTime _bookingSortTime(Map<String, dynamic> d) {
  final c1 = d['created_at'];
  final c2 = d['createdAt'];
  if (c1 is Timestamp) return c1.toDate();
  if (c2 is Timestamp) return c2.toDate();
  return DateTime.fromMillisecondsSinceEpoch(0);
}

List<QueryDocumentSnapshot<Map<String, dynamic>>> _sortedBookingDocs(
  List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
) {
  final list = List<QueryDocumentSnapshot<Map<String, dynamic>>>.from(docs);
  list.sort(
    (a, b) => _bookingSortTime(b.data()).compareTo(_bookingSortTime(a.data())),
  );
  return list;
}

String _customerDisplay(Map<String, dynamic> data) {
  final direct = (data['customerName'] ?? '').toString().trim();
  if (direct.isNotEmpty) return direct;
  final f = (data['lead_first_name'] ?? '').toString().trim();
  final l = (data['lead_last_name'] ?? '').toString().trim();
  final combined = '$f $l'.trim();
  if (combined.isNotEmpty) return combined;
  final email = (data['email'] ?? '').toString().trim();
  if (email.isNotEmpty) return email;
  return '—';
}

String _tourDisplay(Map<String, dynamic> data) {
  final a = (data['tourName'] ?? '').toString().trim();
  if (a.isNotEmpty) return a;
  final b = (data['tour_title'] ?? '').toString().trim();
  return b.isEmpty ? '—' : b;
}

String _bookingDateLabel(Map<String, dynamic> data) {
  final tr = data['travel_date'];
  if (tr is Timestamp) {
    final dt = tr.toDate();
    return '${dt.day}/${dt.month}/${dt.year}';
  }
  final c1 = data['created_at'];
  final c2 = data['createdAt'];
  Timestamp? t;
  if (c1 is Timestamp) {
    t = c1;
  } else if (c2 is Timestamp) {
    t = c2;
  }
  if (t != null) {
    final dt = t.toDate();
    return '${dt.day}/${dt.month}/${dt.year}';
  }
  return '—';
}

class AdminBookingsScreen extends StatefulWidget {
  const AdminBookingsScreen({super.key});

  @override
  State<AdminBookingsScreen> createState() => _AdminBookingsScreenState();
}

class _AdminBookingsScreenState extends State<AdminBookingsScreen> {
  String _filter = 'all';
  final List<String> _filters = ['all', 'confirmed', 'completed', 'cancelled', 'cancel requests'];
  bool _syncingMapStats = false;

  Future<bool> _currentUserIsActiveAdmin() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return false;
    final snap = await FirebaseFirestore.instance.collection('admins').doc(uid).get();
    final d = snap.data();
    if (d == null) return false;
    if ((d['role'] as String?) != 'admin') return false;
    if (d['active'] == false) return false;
    return true;
  }

  /// User app (`booking_service.dart`) uses snake_case + title-case status.
  /// We load all docs once and filter/sort in memory to avoid composite indexes
  /// and mixed legacy/admin field names.

  Future<void> _syncMapReportsFromBookings() async {
    setState(() => _syncingMapStats = true);
    try {
      final isAdmin = await _currentUserIsActiveAdmin();
      if (!isAdmin) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You need an active admin account to sync map stats.'),
          ),
        );
        return;
      }

      QuerySnapshot<Map<String, dynamic>> bookings;
      try {
        bookings = await FirebaseFirestore.instance.collection('bookings').get();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cannot read bookings (permission denied). Are you logged in as an admin user?\\n$e')),
        );
        return;
      }

      final outCompletedByCat = <String, int>{
        'Cultural': 0,
        'Beach': 0,
        'Wildlife': 0,
        'Mountain': 0,
        'Food': 0,
      };
      final completedTourTotals = <String, int>{};
      final upcomingWeekTotals = <String, int>{};
      final allTourTotals = <String, int>{};

      final startToday = _startOfToday();
      final endWeek = _endUpcomingWeek();

      // Build tourId set (completed + upcoming-week) so we can fetch tours in chunks.
      final tourIds = <String>{};

      for (final doc in bookings.docs) {
        final bd = doc.data();
        final status = (bd['status'] as String? ?? '').toString();
        if (_isCancelledStatus(status)) continue;
        final isCompleted = _isCompletedStatus(status);

        final tid = (bd['tour_id'] as String? ?? '').trim();
        if (tid.isEmpty) continue;
        tourIds.add(tid);

        allTourTotals[tid] = (allTourTotals[tid] ?? 0) + 1;

        if (isCompleted) {
          completedTourTotals[tid] = (completedTourTotals[tid] ?? 0) + 1;
          continue;
        }

        // Trending bucket: next 7 days, not cancelled, not completed.
        final tr = bd['travel_date'];
        if (tr is! Timestamp) continue;
        final dt = tr.toDate();
        final day = DateTime(dt.year, dt.month, dt.day);
        final inWeek = !day.isBefore(startToday) && !day.isAfter(endWeek);
        if (!inWeek) continue;
        upcomingWeekTotals[tid] = (upcomingWeekTotals[tid] ?? 0) + 1;
      }

      // Fetch tours by id in chunks (whereIn limit 10).
      final tourById = <String, Map<String, dynamic>>{};
      final ids = tourIds.toList();
      for (var i = 0; i < ids.length; i += 10) {
        final chunk = ids.sublist(i, (i + 10).clamp(0, ids.length));
        final snap = await FirebaseFirestore.instance
            .collection('tours')
            .where(FieldPath.documentId, whereIn: chunk)
            .get();
        for (final t in snap.docs) {
          tourById[t.id] = t.data();
        }
      }

      // Completed visits by category = completed bookings per tour, mapped to env/category.
      for (final e in completedTourTotals.entries) {
        final tid = e.key;
        final count = e.value;
        final td = tourById[tid] ?? const <String, dynamic>{};

        final keys = <String>[];
        final v = td['visibility'];
        if (v is Map) {
          bool g(String k) => v[k] == true;
          if (g('environment_cultural')) keys.add('Cultural');
          if (g('environment_beach')) keys.add('Beach');
          if (g('environment_wildlife')) keys.add('Wildlife');
          if (g('environment_mountain')) keys.add('Mountain');
          if (g('environment_food')) keys.add('Food');
        }
        if (keys.isEmpty) {
          final cat = (td['category'] as String? ?? '').trim().toLowerCase();
          switch (cat) {
            case 'cultural':
              keys.add('Cultural');
              break;
            case 'beach':
              keys.add('Beach');
              break;
            case 'wildlife':
              keys.add('Wildlife');
              break;
            case 'mountain':
              keys.add('Mountain');
              break;
            case 'food':
              keys.add('Food');
              break;
          }
        }
        for (final k in keys) {
          outCompletedByCat[k] = (outCompletedByCat[k] ?? 0) + count;
        }
      }

      try {
        await FirebaseFirestore.instance.collection('public_stats').doc('map_reports').set(
          {
            'completed_visits_by_category': outCompletedByCat,
            'completed_tour_bookings_total': completedTourTotals,
            'upcoming_week_tour_bookings_total': upcomingWeekTotals,
            'all_tour_bookings_total': allTourTotals,
            'backfilled_from_bookings': true,
            'backfilled_at': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      } on FirebaseException catch (e) {
        if (!mounted) return;
        final denied = e.code == 'permission-denied';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              denied
                  ? 'Cannot write map stats. Deploy Firestore rules and verify admin access.'
                  : 'Cannot write public_stats/map_reports.\n$e',
            ),
          ),
        );
        return;
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cannot write public_stats/map_reports (permission denied).\\n$e')),
        );
        return;
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Synced map stats from ${bookings.docs.length} bookings.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sync failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _syncingMapStats = false);
    }
  }

  Future<void> _updateStatus(
    String docId,
    String filterKey, {
    _CancelRequestAction? cancelAction,
  }) async {
    final status = _statusForFirestore(filterKey);
    final ref = FirebaseFirestore.instance.collection('bookings').doc(docId);
    final before = await ref.get();
    final bd = before.data() ?? const <String, dynamic>{};
    final oldStatus = (bd['status'] as String? ?? '').trim();
    final tourId = (bd['tour_id'] as String? ?? '').trim();
    DateTime? travelDate;
    final tr = bd['travel_date'];
    if (tr is Timestamp) travelDate = tr.toDate();

    final updates = <String, dynamic>{'status': status};
    if (cancelAction == _CancelRequestAction.approve) {
      updates['cancel_request_status'] = 'approved';
      updates['cancel_request_resolved_at'] = FieldValue.serverTimestamp();
    } else if (cancelAction == _CancelRequestAction.reject) {
      updates['cancel_request_status'] = 'rejected';
      updates['cancel_request_resolved_at'] = FieldValue.serverTimestamp();
    }
    await ref.update(updates);

    // Keep Map Reports aggregates consistent with admin status updates.
    final wasCancelled = _isCancelledStatus(oldStatus);
    final isCancelled = _isCancelledStatus(status);
    final wasCompleted = _isCompletedStatus(oldStatus);
    final isCompleted = _isCompletedStatus(status);

    final completedDelta = (!wasCompleted && isCompleted)
        ? 1
        : (wasCompleted && !isCompleted)
            ? -1
            : 0;

    int upcomingDelta = 0;
    if (travelDate != null) {
      final td = DateTime(travelDate.year, travelDate.month, travelDate.day);
      final inWeek = !td.isBefore(_startOfToday()) && !td.isAfter(_endUpcomingWeek());
      final countedBefore = inWeek && !wasCancelled && !wasCompleted;
      final countedAfter = inWeek && !isCancelled && !isCompleted;
      if (countedBefore != countedAfter) upcomingDelta = countedAfter ? 1 : -1;
    }

    await _applyMapReportsDelta(
      tourId: tourId,
      travelDate: travelDate,
      completedDelta: completedDelta,
      upcomingWeekDelta: upcomingDelta,
    );
    await ActivityLogService.log(
      type: 'booking',
      message: 'Booking status updated to ${_statusForFirestore(filterKey)}',
    );

    // Send user notification for admin decision on cancellation requests.
    final userId = bd['user_id'] as String?;
    if (userId != null && cancelAction != null) {
      try {
        final isApproved = cancelAction == _CancelRequestAction.approve;
        final tourName = bd['tour_title'] ?? bd['tourName'] ?? 'your tour';
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('notifications')
            .add({
          'type': isApproved
              ? 'booking_cancellation_approved'
              : 'booking_cancellation_rejected',
          'title': isApproved
              ? 'Cancellation Approved'
              : 'Cancellation Not Approved',
          'body': isApproved
              ? 'Your cancellation request for $tourName has been approved. This booking is now moved to Cancelled.'
              : 'Your cancellation request for $tourName was not approved. Your booking remains active in Upcoming.',
          'booking_id': docId,
          'tour_title': '$tourName',
          'booking_status': status,
          'read': false,
          'created_at': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        debugPrint('Failed to send notification: $e');
      }
    }
  }



  @override
  Widget build(BuildContext context) {
    final c = context.adminColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTopBar(c),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
          child: Row(
            children: _filters.map((f) {
              final active = _filter == f;
              return GestureDetector(
                onTap: () => setState(() => _filter = f),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: active
                        ? BrandColors.accent
                        : c.chipBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: active
                          ? BrandColors.accent
                          : c.border,
                    ),
                  ),
                  child: Text(
                    f == 'cancel requests' ? 'Cancel Requests' : f[0].toUpperCase() + f.substring(1),
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: active ? BrandColors.onAccent : c.muted,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('bookings')
                .snapshots(),
            builder: (context, snap) {
              if (snap.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Could not load bookings.\n${snap.error}',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        color: c.muted,
                      ),
                    ),
                  ),
                );
              }
              if (!snap.hasData) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: BrandColors.accent,
                    strokeWidth: 2,
                  ),
                );
              }
              final docs = _sortedBookingDocs(snap.data!.docs)
                  .where((d) => _matchesStatusFilter(d.data(), _filter))
                  .toList();
              if (docs.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 48),
                    decoration: BoxDecoration(
                      color: c.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: c.border),
                    ),
                    child: Center(
                      child: Text(
                        _filter == 'all'
                            ? 'No bookings yet.'
                            : _filter == 'cancel requests'
                                ? 'No cancel requests.'
                                : 'No ${_filter[0].toUpperCase()}${_filter.substring(1)} bookings.',
                        style: GoogleFonts.dmSans(
                          fontSize: 13,
                          color: c.muted,
                        ),
                      ),
                    ),
                  ),
                );
              }
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  decoration: BoxDecoration(
                    color: c.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: c.border),
                  ),
                  child: Column(
                    children: [
                      _tableHeader(c),
                      Expanded(
                        child: ListView.builder(
                          itemCount: docs.length,
                          itemBuilder: (_, i) {
                            final d = docs[i].data();
                            return _BookingTableRow(
                              docId: docs[i].id,
                              data: d,
                              onStatusChange: (s, action) => _updateStatus(
                                docs[i].id,
                                s,
                                cancelAction: action,
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildTopBar(AdminThemeColors c) {
    return Container(
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
            'Bookings',
            style: GoogleFonts.dmSans(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: c.textPrimary,
            ),
          ),
          const Spacer(),
          TextButton.icon(
            onPressed: _syncingMapStats ? null : _syncMapReportsFromBookings,
            icon: _syncingMapStats
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.sync_rounded, size: 16),
            label: Text(
              _syncingMapStats ? 'Syncing…' : 'Sync Map Stats',
              style: GoogleFonts.dmSans(fontWeight: FontWeight.w600, fontSize: 12),
            ),
          ),
          const AdminProfileBar(),
        ],
      ),
    );
  }

  Widget _tableHeader(AdminThemeColors c) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: c.border, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              'Customer',
              style: GoogleFonts.dmSans(
                fontSize: 11,
                color: c.muted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              'Tour',
              style: GoogleFonts.dmSans(
                fontSize: 11,
                color: c.muted,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Date',
              style: GoogleFonts.dmSans(
                fontSize: 11,
                color: c.muted,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Amount',
              style: GoogleFonts.dmSans(
                fontSize: 11,
                color: c.muted,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Status',
              style: GoogleFonts.dmSans(
                fontSize: 11,
                color: c.muted,
              ),
            ),
          ),

        ],
      ),
    );
  }
}

class _BookingTableRow extends StatelessWidget {
  final String docId;
  final Map<String, dynamic> data;
  final Future<void> Function(String, _CancelRequestAction?) onStatusChange;

  const _BookingTableRow({
    required this.docId,
    required this.data,
    required this.onStatusChange,
  });

  Color _statusColor(String key) {
    switch (key) {
      case 'confirmed':
        return BrandColors.accent;
      case 'cancelled':
      case 'cancel_pending':
        return const Color(0xFFF47067);
      default:
        return const Color(0xFFF0A94A);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.adminColors;
    final name = _customerDisplay(data);
    final tour = _tourDisplay(data);
    final amount = data['total_price'] ?? data['totalAmount'] ?? 0;
    final statusKey = _statusKeyFromMap(data);
    final statusLabel = _statusDisplayLabel(statusKey);
    final date = _bookingDateLabel(data);
    final currency = (data['currency'] ?? 'LKR').toString();

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: c.border, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              name,
              style: GoogleFonts.dmSans(
                fontSize: 12,
                color: c.textPrimary,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              tour,
              style: GoogleFonts.dmSans(
                fontSize: 12,
                color: c.muted,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              date,
              style: GoogleFonts.dmSans(
                fontSize: 12,
                color: c.muted,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '$currency $amount',
              style: GoogleFonts.dmSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: c.textPrimary,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _statusColor(statusKey).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      statusLabel,
                      style: GoogleFonts.dmSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: _statusColor(statusKey),
                      ),
                    ),
                  ),
                ),
                if (statusKey == 'cancel_pending') ...[
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () => onStatusChange(
                      'cancelled',
                      _CancelRequestAction.approve,
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      foregroundColor: const Color(0xFFF47067),
                    ),
                    child: Text(
                      'Approve Cancel',
                      style: GoogleFonts.dmSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  TextButton(
                    onPressed: () => onStatusChange(
                      'confirmed',
                      _CancelRequestAction.reject,
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      foregroundColor: const Color(0xFF2E7D32),
                    ),
                    child: Text(
                      'Reject Cancel',
                      style: GoogleFonts.dmSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

        ],
      ),
    );
  }
}
