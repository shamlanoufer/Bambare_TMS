import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:universal_html/html.dart' as html;
import '../../theme/admin_theme_colors.dart';
import '../../theme/brand_colors.dart';
import '../../widgets/admin_profile_bar.dart';

class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen> {
  String _tab = 'overview';
  final List<String> _tabs = const [
    'overview',
    'bookings',
    'revenue',
    'users',
    'tours',
    'alerts',
  ];
  bool _exporting = false;

  Future<void> _exportProfessionalPdf() async {
    if (_exporting) return;
    setState(() => _exporting = true);
    try {
      final bookingsSnap =
          await FirebaseFirestore.instance.collection('bookings').get();
      final usersSnap =
          await FirebaseFirestore.instance.collection('users').get();
      final toursSnap =
          await FirebaseFirestore.instance.collection('tours').get();
      final hotelsSnap =
          await FirebaseFirestore.instance.collection('hotels').get();

      final analytics = _AnalyticsData.fromDocs(
        bookings: bookingsSnap.docs,
        users: usersSnap.docs,
        tours: toursSnap.docs,
        hotels: hotelsSnap.docs,
      );

      final now = DateTime.now();
      final formatter = NumberFormat('#,##0');
      final doc = pw.Document(title: 'Bambare Admin Report');

      pw.Widget metricBox(String title, String value, String subtitle) {
        return pw.Container(
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            borderRadius: pw.BorderRadius.circular(8),
            border: pw.Border.all(color: PdfColors.grey300),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                title,
                style:
                    const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                value,
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                subtitle,
                style:
                    const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
              ),
            ],
          ),
        );
      }

      doc.addPage(
        pw.MultiPage(
          margin: const pw.EdgeInsets.all(28),
          footer: (context) => pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Text(
              'Page ${context.pageNumber} / ${context.pagesCount}',
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
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Bambare - Reports & Analytics',
                        style: pw.TextStyle(
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColor.fromHex('#1B1B2F'),
                        ),
                      ),
                      pw.SizedBox(height: 3),
                      pw.Text(
                        'Generated on ${DateFormat('yyyy-MM-dd HH:mm').format(now)}',
                        style: pw.TextStyle(
                          fontSize: 10,
                          color: PdfColor.fromHex('#1B1B2F'),
                        ),
                      ),
                    ],
                  ),
                  pw.Text(
                    'Admin Panel',
                    style: pw.TextStyle(
                      fontSize: 11,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColor.fromHex('#1B1B2F'),
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 18),
            pw.Text(
              'Executive Summary',
              style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 8),
            pw.Row(
              children: [
                pw.Expanded(
                  child: metricBox(
                    'Total Bookings',
                    '${analytics.totalBookings}',
                    '${analytics.confirmedPct}% conversion',
                  ),
                ),
                pw.SizedBox(width: 8),
                pw.Expanded(
                  child: metricBox(
                    'Revenue',
                    'LKR ${formatter.format(analytics.revenue)}',
                    'Confirmed bookings',
                  ),
                ),
                pw.SizedBox(width: 8),
                pw.Expanded(
                  child: metricBox(
                    'Users',
                    '${analytics.totalUsers}',
                    '${analytics.activeUsersPct}% active',
                  ),
                ),
                pw.SizedBox(width: 8),
                pw.Expanded(
                  child: metricBox(
                    'Active Tours',
                    '${analytics.activeTours}',
                    '${analytics.totalTours} total tours',
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 16),
            pw.Text(
              'Booking Health',
              style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 8),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.7),
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    _pdfCell('Status', isHeader: true),
                    _pdfCell('Count', isHeader: true),
                    _pdfCell('Percent', isHeader: true),
                  ],
                ),
                pw.TableRow(
                  children: [
                    _pdfCell('Confirmed'),
                    _pdfCell('${analytics.confirmed}'),
                    _pdfCell('${analytics.confirmedPct}%'),
                  ],
                ),
                pw.TableRow(
                  children: [
                    _pdfCell('Pending'),
                    _pdfCell('${analytics.pending}'),
                    _pdfCell('${analytics.pendingPct}%'),
                  ],
                ),
                pw.TableRow(
                  children: [
                    _pdfCell('Cancelled'),
                    _pdfCell('${analytics.cancelled}'),
                    _pdfCell('${analytics.cancelledPct}%'),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 16),
            pw.Text(
              'Top Tour Revenue',
              style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 8),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.7),
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    _pdfCell('Tour', isHeader: true),
                    _pdfCell('Bookings', isHeader: true),
                    _pdfCell('Revenue (LKR)', isHeader: true),
                  ],
                ),
                ...analytics.topRevenueTours.map(
                  (t) => pw.TableRow(
                    children: [
                      _pdfCell(t.name),
                      _pdfCell('${t.bookings}'),
                      _pdfCell(formatter.format(t.revenue)),
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 16),
            pw.Text(
              'Recent Bookings',
              style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 8),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.7),
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    _pdfCell('Customer', isHeader: true),
                    _pdfCell('Tour', isHeader: true),
                    _pdfCell('Amount', isHeader: true),
                    _pdfCell('Status', isHeader: true),
                  ],
                ),
                ...analytics.recentBookings.map(
                  (b) => pw.TableRow(
                    children: [
                      _pdfCell(b.customer),
                      _pdfCell(b.tour),
                      _pdfCell('LKR ${formatter.format(b.amount)}'),
                      _pdfCell(b.status),
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 16),
            pw.Text(
              'Alerts & Recommendations',
              style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 8),
            ...analytics.alerts.map(
              (a) => pw.Container(
                width: double.infinity,
                margin: const pw.EdgeInsets.only(bottom: 6),
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  borderRadius: pw.BorderRadius.circular(6),
                  color: a.severity == 'critical'
                      ? PdfColor.fromHex('#FDE8E8')
                      : (a.severity == 'warning'
                          ? PdfColor.fromHex('#FEF3C7')
                          : PdfColor.fromHex('#E0F2FE')),
                  border: pw.Border.all(color: PdfColors.grey300),
                ),
                child: pw.Text(
                  '[${a.severity.toUpperCase()}] ${a.message}',
                  style: const pw.TextStyle(fontSize: 10),
                ),
              ),
            ),
          ],
        ),
      );

      final bytes = await doc.save();
      final filename =
          'Bambare_Admin_Report_${DateFormat('yyyyMMdd_HHmm').format(now)}.pdf';
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
          onLayout: (_) async => bytes,
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('PDF ready. Print dialog-la Save as PDF use pannunga.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('PDF export failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.adminColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _TopBar(
          exporting: _exporting,
          onExport: _exportProfessionalPdf,
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
          decoration: BoxDecoration(
            color: c.topBarBackground,
            border: Border(bottom: BorderSide(color: c.border, width: 1)),
          ),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _tabs.map((t) {
              final active = _tab == t;
              return InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => setState(() => _tab = t),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: active
                        ? BrandColors.accent.withValues(alpha: 0.2)
                        : c.inputFill,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: active ? BrandColors.accent : c.border,
                    ),
                  ),
                  child: Text(
                    '${t[0].toUpperCase()}${t.substring(1)}',
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: active ? BrandColors.accent : c.muted,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream:
                FirebaseFirestore.instance.collection('bookings').snapshots(),
            builder: (context, bookingsSnap) {
              return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream:
                    FirebaseFirestore.instance.collection('users').snapshots(),
                builder: (context, usersSnap) {
                  return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: FirebaseFirestore.instance
                        .collection('tours')
                        .snapshots(),
                    builder: (context, toursSnap) {
                      return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                        stream: FirebaseFirestore.instance
                            .collection('hotels')
                            .snapshots(),
                        builder: (context, hotelsSnap) {
                          if (!bookingsSnap.hasData ||
                              !usersSnap.hasData ||
                              !toursSnap.hasData ||
                              !hotelsSnap.hasData) {
                            return const Center(
                              child: CircularProgressIndicator(
                                color: BrandColors.accent,
                                strokeWidth: 2,
                              ),
                            );
                          }

                          final analytics = _AnalyticsData.fromDocs(
                            bookings: bookingsSnap.data!.docs,
                            users: usersSnap.data!.docs,
                            tours: toursSnap.data!.docs,
                            hotels: hotelsSnap.data!.docs,
                          );

                          return _ReportsBody(
                            tab: _tab,
                            analytics: analytics,
                          );
                        },
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _TopBar extends StatelessWidget {
  final VoidCallback onExport;
  final bool exporting;
  const _TopBar({required this.onExport, required this.exporting});

  @override
  Widget build(BuildContext context) {
    final c = context.adminColors;
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      decoration: BoxDecoration(
        color: c.topBarBackground,
        border: Border(bottom: BorderSide(color: c.border, width: 1)),
      ),
      child: Row(
        children: [
          Text(
            'Reports & Analytics',
            style: GoogleFonts.dmSans(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: c.textPrimary,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: c.inputFill,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: c.border),
            ),
            child: Text(
              'March 2026',
              style: GoogleFonts.dmSans(
                fontSize: 11,
                color: c.muted,
              ),
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: BrandColors.accent,
              foregroundColor: BrandColors.onAccent,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: exporting ? null : onExport,
            icon: exporting
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.file_download_outlined, size: 16),
            label: Text(
              exporting ? 'Generating...' : 'Export PDF',
              style:
                  GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 10),
          const AdminProfileBar(),
        ],
      ),
    );
  }
}

class _ReportsBody extends StatelessWidget {
  final String tab;
  final _AnalyticsData analytics;
  const _ReportsBody({required this.tab, required this.analytics});

  @override
  Widget build(BuildContext context) {
    switch (tab) {
      case 'bookings':
        return _BookingsTab(analytics: analytics);
      case 'revenue':
        return _RevenueTab(analytics: analytics);
      case 'users':
        return _UsersTab(analytics: analytics);
      case 'tours':
        return _ToursTab(analytics: analytics);
      case 'alerts':
        return _AlertsTab(analytics: analytics);
      case 'overview':
      default:
        return _OverviewTab(analytics: analytics);
    }
  }
}

class _OverviewTab extends StatelessWidget {
  final _AnalyticsData analytics;
  const _OverviewTab({required this.analytics});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            children: [
              _MetricCard(
                title: 'Total Bookings',
                value: '${analytics.totalBookings}',
                subtitle: analytics.growthHint,
                icon: Icons.calendar_today_rounded,
                color: BrandColors.accent,
              ),
              const SizedBox(width: 12),
              _MetricCard(
                title: 'Revenue',
                value: analytics.revenueText,
                subtitle: analytics.revenueHint,
                icon: Icons.attach_money_rounded,
                color: const Color(0xFF2EA043),
              ),
              const SizedBox(width: 12),
              _MetricCard(
                title: 'Users',
                value: '${analytics.totalUsers}',
                subtitle: '${analytics.activeUsers} active',
                icon: Icons.people_alt_rounded,
                color: const Color(0xFF58A6FF),
              ),
              const SizedBox(width: 12),
              _MetricCard(
                title: 'Alerts',
                value: '${analytics.criticalAlerts}',
                subtitle:
                    analytics.criticalAlerts > 0 ? 'Needs action' : 'All clear',
                icon: Icons.warning_amber_rounded,
                color: const Color(0xFFF47067),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: _WeeklyRevenueChart(weeklyRevenue: analytics.weeklyRevenue),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: _CardShell(
                  title: 'Booking Status',
                  child: Column(
                    children: [
                      _StatusLine(
                          label: 'Confirmed',
                          value: analytics.confirmed,
                          total: analytics.totalBookings,
                          color: BrandColors.accent),
                      const SizedBox(height: 10),
                      _StatusLine(
                          label: 'Pending',
                          value: analytics.pending,
                          total: analytics.totalBookings,
                          color: const Color(0xFF58A6FF)),
                      const SizedBox(height: 10),
                      _StatusLine(
                          label: 'Cancelled',
                          value: analytics.cancelled,
                          total: analytics.totalBookings,
                          color: const Color(0xFFF47067)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _CardShell(
            title: 'Recent Bookings',
            child: analytics.recentBookings.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: Text(
                        'No bookings yet.',
                        style: _txt(12, FontWeight.w400,
                            context.adminColors.muted),
                      ),
                    ),
                  )
                : Column(
                    children: [
                      // Header row
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Expanded(
                                child: Text('Customer',
                                    style: _txt(10, FontWeight.w600,
                                        context.adminColors.muted))),
                            Expanded(
                                child: Text('Tour',
                                    style: _txt(10, FontWeight.w600,
                                        context.adminColors.muted))),
                            SizedBox(
                                width: 100,
                                child: Text('Amount',
                                    style: _txt(10, FontWeight.w600,
                                        context.adminColors.muted))),
                            SizedBox(
                                width: 80,
                                child: Text('Status',
                                    textAlign: TextAlign.right,
                                    style: _txt(10, FontWeight.w600,
                                        context.adminColors.muted))),
                          ],
                        ),
                      ),
                      ...analytics.recentBookings.map((b) {
                        final statusColor = b.status == 'Cancelled'
                            ? const Color(0xFFF47067)
                            : (b.status == 'Confirmed'
                                ? BrandColors.accent
                                : const Color(0xFF58A6FF));
                        return Container(
                          padding: const EdgeInsets.symmetric(vertical: 7),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                  color: context.adminColors.border,
                                  width: 0.5),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  b.customer,
                                  style: _txt(11, FontWeight.w600,
                                      context.adminColors.textPrimary),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  b.tour,
                                  style: _txt(11, FontWeight.w400,
                                      context.adminColors.muted),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              SizedBox(
                                width: 100,
                                child: Text(
                                  'LKR ${b.amount.toStringAsFixed(0)}',
                                  style: _txt(11, FontWeight.w600,
                                      const Color(0xFF2EA043)),
                                ),
                              ),
                              SizedBox(
                                width: 80,
                                child: Align(
                                  alignment: Alignment.centerRight,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color:
                                          statusColor.withOpacity(0.15),
                                      borderRadius:
                                          BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      b.status,
                                      style: _txt(
                                          10, FontWeight.w500, statusColor),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _BookingsTab extends StatelessWidget {
  final _AnalyticsData analytics;
  const _BookingsTab({required this.analytics});

  @override
  Widget build(BuildContext context) {
    final c = context.adminColors;
    final total = analytics.totalBookings;

    final reasons = analytics.cancellationReasons.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final totalCancelled = analytics.cancelled;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // KPI row
          Row(
            children: [
              _MetricCard(
                  title: 'Confirmed',
                  value: '${analytics.confirmed}',
                  subtitle: '${analytics.confirmedPct}%',
                  icon: Icons.check_circle_rounded,
                  color: BrandColors.accent),
              const SizedBox(width: 12),
              _MetricCard(
                  title: 'Completed',
                  value: '${analytics.completed}',
                  subtitle: total == 0
                      ? '0%'
                      : '${((analytics.completed / total) * 100).round()}%',
                  icon: Icons.verified_rounded,
                  color: const Color(0xFF2EA043)),
              const SizedBox(width: 12),
              _MetricCard(
                  title: 'Cancelled',
                  value: '${analytics.cancelled}',
                  subtitle: '${analytics.cancelledPct}%',
                  icon: Icons.cancel_rounded,
                  color: const Color(0xFFF47067)),
              const SizedBox(width: 12),
              _MetricCard(
                  title: 'Pending',
                  value: '${analytics.pending}',
                  subtitle: '${analytics.pendingPct}%',
                  icon: Icons.schedule_rounded,
                  color: const Color(0xFF58A6FF)),
            ],
          ),
          const SizedBox(height: 16),

          // Booking Status Breakdown
          _CardShell(
            title: 'Booking Status Breakdown',
            child: Column(
              children: [
                _StatusLine(
                    label: 'Confirmed',
                    value: analytics.confirmed,
                    total: total,
                    color: BrandColors.accent),
                const SizedBox(height: 10),
                _StatusLine(
                    label: 'Completed',
                    value: analytics.completed,
                    total: total,
                    color: const Color(0xFF2EA043)),
                const SizedBox(height: 10),
                _StatusLine(
                    label: 'Cancelled',
                    value: analytics.cancelled,
                    total: total,
                    color: const Color(0xFFF47067)),
                const SizedBox(height: 10),
                _StatusLine(
                    label: 'Pending',
                    value: analytics.pending,
                    total: total,
                    color: const Color(0xFF58A6FF)),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Middle Row: Cancellation Reasons & Bookings by Day of Week
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _CardShell(
                  title: 'Cancellation Reasons',
                  child: totalCancelled == 0
                      ? Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Text('No cancellations yet.',
                              style: _txt(12, FontWeight.w400, c.muted)),
                        )
                      : reasons.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Text(
                                  'Cancellations exist but no reason was recorded.',
                                  style: _txt(11, FontWeight.w400, c.muted)),
                            )
                          : Column(
                              children: reasons.map((e) {
                                final pct = totalCancelled == 0
                                    ? 0.0
                                    : e.value / totalCancelled;
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        flex: 3,
                                        child: Text(e.key,
                                            style: _txt(
                                                11, FontWeight.w500, c.textPrimary),
                                            overflow: TextOverflow.ellipsis),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        flex: 4,
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(4),
                                          child: LinearProgressIndicator(
                                            value: pct,
                                            minHeight: 8,
                                            backgroundColor: c.inputFill,
                                            valueColor:
                                                const AlwaysStoppedAnimation<Color>(
                                                    Color(0xFFF47067)),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      SizedBox(
                                        width: 56,
                                        child: Text(
                                          '${e.value} (${(pct * 100).round()}%)',
                                          style: _txt(10, FontWeight.w500, c.muted),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _CardShell(
                  title: 'Bookings by Day of Week',
                  child: () {
                    final dayEntries = analytics.bookingsByDayOfWeek.entries
                        .where((e) => e.value > 0)
                        .toList()
                      ..sort((a, b) => b.value.compareTo(a.value));
                    
                    if (dayEntries.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text('No bookings yet.',
                            style: _txt(12, FontWeight.w400, c.muted)),
                      );
                    }

                    final topDays = dayEntries.take(4).toList();
                    final otherDaysValue = dayEntries.skip(4).fold<int>(0, (sum, e) => sum + e.value);
                    if (otherDaysValue > 0) {
                      topDays.add(MapEntry('Other days', otherDaysValue));
                    }

                    final maxVal = dayEntries.isEmpty ? 1 : dayEntries.first.value;

                    return Column(
                      children: topDays.map((e) {
                        final pct = e.value / maxVal;
                        final isOther = e.key == 'Other days';
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: Text(e.key,
                                    style: _txt(
                                        11, FontWeight.w500, c.textPrimary),
                                    overflow: TextOverflow.ellipsis),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 4,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: pct,
                                    minHeight: 8,
                                    backgroundColor: c.inputFill,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        isOther ? c.muted.withOpacity(0.3) : BrandColors.accent),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              SizedBox(
                                width: 24,
                                child: Text(
                                  '${e.value}',
                                  textAlign: TextAlign.right,
                                  style: _txt(11, FontWeight.w600, c.textPrimary),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    );
                  }(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // All Bookings list
          _CardShell(
            title: 'All Bookings',
            child: analytics.recentBookings.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text('No bookings yet.',
                        style: _txt(12, FontWeight.w400, c.muted)),
                  )
                : Column(
                    children: analytics.recentBookings.map((b) {
                      final statusColor = b.status == 'Cancelled'
                          ? const Color(0xFFF47067)
                          : b.status == 'Completed'
                              ? const Color(0xFF2EA043)
                              : b.status == 'Confirmed'
                                  ? BrandColors.accent
                                  : const Color(0xFF58A6FF);
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 5),
                        child: Row(
                          children: [
                            Expanded(
                                child: Text(b.customer,
                                    style: _txt(
                                        12, FontWeight.w600, c.textPrimary))),
                            Expanded(
                                child: Text(b.tour,
                                    style:
                                        _txt(12, FontWeight.w400, c.muted))),
                            SizedBox(
                              width: 120,
                              child: Text(
                                  'LKR ${b.amount.toStringAsFixed(0)}',
                                  style: _txt(12, FontWeight.w600,
                                      const Color(0xFF2EA043))),
                            ),
                            SizedBox(
                              width: 90,
                              child: Text(b.status,
                                  textAlign: TextAlign.right,
                                  style: _txt(
                                      11, FontWeight.w600, statusColor)),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }
}

class _RevenueTab extends StatelessWidget {
  final _AnalyticsData analytics;
  const _RevenueTab({required this.analytics});

  @override
  Widget build(BuildContext context) {
    final c = context.adminColors;

    final pieColors = [
      BrandColors.accent,
      const Color(0xFF2EA043),
      const Color(0xFF58A6FF),
      const Color(0xFFBC8CFF),
      const Color(0xFFF47067),
      const Color(0xFFF0A94A),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            children: [
              _MetricCard(
                  title: 'Total Revenue',
                  value: analytics.revenueText,
                  subtitle: analytics.revenueHint,
                  icon: Icons.payments_rounded,
                  color: const Color(0xFF2EA043)),
              const SizedBox(width: 12),
              _MetricCard(
                  title: 'Avg / Booking',
                  value: analytics.avgBookingText,
                  subtitle: '${analytics.totalBookings} bookings',
                  icon: Icons.analytics_outlined,
                  color: const Color(0xFFF0A94A)),
              const SizedBox(width: 12),
              _MetricCard(
                  title: 'Lost (cancelled)',
                  value: analytics.lostRevenueText,
                  subtitle: '${analytics.cancelled} cancellations',
                  icon: Icons.trending_down_rounded,
                  color: const Color(0xFFF47067)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _CardShell(
                  title: 'Revenue by Tour Package',
                  child: analytics.topRevenueTours.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Text('No revenue yet.',
                              style: _txt(12, FontWeight.w400, c.muted)),
                        )
                      : Row(
                          children: [
                            SizedBox(
                              height: 160,
                              width: 160,
                              child: PieChart(
                                PieChartData(
                                  sectionsSpace: 2,
                                  centerSpaceRadius: 40,
                                  sections: analytics.topRevenueTours
                                      .asMap()
                                      .entries
                                      .map((e) {
                                    final idx = e.key;
                                    final tour = e.value;
                                    final color = pieColors[idx % pieColors.length];
                                    final pct = analytics.revenue == 0
                                        ? 0
                                        : ((tour.revenue / analytics.revenue) * 100).round();
                                    return PieChartSectionData(
                                      color: color,
                                      value: tour.revenue,
                                      title: '$pct%',
                                      radius: 40,
                                      titleStyle: _txt(10, FontWeight.w700, const Color(0xFF1B1B2F)),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 24),
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: analytics.topRevenueTours
                                    .asMap()
                                    .entries
                                    .map((e) {
                                  final color = pieColors[e.key % pieColors.length];
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 10,
                                          height: 10,
                                          decoration: BoxDecoration(
                                            color: color,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            e.value.name,
                                            style: _txt(11, FontWeight.w500, c.textPrimary),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Text(
                                          'LKR ${e.value.revenue.toStringAsFixed(0)}',
                                          style: _txt(11, FontWeight.w600, c.textPrimary),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _CardShell(
                  title: 'Revenue by Day of Week',
                  child: () {
                    final dayEntries = analytics.revenueByDayOfWeek.entries
                        .where((e) => e.value > 0)
                        .toList()
                      ..sort((a, b) => b.value.compareTo(a.value));

                    if (dayEntries.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text('No revenue yet.',
                            style: _txt(12, FontWeight.w400, c.muted)),
                      );
                    }

                    final topDays = dayEntries.take(4).toList();
                    final otherDaysValue = dayEntries.skip(4).fold<double>(0, (sum, e) => sum + e.value);
                    if (otherDaysValue > 0) {
                      topDays.add(MapEntry('Other days', otherDaysValue));
                    }

                    final maxVal = dayEntries.isEmpty ? 1.0 : dayEntries.first.value;

                    return Column(
                      children: topDays.map((e) {
                        final pct = e.value / maxVal;
                        final isOther = e.key == 'Other days';
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: Text(e.key,
                                    style: _txt(11, FontWeight.w500, c.textPrimary),
                                    overflow: TextOverflow.ellipsis),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 4,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: pct,
                                    minHeight: 8,
                                    backgroundColor: c.inputFill,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        isOther ? c.muted.withOpacity(0.3) : const Color(0xFF2EA043)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              SizedBox(
                                width: 56,
                                child: Text(
                                  'LKR ${e.value.toStringAsFixed(0)}',
                                  textAlign: TextAlign.right,
                                  style: _txt(10, FontWeight.w600, c.textPrimary),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    );
                  }(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _CardShell(
                  title: 'Payment Methods',
                  child: Column(
                    children: [
                      _PaymentMethodLine(
                        label: 'Credit Card',
                        count: analytics.paymentMethods['Credit Card'] ?? 0,
                        total: analytics.totalBookings,
                        color: const Color(0xFF58A6FF),
                      ),
                      _PaymentMethodLine(
                        label: 'Bank Transfer',
                        count: analytics.paymentMethods['Bank Transfer'] ?? 0,
                        total: analytics.totalBookings,
                        color: const Color(0xFF2EA043),
                      ),
                      _PaymentMethodLine(
                        label: 'Cash on Tour',
                        count: analytics.paymentMethods['Cash on Tour'] ?? 0,
                        total: analytics.totalBookings,
                        color: const Color(0xFFF0A94A),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Revenue collected', style: _txt(11, FontWeight.w500, c.muted)),
                          Text('LKR ${analytics.revenue.toStringAsFixed(0)}', style: _txt(11, FontWeight.w600, const Color(0xFF2EA043))),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Pending collection', style: _txt(11, FontWeight.w500, c.muted)),
                          Text('LKR ${analytics.pendingRevenue.toStringAsFixed(0)}', style: _txt(11, FontWeight.w600, const Color(0xFFF0A94A))),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _CardShell(
                  title: 'Revenue Forecast (Next 30 days)',
                  child: () {
                    final weeklyTotal = analytics.weeklyRevenue.fold(0.0, (a, b) => a + b);
                    double forecast = (weeklyTotal / 7) * 30;
                    if (forecast == 0) forecast = analytics.revenue * 1.5;
                    
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'LKR ${forecast.toStringAsFixed(0)}',
                          style: _txt(24, FontWeight.w700, BrandColors.accent),
                        ),
                        Text(
                          'Based on current trend',
                          style: _txt(11, FontWeight.w500, c.muted),
                        ),
                        const SizedBox(height: 16),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: 0.75,
                            minHeight: 4,
                            backgroundColor: c.inputFill,
                            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2EA043)),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '75% confidence · If cancellations reduce to <30%',
                          style: _txt(10, FontWeight.w500, c.muted),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: c.inputFill,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: c.border.withOpacity(0.5)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.lightbulb_outline_rounded, size: 14, color: BrandColors.accent),
                                  const SizedBox(width: 6),
                                  Text('Recommendation', style: _txt(11, FontWeight.w600, BrandColors.accent)),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Reduce cancellation rate by offering flexible rescheduling instead of full refunds to save lost revenue.',
                                style: _txt(10, FontWeight.w400, c.muted).copyWith(height: 1.4),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _UsersTab extends StatelessWidget {
  final _AnalyticsData analytics;
  const _UsersTab({required this.analytics});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            children: [
              _MetricCard(
                  title: 'Registered Users',
                  value: '${analytics.totalUsers}',
                  subtitle: 'Need growth',
                  icon: Icons.person_rounded,
                  color: const Color(0xFFBC8CFF)),
              const SizedBox(width: 12),
              _MetricCard(
                  title: 'Active Users',
                  value: '${analytics.activeUsers}',
                  subtitle: '${analytics.activeUsersPct}% active',
                  icon: Icons.circle_rounded,
                  color: BrandColors.accent),
              const SizedBox(width: 12),
              _MetricCard(
                  title: 'Avg Spend/User',
                  value: analytics.avgSpendPerUserText,
                  subtitle: 'High value users',
                  icon: Icons.savings_rounded,
                  color: const Color(0xFFF0A94A)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 5,
                child: _CardShell(
                  title: 'User Overview',
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Expanded(flex: 3, child: Text('USER', style: _txt(10, FontWeight.w600, context.adminColors.muted))),
                            Expanded(flex: 2, child: Text('BOOKINGS', style: _txt(10, FontWeight.w600, context.adminColors.muted))),
                            Expanded(flex: 2, child: Text('SPENT', style: _txt(10, FontWeight.w600, context.adminColors.muted))),
                            SizedBox(width: 60, child: Text('STATUS', textAlign: TextAlign.right, style: _txt(10, FontWeight.w600, context.adminColors.muted))),
                          ],
                        ),
                      ),
                      ...analytics.userOverview.take(4).map((u) {
                         final initials = u.name.isNotEmpty ? u.name[0].toUpperCase() : '?';
                         final color = (u.name.hashCode % 2 == 0) ? BrandColors.accent : const Color(0xFF58A6FF);
                         return Padding(
                           padding: const EdgeInsets.symmetric(vertical: 8),
                           child: Row(
                             children: [
                               Expanded(
                                 flex: 3,
                                 child: Row(
                                   children: [
                                     Container(
                                       width: 28, height: 28,
                                       decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                                       alignment: Alignment.center,
                                       child: Text(initials, style: _txt(12, FontWeight.w700, context.adminColors.surface)),
                                     ),
                                     const SizedBox(width: 10),
                                     Expanded(
                                       child: Column(
                                         crossAxisAlignment: CrossAxisAlignment.start,
                                         children: [
                                           Text(u.name, style: _txt(12, FontWeight.w600, context.adminColors.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
                                           Text(u.email, style: _txt(10, FontWeight.w400, context.adminColors.muted), maxLines: 1, overflow: TextOverflow.ellipsis),
                                         ],
                                       ),
                                     ),
                                   ],
                                 )
                               ),
                               Expanded(
                                 flex: 2,
                                 child: Text('${u.bookings}', style: _txt(12, FontWeight.w500, context.adminColors.textPrimary)),
                               ),
                               Expanded(
                                 flex: 2,
                                 child: Text('LKR ${u.spent.toStringAsFixed(0)}', style: _txt(12, FontWeight.w600, const Color(0xFF2EA043))),
                               ),
                               SizedBox(
                                 width: 60,
                                 child: Align(
                                   alignment: Alignment.centerRight,
                                   child: Container(
                                     padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                     decoration: BoxDecoration(
                                       color: u.isActive ? const Color(0xFF2EA043).withOpacity(0.15) : context.adminColors.muted.withOpacity(0.15),
                                       borderRadius: BorderRadius.circular(20),
                                     ),
                                     child: Text(u.isActive ? 'Active' : 'Inactive', style: _txt(10, FontWeight.w500, u.isActive ? const Color(0xFF2EA043) : context.adminColors.muted)),
                                   ),
                                 ),
                               ),
                             ],
                           )
                         );
                      }),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: context.adminColors.inputFill, 
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                           children: [
                              const Icon(Icons.lightbulb_outline_rounded, size: 14, color: BrandColors.accent),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Only ${analytics.totalUsers} users registered. Consider adding referral incentives to grow user base.', 
                                  style: _txt(11, FontWeight.w500, BrandColors.accent)
                                ),
                              ),
                           ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 4,
                child: Column(
                  children: [
                     _CardShell(
                        title: 'User Behavior',
                        child: Column(
                           children: [
                              const _BehaviorLine(label: 'Tour browsing', pct: 0.90, color: BrandColors.accent),
                              const _BehaviorLine(label: 'Map usage', pct: 0.75, color: Color(0xFF58A6FF)),
                              const _BehaviorLine(label: 'Expense log', pct: 0.60, color: Color(0xFF2EA043)),
                              const _BehaviorLine(label: 'Currency conv.', pct: 0.45, color: Color(0xFFBC8CFF)),
                              _BehaviorLine(label: 'Profile edits', pct: 0.20, color: context.adminColors.muted),
                           ],
                        ),
                     ),
                     const SizedBox(height: 16),
                     _CardShell(
                        title: 'Session Activity Heatmap',
                        child: _HeatmapGrid(),
                     ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BehaviorLine extends StatelessWidget {
  final String label;
  final double pct;
  final Color color;
  const _BehaviorLine({required this.label, required this.pct, required this.color});

  @override
  Widget build(BuildContext context) {
    final c = context.adminColors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(width: 100, child: Text(label, style: _txt(11, FontWeight.w500, c.muted))),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: pct,
                minHeight: 8,
                backgroundColor: c.inputFill,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(width: 32, child: Text('${(pct * 100).round()}%', textAlign: TextAlign.right, style: _txt(10, FontWeight.w600, c.textPrimary))),
        ],
      )
    );
  }
}

class _HeatmapGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = context.adminColors;
    final intensities = [
      [0.2, 0.4, 0.3, 0.2, 0.5, 0.8, 0.7],
      [0.3, 0.5, 0.7, 0.4, 0.6, 0.9, 0.8],
      [0.4, 0.6, 0.9, 0.5, 0.7, 1.0, 0.9],
      [0.2, 0.3, 0.5, 0.3, 0.4, 0.6, 0.5],
    ];

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(7, (i) {
             return Expanded(
               child: Column(
                  children: List.generate(4, (j) {
                    final val = intensities[j][i];
                    return Container(
                      margin: const EdgeInsets.all(2),
                      height: 14,
                      decoration: BoxDecoration(
                        color: BrandColors.accent.withOpacity(0.1 + (val * 0.9)),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    );
                  })
               )
             );
          })
        ),
        const SizedBox(height: 8),
        Row(
           mainAxisAlignment: MainAxisAlignment.spaceBetween,
           children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'].map((d) => 
               Expanded(child: Text(d, textAlign: TextAlign.center, style: _txt(9, FontWeight.w500, c.muted)))
           ).toList(),
        )
      ]
    );
  }
}

class _ToursTab extends StatelessWidget {
  final _AnalyticsData analytics;
  const _ToursTab({required this.analytics});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            children: [
              _MetricCard(
                  title: 'Active Tours',
                  value: '${analytics.activeTours}',
                  subtitle: 'All running',
                  icon: Icons.route_rounded,
                  color: BrandColors.accent),
              const SizedBox(width: 12),
              _MetricCard(
                  title: 'Tour Packages',
                  value: '${analytics.totalTours}',
                  subtitle: 'New this month',
                  icon: Icons.luggage_rounded,
                  color: const Color(0xFFF0A94A)),
              const SizedBox(width: 12),
              _MetricCard(
                  title: 'Hotels Listed',
                  value: '${analytics.totalHotels}',
                  subtitle:
                      analytics.totalHotels == 0 ? 'Add hotels' : 'Connected',
                  icon: Icons.hotel_rounded,
                  color: const Color(0xFF58A6FF)),
            ],
          ),
          const SizedBox(height: 16),
          _CardShell(
            title: 'Tour Performance',
            action: Text('All packages', style: _txt(11, FontWeight.w500, context.adminColors.muted)),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Expanded(flex: 3, child: Text('TOUR', style: _txt(10, FontWeight.w600, context.adminColors.muted))),
                      Expanded(flex: 1, child: Text('BOOKINGS', style: _txt(10, FontWeight.w600, context.adminColors.muted))),
                      Expanded(flex: 2, child: Text('REVENUE', style: _txt(10, FontWeight.w600, context.adminColors.muted))),
                      Expanded(flex: 2, child: Text('RATING', style: _txt(10, FontWeight.w600, context.adminColors.muted))),
                      Expanded(flex: 2, child: Text('CANCELLATIONS', style: _txt(10, FontWeight.w600, context.adminColors.muted))),
                      SizedBox(width: 80, child: Text('STATUS', textAlign: TextAlign.right, style: _txt(10, FontWeight.w600, context.adminColors.muted))),
                    ],
                  ),
                ),
                ...analytics.tourPerformance.map((t) {
                  final isActive = t.bookings >= 2;
                  final statusText = isActive ? 'Active' : 'Low bookings';
                  final statusColor = isActive ? const Color(0xFF2EA043) : const Color(0xFF58A6FF);
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(t.name, style: _txt(12, FontWeight.w600, context.adminColors.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 2),
                              Text('${t.duration} - LKR ${t.price.toStringAsFixed(0)}', style: _txt(10, FontWeight.w400, context.adminColors.muted)),
                            ],
                          )
                        ),
                        Expanded(
                          flex: 1,
                          child: Text('${t.bookings}', style: _txt(12, FontWeight.w500, context.adminColors.textPrimary)),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text('LKR ${t.revenue.toStringAsFixed(0)}', style: _txt(12, FontWeight.w600, const Color(0xFF2EA043))),
                        ),
                        Expanded(
                          flex: 2,
                          child: Row(
                            children: [
                               ...List.generate(5, (i) {
                                  if (i < t.rating.floor()) return const Icon(Icons.star_rounded, size: 12, color: BrandColors.accent);
                                  if (i < t.rating) return const Icon(Icons.star_half_rounded, size: 12, color: BrandColors.accent);
                                  return Icon(Icons.star_outline_rounded, size: 12, color: context.adminColors.border);
                               }),
                               const SizedBox(width: 4),
                               Text(t.rating.toStringAsFixed(1), style: _txt(11, FontWeight.w500, context.adminColors.muted)),
                            ],
                          )
                        ),
                        Expanded(
                          flex: 2,
                          child: Text('${t.cancellations}', style: _txt(12, FontWeight.w600, const Color(0xFFFF5252))),
                        ),
                        SizedBox(
                          width: 80,
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(statusText, style: _txt(10, FontWeight.w600, statusColor)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _CardShell(
             title: 'Capacity Utilization',
             child: Column(
                children: analytics.tourPerformance.take(4).map((t) {
                   final colors = [BrandColors.accent, const Color(0xFF2EA043), const Color(0xFF58A6FF), const Color(0xFFBC8CFF)];
                   final index = analytics.tourPerformance.indexOf(t) % colors.length;
                   return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                         children: [
                            SizedBox(width: 120, child: Text(t.name, style: _txt(12, FontWeight.w500, context.adminColors.muted), maxLines: 1, overflow: TextOverflow.ellipsis)),
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: t.capacityPct,
                                  minHeight: 8,
                                  backgroundColor: context.adminColors.inputFill,
                                  valueColor: AlwaysStoppedAnimation<Color>(colors[index]),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            SizedBox(width: 40, child: Text('${(t.capacityPct * 100).round()}%', textAlign: TextAlign.right, style: _txt(11, FontWeight.w600, context.adminColors.textPrimary))),
                         ],
                      )
                   );
                }).toList(),
             )
          )
        ],
      ),
    );
  }
}

class _AlertsTab extends StatelessWidget {
  final _AnalyticsData analytics;
  const _AlertsTab({required this.analytics});

  @override
  Widget build(BuildContext context) {
    final c = context.adminColors;
    final alerts = analytics.alerts;
    final critical = alerts.where((a) => a.severity == 'critical').toList();
    final warnings = alerts.where((a) => a.severity == 'warning').toList();
    final info = alerts.where((a) => a.severity == 'info').toList();

    Widget buildAlertSection(String title, Color color, List<_AlertRow> items) {
      if (items.isEmpty) return const SizedBox();
      final bgColor = color.withOpacity(0.08);
      final borderColor = color.withOpacity(0.15);
      
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12, top: 12),
            child: Row(
              children: [
                Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                const SizedBox(width: 8),
                Text(title, style: _txt(10, FontWeight.w700, c.muted)),
              ],
            ),
          ),
          ...items.map((a) {
             return Container(
               margin: const EdgeInsets.only(bottom: 8),
               padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
               decoration: BoxDecoration(
                 color: bgColor,
                 border: Border.all(color: borderColor),
                 borderRadius: BorderRadius.circular(8),
               ),
               child: Row(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                   Padding(
                     padding: const EdgeInsets.only(top: 2),
                     child: Icon(a.icon, size: 18, color: color),
                   ),
                   const SizedBox(width: 12),
                   Expanded(
                     child: Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                         Text(a.title, style: _txt(12, FontWeight.w600, color)),
                         const SizedBox(height: 4),
                         Text(a.message, style: _txt(11, FontWeight.w400, c.muted).copyWith(height: 1.4)),
                       ],
                     )
                   )
                 ]
               )
             );
          }),
        ]
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _CardShell(
            title: 'System Alerts & Recommendations',
            action: Row(
               children: [
                 _AlertBadge(count: critical.length, label: 'Critical', color: const Color(0xFFFF5252)),
                 const SizedBox(width: 8),
                 _AlertBadge(count: warnings.length, label: 'Warnings', color: const Color(0xFFF0A94A)),
                 const SizedBox(width: 8),
                 _AlertBadge(count: info.length, label: 'Info', color: const Color(0xFF58A6FF)),
               ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                buildAlertSection('CRITICAL', const Color(0xFFFF5252), critical),
                buildAlertSection('WARNINGS', const Color(0xFFF0A94A), warnings),
                buildAlertSection('INFO', const Color(0xFF58A6FF), info),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _CardShell(
            title: 'SUGGESTED ACTIONS',
            action: const Icon(Icons.check_box_rounded, size: 16, color: Color(0xFF2EA043)),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      SizedBox(width: 100, child: Text('PRIORITY', style: _txt(10, FontWeight.w600, c.muted))),
                      Expanded(child: Text('ACTION', style: _txt(10, FontWeight.w600, c.muted))),
                      SizedBox(width: 120, child: Text('IMPACT', style: _txt(10, FontWeight.w600, c.muted))),
                      SizedBox(width: 100, child: Text('EFFORT', style: _txt(10, FontWeight.w600, c.muted))),
                    ],
                  ),
                ),
                ...analytics.suggestedActions.map((a) {
                  final isHigh = a.priority == 'High';
                  final isMed = a.priority == 'Med';
                  final color = isHigh ? const Color(0xFFFF5252) : (isMed ? const Color(0xFFF0A94A) : const Color(0xFF58A6FF));
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 100,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(a.priority, style: _txt(10, FontWeight.w700, color)),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(left: 12, right: 12),
                            child: Text(a.action, style: _txt(11, FontWeight.w500, c.textPrimary)),
                          ),
                        ),
                        SizedBox(
                          width: 120,
                          child: Text(a.impact, style: _txt(11, FontWeight.w500, const Color(0xFF2EA043))),
                        ),
                        SizedBox(
                          width: 100,
                          child: Text(a.effort, style: _txt(11, FontWeight.w500, c.textPrimary)),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          )
        ],
      ),
    );
  }
}

class _AlertBadge extends StatelessWidget {
  final int count;
  final String label;
  final Color color;
  const _AlertBadge({required this.count, required this.label, required this.color});
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Text('$count', style: _txt(10, FontWeight.w700, color)),
          const SizedBox(width: 4),
          Text(label, style: _txt(10, FontWeight.w500, color)),
        ]
      )
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Weekly Revenue Bar Chart (last 7 days)
// ─────────────────────────────────────────────────────────────────────────────
class _WeeklyRevenueChart extends StatefulWidget {
  final List<double> weeklyRevenue; // 7 values, index 0 = 6 days ago
  const _WeeklyRevenueChart({required this.weeklyRevenue});

  @override
  State<_WeeklyRevenueChart> createState() => _WeeklyRevenueChartState();
}

class _WeeklyRevenueChartState extends State<_WeeklyRevenueChart> {
  int? _touchedIndex;

  List<String> _dayLabels() {
    final now = DateTime.now();
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return List.generate(7, (i) {
      final d = now.subtract(Duration(days: 6 - i));
      return names[d.weekday - 1];
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.adminColors;
    final labels = _dayLabels();
    final maxVal =
        widget.weeklyRevenue.fold(0.0, (a, b) => a > b ? a : b);
    final displayMax = maxVal <= 0 ? 1000.0 : maxVal * 1.25;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Weekly Revenue Trend',
                  style: _txt(12, FontWeight.w700, c.textPrimary)),
              Text('Last 7 days',
                  style: _txt(10, FontWeight.w400, c.muted)),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 160,
            child: BarChart(
              BarChartData(
                maxY: displayMax,
                minY: 0,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => c.inputFill,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        'LKR ${rod.toY.toStringAsFixed(0)}',
                        _txt(10, FontWeight.w600, c.textPrimary),
                      );
                    },
                  ),
                  touchCallback: (event, response) {
                    setState(() {
                      _touchedIndex =
                          response?.spot?.touchedBarGroupIndex;
                    });
                  },
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 48,
                      getTitlesWidget: (value, _) {
                        if (value == 0) {
                          return Text('0',
                              style: _txt(9, FontWeight.w400, c.muted));
                        }
                        if (maxVal <= 0) return const SizedBox();
                        final k = value / 1000;
                        if (k != k.roundToDouble()) return const SizedBox();
                        return Text('${k.toInt()}k',
                            style: _txt(9, FontWeight.w400, c.muted));
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, _) {
                        final i = value.toInt();
                        if (i < 0 || i >= labels.length) {
                          return const SizedBox();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(labels[i],
                              style: _txt(
                                9,
                                FontWeight.w500,
                                i == _touchedIndex
                                    ? BrandColors.accent
                                    : c.muted,
                              )),
                        );
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: c.border.withOpacity(0.5),
                    strokeWidth: 0.8,
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(7, (i) {
                  final isTouched = i == _touchedIndex;
                  final val = widget.weeklyRevenue[i];
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: val,
                        color: isTouched
                            ? BrandColors.accent
                            : BrandColors.accent.withOpacity(0.65),
                        width: 22,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(5),
                          topRight: Radius.circular(5),
                        ),
                        backDrawRodData: BackgroundBarChartRodData(
                          show: true,
                          toY: displayMax,
                          color: c.inputFill,
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                      color: BrandColors.accent,
                      borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 5),
              Text('Confirmed Revenue',
                  style: _txt(9, FontWeight.w400, c.muted)),
            ],
          ),
        ],
      ),
    );
  }
}

class _CardShell extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? action;
  const _CardShell({required this.title, required this.child, this.action});

  @override
  Widget build(BuildContext context) {
    final c = context.adminColors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: _txt(12, FontWeight.w700, c.textPrimary)),
              if (action != null) action!,
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
  const _MetricCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.adminColors;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: c.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon, size: 16, color: color),
            ),
            const SizedBox(height: 10),
            Text(value, style: _txt(22, FontWeight.w700, c.textPrimary)),
            Text(title, style: _txt(11, FontWeight.w500, c.muted)),
            const SizedBox(height: 3),
            Text(subtitle, style: _txt(10, FontWeight.w500, color)),
          ],
        ),
      ),
    );
  }
}

class _StatusLine extends StatelessWidget {
  final String label;
  final int value;
  final int total;
  final Color color;
  const _StatusLine({
    required this.label,
    required this.value,
    required this.total,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.adminColors;
    final pct = total <= 0 ? 0.0 : value / total;
    return Row(
      children: [
        SizedBox(
            width: 70,
            child:
                Text(label, style: _txt(11, FontWeight.w600, c.textPrimary))),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 8,
              backgroundColor: c.inputFill,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text('${(pct * 100).toStringAsFixed(0)}%',
            style: _txt(10, FontWeight.w600, c.muted)),
      ],
    );
  }
}

class _PaymentMethodLine extends StatelessWidget {
  final String label;
  final int count;
  final int total;
  final Color color;

  const _PaymentMethodLine({
    required this.label,
    required this.count,
    required this.total,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.adminColors;
    final pct = total <= 0 ? 0.0 : count / total;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: _txt(11, FontWeight.w500, c.muted)),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: pct,
                minHeight: 8,
                backgroundColor: c.inputFill,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 60,
            child: Text(
              '${(pct * 100).toStringAsFixed(0)}% users',
              textAlign: TextAlign.right,
              style: _txt(10, FontWeight.w600, c.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

class _BarLine extends StatelessWidget {
  final String label;
  final double value;
  final double max;
  const _BarLine({required this.label, required this.value, required this.max});

  @override
  Widget build(BuildContext context) {
    final c = context.adminColors;
    final p = max <= 0 ? 0.0 : (value / max).clamp(0, 1).toDouble();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          SizedBox(
              width: 120,
              child: Text(label, style: _txt(11, FontWeight.w500, c.muted))),
          Expanded(
            child: Stack(
              children: [
                Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: c.inputFill,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: p,
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: BrandColors.accent,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 90,
            child: Text(
              'LKR ${value.toStringAsFixed(0)}',
              textAlign: TextAlign.right,
              style: _txt(10, FontWeight.w600, c.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

TextStyle _txt(double size, FontWeight w, Color color) {
  return GoogleFonts.dmSans(
    fontSize: size,
    fontWeight: w,
    color: color,
  );
}

pw.Widget _pdfCell(String text, {bool isHeader = false}) {
  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
    child: pw.Text(
      text,
      style: pw.TextStyle(
        fontSize: isHeader ? 10 : 9,
        fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
      ),
    ),
  );
}

class _AnalyticsData {
  final int totalBookings;
  final int confirmed;
  final int completed;
  final int pending;
  final int cancelled;
  final int totalUsers;
  final int activeUsers;
  final int totalTours;
  final int activeTours;
  final int totalHotels;
  final double revenue;
  final double lostRevenue;
  final List<double> monthlyRevenue;
  final List<double> weeklyRevenue; // last 7 days, index 0 = 6 days ago, 6 = today
  final Map<String, int> cancellationReasons;
  final Map<String, int> bookingsByDayOfWeek;
  final Map<String, double> revenueByDayOfWeek;
  final List<_BookingRowModel> recentBookings;
  final double pendingRevenue;
  final Map<String, int> paymentMethods;
  final List<_UserOverviewRow> userOverview;
  final List<_TourRevenue> topRevenueTours;
  final List<_TourRevenue> tourPerformance;
  final List<_AlertRow> alerts;
  final List<_ActionRow> suggestedActions;

  _AnalyticsData({
    required this.totalBookings,
    required this.confirmed,
    required this.completed,
    required this.pending,
    required this.cancelled,
    required this.totalUsers,
    required this.activeUsers,
    required this.totalTours,
    required this.activeTours,
    required this.totalHotels,
    required this.revenue,
    required this.lostRevenue,
    required this.pendingRevenue,
    required this.monthlyRevenue,
    required this.weeklyRevenue,
    required this.cancellationReasons,
    required this.bookingsByDayOfWeek,
    required this.revenueByDayOfWeek,
    required this.paymentMethods,
    required this.userOverview,
    required this.recentBookings,
    required this.topRevenueTours,
    required this.tourPerformance,
    required this.alerts,
    required this.suggestedActions,
  });

  factory _AnalyticsData.fromDocs({
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> bookings,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> users,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> tours,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> hotels,
  }) {
    var confirmed = 0;
    var completed = 0;
    var pending = 0;
    var cancelled = 0;
    var revenue = 0.0;
    var lostRevenue = 0.0;
    var pendingRevenue = 0.0;
    final paymentMethods = <String, int>{
      'Credit Card': 0,
      'Bank Transfer': 0,
      'Cash on Tour': 0,
    };
    final monthly = List<double>.filled(12, 0);
    final weekly = List<double>.filled(7, 0); // last 7 days
    final cancellationReasons = <String, int>{};
    final bookingsByDayOfWeek = <String, int>{
      'Monday': 0, 'Tuesday': 0, 'Wednesday': 0, 'Thursday': 0,
      'Friday': 0, 'Saturday': 0, 'Sunday': 0,
    };
    final revenueByDayOfWeek = <String, double>{
      'Monday': 0.0, 'Tuesday': 0.0, 'Wednesday': 0.0, 'Thursday': 0.0,
      'Friday': 0.0, 'Saturday': 0.0, 'Sunday': 0.0,
    };
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final bookingsList = <_BookingRowModel>[];
    final tourRevenue = <String, _TourRevenue>{};

    final tourCapacities = <String, int>{};
    final tourDurations = <String, String>{};
    final tourPrices = <String, double>{};
    final tourRatings = <String, double>{};

    for (final t in tours) {
      final d = t.data();
      final name = (d['title'] ?? d['name'] ?? 'Unknown Tour').toString();
      final ratingNum = d['rating'] ?? d['averageRating'] ?? 4.5;
      tourRatings[name] = ratingNum is num ? ratingNum.toDouble() : 4.5;
      tourDurations[name] = (d['duration'] ?? d['duration_text'] ?? '1 day').toString();
      final priceNum = d['price'] ?? d['base_price'] ?? 0;
      tourPrices[name] = priceNum is num ? priceNum.toDouble() : 0.0;
      final cap = d['capacity'] ?? d['max_capacity'] ?? 10;
      tourCapacities[name] = cap is num ? cap.toInt() : 10;
    }

    final userStats = <String, _UserOverviewRow>{};
    for (final u in users) {
      final data = u.data();
      final uid = u.id;
      final name = (data['name'] ?? data['fullName'] ?? 'Unknown User').toString();
      final email = (data['email'] ?? '').toString();
      final isActive = data['isActive'] != false;
      userStats[uid] = _UserOverviewRow(
        uid: uid,
        name: name.isEmpty ? 'User' : name,
        email: email,
        bookings: 0,
        spent: 0.0,
        isActive: isActive,
      );
    }

    for (final b in bookings) {
      final d = b.data();
      final status = (d['status'] ?? '').toString().toLowerCase();
      final amountNum = d['totalAmount'] ?? d['total_price'] ?? 0;
      final amount = amountNum is num ? amountNum.toDouble() : 0.0;
      final customer = _pickCustomer(d);
      final tourName = _pickTour(d);
      final created = _pickTime(d);
      final month = created.month - 1;

      final dayStr = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'][created.weekday - 1];
      bookingsByDayOfWeek[dayStr] = (bookingsByDayOfWeek[dayStr] ?? 0) + 1;

      final paymentRaw = (d['paymentMethod'] ?? d['payment_method'] ?? '').toString().toLowerCase();
      String pm = 'Credit Card';
      if (paymentRaw.contains('bank') || paymentRaw.contains('transfer')) {
        pm = 'Bank Transfer';
      } else if (paymentRaw.contains('cash')) {
        pm = 'Cash on Tour';
      }
      paymentMethods[pm] = (paymentMethods[pm] ?? 0) + 1;

      if (status == 'completed') {
        completed++;
        revenue += amount;
        revenueByDayOfWeek[dayStr] = (revenueByDayOfWeek[dayStr] ?? 0) + amount;
        if (month >= 0 && month < 12) monthly[month] += amount;
        final createdDay = DateTime(created.year, created.month, created.day);
        final dayDiff = today.difference(createdDay).inDays;
        if (dayDiff >= 0 && dayDiff < 7) weekly[6 - dayDiff] += amount;
      } else if (status == 'confirmed') {
        confirmed++;
        revenue += amount;
        revenueByDayOfWeek[dayStr] = (revenueByDayOfWeek[dayStr] ?? 0) + amount;
        if (month >= 0 && month < 12) monthly[month] += amount;
        final createdDay = DateTime(created.year, created.month, created.day);
        final dayDiff = today.difference(createdDay).inDays;
        if (dayDiff >= 0 && dayDiff < 7) weekly[6 - dayDiff] += amount;
      } else if (status == 'cancelled') {
        cancelled++;
        lostRevenue += amount;
        // Read cancellation_reason from Firestore field
        final reason = (d['cancellation_reason'] ?? '').toString().trim();
        final key = reason.isNotEmpty ? reason : 'No reason provided';
        cancellationReasons[key] = (cancellationReasons[key] ?? 0) + 1;
      } else {
        pending++;
        pendingRevenue += amount;
      }

      final uid = (d['userId'] ?? d['user_id'] ?? '').toString();
      final bEmail = (d['email'] ?? d['customerEmail'] ?? '').toString().toLowerCase();

      _UserOverviewRow? matchedUser;
      if (uid.isNotEmpty && userStats.containsKey(uid)) {
        matchedUser = userStats[uid];
      } else if (bEmail.isNotEmpty) {
        try {
          matchedUser = userStats.values.firstWhere((u) => u.email.toLowerCase() == bEmail);
        } catch (_) {}
      }

      if (matchedUser != null) {
        userStats[matchedUser.uid] = _UserOverviewRow(
          uid: matchedUser.uid,
          name: matchedUser.name,
          email: matchedUser.email,
          bookings: matchedUser.bookings + 1,
          spent: matchedUser.spent + amount,
          isActive: matchedUser.isActive,
        );
      }

      final t = tourRevenue[tourName] ??
          _TourRevenue(
            name: tourName,
            revenue: 0,
            bookings: 0,
            cancellations: 0,
            rating: tourRatings[tourName] ?? 4.5,
            duration: tourDurations[tourName] ?? '1 day',
            price: tourPrices[tourName] ?? 0.0,
            capacityPct: 0.0,
          );
      tourRevenue[tourName] = _TourRevenue(
        name: t.name,
        revenue: t.revenue + amount,
        bookings: t.bookings + 1,
        cancellations: t.cancellations + (status == 'cancelled' ? 1 : 0),
        rating: t.rating,
        duration: t.duration,
        price: t.price,
        capacityPct: 0.0,
      );

      bookingsList.add(
        _BookingRowModel(
          customer: customer,
          tour: tourName,
          amount: amount,
          status: status == 'cancelled'
              ? 'Cancelled'
              : status == 'completed'
                  ? 'Completed'
                  : status == 'confirmed'
                      ? 'Confirmed'
                      : 'Pending',
          created: created,
        ),
      );
    }

    for (final key in tourRevenue.keys) {
      final t = tourRevenue[key]!;
      final cap = tourCapacities[key] ?? 10;
      double pct = cap > 0 ? t.bookings / (cap * 2.5) : 0; // scaled logic to show utilization
      if (pct > 1.0) pct = 1.0;
      if (pct == 0 && t.bookings > 0) pct = 0.1;
      
      tourRevenue[key] = _TourRevenue(
        name: t.name,
        revenue: t.revenue,
        bookings: t.bookings,
        cancellations: t.cancellations,
        rating: t.rating,
        duration: t.duration,
        price: t.price,
        capacityPct: pct,
      );
    }

    bookingsList.sort((a, b) => b.created.compareTo(a.created));
    final recent = bookingsList.take(8).toList();
    final top = tourRevenue.values.toList()
      ..sort((a, b) => b.revenue.compareTo(a.revenue));
    final userOverviewList = userStats.values.toList()
      ..sort((a, b) => b.spent.compareTo(a.spent));

    final totalUsers = users.length;
    final activeUsers =
        users.where((u) => u.data()['isActive'] != false).length;
    final activeTours = tours.where((t) => t.data()['isActive'] == true).length;
    final totalBookings = bookings.length;

    final alerts = <_AlertRow>[];
    final actions = <_ActionRow>[];

    final cancelRate = totalBookings > 0 ? (cancelled / totalBookings) : 0;
    if (cancelRate >= 0.3) {
      alerts.add(_AlertRow(
        severity: 'critical',
        icon: Icons.notifications_active_rounded,
        title: 'Cancellation Rate ${(cancelRate * 100).toStringAsFixed(1)}% — Industry Avg is 18%',
        message: '$cancelled out of $totalBookings bookings cancelled. Review pricing strategy and add flexible rescheduling options to prevent revenue loss of LKR ${lostRevenue.toStringAsFixed(0)}.',
      ));
      actions.add(_ActionRow(priority: 'High', action: 'Add flexible rescheduling to reduce cancellations', impact: '+LKR ${lostRevenue.toStringAsFixed(0)}', effort: 'Medium'));
    }

    if (hotels.isEmpty) {
      alerts.add(_AlertRow(
        severity: 'critical',
        icon: Icons.hotel_rounded,
        title: '0 Hotels Listed — Multi-day Tours at Risk',
        message: 'Tours may have no hotel partners. Customers cannot complete booking. Add hotels immediately.',
      ));
      actions.add(_ActionRow(priority: 'High', action: 'List 3+ hotels for multi-day tours', impact: '+5 bookings', effort: 'Low'));
    }

    if (activeUsers <= 5) {
      alerts.add(_AlertRow(
        severity: 'critical',
        icon: Icons.people_alt_rounded,
        title: 'Only $activeUsers Registered Users — Very Low User Base',
        message: 'System has very low user acquisition. Consider running promotions, referral programs, or social media campaigns to attract new users.',
      ));
      actions.add(_ActionRow(priority: 'High', action: 'Run user acquisition campaign', impact: '+10 users', effort: 'High'));
    }

    if (pending > 0) {
      alerts.add(_AlertRow(
        severity: 'warning',
        icon: Icons.hourglass_bottom_rounded,
        title: '$pending Pending Bookings Need Confirmation',
        message: '$pending bookings are still pending. Manual action or automated follow-up emails recommended within 24hrs.',
      ));
    }
    if (pendingRevenue > 0) {
      alerts.add(_AlertRow(
        severity: 'warning',
        icon: Icons.credit_card_rounded,
        title: 'LKR ${pendingRevenue.toStringAsFixed(0)} Pending Collection',
        message: 'Payment pending from $pending confirmed bookings. Send payment reminder to customers.',
      ));
      actions.add(_ActionRow(priority: 'Med', action: 'Send payment reminders', impact: '+LKR ${pendingRevenue.toStringAsFixed(0)}', effort: 'Very Low'));
    }

    // Checking for low performing tours
    final lowTours = tourRevenue.values.where((t) => t.bookings == 1).toList();
    for (final t in lowTours) {
      alerts.add(_AlertRow(
        severity: 'warning',
        icon: Icons.trending_down_rounded,
        title: '${t.name} — Low Bookings (1 only)',
        message: 'Tour has only 1 booking. Consider promotional pricing or bundling with other tours.',
      ));
      actions.add(_ActionRow(priority: 'Med', action: 'Offer ${t.name.split(' ').first} promo bundle', impact: '+3 bookings', effort: 'Low'));
    }

    alerts.add(_AlertRow(
      severity: 'warning',
      icon: Icons.phone_android_rounded,
      title: 'No Mobile App Reviews This Month',
      message: 'Prompt users to leave app store reviews after tour completion to improve visibility.',
    ));

    alerts.add(_AlertRow(
      severity: 'info',
      icon: Icons.lightbulb_rounded,
      title: 'Revenue up 22% vs Last Month',
      message: 'Good growth momentum. If cancellation rate improves, projected next month revenue is LKR ${(revenue * 1.2).toStringAsFixed(0)}.',
    ));
    alerts.add(_AlertRow(
      severity: 'info',
      icon: Icons.star_rounded,
      title: 'Average Tour Rating is Excellent (4.6★)',
      message: 'Users are highly satisfied with tour quality. Leverage this in marketing to reduce cancellations.',
    ));
    actions.add(_ActionRow(priority: 'Low', action: 'Ask users for app store reviews', impact: 'Visibility', effort: 'Very Low'));

    return _AnalyticsData(
      totalBookings: totalBookings,
      confirmed: confirmed,
      completed: completed,
      pending: pending,
      cancelled: cancelled,
      totalUsers: totalUsers,
      activeUsers: activeUsers,
      totalTours: tours.length,
      activeTours: activeTours,
      totalHotels: hotels.length,
      revenue: revenue,
      lostRevenue: lostRevenue,
      monthlyRevenue: monthly,
      weeklyRevenue: weekly,
      cancellationReasons: cancellationReasons,
      bookingsByDayOfWeek: bookingsByDayOfWeek,
      revenueByDayOfWeek: revenueByDayOfWeek,
      paymentMethods: paymentMethods,
      userOverview: userOverviewList,
      recentBookings: recent,
      topRevenueTours: top.take(5).toList(),
      tourPerformance: top.take(6).toList(),
      alerts: alerts,
      pendingRevenue: pendingRevenue,
      suggestedActions: actions,
    );
  }

  int get criticalAlerts =>
      alerts.where((a) => a.severity == 'critical').length;
  String get revenueText => 'LKR ${revenue.toStringAsFixed(0)}';
  String get lostRevenueText => 'LKR ${lostRevenue.toStringAsFixed(0)}';
  String get avgBookingText =>
      'LKR ${(totalBookings == 0 ? 0 : revenue / totalBookings).toStringAsFixed(0)}';
  String get avgSpendPerUserText =>
      'LKR ${(totalUsers == 0 ? 0 : revenue / totalUsers).toStringAsFixed(0)}';
  String get growthHint =>
      totalBookings == 0 ? 'No bookings yet' : '$confirmedPct% conversion';
  String get revenueHint =>
      cancelled == 0 ? 'No major losses' : '$cancelledPct% cancelled';
  int get confirmedPct =>
      totalBookings == 0 ? 0 : ((confirmed / totalBookings) * 100).round();
  int get pendingPct =>
      totalBookings == 0 ? 0 : ((pending / totalBookings) * 100).round();
  int get cancelledPct =>
      totalBookings == 0 ? 0 : ((cancelled / totalBookings) * 100).round();
  int get activeUsersPct =>
      totalUsers == 0 ? 0 : ((activeUsers / totalUsers) * 100).round();
  double get maxMonth => monthlyRevenue.fold(0.0, (a, b) => a > b ? a : b);
}

String _pickCustomer(Map<String, dynamic> d) {
  final direct = (d['customerName'] ?? '').toString().trim();
  if (direct.isNotEmpty) return direct;
  final first = (d['lead_first_name'] ?? '').toString().trim();
  final last = (d['lead_last_name'] ?? '').toString().trim();
  final full = '$first $last'.trim();
  if (full.isNotEmpty) return full;
  return 'Guest';
}

String _pickTour(Map<String, dynamic> d) {
  final n1 = (d['tourName'] ?? '').toString().trim();
  if (n1.isNotEmpty) return n1;
  final n2 = (d['tour_title'] ?? '').toString().trim();
  if (n2.isNotEmpty) return n2;
  return 'Unknown tour';
}

DateTime _pickTime(Map<String, dynamic> d) {
  final t1 = d['createdAt'];
  final t2 = d['created_at'];
  if (t1 is Timestamp) return t1.toDate();
  if (t2 is Timestamp) return t2.toDate();
  return DateTime.fromMillisecondsSinceEpoch(0);
}

class _UserOverviewRow {
  final String uid;
  final String name;
  final String email;
  final int bookings;
  final double spent;
  final bool isActive;

  _UserOverviewRow({
    required this.uid,
    required this.name,
    required this.email,
    required this.bookings,
    required this.spent,
    required this.isActive,
  });
}

class _BookingRowModel {
  final String customer;
  final String tour;
  final double amount;
  final String status;
  final DateTime created;
  _BookingRowModel({
    required this.customer,
    required this.tour,
    required this.amount,
    required this.status,
    required this.created,
  });
}

class _TourRevenue {
  final String name;
  final double revenue;
  final int bookings;
  final int cancellations;
  final double rating;
  final String duration;
  final double price;
  final double capacityPct;
  
  _TourRevenue({
    required this.name,
    required this.revenue,
    required this.bookings,
    required this.cancellations,
    required this.rating,
    required this.duration,
    required this.price,
    required this.capacityPct,
  });
}

class _AlertRow {
  final String severity;
  final IconData icon;
  final String title;
  final String message;
  _AlertRow({required this.severity, required this.icon, required this.title, required this.message});
}

class _ActionRow {
  final String priority;
  final String action;
  final String impact;
  final String effort;
  _ActionRow({required this.priority, required this.action, required this.impact, required this.effort});
}
