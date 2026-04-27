import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:typed_data';

import '../../core/theme.dart';
import '../../models/expense.dart';
import '../../services/expense_service.dart';
import 'full_report_screen.dart';
import '../../utils/pdf_save.dart';

class MonthlyReportScreen extends StatefulWidget {
  const MonthlyReportScreen({super.key});

  @override
  State<MonthlyReportScreen> createState() => _MonthlyReportScreenState();
}

class _MonthlyReportScreenState extends State<MonthlyReportScreen> {
  static const _bg = Color(0xFFF7F8FA);
  static const _accent = Color(0xFFFF8A1F);

  late DateTime _month; // first day of month
  bool _exporting = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month, 1);
  }

  DateTime _addMonths(DateTime d, int delta) {
    return DateTime(d.year, d.month + delta, 1);
  }

  String _monthName(DateTime d) {
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
    return months[d.month - 1];
  }

  String _monthTitle(DateTime d) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[d.month - 1]} ${d.year}';
  }

  String _fmtInt(num n) {
    final s = n.round().abs().toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  (Color dot, Color bar) _catColor(String label) {
    switch (label.toLowerCase()) {
      case 'food':
        return (const Color(0xFFFF8A1F), const Color(0xFFFF8A1F));
      case 'transport':
        return (const Color(0xFF2E6BE6), const Color(0xFF2E6BE6));
      case 'hotel':
        return (const Color(0xFF7B61FF), const Color(0xFF7B61FF));
      case 'shopping':
        return (const Color(0xFF2E7D32), const Color(0xFF2E7D32));
      case 'activities':
        return (const Color(0xFFF4B000), const Color(0xFFF4B000));
      default:
        return (const Color(0xFF6B7280), const Color(0xFF6B7280));
    }
  }

  Future<void> _exportPdf({
    required DateTime month,
    required double total,
    required List<double> monthTotals,
    required List<({String label, double amount, double pct})> breakdown,
  }) async {
    if (_exporting) return;
    setState(() => _exporting = true);
    try {
      final doc = pw.Document();
      final title = '${_monthTitle(month)} Report';
      final totalStr = 'LKR ${_fmtInt(total)}';
      final pdfMonths = [
        _addMonths(month, -2),
        _addMonths(month, -1),
        month,
      ];

      PdfColor pdfColor(Color c) {
        final r = (c.r * 255.0).round().clamp(0, 255);
        final g = (c.g * 255.0).round().clamp(0, 255);
        final b = (c.b * 255.0).round().clamp(0, 255);
        return PdfColor(r / 255.0, g / 255.0, b / 255.0);
      }

      doc.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.fromLTRB(32, 32, 32, 32),
          build: (context) {
            const barMaxW = 460.0; // safe within A4 minus margins

            pw.Widget barRow({
              required String label,
              required double pct,
              required String amount,
              required PdfColor color,
            }) {
              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    children: [
                      pw.Container(
                        width: 6,
                        height: 6,
                        decoration: pw.BoxDecoration(
                          color: color,
                          shape: pw.BoxShape.circle,
                        ),
                      ),
                      pw.SizedBox(width: 8),
                      pw.Expanded(
                        child: pw.Text(
                          label,
                          style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      pw.Text(
                        '${(pct * 100).round()}%',
                        style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                      ),
                      pw.SizedBox(width: 10),
                      pw.SizedBox(
                        width: 64,
                        child: pw.Text(
                          amount,
                          textAlign: pw.TextAlign.right,
                          style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 6),
                  // Avoid rounded corners in PDF bars; some viewers render artifacts.
                  pw.Stack(
                    children: [
                      pw.Container(
                        width: barMaxW,
                        height: 6,
                        color: PdfColors.grey200,
                      ),
                      pw.Container(
                        width: (pct.clamp(0, 1) * barMaxW).toDouble(),
                        height: 6,
                        color: color,
                      ),
                    ],
                  ),
                ],
              );
            }

            final maxTotal = monthTotals.fold<double>(0, (a, b) => a > b ? a : b);

            return [
              pw.Text(
                title,
                style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 6),
              pw.Text('Colombo · Kandy · Galle', style: const pw.TextStyle(fontSize: 11)),
              pw.SizedBox(height: 18),
              pw.Container(
                padding: const pw.EdgeInsets.all(14),
                decoration: const pw.BoxDecoration(
                  color: PdfColors.grey900,
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'TOTAL SPENT',
                      style: pw.TextStyle(
                        fontSize: 10,
                        letterSpacing: 1.2,
                        color: PdfColors.grey300,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 6),
                    pw.Text(
                      totalStr,
                      style: pw.TextStyle(
                        fontSize: 26,
                        color: PdfColors.white,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 18),
              pw.Text(
                '3-Month Comparison',
                style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 10),
              pw.Row(
                children: [
                  for (var i = 0; i < monthTotals.length; i++) ...[
                    pw.Expanded(
                      child: pw.Container(
                        height: 44,
                        decoration: const pw.BoxDecoration(
                          color: PdfColors.grey300,
                        ),
                        child: pw.Align(
                          alignment: pw.Alignment.bottomCenter,
                          child: pw.Container(
                            height: maxTotal <= 0
                                ? 0
                                : (44 * (monthTotals[i] / maxTotal).clamp(0, 1)).toDouble(),
                            decoration: pw.BoxDecoration(
                              color: i == monthTotals.length - 1 ? PdfColors.orange : PdfColors.grey400,
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (i != monthTotals.length - 1) pw.SizedBox(width: 10),
                  ],
                ],
              ),
              pw.SizedBox(height: 8),
              pw.Row(
                children: [
                  for (var i = 0; i < pdfMonths.length; i++) ...[
                    pw.Expanded(
                      child: pw.Text(
                        _monthName(pdfMonths[i]),
                        textAlign: pw.TextAlign.center,
                        style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                      ),
                    ),
                    if (i != pdfMonths.length - 1) pw.SizedBox(width: 10),
                  ],
                ],
              ),
              pw.SizedBox(height: 18),
              pw.Text(
                'Breakdown by category',
                style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 10),
              for (final b in breakdown) ...[
                barRow(
                  label: b.label,
                  pct: b.pct,
                  amount: _fmtInt(b.amount),
                  color: pdfColor(_catColor(b.label).$1),
                ),
                pw.SizedBox(height: 12),
              ],
            ];
          },
        ),
      );

      final bytes = await doc.save();
      final name = 'monthly_report_${month.year}_${month.month.toString().padLeft(2, '0')}';
      final savedTo = await savePdfBytes(
        bytes: Uint8List.fromList(bytes),
        baseName: name,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              savedTo == null
                  ? 'Could not save PDF on this device'
                  : 'PDF saved: $savedTo',
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not export PDF. $e')),
      );
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final svc = ExpenseService();
    final months = [
      _addMonths(_month, -2),
      _addMonths(_month, -1),
      _month,
    ];

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        bottom: false,
        child: StreamBuilder<List<Expense>>(
          stream: svc.myExpensesStream(),
          builder: (context, snap) {
            final list = snap.data ?? const <Expense>[];

            bool inMonth(Expense e, DateTime m) =>
                e.spentAt.year == m.year && e.spentAt.month == m.month;

            double totalFor(DateTime m) => list
                .where((e) => inMonth(e, m))
                .fold<double>(0, (a, e) => a + e.amount);

            final curTotal = totalFor(_month);
            final monthTotals = months.map(totalFor).toList();
            final maxTotal = monthTotals.fold<double>(0, (a, b) => a > b ? a : b);

            final byCat = <String, double>{};
            for (final e in list.where((e) => inMonth(e, _month))) {
              byCat[e.category] = (byCat[e.category] ?? 0) + e.amount;
            }

            const order = ['Food', 'Transport', 'Hotel', 'Shopping', 'Activities'];
            final items = <({String label, double amount})>[
              for (final k in order) (label: k, amount: byCat[k] ?? 0),
            ];
            final spentPct = 60000.0 <= 0 ? 0.0 : (curTotal / 60000.0).clamp(0.0, 1.0);
            final breakdown = <({String label, double amount, double pct})>[
              for (final it in items)
                (label: it.label, amount: it.amount, pct: curTotal <= 0 ? 0 : (it.amount / curTotal)),
            ];

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
                    const Spacer(),
                    FilledButton(
                      onPressed: _exporting
                          ? null
                          : () => _exportPdf(
                                month: _month,
                                total: curTotal,
                                monthTotals: monthTotals,
                                breakdown: breakdown,
                              ),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.black.withValues(alpha: 0.80),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _exporting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
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
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1C1C1F),
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.14),
                        blurRadius: 18,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_monthTitle(_month)} Report',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Colombo · Kandy · Galle',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white.withValues(alpha: 0.65),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'TOTAL SPENT',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                          color: Colors.white.withValues(alpha: 0.65),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'LKR ${_fmtInt(curTotal)}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -0.8,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${(spentPct * 100).round()}% of LKR 60,000 budget spent',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white.withValues(alpha: 0.70),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _WhiteCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '3-Month Comparison',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.black,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          for (var i = 0; i < months.length; i++) ...[
                            Expanded(
                              child: Column(
                                children: [
                                  Container(
                                    height: 38,
                                    decoration: BoxDecoration(
                                      color: i == months.length - 1
                                          ? _accent
                                          : Colors.black.withValues(alpha: 0.10),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Align(
                                      alignment: Alignment.bottomCenter,
                                      child: FractionallySizedBox(
                                        heightFactor: maxTotal <= 0
                                            ? 0
                                            : (monthTotals[i] / maxTotal).clamp(0.0, 1.0),
                                        widthFactor: 1,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: i == months.length - 1
                                                ? _accent
                                                : Colors.black.withValues(alpha: 0.10),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    _monthName(months[i]),
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (i != months.length - 1) const SizedBox(width: 10),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _WhiteCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Breakdown by category',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.black,
                        ),
                      ),
                      const SizedBox(height: 12),
                      for (final it in items) ...[
                        _BreakdownRow(
                          label: it.label,
                          amount: it.amount,
                          pct: curTotal <= 0 ? 0 : (it.amount / curTotal),
                          dot: _catColor(it.label).$1,
                          bar: _catColor(it.label).$2,
                          fmt: _fmtInt,
                        ),
                        const SizedBox(height: 12),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  height: 54,
                  child: FilledButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => FullReportScreen(month: _month),
                        ),
                      );
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.black.withValues(alpha: 0.90),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Text(
                      'View Full Report',
                      style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w900, fontSize: 14),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _WhiteCard extends StatelessWidget {
  const _WhiteCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  const _BreakdownRow({
    required this.label,
    required this.amount,
    required this.pct,
    required this.dot,
    required this.bar,
    required this.fmt,
  });

  final String label;
  final double amount;
  final double pct;
  final Color dot;
  final Color bar;
  final String Function(num) fmt;

  @override
  Widget build(BuildContext context) {
    final percentLabel = '${(pct * 100).round()}%';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.black,
                ),
              ),
            ),
            Text(
              percentLabel,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppTheme.grey,
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 60,
              child: Text(
                fmt(amount),
                textAlign: TextAlign.right,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.black,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: pct.clamp(0.0, 1.0),
            minHeight: 6,
            backgroundColor: Colors.black.withValues(alpha: 0.06),
            valueColor: AlwaysStoppedAnimation<Color>(bar),
          ),
        ),
      ],
    );
  }
}

