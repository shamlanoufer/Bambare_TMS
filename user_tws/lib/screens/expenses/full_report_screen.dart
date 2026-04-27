import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../core/theme.dart';
import '../../models/expense.dart';
import '../../services/expense_service.dart';
import '../../utils/pdf_save.dart';

const _reportAccent = Color(0xFFFF8A1F);

(Color bg, IconData icon, Color accent) _categoryVisualFor(String category) {
  switch (category.toLowerCase()) {
    case 'food':
      return (const Color(0xFFFFF3EA), Icons.restaurant_rounded, _reportAccent);
    case 'transport':
      return (const Color(0xFFE9F1FF), Icons.directions_car_rounded, const Color(0xFF2E6BE6));
    case 'hotel':
      return (const Color(0xFFF0ECFF), Icons.apartment_rounded, const Color(0xFF7B61FF));
    case 'shopping':
      return (const Color(0xFFECF7EF), Icons.shopping_bag_rounded, const Color(0xFF2E7D32));
    case 'activities':
      return (const Color(0xFFFFF7DD), Icons.local_activity_rounded, const Color(0xFFF4B000));
    default:
      return (const Color(0xFFF1F5F9), Icons.receipt_long_rounded, const Color(0xFF6B7280));
  }
}

class FullReportScreen extends StatefulWidget {
  const FullReportScreen({super.key, required this.month});

  /// First day of the month.
  final DateTime month;

  @override
  State<FullReportScreen> createState() => _FullReportScreenState();
}

class _FullReportScreenState extends State<FullReportScreen> {
  static const _bg = Color(0xFFF7F8FA);
  static const _accent = _reportAccent;

  bool _exporting = false;

  bool _inMonth(Expense e, DateTime m) => e.spentAt.year == m.year && e.spentAt.month == m.month;

