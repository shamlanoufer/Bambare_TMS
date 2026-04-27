import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:typed_data';

import '../../core/theme.dart';
import '../../models/travel_document.dart';
import '../../services/travel_document_service.dart';
import 'upsert_travel_document_screen.dart';
import '../../utils/pdf_save.dart';

class TravelDocumentsScreen extends StatefulWidget {
  const TravelDocumentsScreen({super.key});

  @override
  State<TravelDocumentsScreen> createState() => _TravelDocumentsScreenState();
}

class _TravelDocumentsScreenState extends State<TravelDocumentsScreen> {
  final _svc = TravelDocumentService();
  bool _exporting = false;

  String _fmtDateLong(DateTime d) {
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

  String _fmtDateShort(DateTime d) {
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  Future<void> _exportPdf(List<TravelDocument> docs) async {
    if (_exporting) return;
    setState(() => _exporting = true);
    try {
      final now = DateTime.now();
      const title = 'Travel Documents Report';
      final expiring = docs.where((d) => d.isExpiringSoon).toList()
        ..sort((a, b) => a.daysLeft.compareTo(b.daysLeft));
      final expired = docs.where((d) => d.isExpired).toList();

      final doc = pw.Document();

      PdfColor c(Color x) => PdfColor(x.r, x.g, x.b);

      pw.Widget pill(String t, PdfColor bg, PdfColor fg) => pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: pw.BoxDecoration(
              color: bg,
              borderRadius: pw.BorderRadius.circular(999),
            ),
            child: pw.Text(
              t,
              style: pw.TextStyle(
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
                color: fg,
              ),
            ),
          );

      pw.Widget kv(String k, String v) => pw.Row(
            children: [
              pw.Expanded(
                flex: 2,
                child: pw.Text(
                  k,
                  style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.grey700,
                  ),
                ),
              ),
              pw.Expanded(
                flex: 3,
                child: pw.Text(
                  v.isEmpty ? '—' : v,
                  style: const pw.TextStyle(fontSize: 10),
                ),
              ),
            ],
          );

      doc.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.fromLTRB(32, 28, 32, 32),
          build: (_) {
            final rows = <pw.TableRow>[
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                children: [
                  _pdfCell('TYPE', bold: true),
                  _pdfCell('COUNTRY', bold: true),
                  _pdfCell('FULL NAME', bold: true),
                  _pdfCell('DOC NO.', bold: true),
                  _pdfCell('ISSUE', bold: true),
                  _pdfCell('EXPIRY', bold: true),
                  _pdfCell('STATUS', bold: true),
                ],
              ),
              ...docs.map((d) {
                final status = d.isExpired
                    ? 'Expired'
                    : (d.isExpiringSoon ? 'Expiring (${d.daysLeft}d)' : 'Valid');
                return pw.TableRow(
                  children: [
                    _pdfCell(d.type),
                    _pdfCell(d.issuingCountry),
                    _pdfCell(d.fullName),
                    _pdfCell(d.documentNo),
                    _pdfCell(_fmtDateShort(d.issueDate)),
                    _pdfCell(_fmtDateShort(d.expiryDate)),
                    _pdfCell(status),
                  ],
                );
              }),
            ];

            return [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        title,
                        style: pw.TextStyle(
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Generated ${_fmtDateLong(now)}',
                        style: const pw.TextStyle(
                          fontSize: 10,
                          color: PdfColors.grey700,
                        ),
                      ),
                    ],
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.grey100,
                      border: pw.Border.all(color: PdfColors.grey300),
                      borderRadius: pw.BorderRadius.circular(12),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text('Total', style: const pw.TextStyle(fontSize: 9)),
                        pw.Text(
                          '${docs.length}',
                          style: pw.TextStyle(
                            fontSize: 16,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 14),
              pw.Row(
                children: [
                  pill('Valid: ${docs.length - expired.length}', PdfColors.green50,
                      PdfColors.green800),
                  pw.SizedBox(width: 8),
                  pill('Expiring: ${expiring.length}', PdfColors.orange50,
                      PdfColors.orange800),
                  pw.SizedBox(width: 8),
                  pill('Expired: ${expired.length}', PdfColors.red50,
                      PdfColors.red800),
                ],
              ),
              pw.SizedBox(height: 14),
              if (expiring.isNotEmpty) ...[
                pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    color: c(const Color(0xFFFFF1CD)),
                    borderRadius: pw.BorderRadius.circular(12),
                    border: pw.Border.all(color: c(const Color(0xFFFFD66B))),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Expiring soon',
                        style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      for (final d in expiring.take(5)) ...[
                        kv('• ${d.type}', '${d.issuingCountry} · ${d.daysLeft} days left'),
                        pw.SizedBox(height: 4),
                      ],
                    ],
                  ),
                ),
                pw.SizedBox(height: 14),
              ],
              pw.Text(
                'All documents',
                style:
                    pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 8),
              pw.Table(
                border: pw.TableBorder.all(
                  color: PdfColors.grey300,
                  width: 0.6,
                ),
                defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
                columnWidths: const {
                  0: pw.FlexColumnWidth(1.3),
                  1: pw.FlexColumnWidth(1.2),
                  2: pw.FlexColumnWidth(1.6),
                  3: pw.FlexColumnWidth(1.2),
                  4: pw.FlexColumnWidth(1.0),
                  5: pw.FlexColumnWidth(1.0),
                  6: pw.FlexColumnWidth(1.0),
                },
                children: rows,
              ),
            ];
          },
        ),
      );

      final bytes = await doc.save();
      final name =
          'travel_documents_${now.year}_${now.month.toString().padLeft(2, '0')}_${now.day.toString().padLeft(2, '0')}';
      final savedTo = await savePdfBytes(
        bytes: Uint8List.fromList(bytes),
        baseName: name,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            savedTo == null
                ? 'Could not save PDF on this device'
                : 'PDF saved: $savedTo',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('images/home/4.png', fit: BoxFit.cover),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withValues(alpha: 0.74),
                  Colors.white.withValues(alpha: 0.92),
                  Colors.white,
                ],
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: StreamBuilder<List<TravelDocument>>(
              stream: _svc.myDocsStream(),
              builder: (context, snap) {
                final docs = snap.data ?? const <TravelDocument>[];
                final expiring = docs.where((d) => d.isExpiringSoon).toList();

                return ListView(
                  padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
                  children: [
                    Row(
                      children: [
                        Material(
                          color: Colors.black.withValues(alpha: 0.10),
                          shape: const CircleBorder(),
                          child: IconButton(
                            onPressed: () => Navigator.of(context).maybePop(),
                            icon: const Icon(Icons.arrow_back_ios_new_rounded),
                            iconSize: 18,
                            color: AppTheme.black,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Travel Documents',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.black,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        FilledButton(
                          onPressed: _exporting ? null : () => _exportPdf(docs),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.black.withValues(alpha: 0.80),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _exporting
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  'Export PDF',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 12,
                                  ),
                                ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (expiring.isNotEmpty)
                      _ExpiringBanner(
                        label:
                            '${expiring.first.issuingCountry} ${expiring.first.type} expiring in ${expiring.first.daysLeft} days',
                      ),
                    if (expiring.isNotEmpty) const SizedBox(height: 12),
                    Text(
                      'My Documents · ${docs.length}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.black,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (docs.isEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(0, 40, 0, 60),
                        child: Column(
                          children: [
                            const Icon(Icons.folder_open_rounded,
                                size: 52, color: Color(0xFF9CA3AF)),
                            const SizedBox(height: 10),
                            Text(
                              'No documents yet.',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                color: AppTheme.black,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Tap “Add New Document” to create one.',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.grey,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      for (final d in docs) ...[
                        _DocCard(
                          doc: d,
                          onView: () => _showView(context, d),
                          onEdit: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => UpsertTravelDocumentScreen(
                                existing: d,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 52,
                      child: FilledButton.icon(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const UpsertTravelDocumentScreen(),
                          ),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFE8B800),
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        icon: const Icon(Icons.add_rounded),
                        label: Text(
                          'Add New Document',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showView(BuildContext context, TravelDocument d) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${d.type} · ${d.issuingCountry}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.black,
                ),
              ),
              const SizedBox(height: 10),
              _kv('Full Name', d.fullName),
              _kv('Document No.', d.documentNo),
              _kv('Issue Date', _fmtDate(d.issueDate)),
              _kv('Expiry Date', _fmtDate(d.expiryDate)),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: FilledButton(
                  onPressed: () => Navigator.pop(context),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.black.withValues(alpha: 0.90),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    'Close',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _kv(String k, String v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              k,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppTheme.grey,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              v.isEmpty ? '—' : v,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: AppTheme.black,
              ),
            ),
          ),
        ],
      ),
    );
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
}

class _ExpiringBanner extends StatelessWidget {
  const _ExpiringBanner({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFE8A3),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFFD66B)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Color(0xFF8A5B00)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF5A3E00),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

pw.Widget _pdfCell(String text, {bool bold = false}) {
  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
    child: pw.Text(
      text.isEmpty ? '—' : text,
      maxLines: 2,
      overflow: pw.TextOverflow.clip,
      style: pw.TextStyle(
        fontSize: 8.5,
        fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
      ),
    ),
  );
}

class _DocCard extends StatelessWidget {
  const _DocCard({
    required this.doc,
    required this.onView,
    required this.onEdit,
  });

  final TravelDocument doc;
  final VoidCallback onView;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final isExpired = doc.isExpired;
    final daysLeft = doc.daysLeft;
    final statusLabel = isExpired ? 'Expired' : 'Valid';
    final statusBg = isExpired ? const Color(0xFFFFD6D6) : const Color(0xFFDAF4E7);
    final statusFg = isExpired ? const Color(0xFFC62828) : const Color(0xFF0A9B5B);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(
                  _emojiForType(doc.type),
                  style: const TextStyle(fontSize: 18),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      doc.type,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.black,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      doc.issuingCountry,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.grey,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'EXPIRES',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.grey,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _shortDate(doc.expiryDate),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.black,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isExpired ? 'Expired' : '$daysLeft days left',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.grey,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _pill(statusLabel, statusBg, statusFg),
              const SizedBox(width: 8),
              if (doc.isExpiringSoon)
                _pill('Expiring', const Color(0xFFFFF1CD), const Color(0xFFD58C00)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _miniField('Full Name', doc.fullName),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _miniField('Document No.', _mask(doc.documentNo)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _miniField('Issue Date', _shortDate(doc.issueDate)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _miniField('Expiry Date', _shortDate(doc.expiryDate)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 42,
                  child: FilledButton(
                    onPressed: onView,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFFFD54F),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      'View Document',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 42,
                  child: OutlinedButton(
                    onPressed: onEdit,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.black,
                      backgroundColor: Colors.white,
                      side: BorderSide(
                        color: Colors.black.withValues(alpha: 0.12),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      'Edit',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniField(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 9,
              fontWeight: FontWeight.w900,
              color: AppTheme.grey,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value.isEmpty ? '—' : value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: AppTheme.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _pill(String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 10,
          fontWeight: FontWeight.w900,
          color: fg,
        ),
      ),
    );
  }

  String _mask(String s) {
    final t = s.trim();
    if (t.length <= 4) return t.isEmpty ? '—' : t;
    return '${t.substring(0, 2)}****${t.substring(t.length - 2)}';
  }

  String _shortDate(DateTime d) {
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

  String _emojiForType(String type) {
    switch (type.toLowerCase()) {
      case 'passport':
        return '📕';
      case 'national id':
        return '🪪';
      case 'visa':
        return '🛂';
      case 'travel insurance':
        return '🛡️';
      default:
        return '📄';
    }
  }
}

