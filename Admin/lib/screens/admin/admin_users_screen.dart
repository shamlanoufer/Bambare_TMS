import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/admin_theme_colors.dart';
import '../../theme/brand_colors.dart';
import '../../services/activity_log_service.dart';
import '../../widgets/admin_profile_bar.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:universal_html/html.dart' as html;

String _userDisplayName(Map<String, dynamic> d) {
  for (final key in ['fullName', 'name', 'displayName', 'username']) {
    final v = d[key];
    if (v != null) {
      final s = v.toString().trim();
      if (s.isNotEmpty) return s;
    }
  }
  final email = d['email']?.toString().trim();
  if (email != null && email.contains('@')) {
    return email.split('@').first;
  }
  return '—';
}

String? _userPhotoUrl(Map<String, dynamic> d) {
  for (final key in [
    'photoUrl',
    'photoURL',
    'avatarUrl',
    'avatar',
    'profilePic'
  ]) {
    final v = d[key];
    if (v != null) {
      final s = v.toString().trim();
      if (s.isNotEmpty) return s;
    }
  }
  return null;
}

String _userInitials(String displayName, String email) {
  final t = displayName.trim();
  if (t.isNotEmpty && t != '—') {
    final parts = t.split(RegExp(r'\s+'));
    if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      final a = parts[0].runes.first;
      final b = parts[1].runes.first;
      return '${String.fromCharCode(a)}${String.fromCharCode(b)}'.toUpperCase();
    }
    final runes = t.runes.toList();
    if (runes.length >= 2) {
      return '${String.fromCharCode(runes[0])}${String.fromCharCode(runes[1])}'
          .toUpperCase();
    }
    if (runes.isNotEmpty) {
      return String.fromCharCode(runes.first).toUpperCase();
    }
  }
  final e = email.trim();
  if (e.contains('@')) {
    final local = e.split('@').first;
    if (local.length >= 2) {
      return local.substring(0, 2).toUpperCase();
    }
    if (local.isNotEmpty) {
      return local.substring(0, 1).toUpperCase();
    }
  }
  if (e.length >= 2) {
    return e.substring(0, 2).toUpperCase();
  }
  return '?';
}

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final String _roleFilter = 'all';

  Query<Map<String, dynamic>> get _query {
    final base = FirebaseFirestore.instance
        .collection('users')
        .orderBy('createdAt', descending: true);
    if (_roleFilter == 'all') return base;
    return base.where('role', isEqualTo: _roleFilter);
  }

  Future<void> _toggleStatus(String docId, bool isActive) async {
    await FirebaseFirestore.instance.collection('users').doc(docId).update({
      'isActive': !isActive,
    });
  }

  Future<void> _deleteUser(String docId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final c = dialogContext.adminColors;
        return AlertDialog(
          backgroundColor: c.dialogBackground,
          title: Text(
            'Delete User',
            style: GoogleFonts.dmSans(color: c.textPrimary),
          ),
          content: Text(
            'This will permanently delete the user account.',
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
      await FirebaseFirestore.instance.collection('users').doc(docId).delete();
      await ActivityLogService.log(
        type: 'user',
        message: 'User account removed',
      );
    }
  }

  Future<_UserInsights> _fetchUserInsights(
      String userDocId, Map<String, dynamic> userData) async {
    final email = (userData['email'] ?? '').toString().trim().toLowerCase();
    final name = _userDisplayName(userData).toLowerCase();
    final uidFromDoc = (userData['uid'] ?? '').toString().trim();
    final snap = await FirebaseFirestore.instance.collection('bookings').get();

    final history = <_BookingHistoryItem>[];
    var bookings = 0;
    var cancelled = 0;
    var totalSpent = 0.0;
    var totalRating = 0.0;
    var ratingCount = 0;

    for (final doc in snap.docs) {
      final b = doc.data();
      final bEmail =
          (b['email'] ?? b['userEmail'] ?? '').toString().trim().toLowerCase();
      final bUid =
          (b['user_id'] ?? b['userId'] ?? b['uid'] ?? '').toString().trim();
      final customerName = _userDisplayName({
        'fullName': b['customerName'] ??
            '${b['lead_first_name'] ?? ''} ${b['lead_last_name'] ?? ''}',
      }).toLowerCase();

      final match = (uidFromDoc.isNotEmpty && bUid == uidFromDoc) ||
          bUid == userDocId ||
          (email.isNotEmpty && bEmail == email) ||
          (name.isNotEmpty && customerName == name);
      if (!match) continue;

      bookings++;
      final amount = (b['total_price'] ?? b['totalAmount'] ?? 0);
      final amountValue = amount is num ? amount.toDouble() : 0.0;
      totalSpent += amountValue;

      final statusRaw = (b['status'] ?? 'Pending').toString();
      final status =
          statusRaw[0].toUpperCase() + statusRaw.substring(1).toLowerCase();
      if (status.toLowerCase().contains('cancel')) cancelled++;

      final ratingRaw = b['rating'];
      if (ratingRaw is num) {
        totalRating += ratingRaw.toDouble();
        ratingCount++;
      }

      final ts = b['created_at'] ?? b['createdAt'];
      final date = ts is Timestamp ? ts.toDate() : DateTime.now();
      history.add(
        _BookingHistoryItem(
          id: doc.id.length > 4
              ? doc.id.substring(doc.id.length - 4).toUpperCase()
              : doc.id.toUpperCase(),
          tour: (b['tourName'] ?? b['tour_title'] ?? 'Tour').toString(),
          date: date,
          amount: amountValue,
          status: status,
        ),
      );
    }

    history.sort((a, b) => b.date.compareTo(a.date));
    final cancelRate = bookings == 0 ? 0.0 : (cancelled / bookings * 100);
    final avgRating = ratingCount == 0 ? 4.2 : totalRating / ratingCount;
    return _UserInsights(
      totalBookings: bookings,
      totalSpent: totalSpent,
      cancelRate: cancelRate,
      avgRating: avgRating,
      bookingHistory: history.take(5).toList(),
    );
  }

  Future<void> _generateProfilePDF(
    Map<String, dynamic> d,
    _UserInsights insights,
  ) async {
    final now = DateTime.now();
    final f = NumberFormat('#,##0');
    final name = _userDisplayName(d);
    final email = d['email']?.toString() ?? '—';
    final role = (d['role'] ?? 'customer').toString();
    final status = (d['isActive'] ?? true) ? 'Active' : 'Inactive';
    final joinedTs = d['createdAt'] as Timestamp?;
    final joined = joinedTs != null
        ? DateFormat('yyyy-MM-dd').format(joinedTs.toDate())
        : '—';

    final pdf = pw.Document(title: 'User Report - $name');
    pdf.addPage(
      pw.MultiPage(
        margin: const pw.EdgeInsets.all(26),
        footer: (context) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            'Generated ${DateFormat('yyyy-MM-dd HH:mm').format(now)}   Page ${context.pageNumber}/${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
          ),
        ),
        build: (context) => [
          pw.Container(
            padding: const pw.EdgeInsets.all(14),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromHex('#FFD40D'),
              borderRadius: pw.BorderRadius.circular(10),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Bambare User Profile Report',
                  style: pw.TextStyle(
                    fontSize: 19,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColor.fromHex('#1B1B2F'),
                  ),
                ),
                pw.Text(
                  role.toUpperCase(),
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColor.fromHex('#1B1B2F'),
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 16),
          pw.Text(name,
              style:
                  pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
          pw.Text(email,
              style:
                  const pw.TextStyle(fontSize: 11, color: PdfColors.grey700)),
          pw.SizedBox(height: 10),
          pw.Row(
            children: [
              _pdfMetric('Bookings', '${insights.totalBookings}'),
              pw.SizedBox(width: 8),
              _pdfMetric('Total Spent', 'LKR ${f.format(insights.totalSpent)}'),
              pw.SizedBox(width: 8),
              _pdfMetric(
                  'Cancel Rate', '${insights.cancelRate.toStringAsFixed(0)}%'),
              pw.SizedBox(width: 8),
              _pdfMetric('Avg Rating', insights.avgRating.toStringAsFixed(1)),
            ],
          ),
          pw.SizedBox(height: 16),
          pw.Text('Profile Information',
              style:
                  pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 6),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.7),
            children: [
              _pdfRow('Full Name', name),
              _pdfRow('Email', email),
              _pdfRow(
                  'Phone', (d['phoneNumber'] ?? d['phone'] ?? '—').toString()),
              _pdfRow('Location',
                  (d['location'] ?? d['address'] ?? '—').toString()),
              _pdfRow('Joined Date', joined),
              _pdfRow('Account Status', status),
            ],
          ),
          pw.SizedBox(height: 16),
          pw.Text('Recent Booking History',
              style:
                  pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 6),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.7),
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                children: [
                  _pdfCell('ID', true),
                  _pdfCell('Tour', true),
                  _pdfCell('Date', true),
                  _pdfCell('Amount', true),
                  _pdfCell('Status', true),
                ],
              ),
              ...insights.bookingHistory.map(
                (h) => pw.TableRow(
                  children: [
                    _pdfCell(h.id, false),
                    _pdfCell(h.tour, false),
                    _pdfCell(DateFormat('yyyy-MM-dd').format(h.date), false),
                    _pdfCell('LKR ${f.format(h.amount)}', false),
                    _pdfCell(h.status, false),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );

    final bytes = await pdf.save();
    final filename =
        'Bambare_User_Report_${name.replaceAll(' ', '_')}_${DateFormat('yyyyMMdd_HHmm').format(now)}.pdf';
    if (kIsWeb) {
      final blob = html.Blob([bytes], 'application/pdf');
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..style.display = 'none'
        ..download = filename;
      html.document.body?.children.add(anchor);
      anchor.click();
      anchor.remove();
      html.Url.revokeObjectUrl(url);
    } else {
      await Printing.layoutPdf(
        name: filename,
        onLayout: (PdfPageFormat format) async => bytes,
      );
    }
  }

  pw.TableRow _pdfRow(String label, String value) {
    return pw.TableRow(
      children: [
        _pdfCell(label, true),
        _pdfCell(value, false),
      ],
    );
  }

  pw.Widget _pdfCell(String text, bool header) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 9,
          fontWeight: header ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  pw.Widget _pdfMetric(String label, String value) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(8),
        decoration: pw.BoxDecoration(
          borderRadius: pw.BorderRadius.circular(8),
          border: pw.Border.all(color: PdfColors.grey300),
        ),
        child: pw.Column(
          children: [
            pw.Text(value,
                style:
                    pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 2),
            pw.Text(label,
                style:
                    const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
          ],
        ),
      ),
    );
  }

  void _showUserDetails(String userId, Map<String, dynamic> d) {
    showDialog(
      context: context,
      builder: (context) {
        final name = _userDisplayName(d);
        final email = d['email']?.toString() ?? '—';
        final role = (d['role'] ?? 'customer').toString();
        final photoUrl = _userPhotoUrl(d);
        final initials = _userInitials(name, email);
        final username =
            (d['username'] ?? '@${name.toLowerCase().replaceAll(' ', '')}')
                .toString();
        final phone = (d['phoneNumber'] ?? d['phone'] ?? '—').toString();
        final location = (d['location'] ?? d['address'] ?? '—').toString();
        final gender = (d['gender'] ?? '—').toString();
        final joinedTs = d['createdAt'] as Timestamp?;
        final joined = joinedTs != null
            ? DateFormat('yyyy-MM-dd').format(joinedTs.toDate())
            : '—';
        final isActive = (d['isActive'] ?? true) == true;

        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: 640,
            constraints: const BoxConstraints(maxHeight: 780),
            decoration: BoxDecoration(
              color: const Color(0xFFF4F5F7),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE4E7EB)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: FutureBuilder<_UserInsights>(
              future: _fetchUserInsights(userId, d),
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(30),
                      child:
                          CircularProgressIndicator(color: BrandColors.accent),
                    ),
                  );
                }
                final stats = snap.data!;
                return Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 74,
                                  height: 74,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF8E67FF),
                                        Color(0xFF6E4EE6)
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  child: _UserTableAvatar(
                                    photoUrl: photoUrl,
                                    initials: initials,
                                    isAdmin: role == 'admin',
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        name,
                                        style: GoogleFonts.dmSans(
                                          fontSize: 32,
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFF171923),
                                        ),
                                      ),
                                      Text(
                                        '$username · $email',
                                        style: GoogleFonts.dmSans(
                                            fontSize: 14,
                                            color: const Color(0xFF667085)),
                                      ),
                                      const SizedBox(height: 8),
                                      Wrap(
                                        spacing: 8,
                                        children: [
                                          _pill(
                                              role[0].toUpperCase() +
                                                  role.substring(1),
                                              const Color(0xFFDCE9FF),
                                              const Color(0xFF2D6CDF)),
                                          _pill(
                                              isActive ? 'Active' : 'Inactive',
                                              const Color(0xFFDAF4E7),
                                              const Color(0xFF0A9B5B)),
                                          _pill(
                                              'USR-${userId.length >= 3 ? userId.substring(userId.length - 3).toUpperCase() : userId.toUpperCase()}',
                                              const Color(0xFFFFF1CD),
                                              const Color(0xFFD58C00)),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                _statCard('${stats.totalBookings}', 'Bookings',
                                    const Color(0xFF171923)),
                                const SizedBox(width: 8),
                                _statCard(
                                    'LKR ${NumberFormat('#,##0').format(stats.totalSpent)}',
                                    'Total Spent',
                                    const Color(0xFF0A9B5B)),
                                const SizedBox(width: 8),
                                _statCard(
                                    '${stats.cancelRate.toStringAsFixed(0)}%',
                                    'Cancel Rate',
                                    const Color(0xFFE02424)),
                                const SizedBox(width: 8),
                                _statCard(
                                    '★ ${stats.avgRating.toStringAsFixed(1)}',
                                    'Avg Rating',
                                    const Color(0xFFD58C00)),
                              ],
                            ),
                            const SizedBox(height: 16),
                            const Divider(color: Color(0xFFD7DBE0)),
                            const SizedBox(height: 10),
                            Text('PERSONAL INFORMATION',
                                style: GoogleFonts.dmSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.2,
                                    color: const Color(0xFF98A2B3))),
                            const SizedBox(height: 10),
                            Wrap(
                              runSpacing: 10,
                              spacing: 10,
                              children: [
                                _infoCard('Full Name', name),
                                _infoCard('Username', username),
                                _infoCard('Email Address', email),
                                _infoCard('Phone Number', phone),
                                _infoCard('Location', location),
                                _infoCard('Gender', gender),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Text('ACCOUNT DETAILS',
                                style: GoogleFonts.dmSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.2,
                                    color: const Color(0xFF98A2B3))),
                            const SizedBox(height: 10),
                            Wrap(
                              runSpacing: 10,
                              spacing: 10,
                              children: [
                                _infoCard('Joined Date', joined),
                                _infoCard(
                                    'Last Login',
                                    (d['lastLogin'] ?? d['last_login'] ?? '—')
                                        .toString()),
                                _infoCard('Role',
                                    role[0].toUpperCase() + role.substring(1)),
                                _infoCard('Account Status',
                                    isActive ? 'Active' : 'Inactive'),
                                _infoCard('Device / Browser',
                                    (d['device'] ?? '—').toString()),
                                _infoCard('App Version',
                                    (d['appVersion'] ?? '—').toString()),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Text('BOOKING HISTORY',
                                style: GoogleFonts.dmSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.2,
                                    color: const Color(0xFF98A2B3))),
                            const SizedBox(height: 8),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border:
                                    Border.all(color: const Color(0xFFE4E7EB)),
                              ),
                              child: Column(
                                children: [
                                  _historyHeader(),
                                  ...stats.bookingHistory.map(_historyRow),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      child: Row(
                        children: [
                          OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Close'),
                          ),
                          const Spacer(),
                          ElevatedButton.icon(
                            onPressed: () async {
                              await _generateProfilePDF(d, stats);
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content:
                                        Text('User profile PDF downloaded.')),
                              );
                            },
                            icon: const Icon(Icons.picture_as_pdf_outlined,
                                size: 16),
                            label: const Text('Export PDF Report'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: BrandColors.accent,
                              foregroundColor: BrandColors.onAccent,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
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
      },
    );
  }

  Widget _pill(String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(
        text,
        style: GoogleFonts.dmSans(
            fontSize: 12, fontWeight: FontWeight.w600, color: fg),
      ),
    );
  }

  Widget _statCard(String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFEDEFF2),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: GoogleFonts.dmSans(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              label,
              style: GoogleFonts.dmSans(
                  fontSize: 11, color: const Color(0xFF98A2B3)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoCard(String label, String value) {
    return SizedBox(
      width: 285,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFEDEFF2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label.toUpperCase(),
              style: GoogleFonts.dmSans(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF98A2B3),
              ),
            ),
            const SizedBox(height: 5),
            Text(
              value,
              style: GoogleFonts.dmSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF171923),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _historyHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          _historyCell('ID', true, 1),
          _historyCell('Tour', true, 3),
          _historyCell('Date', true, 2),
          _historyCell('Amount', true, 2),
          _historyCell('Status', true, 2),
        ],
      ),
    );
  }

  Widget _historyRow(_BookingHistoryItem h) {
    final statusColor = h.status.toLowerCase().contains('cancel')
        ? const Color(0xFFE02424)
        : (h.status.toLowerCase().contains('confirm')
            ? const Color(0xFF0A9B5B)
            : const Color(0xFFD58C00));
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Row(
        children: [
          _historyCell(h.id, false, 1),
          _historyCell(h.tour, false, 3),
          _historyCell(DateFormat('yyyy-MM-dd').format(h.date), false, 2),
          _historyCell(
              'LKR ${NumberFormat('#,##0').format(h.amount)}', false, 2),
          Expanded(
            flex: 2,
            child: Text(
              h.status,
              style: GoogleFonts.dmSans(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: statusColor,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _historyCell(String text, bool header, int flex) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        style: GoogleFonts.dmSans(
          fontSize: header ? 10 : 11,
          fontWeight: header ? FontWeight.w700 : FontWeight.w500,
          color: header ? const Color(0xFF98A2B3) : const Color(0xFF171923),
        ),
      ),
    );
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
                'User Management',
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
          child: StreamBuilder<QuerySnapshot>(
            stream: _query.snapshots(),
            builder: (context, snap) {
              if (!snap.hasData) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: BrandColors.accent,
                    strokeWidth: 2,
                  ),
                );
              }
              final docs = snap.data!.docs;
              return Padding(
                padding: const EdgeInsets.all(24),
                child: Container(
                  decoration: BoxDecoration(
                    color: c.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: c.border),
                  ),
                  child: Column(
                    children: [
                      // Header
                      Container(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: c.border,
                              width: 0.5,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Text(
                                'User',
                                style: GoogleFonts.dmSans(
                                  fontSize: 11,
                                  color: c.muted,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: Text(
                                'Email',
                                style: GoogleFonts.dmSans(
                                  fontSize: 11,
                                  color: c.muted,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                'Role',
                                style: GoogleFonts.dmSans(
                                  fontSize: 11,
                                  color: c.muted,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                'Joined',
                                style: GoogleFonts.dmSans(
                                  fontSize: 11,
                                  color: c.muted,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Text(
                                'Status',
                                style: GoogleFonts.dmSans(
                                  fontSize: 11,
                                  color: c.muted,
                                ),
                              ),
                            ),
                            const SizedBox(width: 56),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          itemCount: docs.length,
                          itemBuilder: (_, i) {
                            final d = docs[i].data() as Map<String, dynamic>;
                            final email = d['email']?.toString().trim() ?? '—';
                            final name = _userDisplayName(d);
                            final photoUrl = _userPhotoUrl(d);
                            final initials = _userInitials(name, email);
                            final role = d['role'] ?? 'customer';
                            final isActive = d['isActive'] ?? true;
                            final ts = d['createdAt'] as Timestamp?;
                            final joined = ts != null
                                ? '${ts.toDate().day}/${ts.toDate().month}/${ts.toDate().year}'
                                : '—';
                            final isAdmin = role == 'admin';

                            return Container(
                              padding: const EdgeInsets.fromLTRB(
                                16,
                                10,
                                16,
                                10,
                              ),
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    color: c.border,
                                    width: 0.5,
                                  ),
                                ),
                              ),
                              child: InkWell(
                                onTap: () => _showUserDetails(docs[i].id, d),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 3,
                                      child: Row(
                                        children: [
                                          _UserTableAvatar(
                                            photoUrl: photoUrl,
                                            initials: initials,
                                            isAdmin: isAdmin,
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              name,
                                              style: GoogleFonts.dmSans(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                                color: c.textPrimary,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      flex: 3,
                                      child: Text(
                                        email,
                                        style: GoogleFonts.dmSans(
                                          fontSize: 11,
                                          color: c.muted,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Align(
                                        alignment: Alignment.centerLeft,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 3,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isAdmin
                                                ? const Color(0xFFBC8CFF)
                                                    .withValues(alpha: 0.15)
                                                : const Color(0xFF58A6FF)
                                                    .withValues(alpha: 0.15),
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            role[0].toUpperCase() +
                                                role.substring(1),
                                            style: GoogleFonts.dmSans(
                                              fontSize: 10,
                                              color: isAdmin
                                                  ? const Color(0xFFBC8CFF)
                                                  : const Color(0xFF58A6FF),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        joined,
                                        style: GoogleFonts.dmSans(
                                          fontSize: 11,
                                          color: c.muted,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 1,
                                      child: Transform.scale(
                                        scale: 0.72,
                                        alignment: Alignment.centerLeft,
                                        child: Switch(
                                          materialTapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                          value: isActive,
                                          activeThumbColor: BrandColors.accent,
                                          activeTrackColor: BrandColors.accent
                                              .withValues(alpha: 0.35),
                                          onChanged: (_) => _toggleStatus(
                                            docs[i].id,
                                            isActive,
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      width: 56,
                                      child: Align(
                                        alignment: Alignment.center,
                                        child: IconButton(
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(
                                            minWidth: 44,
                                            minHeight: 44,
                                          ),
                                          icon: const Icon(
                                            Icons.delete_outline,
                                            size: 23,
                                            color: Color(0xFFF47067),
                                          ),
                                          onPressed: () =>
                                              _deleteUser(docs[i].id),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
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
      ],
    );
  }
}

class _UserTableAvatar extends StatelessWidget {
  const _UserTableAvatar({
    required this.photoUrl,
    required this.initials,
    required this.isAdmin,
  });

  final String? photoUrl;
  final String initials;
  final bool isAdmin;

  @override
  Widget build(BuildContext context) {
    final bgTint = isAdmin ? const Color(0xFFBC8CFF) : BrandColors.accent;
    final bgSoft = isAdmin
        ? const Color(0xFFBC8CFF).withValues(alpha: 0.2)
        : BrandColors.accent.withValues(alpha: 0.2);

    final placeholder = Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: bgSoft,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          initials,
          style: GoogleFonts.dmSans(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: bgTint,
          ),
        ),
      ),
    );

    final url = photoUrl;
    if (url == null || url.isEmpty) {
      return placeholder;
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 32,
        height: 32,
        child: Image.network(
          url,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => placeholder,
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: bgSoft,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: bgTint,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _UserInsights {
  final int totalBookings;
  final double totalSpent;
  final double cancelRate;
  final double avgRating;
  final List<_BookingHistoryItem> bookingHistory;

  const _UserInsights({
    required this.totalBookings,
    required this.totalSpent,
    required this.cancelRate,
    required this.avgRating,
    required this.bookingHistory,
  });
}

class _BookingHistoryItem {
  final String id;
  final String tour;
  final DateTime date;
  final double amount;
  final String status;

  const _BookingHistoryItem({
    required this.id,
    required this.tour,
    required this.date,
    required this.amount,
    required this.status,
  });
}