  String _monthTitleShort(DateTime d) {
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

  String _dayLabel(DateTime d) {
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
    return '${months[d.month - 1]} ${d.day}';
  }

  String _timeLabel(DateTime d) {
    final h = d.hour;
    final m = d.minute.toString().padLeft(2, '0');
    final ap = h >= 12 ? 'PM' : 'AM';
    final hh = (h % 12 == 0) ? 12 : (h % 12);
    return '$hh:$m $ap';
  }

  (Color bg, IconData icon, Color accent) _categoryVisual(String category) => _categoryVisualFor(category);

  (Color label, Color card) _statColor(String key) {
    switch (key) {
      case 'TOTAL':
        return (const Color(0xFFFF8A1F), const Color(0xFF2A2016));
      case 'AVG/TXN':
        return (const Color(0xFF2E6BE6), const Color(0xFF1B2230));
      case 'DAYS':
        return (const Color(0xFF7B61FF), const Color(0xFF241E33));
      case 'ENTRIES':
        return (const Color(0xFF2E7D32), const Color(0xFF1C2A20));
      default:
        return (Colors.white, Colors.black);
    }
  }

  String _normPay(String s) {
    final v = s.trim().toLowerCase();
    if (v.contains('card')) return 'Card';
    if (v.contains('cash')) return 'Cash';
    return s.trim().isEmpty ? 'Other' : s.trim();
  }

  Future<void> _exportPdf({
    required DateTime month,
    required double total,
    required double avgTxn,
    required int days,
    required int entries,
    required List<Expense> topExpenses,
    required List<({DateTime day, double total})> daily,
    required Map<String, ({int count, double total})> pay,
    required Map<String, List<Expense>> byCategory,
  }) async {
    if (_exporting) return;
    setState(() => _exporting = true);
    try {
      final doc = pw.Document();

      String titleMonth(DateTime d) {
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

      doc.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.fromLTRB(32, 32, 32, 32),
          build: (context) {
            const cardPad = pw.EdgeInsets.all(14);

            pw.Widget sectionTitle(String t) => pw.Row(
                  children: [
                    pw.Container(width: 6, height: 6, color: PdfColors.black),
                    pw.SizedBox(width: 8),
                    pw.Text(t, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                  ],
                );

            pw.Widget card({required pw.Widget child}) => pw.Container(
                  padding: cardPad,
                  decoration: const pw.BoxDecoration(color: PdfColors.white),
                  child: child,
                );

            pw.Widget statBox(String label, String value, PdfColor labelColor, PdfColor bg) {
              return pw.Expanded(
                child: pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  decoration: pw.BoxDecoration(color: bg),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        label,
                        style: pw.TextStyle(
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                          letterSpacing: 0.6,
                          color: labelColor,
                        ),
                      ),
                      pw.SizedBox(height: 6),
                      pw.Text(
                        value,
                        style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                      ),
                    ],
                  ),
                ),
              );
            }

            final dailyMax = daily.fold<double>(0, (m, it) => it.total > m ? it.total : m);
            final cardPay = pay[_normPay('card')] ?? pay['Card'] ?? (count: 0, total: 0.0);
            final cashPay = pay[_normPay('cash')] ?? pay['Cash'] ?? (count: 0, total: 0.0);
            final payTotal = pay.values.fold<double>(0, (a, v) => a + v.total);
            final cardPct = payTotal <= 0 ? 0.0 : (cardPay.total / payTotal).clamp(0.0, 1.0);
            final cashPct = payTotal <= 0 ? 0.0 : (cashPay.total / payTotal).clamp(0.0, 1.0);

            return [
              pw.Row(
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Full Report', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          titleMonth(month),
                          style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
                        ),
                      ],
                    ),
                  ),
                  pw.Text('Exported', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                ],
              ),
              pw.SizedBox(height: 14),
              pw.Row(
                children: [
                  statBox('TOTAL', 'LKR ${_fmtInt(total)}', PdfColors.orange, const PdfColor(0.16, 0.12, 0.08)),
                  pw.SizedBox(width: 8),
                  statBox('AVG/TXN', 'LKR ${_fmtInt(avgTxn)}', PdfColors.blue, const PdfColor(0.10, 0.13, 0.18)),
                  pw.SizedBox(width: 8),
                  statBox('DAYS', '$days days', PdfColors.deepPurple, const PdfColor(0.14, 0.12, 0.20)),
                  pw.SizedBox(width: 8),
                  statBox('ENTRIES', '$entries txns', PdfColors.green, const PdfColor(0.11, 0.17, 0.13)),
                ],
              ),
              pw.SizedBox(height: 14),
              card(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    sectionTitle('Top Expenses'),
                    pw.SizedBox(height: 10),
                    for (var i = 0; i < topExpenses.length; i++)
                      pw.Padding(
                        padding: const pw.EdgeInsets.only(bottom: 8),
                        child: pw.Row(
                          children: [
                            pw.Container(
                              width: 18,
                              height: 18,
                              alignment: pw.Alignment.center,
                              decoration: pw.BoxDecoration(
                                color: i == 0 ? PdfColors.orange : PdfColors.grey300,
                                shape: pw.BoxShape.circle,
                              ),
                              child: pw.Text(
                                '${i + 1}',
                                style: pw.TextStyle(
                                  fontSize: 9,
                                  fontWeight: pw.FontWeight.bold,
                                  color: i == 0 ? PdfColors.white : PdfColors.black,
                                ),
                              ),
                            ),
                            pw.SizedBox(width: 10),
                            pw.Expanded(
                              child: pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                  pw.Text(
                                    topExpenses[i].note.isEmpty ? topExpenses[i].category : topExpenses[i].note,
                                    style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
                                  ),
                                  pw.SizedBox(height: 2),
                                  pw.Text(
                                    '${topExpenses[i].category} · ${topExpenses[i].spentAt.year}-${topExpenses[i].spentAt.month.toString().padLeft(2, '0')}-${topExpenses[i].spentAt.day.toString().padLeft(2, '0')}',
                                    style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
                                  ),
                                ],
                              ),
                            ),
                            pw.SizedBox(width: 10),
                            pw.Text(
                              '-${_fmtInt(topExpenses[i].amount)}',
                              style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.red),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              pw.SizedBox(height: 14),
              card(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    sectionTitle('Daily Spend'),
                    pw.SizedBox(height: 12),
                    for (final d in daily) ...[
                      pw.Row(
                        children: [
                          pw.Expanded(
                            child: pw.Text(
                              '${d.day.month.toString().padLeft(2, '0')}-${d.day.day.toString().padLeft(2, '0')}',
                              style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
                            ),
                          ),
                          pw.Text('LKR ${_fmtInt(d.total)}', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                        ],
                      ),
                      pw.SizedBox(height: 6),
                      pw.Stack(
                        children: [
                          pw.Container(height: 6, color: PdfColors.grey200),
                          pw.Container(
                            height: 6,
                            width: (dailyMax <= 0 ? 0.0 : (440.0 * (d.total / dailyMax).clamp(0.0, 1.0))).toDouble(),
                            color: PdfColors.orange,
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 10),
                    ],
                  ],
                ),
              ),
              pw.SizedBox(height: 14),
              card(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    sectionTitle('Payment Methods'),
                    pw.SizedBox(height: 12),
                    pw.Row(
                      children: [
                        pw.Expanded(
                          child: pw.Container(
                            padding: const pw.EdgeInsets.all(10),
                            decoration: const pw.BoxDecoration(color: PdfColors.blue50),
                            child: pw.Column(
                              children: [
                                pw.Text('${cardPay.count} txns', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                                pw.SizedBox(height: 2),
                                pw.Text('LKR ${_fmtInt(cardPay.total)}', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                              ],
                            ),
                          ),
                        ),
                        pw.SizedBox(width: 10),
                        pw.Expanded(
                          child: pw.Container(
                            padding: const pw.EdgeInsets.all(10),
                            decoration: const pw.BoxDecoration(color: PdfColors.green50),
                            child: pw.Column(
                              children: [
                                pw.Text('${cashPay.count} txns', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                                pw.SizedBox(height: 2),
                                pw.Text('LKR ${_fmtInt(cashPay.total)}', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 10),
                    pw.Stack(
                      children: [
                        pw.Container(height: 8, color: PdfColors.grey200),
                        pw.Container(height: 8, width: (440.0 * cardPct).toDouble(), color: PdfColors.blue),
                        pw.Container(
                          height: 8,
                          width: (440.0 * cashPct).toDouble(),
                          margin: pw.EdgeInsets.only(left: (440.0 * cardPct).toDouble()),
                          color: PdfColors.green,
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 8),
                    pw.Row(
                      children: [
                        pw.Container(width: 6, height: 6, color: PdfColors.blue),
                        pw.SizedBox(width: 6),
                        pw.Text('Card ${(cardPct * 100).round()}%', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                        pw.SizedBox(width: 14),
                        pw.Container(width: 6, height: 6, color: PdfColors.green),
                        pw.SizedBox(width: 6),
                        pw.Text('Cash ${(cashPct * 100).round()}%', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 14),
              for (final entry in byCategory.entries) ...[
                card(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        children: [
                          pw.Expanded(
                            child: pw.Text(entry.key, style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
                          ),
                          pw.Text(
                            'LKR ${_fmtInt(entry.value.fold<double>(0, (a, e) => a + e.amount))}',
                            style: const pw.TextStyle(fontSize: 11),
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text('${entry.value.length} transactions', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                      pw.SizedBox(height: 10),
                      for (var i = 0; i < entry.value.length; i++) ...[
                        pw.Row(
                          children: [
                            pw.Expanded(
                              child: pw.Text(
                                entry.value[i].note.isEmpty ? entry.value[i].category : entry.value[i].note,
                                style: const pw.TextStyle(fontSize: 10),
                              ),
                            ),
                            pw.Text(
                              '-${_fmtInt(entry.value[i].amount)}',
                              style: const pw.TextStyle(fontSize: 10, color: PdfColors.red),
                            ),
                          ],
                        ),
                        if (i != entry.value.length - 1) ...[
                          pw.SizedBox(height: 6),
                          pw.Container(height: 1, color: PdfColors.grey200),
                          pw.SizedBox(height: 6),
                        ],
                      ],
                    ],
                  ),
                ),
                pw.SizedBox(height: 12),
              ],
            ];
          },
        ),
      );

      final bytes = await doc.save();
      final name = 'full_report_${month.year}_${month.month.toString().padLeft(2, '0')}';
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
    final month = widget.month;

    return Scaffold(
      backgroundColor: _bg,
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
            child: StreamBuilder<List<Expense>>(
              stream: svc.myExpensesStream(),
              builder: (context, snap) {
                final all = snap.data ?? const <Expense>[];
                final list = all.where((e) => _inMonth(e, month)).toList()
                  ..sort((a, b) => b.spentAt.compareTo(a.spentAt));

                final total = list.fold<double>(0, (a, e) => a + e.amount);
                final entries = list.length;
                final avgTxn = entries <= 0 ? 0.0 : (total / entries);
                final uniqueDays = list.map((e) => DateTime(e.spentAt.year, e.spentAt.month, e.spentAt.day)).toSet();
                final days = uniqueDays.length;

                final top = [...list]..sort((a, b) => b.amount.compareTo(a.amount));
                final top5 = top.take(5).toList();

                final byDay = <DateTime, double>{};
                for (final e in list) {
                  final d = DateTime(e.spentAt.year, e.spentAt.month, e.spentAt.day);
                  byDay[d] = (byDay[d] ?? 0) + e.amount;
                }
                final daily = byDay.entries
                    .map((e) => (day: e.key, total: e.value))
                    .toList()
                  ..sort((a, b) => a.day.compareTo(b.day));
                final maxDaily = daily.fold<double>(0, (m, it) => it.total > m ? it.total : m);

                final pay = <String, ({int count, double total})>{};
                for (final e in list) {
                  final k = _normPay(e.paymentMethod);
                  final prev = pay[k];
                  pay[k] = (
                    count: (prev?.count ?? 0) + 1,
                    total: (prev?.total ?? 0) + e.amount,
                  );
                }
                final cardPay = pay['Card'] ?? (count: 0, total: 0.0);
                final cashPay = pay['Cash'] ?? (count: 0, total: 0.0);
                final payTotal = pay.values.fold<double>(0, (a, v) => a + v.total);
                final cardPct = payTotal <= 0 ? 0.0 : (cardPay.total / payTotal).clamp(0.0, 1.0);
                final cashPct = payTotal <= 0 ? 0.0 : (cashPay.total / payTotal).clamp(0.0, 1.0);

                final byCategory = <String, List<Expense>>{};
                for (final e in list) {
                  byCategory.putIfAbsent(e.category, () => []).add(e);
                }
                for (final entry in byCategory.entries) {
                  entry.value.sort((a, b) => b.spentAt.compareTo(a.spentAt));
                }

                const catOrder = ['Food', 'Transport', 'Shopping', 'Activities', 'Hotel'];
                final catKeys = [
                  ...catOrder.where(byCategory.containsKey),
                  ...byCategory.keys.where((k) => !catOrder.contains(k)).toList()..sort(),
                ];

                return ListView(
                  padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
                  children: [
                    Row(
                      children: [
                        Material(
                          color: Colors.black.withValues(alpha: 0.12),
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
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Full Report',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  color: AppTheme.black,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _monthTitleShort(month),
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        FilledButton(
                          onPressed: _exporting
                              ? null
                              : () => _exportPdf(
                                    month: month,
                                    total: total,
                                    avgTxn: avgTxn,
                                    days: days,
                                    entries: entries,
                                    topExpenses: top5,
                                    daily: daily,
                                    pay: pay,
                                    byCategory: {for (final k in catKeys) k: byCategory[k] ?? const []},
                                  ),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.black.withValues(alpha: 0.78),
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
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _StatPill(
                            label: 'TOTAL',
                            value: 'LKR ${_fmtInt(total)}',
                            colors: _statColor('TOTAL'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _StatPill(
                            label: 'AVG/TXN',
                            value: 'LKR ${_fmtInt(avgTxn)}',
                            colors: _statColor('AVG/TXN'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _StatPill(
                            label: 'DAYS',
                            value: '$days days',
                            colors: _statColor('DAYS'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _StatPill(
                            label: 'ENTRIES',
                            value: '$entries txns',
                            colors: _statColor('ENTRIES'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _WhiteCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.emoji_events_rounded, size: 18, color: AppTheme.black),
                              const SizedBox(width: 8),
                              Text(
                                'Top Expenses',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                  color: AppTheme.black,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (top5.isEmpty)
                            Text(
                              'No expenses yet.',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.grey,
                              ),
                            )
                          else
                            for (var i = 0; i < top5.length; i++) ...[
                              _TopExpenseRow(
                                rank: i + 1,
                                expense: top5[i],
                                fmt: _fmtInt,
                              ),
                              if (i != top5.length - 1)
                                Divider(height: 18, color: Colors.black.withValues(alpha: 0.06)),
                            ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    _WhiteCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.bar_chart_rounded, size: 18, color: AppTheme.black),
                              const SizedBox(width: 8),
                              Text(
                                'Daily Spend',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                  color: AppTheme.black,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (daily.isEmpty)
                            Text(
                              'No expenses yet.',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.grey,
                              ),
                            )
                          else
                            for (final d in daily) ...[
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      _dayLabel(d.day),
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w900,
                                        color: AppTheme.black,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    'LKR ${_fmtInt(d.total)}',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w900,
                                      color: AppTheme.black,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(999),
                                child: LinearProgressIndicator(
                                  value: maxDaily <= 0 ? 0 : (d.total / maxDaily).clamp(0.0, 1.0),
                                  minHeight: 6,
                                  backgroundColor: Colors.black.withValues(alpha: 0.06),
                                  valueColor: const AlwaysStoppedAnimation<Color>(_accent),
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    _WhiteCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.credit_card_rounded, size: 18, color: AppTheme.black),
                              const SizedBox(width: 8),
                              Text(
                                'Payment Methods',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                  color: AppTheme.black,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _MiniPayCard(
                                  icon: Icons.credit_card_rounded,
                                  bg: const Color(0xFFE9F1FF),
                                  title: '${cardPay.count} txns',
                                  subtitle: 'LKR ${_fmtInt(cardPay.total)}',
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _MiniPayCard(
                                  icon: Icons.attach_money_rounded,
                                  bg: const Color(0xFFECF7EF),
                                  title: '${cashPay.count} txns',
                                  subtitle: 'LKR ${_fmtInt(cashPay.total)}',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: SizedBox(
                              height: 10,
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: (cardPct * 1000).round().clamp(0, 1000),
                                    child: Container(color: const Color(0xFF2E6BE6)),
                                  ),
                                  Expanded(
                                    flex: (cashPct * 1000).round().clamp(0, 1000),
                                    child: Container(color: const Color(0xFF11B76D)),
                                  ),
                                  Expanded(
                                    flex: (1000 - (cardPct * 1000).round().clamp(0, 1000) - (cashPct * 1000).round().clamp(0, 1000))
                                        .clamp(0, 1000),
                                    child: Container(color: Colors.black.withValues(alpha: 0.06)),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              _LegendDot(color: const Color(0xFF2E6BE6), label: 'Card ${(cardPct * 100).round()}%'),
                              const SizedBox(width: 14),
                              _LegendDot(color: const Color(0xFF11B76D), label: 'Cash ${(cashPct * 100).round()}%'),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    for (final cat in catKeys) ...[
                      Builder(
                        builder: (context) {
                          final items = byCategory[cat] ?? const <Expense>[];
                          final totalCat = items.fold<double>(0, (a, e) => a + e.amount);
                          final v = _categoryVisual(cat);
                          return _WhiteCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 38,
                                      height: 38,
                                      decoration: BoxDecoration(
                                        color: v.$1,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(v.$2, color: v.$3, size: 20),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            cat,
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w900,
                                              color: AppTheme.black,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${items.length} transactions',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: AppTheme.grey,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      'LKR ${_fmtInt(totalCat)}',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w900,
                                        color: v.$3,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                for (var i = 0; i < items.length; i++) ...[
                                  _TxnRow(
                                    title: (items[i].note.isEmpty ? items[i].category : items[i].note),
                                    subtitle: '${items[i].spentAt.year}-${items[i].spentAt.month.toString().padLeft(2, '0')}-${items[i].spentAt.day.toString().padLeft(2, '0')} · ${_timeLabel(items[i].spentAt)} · ${_normPay(items[i].paymentMethod)}',
                                    amount: items[i].amount,
                                    fmt: _fmtInt,
                                  ),
                                  if (i != items.length - 1)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                      child: Divider(height: 1, color: Colors.black.withValues(alpha: 0.06)),
                                    ),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 14),
                    ],
                    const SizedBox(height: 10),
                  ],
                );
              },
            ),
          ),
        ],
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

class _StatPill extends StatelessWidget {
  const _StatPill({required this.label, required this.value, required this.colors});

  final String label;
  final String value;
  final (Color label, Color card) colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colors.$2,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.6,
              color: colors.$1,
            ),
          ),
          const Spacer(),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _TopExpenseRow extends StatelessWidget {
  const _TopExpenseRow({
    required this.rank,
    required this.expense,
    required this.fmt,
  });

  final int rank;
  final Expense expense;
  final String Function(num) fmt;

  @override
  Widget build(BuildContext context) {
    final title = expense.note.isEmpty ? expense.category : expense.note;
    final sub = '${expense.category} · ${expense.spentAt.year}-${expense.spentAt.month.toString().padLeft(2, '0')}-${expense.spentAt.day.toString().padLeft(2, '0')}';
    final rankBg = switch (rank) {
      1 => const Color(0xFFFF8A1F),
      2 => const Color(0xFF111827),
      3 => const Color(0xFF111827),
      _ => Colors.black.withValues(alpha: 0.10),
    };
    final rankFg = rank <= 3 ? Colors.white : AppTheme.black;

    final (bg, icon, accent) = _categoryVisualFor(expense.category);
    return Row(
      children: [
        Container(
          width: 26,
          height: 26,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: rankBg, shape: BoxShape.circle),
          child: Text(
            '$rank',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: rankFg,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: accent, size: 20),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.black,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                sub,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.grey,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Text(
          '-${fmt(expense.amount)}',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            color: const Color(0xFFFF3B30),
          ),
        ),
      ],
    );
  }
}

class _MiniPayCard extends StatelessWidget {
  const _MiniPayCard({
    required this.icon,
    required this.bg,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final Color bg;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withValues(alpha: 0.03)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 18, color: AppTheme.black),
          const SizedBox(height: 10),
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: AppTheme.black,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppTheme.grey,
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: AppTheme.grey,
          ),
        ),
      ],
    );
  }
}

class _TxnRow extends StatelessWidget {
  const _TxnRow({
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.fmt,
  });

  final String title;
  final String subtitle;
  final double amount;
  final String Function(num) fmt;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.black,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.grey,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Text(
          '-${fmt(amount)}',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            color: const Color(0xFFFF3B30),
          ),
        ),
      ],
    );
  }
}

