import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:typed_data';

import '../../core/theme.dart';
import '../../models/tour.dart';
import '../../services/tour_service.dart';
import '../../services/map_reports_service.dart';
import '../../utils/pdf_save.dart';

class MapReportsScreen extends StatefulWidget {
  const MapReportsScreen({super.key});

  @override
  State<MapReportsScreen> createState() => _MapReportsScreenState();
}

class _MapReportsScreenState extends State<MapReportsScreen> with SingleTickerProviderStateMixin {
  static const _bg = Color(0xFFF7F8FA);
  static const _header = Color(0xFF1C1C1F);
  static const _accent = Color(0xFFFF8A1F);

  late final TabController _tab;
  bool _exportingPdf = false;

  String _fmtInt(num n) => n.round().toString().replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+$)'),
        (m) => '${m[1]},',
      );

  Future<void> _exportPopularPlacesPdf() async {
    if (_exportingPdf) return;
    setState(() => _exportingPdf = true);
    try {
      final toursSvc = TourService();
      final statsSvc = MapReportsService();
      final allowedCats = <String>['Cultural', 'Beach', 'Wildlife', 'Mountain', 'Food'];

      final featuredTours = await toursSvc.featuredToursStream().first;
      final toursAll = await toursSvc.allPublishedToursStream().first;
      final byCat = await statsSvc.completedVisitsByCategoryStream().first;
      final trendingTotals = await statsSvc.trendingTourBookingsTotalStream().first;
      final completedTotals = await statsSvc.completedTourBookingsTotalStream().first;

      final byId = {for (final t in toursAll) t.id: t};
      final rankedAll = [
        for (final t in toursAll)
          (
            tour: t,
            bookings: completedTotals[t.id] ?? 0,
          ),
      ]..sort((a, b) {
          final c = b.bookings.compareTo(a.bookings);
          if (c != 0) return c;
          return b.tour.rating.compareTo(a.tour.rating);
        });

      final trendingTop = trendingTotals.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final trendingRows = trendingTop.where((e) => byId.containsKey(e.key)).take(5).toList();
      final hiddenGem = rankedAll.isEmpty ? null : rankedAll.first;

      final doc = pw.Document();
      final now = DateTime.now();
      final dateLabel = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final printedAt =
          '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
      final totalVisits = byCat.values.fold<int>(0, (a, b) => a + b);
      final totalRatedPlaces = featuredTours.length;
      final totalRankedPlaces = rankedAll.length;
      final busiestCategory = allowedCats.fold<String>(
        allowedCats.first,
        (best, c) => (byCat[c] ?? 0) > (byCat[best] ?? 0) ? c : best,
      );
      final maxCat = byCat.values.fold<int>(0, (m, v) => v > m ? v : m);

      PdfColor pdfColor(Color c) {
        final r = (c.r * 255.0).round().clamp(0, 255);
        final g = (c.g * 255.0).round().clamp(0, 255);
        final b = (c.b * 255.0).round().clamp(0, 255);
        return PdfColor(r / 255.0, g / 255.0, b / 255.0);
      }

      final accent = pdfColor(const Color(0xFFFF8A1F));
      final ink = pdfColor(const Color(0xFF1C1C1F));
      final muted = pdfColor(const Color(0xFF6B7280));
      final cardBg = pdfColor(const Color(0xFFF7F8FA));
      final border = pdfColor(const Color(0xFFE5E7EB));
      final success = pdfColor(const Color(0xFF11B76D));

      pw.Widget statCard({
        required String label,
        required String value,
      }) {
        return pw.Expanded(
          child: pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: pw.BoxDecoration(
              color: cardBg,
              border: pw.Border.all(color: border),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  label,
                  style: pw.TextStyle(fontSize: 9, color: muted),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  value,
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: ink,
                  ),
                ),
              ],
            ),
          ),
        );
      }

      pw.Widget sectionTitle(String title) {
        return pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: pw.BoxDecoration(
            color: cardBg,
            border: pw.Border.all(color: border),
          ),
          child: pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
              color: ink,
              letterSpacing: 0.5,
            ),
          ),
        );
      }

      doc.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.fromLTRB(24, 24, 24, 24),
          build: (_) => [
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.fromLTRB(16, 14, 16, 14),
              decoration: pw.BoxDecoration(
                color: ink,
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'BAMBARE TRAVEL',
                        style: const pw.TextStyle(
                          fontSize: 9,
                          color: PdfColors.white,
                          letterSpacing: 1.2,
                        ),
                      ),
                      pw.SizedBox(height: 5),
                      pw.Text(
                        'Popular Places Report',
                        style: pw.TextStyle(
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                        ),
                      ),
                    ],
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    decoration: pw.BoxDecoration(color: accent),
                    child: pw.Text(
                      'MAP REPORTS',
                      style: pw.TextStyle(
                        fontSize: 8,
                        color: PdfColors.white,
                        fontWeight: pw.FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 10),
            pw.Row(
              children: [
                pw.Text('Generated: ', style: pw.TextStyle(fontSize: 10, color: muted)),
                pw.Text(printedAt, style: pw.TextStyle(fontSize: 10, color: ink)),
              ],
            ),
            pw.SizedBox(height: 6),
            pw.Row(
              children: [
                statCard(label: 'Total Visits', value: _fmtInt(totalVisits)),
                pw.SizedBox(width: 8),
                statCard(label: 'Top Rated Places', value: _fmtInt(totalRatedPlaces)),
                pw.SizedBox(width: 8),
                statCard(label: 'Places Ranked', value: _fmtInt(totalRankedPlaces)),
                pw.SizedBox(width: 8),
                statCard(
                  label: 'Busiest Category',
                  value: '$busiestCategory (${_fmtInt(byCat[busiestCategory] ?? 0)})',
                ),
              ],
            ),
            pw.SizedBox(height: 14),
            sectionTitle('VISITS BY CATEGORY'),
            pw.SizedBox(height: 8),
            ...allowedCats.map(
              (c) {
                final count = byCat[c] ?? 0;
                final pct = maxCat <= 0 ? 0.0 : (count / maxCat).clamp(0.0, 1.0);
                return pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 8),
                  child: pw.Column(
                    children: [
                      pw.Row(
                        children: [
                          pw.Expanded(
                            child: pw.Text(
                              c,
                              style: pw.TextStyle(fontSize: 10, color: ink, fontWeight: pw.FontWeight.bold),
                            ),
                          ),
                          pw.Text(
                            '${_fmtInt(count)} visits',
                            style: pw.TextStyle(fontSize: 10, color: ink),
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 4),
                      pw.Stack(
                        children: [
                          pw.Container(height: 5, color: border),
                          pw.Container(height: 5, width: 500 * pct, color: accent),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
            pw.SizedBox(height: 10),
            sectionTitle('TRENDING THIS WEEK'),
            pw.SizedBox(height: 8),
            if (trendingRows.isEmpty)
              pw.Text('No trends yet', style: pw.TextStyle(fontSize: 10, color: muted))
            else
              ...trendingRows.asMap().entries.map(
                    (e) => pw.Container(
                      width: double.infinity,
                      margin: const pw.EdgeInsets.only(bottom: 6),
                      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: pw.BoxDecoration(
                        color: cardBg,
                        border: pw.Border.all(color: border),
                      ),
                      child: pw.Row(
                        children: [
                          pw.SizedBox(
                            width: 16,
                            child: pw.Text(
                              '${e.key + 1}',
                              style: pw.TextStyle(
                                fontSize: 10,
                                color: accent,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ),
                          pw.Expanded(
                            child: pw.Text(
                              byId[e.value.key]!.title,
                              style: pw.TextStyle(fontSize: 10, color: ink, fontWeight: pw.FontWeight.bold),
                            ),
                          ),
                          pw.Text(
                            '${_fmtInt(e.value.value)} bookings',
                            style: pw.TextStyle(fontSize: 10, color: success, fontWeight: pw.FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
            pw.SizedBox(height: 10),
            sectionTitle('HIDDEN GEM (HIGH RATED, LESS VISITED)'),
            pw.SizedBox(height: 8),
            if (hiddenGem == null)
              pw.Text('No gems yet', style: pw.TextStyle(fontSize: 10, color: muted))
            else
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: cardBg,
                  border: pw.Border.all(color: border),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      hiddenGem.tour.title,
                      style: pw.TextStyle(fontSize: 12, color: ink, fontWeight: pw.FontWeight.bold),
                    ),
                    pw.SizedBox(height: 3),
                    pw.Text(
                      '${hiddenGem.tour.category.isEmpty ? 'Package' : hiddenGem.tour.category}  -  Rating ${hiddenGem.tour.ratingLabel}',
                      style: pw.TextStyle(fontSize: 10, color: muted),
                    ),
                    pw.SizedBox(height: 3),
                    pw.Text(
                      '${_fmtInt(hiddenGem.bookings)} visits',
                      style: pw.TextStyle(fontSize: 10, color: success, fontWeight: pw.FontWeight.bold),
                    ),
                  ],
                ),
              ),
            pw.SizedBox(height: 10),
            sectionTitle('ALL PLACES RANKED'),
            pw.SizedBox(height: 8),
            if (rankedAll.isEmpty)
              pw.Text('No places yet', style: pw.TextStyle(fontSize: 10, color: muted))
            else
              ...rankedAll.take(25).toList().asMap().entries.map(
                    (e) => pw.Container(
                      margin: const pw.EdgeInsets.only(bottom: 5),
                      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: border),
                      ),
                      child: pw.Row(
                        children: [
                          pw.SizedBox(
                            width: 18,
                            child: pw.Text(
                              '${e.key + 1}',
                              style: pw.TextStyle(fontSize: 10, color: accent, fontWeight: pw.FontWeight.bold),
                            ),
                          ),
                          pw.Expanded(
                            child: pw.Text(
                              e.value.tour.title,
                              style: pw.TextStyle(fontSize: 10, color: ink),
                            ),
                          ),
                          pw.Text(
                            '${_fmtInt(e.value.bookings)} visits',
                            style: pw.TextStyle(fontSize: 10, color: muted),
                          ),
                        ],
                      ),
                    ),
                  ),
          ],
          footer: (_) => pw.Container(
            margin: const pw.EdgeInsets.only(top: 10),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Bambare Travel · Internal Report',
                  style: pw.TextStyle(fontSize: 9, color: muted),
                ),
                pw.Text(
                  dateLabel,
                  style: pw.TextStyle(fontSize: 9, color: muted),
                ),
              ],
            ),
          ),
        ),
      );

      final bytes = await doc.save();
      final savedTo = await savePdfBytes(
        bytes: Uint8List.fromList(bytes),
        baseName: 'popular_places_report_$dateLabel',
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
        SnackBar(content: Text('Could not export PDF. $e')),
      );
    } finally {
      if (mounted) setState(() => _exportingPdf = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 1, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 14),
              decoration: BoxDecoration(
                color: _header,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.16),
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Material(
                        color: Colors.white.withValues(alpha: 0.10),
                        shape: const CircleBorder(),
                        child: IconButton(
                          onPressed: () => Navigator.of(context).maybePop(),
                          icon: const Icon(Icons.arrow_back_ios_new_rounded),
                          iconSize: 18,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Map Reports',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'March 2026 · Colombo trip',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Colors.white.withValues(alpha: 0.60),
                              ),
                            ),
                          ],
                        ),
                      ),
                      FilledButton(
                        onPressed: _exportingPdf ? null : _exportPopularPlacesPdf,
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.16),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                          _exportingPdf ? 'Exporting...' : 'Export',
                          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w900, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    height: 46,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 14,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: TabBar(
                      controller: _tab,
                      indicatorColor: _accent,
                      indicatorWeight: 2.4,
                      dividerColor: Colors.transparent,
                      labelColor: _accent,
                      unselectedLabelColor: AppTheme.grey,
                      labelStyle: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w900),
                      unselectedLabelStyle: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w900),
                      tabs: const [
                        Tab(icon: Icon(Icons.star_rounded, size: 16), text: 'Popular Places'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tab,
                children: const [
                  _PopularPlacesTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PopularPlacesTab extends StatefulWidget {
  const _PopularPlacesTab();

  @override
  State<_PopularPlacesTab> createState() => _PopularPlacesTabState();
}

class _PopularPlacesTabState extends State<_PopularPlacesTab> {
  final _statsSvc = MapReportsService();
  bool _ranInit = false;
  bool? _isMapReportsAdmin;
  bool _syncingStats = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || _ranInit) return;
      _ranInit = true;
      final admin = await _statsSvc.currentUserIsMapReportsAdmin();
      if (!mounted) return;
      setState(() => _isMapReportsAdmin = admin);
      await _statsSvc.backfillVisitsFromBookingsIfAdmin();
    });
  }

  Future<void> _onSyncMapReportsPressed() async {
    setState(() => _syncingStats = true);
    try {
      final msg = await _statsSvc.syncMapReportsFromBookingsIfAdmin();
      if (!mounted) return;
      if (msg == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Only an active admin account can sync map stats.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
    } finally {
      if (mounted) setState(() => _syncingStats = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const allowedCats = <String>['Cultural', 'Beach', 'Wildlife', 'Mountain', 'Food'];
    final svc = TourService();
    final statsSvc = _statsSvc;

    String fmtInt(int n) => n.toString().replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+$)'),
          (m) => '${m[1]},',
        );

    return StreamBuilder<List<Tour>>(
      stream: svc.featuredToursStream(), // same as bookings "Popular Tours"
      builder: (context, snap) {
        final tours = snap.data ?? const <Tour>[];

        final distinctCats = <String>{};
        var ratingSum = 0.0;
        for (final t in tours) {
          ratingSum += t.rating;
          final c = t.category.trim();
          if (c.isNotEmpty) distinctCats.add(c);
        }
        final avgRating = tours.isEmpty ? 0.0 : (ratingSum / tours.length);

        final stats = [
          (value: '${tours.length}', label: 'Places logged'),
          (value: '${distinctCats.length}', label: 'Categories'),
          (value: '${avgRating.toStringAsFixed(1)}★', label: 'Avg rating'),
        ];

        final topRated = [...tours]..sort((a, b) => b.rating.compareTo(a.rating));

        Color catColor(String c) {
          switch (c.toLowerCase()) {
            case 'cultural':
              return const Color(0xFFFF8A1F);
            case 'beach':
              return const Color(0xFF2E6BE6);
            case 'wildlife':
              return const Color(0xFF11B76D);
            case 'mountain':
              return const Color(0xFF7B61FF);
            case 'food':
              return const Color(0xFFF4B000);
            default:
              return const Color(0xFF6B7280);
          }
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
          children: [
            _WhiteCard(
              child: Row(
                children: [
                  for (var i = 0; i < stats.length; i++) ...[
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            stats[i].value,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.black,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            stats[i].label,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (i != stats.length - 1)
                      Container(
                        width: 1,
                        height: 34,
                        color: Colors.black.withValues(alpha: 0.06),
                      ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),
            if (_isMapReportsAdmin == true) ...[
              _WhiteCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Admin: booking stats',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.black,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Visits, trending, and rankings read from the shared Firestore document (public_stats / map_reports). '
                      'If older bookings never updated it, sync once from all bookings.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.grey,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: _syncingStats ? null : _onSyncMapReportsPressed,
                      icon: _syncingStats
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.sync_rounded, size: 18),
                      label: Text(
                        _syncingStats ? 'Syncing…' : 'Sync booking stats',
                        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w900, fontSize: 12),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFFF8A1F),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],
            const _SectionLabel(icon: Icons.emoji_events_rounded, text: 'TOP RATED THIS TRIP'),
            const SizedBox(height: 10),
            if (topRated.isEmpty)
              const _WhiteCard(
                child: _EmptyBlock(
                  title: 'No places yet',
                  subtitle: 'Popular places will appear here once they are available in your bookings data.',
                ),
              )
            else
              _WhiteCard(
                child: Column(
                  children: [
                    for (var i = 0; i < topRated.take(6).length; i++) ...[
                      _TourRow(
                        rank: i + 1,
                        tour: topRated[i],
                      ),
                      if (i != topRated.take(6).length - 1)
                        Divider(height: 18, color: Colors.black.withValues(alpha: 0.06)),
                    ],
                  ],
                ),
              ),
            const SizedBox(height: 14),
            const _SectionLabel(icon: Icons.folder_rounded, text: 'VISITS BY CATEGORY'),
            const SizedBox(height: 10),
            StreamBuilder<Map<String, int>>(
              stream: statsSvc.completedVisitsByCategoryStream(),
              builder: (context, s2) {
                final byEnv = s2.data ??
                    const <String, int>{
                      'Cultural': 0,
                      'Beach': 0,
                      'Wildlife': 0,
                      'Mountain': 0,
                      'Food': 0,
                    };
                final maxCat = byEnv.values.fold<int>(0, (m, v) => v > m ? v : m);
                return _WhiteCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          for (final c in allowedCats) _CategoryChip(label: c),
                        ],
                      ),
                      const SizedBox(height: 14),
                      for (final c in allowedCats) ...[
                        _CatBarRow(
                          label: c,
                          color: catColor(c),
                          valueLabel: '${fmtInt(byEnv[c] ?? 0)} visits',
                          pct: maxCat <= 0 ? 0.0 : ((byEnv[c] ?? 0) / maxCat),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 14),
            const _SectionLabel(icon: Icons.local_fire_department_rounded, text: 'TRENDING THIS WEEK'),
            const SizedBox(height: 10),
            StreamBuilder<Map<String, int>>(
              stream: statsSvc.trendingTourBookingsTotalStream(),
              builder: (context, s3) {
                final totals = s3.data ?? const <String, int>{};
                if (totals.isEmpty) {
                  return const _WhiteCard(
                    child: _EmptyBlock(
                      title: 'No trends yet',
                      subtitle: 'Top booked packages will appear here once there is enough upcoming booking activity.',
                    ),
                  );
                }
                return StreamBuilder<List<Tour>>(
                  stream: svc.allPublishedToursStream(),
                  builder: (context, s4) {
                    final toursAll = s4.data ?? const <Tour>[];
                    final byId = {for (final t in toursAll) t.id: t};
                    final ranked = totals.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
                    final top = ranked.where((e) => byId.containsKey(e.key)).take(5).toList();
                    if (top.isEmpty) {
                      return const _WhiteCard(
                        child: _EmptyBlock(
                          title: 'No trends yet',
                          subtitle: 'Booking counts exist, but matching tours could not be found.',
                        ),
                      );
                    }
                    final max = top.fold<int>(0, (m, e) => e.value > m ? e.value : m);
                    return _WhiteCard(
                      child: Column(
                        children: [
                          for (var i = 0; i < top.length; i++) ...[
                            _TrendingTourRow(
                              tour: byId[top[i].key]!,
                              bookings: top[i].value,
                              maxBookings: max <= 0 ? 1 : max,
                            ),
                            if (i != top.length - 1)
                              Divider(height: 18, color: Colors.black.withValues(alpha: 0.06)),
                          ],
                        ],
                      ),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 14),
            const _SectionLabel(icon: Icons.diamond_rounded, text: 'HIDDEN GEMS (HIGH RATED, LESS VISITED)'),
            const SizedBox(height: 10),
            StreamBuilder<Map<String, int>>(
              stream: statsSvc.completedTourBookingsTotalStream(),
              builder: (context, s5) {
                final totals = s5.data ?? const <String, int>{};
                if (totals.isEmpty) {
                  return const _WhiteCard(
                    child: _EmptyBlock(
                      title: 'No gems yet',
                      subtitle: 'A top booked package will appear here once there is enough completed booking activity.',
                    ),
                  );
                }
                return StreamBuilder<List<Tour>>(
                  stream: svc.allPublishedToursStream(),
                  builder: (context, s6) {
                    final toursAll = s6.data ?? const <Tour>[];
                    final byId = {for (final t in toursAll) t.id: t};
                    final ranked = totals.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
                    final top = ranked.where((e) => byId.containsKey(e.key)).take(1).toList();
                    if (top.isEmpty) {
                      return const _WhiteCard(
                        child: _EmptyBlock(
                          title: 'No gems yet',
                          subtitle: 'Booking counts exist, but matching tours could not be found.',
                        ),
                      );
                    }
                    final t = byId[top.first.key]!;
                    return _WhiteCard(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: _BookedTourCard(
                          tour: t,
                          bookings: top.first.value,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 14),
            const _SectionLabel(icon: Icons.list_alt_rounded, text: 'ALL PLACES RANKED'),
            const SizedBox(height: 10),
            StreamBuilder<List<Tour>>(
              stream: svc.allPublishedToursStream(),
              builder: (context, s7) {
                final toursAll = s7.data ?? const <Tour>[];
                return StreamBuilder<Map<String, int>>(
                  stream: statsSvc.completedTourBookingsTotalStream(),
                  builder: (context, s8) {
                    final totals = s8.data ?? const <String, int>{};
                    if (toursAll.isEmpty) {
                      return const _WhiteCard(
                        child: _EmptyBlock(
                          title: 'No places yet',
                          subtitle: 'Packages will appear here once tours are available in the database.',
                        ),
                      );
                    }

                    final ranked = [
                      for (final t in toursAll)
                        (
                          tour: t,
                          bookings: totals[t.id] ?? 0,
                        ),
                    ]
                      ..sort((a, b) {
                        final c = b.bookings.compareTo(a.bookings);
                        if (c != 0) return c;
                        return b.tour.rating.compareTo(a.tour.rating);
                      });

                    final sum = ranked.fold<int>(0, (m, e) => m + e.bookings);
                    final avg = ranked.isEmpty ? 0.0 : (sum / ranked.length);

                    int pctDelta(int bookings) {
                      if (avg <= 0) return 0;
                      return (((bookings - avg) / avg) * 100).round();
                    }

                    return Column(
                      children: [
                        for (var i = 0; i < ranked.length; i++) ...[
                          _WhiteCard(
                            child: _RankedTourRow(
                              rank: i + 1,
                              tour: ranked[i].tour,
                              bookings: ranked[i].bookings,
                              deltaPct: pctDelta(ranked[i].bookings),
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],
                      ],
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 10),
          ],
        );
      },
    );
  }
}

class _BookedTourCard extends StatelessWidget {
  const _BookedTourCard({required this.tour, required this.bookings});

  final Tour tour;
  final int bookings;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 190,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.diamond_rounded, color: AppTheme.black, size: 20),
          ),
          const SizedBox(height: 10),
          Text(
            tour.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w900, fontSize: 12),
          ),
          const SizedBox(height: 6),
          Text(
            '${tour.category.isEmpty ? 'Package' : tour.category}  ★ ${tour.ratingLabel}',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 10, color: AppTheme.grey),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                '$bookings bookings',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w900, fontSize: 11, color: const Color(0xFFFF8A1F)),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFE7F7EE),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'Gem',
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w900, fontSize: 10, color: const Color(0xFF11B76D)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TrendingTourRow extends StatelessWidget {
  const _TrendingTourRow({
    required this.tour,
    required this.bookings,
    required this.maxBookings,
  });

  final Tour tour;
  final int bookings;
  final int maxBookings;

  @override
  Widget build(BuildContext context) {
    final pct = maxBookings <= 0 ? 0.0 : (bookings / maxBookings).clamp(0.0, 1.0);
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.local_fire_department_rounded, color: AppTheme.black, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tour.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w900, fontSize: 12),
              ),
              const SizedBox(height: 2),
              Text(
                '${tour.category.isEmpty ? 'Package' : tour.category}  ★ ${tour.ratingLabel}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 10, color: AppTheme.grey),
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: pct,
                  minHeight: 6,
                  backgroundColor: Colors.black.withValues(alpha: 0.06),
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFF8A1F)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '+${(pct * 100).round()}%',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w900,
                fontSize: 12,
                color: const Color(0xFF11B76D),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '$bookings bookings',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 10, color: AppTheme.grey),
            ),
          ],
        ),
      ],
    );
  }
}

class _RankedTourRow extends StatelessWidget {
  const _RankedTourRow({
    required this.rank,
    required this.tour,
    required this.bookings,
    required this.deltaPct,
  });

  final int rank;
  final Tour tour;
  final int bookings;
  final int deltaPct; // can be negative

  @override
  Widget build(BuildContext context) {
    final up = deltaPct >= 0;
    final color = up ? const Color(0xFF11B76D) : const Color(0xFFFF3B30);
    final arrow = up ? '↑' : '↓';
    final pct = deltaPct.abs();

    return Row(
      children: [
        SizedBox(
          width: 18,
          child: Text(
            '$rank',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w900,
              fontSize: 12,
              color: const Color(0xFFFF8A1F),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.place_rounded, color: AppTheme.black, size: 20),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tour.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w900, fontSize: 12),
              ),
              const SizedBox(height: 2),
              Text(
                '${tour.category.isEmpty ? 'Package' : tour.category}  ★ ${tour.ratingLabel}   $bookings visits',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  fontSize: 10,
                  color: AppTheme.grey,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Text(
          '$arrow $pct%',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w900,
            fontSize: 12,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _TourRow extends StatelessWidget {
  const _TourRow({required this.rank, required this.tour});

  final int rank;
  final Tour tour;

  @override
  Widget build(BuildContext context) {
    final bg = switch (rank) {
      1 => const Color(0xFFFF8A1F),
      _ => Colors.black.withValues(alpha: 0.10),
    };
    final fg = rank == 1 ? Colors.white : AppTheme.black;
    final iconBg = Colors.black.withValues(alpha: 0.05);

    return Row(
      children: [
        Container(
          width: 26,
          height: 26,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
          child: Text(
            '$rank',
            style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w900, color: fg),
          ),
        ),
        const SizedBox(width: 10),
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(14)),
          child: const Icon(Icons.place_rounded, color: AppTheme.black, size: 20),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tour.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w900, fontSize: 12),
              ),
              const SizedBox(height: 2),
              Text(
                '${tour.category.isEmpty ? 'Place' : tour.category} · ★ ${tour.ratingLabel}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 10, color: AppTheme.grey),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Text(
          tour.ratingLabel,
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w900, fontSize: 12, color: const Color(0xFFFF8A1F)),
        ),
      ],
    );
  }
}

class _CatBarRow extends StatelessWidget {
  const _CatBarRow({
    required this.label,
    required this.color,
    required this.valueLabel,
    required this.pct,
  });

  final String label;
  final Color color;
  final String valueLabel;
  final double pct;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w900, fontSize: 12),
              ),
            ),
            Text(
              valueLabel,
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w900, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: pct.clamp(0, 1),
            minHeight: 6,
            backgroundColor: Colors.black.withValues(alpha: 0.06),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

class _EmptyBlock extends StatelessWidget {
  const _EmptyBlock({required this.title, required this.subtitle});
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: AppTheme.black,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppTheme.grey,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.label});
  final String label;

  Color _bg() {
    switch (label.toLowerCase()) {
      case 'cultural':
        return const Color(0xFFFFF3EA);
      case 'beach':
        return const Color(0xFFE9F1FF);
      case 'wildlife':
        return const Color(0xFFECF7EF);
      case 'mountain':
        return const Color(0xFFF0ECFF);
      case 'food':
        return const Color(0xFFFFF7DD);
      default:
        return const Color(0xFFF1F5F9);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _bg(),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
      ),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 11,
          fontWeight: FontWeight.w900,
          color: AppTheme.black,
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

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.grey),
        const SizedBox(width: 8),
        Text(
          text,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.0,
            color: AppTheme.grey,
          ),
        ),
      ],
    );
  }
}

