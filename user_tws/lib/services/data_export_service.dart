import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/travel_document.dart';
import '../models/expense.dart';
import '../models/booking.dart';
import '../models/user_model.dart';

class DataExportService {
  DataExportService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _db = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  String? get _uid => _auth.currentUser?.uid;

  String _fallbackEmail() => _auth.currentUser?.email ?? '';
  String _fallbackPhone() => _auth.currentUser?.phoneNumber ?? '';
  String _fallbackName() =>
      _auth.currentUser?.displayName ?? _auth.currentUser?.email ?? '';

  ({String name, String email, String phone}) _fallbackFromBookings(
    List<Booking> bookings,
  ) {
    if (bookings.isEmpty) return (name: '', email: '', phone: '');
    // Most recent booking likely has lead details.
    final b = bookings.first;
    final name = (b.leadFirstName.isNotEmpty || b.leadLastName.isNotEmpty)
        ? '${b.leadFirstName} ${b.leadLastName}'.trim()
        : '';
    final email = b.email;
    final phone = b.phone;
    return (name: name, email: email, phone: phone);
  }

  Future<UserModel?> _loadUserProfile(String uid) async {
    final snap = await _db.collection('users').doc(uid).get();
    if (!snap.exists) return null;
    final d = snap.data();
    if (d == null) return null;
    return UserModel.fromMap(d);
  }

  Future<List<Booking>> _loadBookings(String uid) async {
    final q =
        await _db.collection('bookings').where('user_id', isEqualTo: uid).get();
    final list = q.docs.map((d) => Booking.fromDoc(d)).toList()
      ..sort((a, b) => b.travelDate.compareTo(a.travelDate));
    return list;
  }

  Future<List<Expense>> _loadExpenses(String uid) async {
    final q = await _db
        .collection('users')
        .doc(uid)
        .collection('expenses')
        .get();
    final list = q.docs.map((d) => Expense.fromDoc(d)).toList()
      ..sort((a, b) => b.spentAt.compareTo(a.spentAt));
    return list;
  }

  Future<List<TravelDocument>> _loadTravelDocs(String uid) async {
    final q = await _db
        .collection('users')
        .doc(uid)
        .collection('travel_documents')
        .get();
    final list = q.docs.map(TravelDocument.fromDoc).toList()
      ..sort((a, b) => a.expiryDate.compareTo(b.expiryDate));
    return list;
  }

  Future<List<String>> _loadSavedTourIds(String uid) async {
    final q = await _db
        .collection('users')
        .doc(uid)
        .collection('saved_tours')
        .get();
    final ids = q.docs.map((d) => d.id).toList()..sort();
    return ids;
  }

