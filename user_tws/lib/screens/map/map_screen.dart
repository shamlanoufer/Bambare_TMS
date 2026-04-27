// lib/screens/map/map_screen.dart
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';

import '../../core/theme.dart';
import '../../models/tour.dart';
import '../../services/tour_service.dart';
<<<<<<< HEAD
import 'map_reports_screen.dart';
=======
>>>>>>> a28bf1f775365ea426a204b88ca42cc04604a505
import '../bookings/tour_detail_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final _tourService = TourService();
  final _mapCtrl = MapController();
  final _searchCtrl = TextEditingController();
  String _query = '';
  String? _focusedTourId;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  static const _slCenter = LatLng(7.8731, 80.7718);

  LatLng _markerPointFor(Tour tour) {
    final m = tour.mapInfo;
    if (m != null) return LatLng(m.centerLat, m.centerLng);
    final title = tour.title;
    final loc = tour.locationLabel;
    final s = '$title $loc'.toLowerCase();
    if (s.contains('sigiriya')) return const LatLng(7.9572, 80.7600);
    if (s.contains('yala')) return const LatLng(6.3728, 81.5219);
    if (s.contains('mirissa')) return const LatLng(5.9483, 80.4512);
    if (s.contains('ella')) return const LatLng(6.8667, 81.0469);
    if (s.contains('marble')) return const LatLng(8.5874, 81.2152);
    if (s.contains('piduruthalagala')) return const LatLng(6.9977, 80.7726);
    if (s.contains('kandy')) return const LatLng(7.2906, 80.6337);
    if (s.contains('trincomalee')) return const LatLng(8.5874, 81.2152);
    if (s.contains('colombo')) return const LatLng(6.9271, 79.8612);
    return _slCenter;
  }

  bool _matchesQuery(Tour t) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return true;
    final hay = '${t.title} ${t.locationLabel} ${t.category}'.toLowerCase();
    return hay.contains(q);
  }

  Tour? _bestMatch(List<Tour> all, String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return null;
    final matches = all.where((t) {
      final hay = '${t.title} ${t.locationLabel} ${t.category}'.toLowerCase();
      return hay.contains(q);
    }).toList();
    if (matches.isEmpty) return null;

    matches.sort((a, b) {
      int score(Tour t) {
        final title = t.title.toLowerCase();
        final loc = t.locationLabel.toLowerCase();
        if (title == q || loc == q) return 0;
        if (title.startsWith(q) || loc.startsWith(q)) return 1;
        return 2;
      }

      final sa = score(a);
      final sb = score(b);
      if (sa != sb) return sa.compareTo(sb);
      return a.title.length.compareTo(b.title.length);
    });
    return matches.first;
  }

  void _focusTour(Tour t) {
    final point = _markerPointFor(t);
    // Zoom in enough for easy tap.
    _mapCtrl.move(point, 11.5);
    setState(() => _focusedTourId = t.id);
    // Auto-clear highlight after a short time.
    Future<void>.delayed(const Duration(milliseconds: 1400)).then((_) {
      if (!mounted) return;
      if (_focusedTourId == t.id) setState(() => _focusedTourId = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.paddingOf(context).bottom;
    return Scaffold(
      backgroundColor: AppTheme.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────
<<<<<<< HEAD
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Explore Map',
                          style: TextStyle(
                            color: AppTheme.black,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Discover destinations near you',
                          style: TextStyle(color: AppTheme.grey, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Wrap(
                    spacing: 10,
                    children: [
                      _TopActionPill(
                        label: 'Popular place',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const MapReportsScreen(),
                            ),
                          );
                        },
                      ),
                    ],
=======
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Explore Map',
                    style: TextStyle(
                      color: AppTheme.black,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Discover destinations near you',
                    style: TextStyle(color: AppTheme.grey, fontSize: 13),
>>>>>>> a28bf1f775365ea426a204b88ca42cc04604a505
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Search Bar ───────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFFEEEEE8),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 14),
                    const Icon(Icons.search_rounded,
                        color: AppTheme.grey, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _searchCtrl,
                        onChanged: (v) => setState(() => _query = v),
                        textInputAction: TextInputAction.search,
                        onSubmitted: (_) {
                          // We focus after stream gives us the tours list.
                          FocusScope.of(context).unfocus();
                        },
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Search destinations...',
                          hintStyle: TextStyle(
                            color: AppTheme.grey,
                            fontSize: 14,
                          ),
                        ),
                        style: const TextStyle(
                          color: AppTheme.black,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    if (_query.trim().isNotEmpty)
                      IconButton(
                        onPressed: () {
                          _searchCtrl.clear();
                            setState(() {
                              _query = '';
                              _focusedTourId = null;
                            });
                        },
                        icon: const Icon(Icons.close_rounded,
                            color: AppTheme.grey),
                        tooltip: 'Clear',
                      ),
                    const SizedBox(width: 6),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ── Sri Lanka Map + tour markers ─────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEEEE8),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: StreamBuilder<List<Tour>>(
                    stream: _tourService.allPublishedToursStream(),
                    builder: (context, snap) {
                      if (snap.connectionState == ConnectionState.waiting &&
                          !snap.hasData) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: AppTheme.yellow,
                            strokeWidth: 2,
                          ),
                        );
                      }
                      if (snap.hasError) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(22),
                            child: Text(
                              'Could not load tours on the map.\n${snap.error}',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                color: AppTheme.grey,
                                height: 1.4,
                              ),
                            ),
                          ),
                        );
                      }

                      final all = snap.data ?? const <Tour>[];
                      final tours = all.where(_matchesQuery).toList();
                      final best = _bestMatch(all, _query);
                      if (best != null && _query.trim().isNotEmpty) {
                        // If user typed and pressed enter, we zoom to best match.
                        // We detect "enter" by comparing controller text to query
                        // and focusing when keyboard is dismissed (unfocused).
                        // Simple heuristic: when query changed and there's a best,
                        // focus only if we haven't focused this tour yet.
                        //
                        // This avoids constant camera moves while typing.
                        final shouldFocus =
                            _focusedTourId == null && tours.length == 1;
                        if (shouldFocus) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (!mounted) return;
                            _focusTour(best);
                          });
                        }
                      }

                      final markers = tours.map((t) {
                        final point = _markerPointFor(t);
                        return Marker(
                          point: point,
                          width: 140,
                          height: 110,
                          alignment: Alignment.topCenter,
                          child: _LollipopMarker(
                            title: t.title,
                            highlighted: _focusedTourId == t.id,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => TourDetailScreen(tour: t),
                                ),
                              );
                            },
                          ),
                        );
                      }).toList(growable: false);

                      return Stack(
                        children: [
                          FlutterMap(
                            mapController: _mapCtrl,
                            options: const MapOptions(
                              initialCenter: _slCenter,
                              initialZoom: 7.0,
                              minZoom: 6.0,
                              maxZoom: 16.0,
                              interactionOptions: InteractionOptions(
                                flags: InteractiveFlag.all,
                              ),
                            ),
                            children: [
                              TileLayer(
                                urlTemplate:
                                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                userAgentPackageName: 'com.bambare.book_tws',
                                maxZoom: 19,
                              ),
                              MarkerLayer(markers: markers),
                            ],
                          ),
                          // Tap-to-focus suggestion (works even without “enter” on web).
                          if (best != null && _query.trim().isNotEmpty)
                            Positioned(
                              left: 16,
                              right: 16,
                              top: 14,
                              child: _SearchResultChip(
                                label: 'Zoom to: ${best.title}',
                                onTap: () => _focusTour(best),
                              ),
                            ),
                          Positioned(
                            left: 16,
                            right: 16,
                            bottom: 16 + math.max(0, bottomPad - 8),
                            child: _MapHintPill(
                              text: tours.isEmpty
                                  ? 'No places found'
                                  : 'Tap a lollipop to open the tour package',
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _MapHintPill extends StatelessWidget {
  const _MapHintPill({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(999),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Text(
          text,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
      ),
    );
  }
}

<<<<<<< HEAD
class _TopActionPill extends StatelessWidget {
  const _TopActionPill({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.90),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          child: Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

=======
>>>>>>> a28bf1f775365ea426a204b88ca42cc04604a505
class _LollipopMarker extends StatelessWidget {
  const _LollipopMarker({
    required this.title,
    required this.highlighted,
    required this.onTap,
  });

  final String title;
  final bool highlighted;
  final VoidCallback onTap;

  static const _accent = Color(0xFFE8B800);

  @override
  Widget build(BuildContext context) {
    // Lollipop: pin + small label bubble (like a “place” marker).
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              constraints: const BoxConstraints(maxWidth: 132),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: highlighted ? _accent : Colors.black12,
                  width: highlighted ? 1.6 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.14),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Container(
              width: highlighted ? 40 : 36,
              height: highlighted ? 40 : 36,
              decoration: BoxDecoration(
                color: _accent,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Icon(
                Icons.location_on_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(height: 2),
            Container(
              width: 4,
              height: 16,
              decoration: BoxDecoration(
                color: _accent.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchResultChip extends StatelessWidget {
  const _SearchResultChip({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: Colors.black12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.10),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.my_location_rounded,
                    size: 16, color: Color(0xFFE8B800)),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
