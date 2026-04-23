import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/admin_theme_colors.dart';
import '../../theme/brand_colors.dart';
import '../../services/activity_log_service.dart';
import '../../widgets/admin_profile_bar.dart';

// ── Booking doc helpers (user app uses snake_case; admin dialog used camelCase) ──

String _statusKeyFromMap(Map<String, dynamic> d) {
  final s = (d['status'] ?? 'pending').toString().trim().toLowerCase();
  if (s.contains('confirm')) return 'confirmed';
  if (s.contains('cancel')) return 'cancelled';
  return 'pending';
}

String _statusForFirestore(String filterKey) {
  switch (filterKey) {
    case 'confirmed':
      return 'Confirmed';
    case 'cancelled':
      return 'Cancelled';
    case 'pending':
    default:
      return 'Pending';
  }
}

String _statusDisplayLabel(String key) {
  switch (key) {
    case 'confirmed':
      return 'Confirmed';
    case 'cancelled':
      return 'Cancelled';
    default:
      return 'Pending';
  }
}

bool _matchesStatusFilter(Map<String, dynamic>? d, String filter) {
  if (filter == 'all' || d == null) return true;
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
  final List<String> _filters = ['all', 'confirmed', 'cancelled'];

  /// User app (`booking_service.dart`) uses snake_case + title-case status.
  /// We load all docs once and filter/sort in memory to avoid composite indexes
  /// and mixed legacy/admin field names.

  Future<void> _updateStatus(String docId, String filterKey) async {
    final status = _statusForFirestore(filterKey);
    await FirebaseFirestore.instance
        .collection('bookings')
        .doc(docId)
        .update({'status': status});
    await ActivityLogService.log(
      type: 'booking',
      message: 'Booking status updated to ${_statusForFirestore(filterKey)}',
    );
  }

  Future<void> _deleteBooking(String docId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final c = dialogContext.adminColors;
        return AlertDialog(
          backgroundColor: c.dialogBackground,
          title: Text(
            'Delete Booking',
            style: GoogleFonts.dmSans(color: c.textPrimary),
          ),
          content: Text(
            'Are you sure you want to delete this booking?',
            style: GoogleFonts.dmSans(color: c.muted),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(
                'Cancel',
                style: GoogleFonts.dmSans(color: c.muted),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(
                'Delete',
                style: GoogleFonts.dmSans(color: const Color(0xFFF47067)),
              ),
            ),
          ],
        );
      },
    );
    if (confirm == true) {
      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(docId)
          .delete();
      await ActivityLogService.log(
        type: 'cancel',
        message: 'Booking deleted',
      );
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
                    f[0].toUpperCase() + f.substring(1),
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
                              onStatusChange: (s) =>
                                  _updateStatus(docs[i].id, s),
                              onDelete: () => _deleteBooking(docs[i].id),
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
          const SizedBox(width: 60),
        ],
      ),
    );
  }
}

class _BookingTableRow extends StatelessWidget {
  final String docId;
  final Map<String, dynamic> data;
  final Function(String) onStatusChange;
  final VoidCallback onDelete;

  const _BookingTableRow({
    required this.docId,
    required this.data,
    required this.onStatusChange,
    required this.onDelete,
  });

  Color _statusColor(String key) {
    switch (key) {
      case 'confirmed':
        return BrandColors.accent;
      case 'cancelled':
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
            child: PopupMenuButton<String>(
              color: c.inputFill,
              onSelected: onStatusChange,
              itemBuilder: (_) => ['confirmed', 'cancelled']
                  .map(
                    (s) => PopupMenuItem(
                      value: s,
                      child: Text(
                        _statusDisplayLabel(s),
                        style: GoogleFonts.dmSans(
                          color: c.textPrimary,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  )
                  .toList(),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _statusColor(statusKey).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      statusLabel,
                      style: GoogleFonts.dmSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: _statusColor(statusKey),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.keyboard_arrow_down,
                      size: 12,
                      color: _statusColor(statusKey),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(
            width: 60,
            child: IconButton(
              icon: const Icon(
                Icons.delete_outline,
                size: 16,
                color: Color(0xFFF47067),
              ),
              onPressed: onDelete,
            ),
          ),
        ],
      ),
    );
  }
}