  String _fmtDate(DateTime d) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[d.month - 1]} ${d.day.toString().padLeft(2, '0')}, ${d.year}';
  }

  pw.Widget _h(String t) => pw.Text(
        t,
        style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
      );

  pw.Widget _kv(String k, String v) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 4),
        child: pw.Row(
          children: [
            pw.SizedBox(
              width: 120,
              child: pw.Text(
                k,
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.grey700,
                ),
              ),
            ),
            pw.Expanded(
              child: pw.Text(
                v.isEmpty ? '—' : v,
                style: const pw.TextStyle(fontSize: 10),
              ),
            ),
          ],
        ),
      );

  pw.Widget _cell(String t, {bool bold = false}) => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
        child: pw.Text(
          t.isEmpty ? '—' : t,
          maxLines: 2,
          style: pw.TextStyle(
            fontSize: 8.5,
            fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ),
      );

  Future<Uint8List> generateMyDataPdf() async {
    final uid = _uid;
    if (uid == null) throw 'Not signed in';

    final profile = await _loadUserProfile(uid);
    final bookings = await _loadBookings(uid);
    final expenses = await _loadExpenses(uid);
    final docs = await _loadTravelDocs(uid);
    final savedTourIds = await _loadSavedTourIds(uid);

    final now = DateTime.now();
    final pdf = pw.Document(title: 'My Data Export');

    // Background image (watermark)
    pw.ImageProvider? bgImage;
    try {
      final data = await rootBundle.load('images/home/4.png');
      bgImage = pw.MemoryImage(data.buffer.asUint8List());
    } catch (_) {
      bgImage = null;
    }

    final pageTheme = pw.PageTheme(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(32, 32, 32, 32),
      buildBackground: (context) {
        if (bgImage == null) return pw.SizedBox();
        return pw.Stack(
          children: [
            pw.Positioned.fill(
              child: pw.Opacity(
                opacity: 0.22,
                child: pw.Image(bgImage, fit: pw.BoxFit.cover),
              ),
            ),
          ],
        );
      },
    );

    // Cover page (always shows user details + background)
    final fromBookings = _fallbackFromBookings(bookings);
    final name = (profile?.fullName ?? '').trim().isNotEmpty
        ? profile!.fullName
        : (fromBookings.name.isNotEmpty ? fromBookings.name : _fallbackName());
    final email = (profile?.email ?? '').trim().isNotEmpty
        ? profile!.email
        : (fromBookings.email.isNotEmpty ? fromBookings.email : _fallbackEmail());
    final phone = (profile?.phone ?? '').trim().isNotEmpty
        ? profile!.phone
        : (fromBookings.phone.isNotEmpty ? fromBookings.phone : _fallbackPhone());

    pdf.addPage(
      pw.MultiPage(
        pageTheme: pageTheme,
        footer: (ctx) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            'Generated ${_fmtDate(now)}   Page ${ctx.pageNumber}/${ctx.pagesCount}',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
          ),
        ),
        build: (_) {
          return [
            // Cover block (merged to avoid blank gap)
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey900,
                borderRadius: pw.BorderRadius.circular(14),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Bambare Travel',
                        style: pw.TextStyle(
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'My Data Export',
                        style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.grey300,
                        ),
                      ),
                    ],
                  ),
                  pw.Text(
                    _fmtDate(now),
                    style: const pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.grey300,
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 12),
            pw.Container(
              padding: const pw.EdgeInsets.all(14),
              decoration: pw.BoxDecoration(
                color: PdfColors.white,
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: pw.BorderRadius.circular(14),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  _h('Account'),
                  pw.SizedBox(height: 6),
                  _kv('Name', name),
                  _kv('Email', email),
                  _kv('Phone', phone),
                  _kv('UID', uid),
                  pw.SizedBox(height: 10),
                  pw.Text(
                    'Included in this export',
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 6),
                  pw.Bullet(text: 'Saved tours (${savedTourIds.length})'),
                  pw.Bullet(text: 'Bookings history (${bookings.length})'),
                  pw.Bullet(text: 'Expenses (${expenses.length})'),
                  pw.Bullet(text: 'Travel documents (${docs.length})'),
                ],
              ),
            ),
            pw.NewPage(),
            _h('Personal details'),
            pw.SizedBox(height: 8),
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColors.white,
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: pw.BorderRadius.circular(12),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  _kv('Name', name),
                  _kv('Email', email),
                  _kv('Phone', phone),
                  _kv('NIC', profile?.nicNumber ?? ''),
                  _kv('DOB', profile?.dateOfBirth ?? ''),
                  _kv('District', profile?.district ?? ''),
                  _kv('Province', profile?.province ?? ''),
                  _kv('Address', profile?.personalAddress ?? ''),
                ],
              ),
            ),
            pw.SizedBox(height: 14),
            _h('Saved tours'),
            pw.SizedBox(height: 8),
            pw.Text(
              'Saved tours count: ${savedTourIds.length}',
              style: const pw.TextStyle(fontSize: 10),
            ),
            if (savedTourIds.isNotEmpty) ...[
              pw.SizedBox(height: 6),
              pw.Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final id in savedTourIds.take(40))
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.grey200,
                        borderRadius: pw.BorderRadius.circular(999),
                      ),
                      child: pw.Text(id, style: const pw.TextStyle(fontSize: 8)),
                    ),
                ],
              ),
            ],
            pw.SizedBox(height: 14),
            _h('Bookings history'),
            pw.SizedBox(height: 8),
            pw.Text(
              'Total bookings: ${bookings.length}',
              style: const pw.TextStyle(fontSize: 10),
            ),
            pw.SizedBox(height: 6),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.6),
              defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    _cell('TOUR', bold: true),
                    _cell('DATE', bold: true),
                    _cell('STATUS', bold: true),
                    _cell('AMOUNT', bold: true),
                  ],
                ),
                for (final b in bookings.take(30))
                  pw.TableRow(
                    children: [
                      _cell(b.tourTitle),
                      _cell(_fmtDate(b.travelDate)),
                      _cell(b.status),
                      _cell(b.formattedTotalPrice),
                    ],
                  ),
              ],
            ),
            pw.SizedBox(height: 14),
            _h('Expenses'),
            pw.SizedBox(height: 8),
            pw.Text(
              'Total entries: ${expenses.length}',
              style: const pw.TextStyle(fontSize: 10),
            ),
            pw.SizedBox(height: 6),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.6),
              defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    _cell('CATEGORY', bold: true),
                    _cell('AMOUNT', bold: true),
                    _cell('METHOD', bold: true),
                    _cell('DATE', bold: true),
                  ],
                ),
                for (final e in expenses.take(30))
                  pw.TableRow(
                    children: [
                      _cell(e.category),
                      _cell('${e.currency} ${e.amount.toStringAsFixed(0)}'),
                      _cell(e.paymentMethod),
                      _cell(_fmtDate(e.spentAt)),
                    ],
                  ),
              ],
            ),
            pw.SizedBox(height: 14),
            _h('Travel documents'),
            pw.SizedBox(height: 8),
            pw.Text(
              'Total documents: ${docs.length}',
              style: const pw.TextStyle(fontSize: 10),
            ),
            pw.SizedBox(height: 6),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.6),
              defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    _cell('TYPE', bold: true),
                    _cell('COUNTRY', bold: true),
                    _cell('FULL NAME', bold: true),
                    _cell('DOC NO.', bold: true),
                    _cell('EXPIRY', bold: true),
                  ],
                ),
                for (final d in docs.take(30))
                  pw.TableRow(
                    children: [
                      _cell(d.type),
                      _cell(d.issuingCountry),
                      _cell(d.fullName),
                      _cell(d.documentNo),
                      _cell(_fmtDate(d.expiryDate)),
                    ],
                  ),
              ],
            ),
          ];
        },
      ),
    );

    final bytes = await pdf.save();
    return Uint8List.fromList(bytes);
  }
}

