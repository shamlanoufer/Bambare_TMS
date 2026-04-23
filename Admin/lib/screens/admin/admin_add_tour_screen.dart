import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/activity_log_service.dart';
import '../../services/admin_tour_storage.dart';
import '../../theme/admin_theme_colors.dart';
import '../../theme/brand_colors.dart';
import '../../widgets/admin_image_pick_row.dart';

/// Full-page form to add or edit a tour so the mobile app can show Overview,
/// Itinerary, and Map from Firestore (`overview_body`, `itinerary_days`, `map_config`, …).
class AdminAddTourScreen extends StatefulWidget {
  const AdminAddTourScreen({super.key, this.docId});

  final String? docId;

  @override
  State<AdminAddTourScreen> createState() => _AdminAddTourScreenState();
}

class _EventRow {
  _EventRow()
      : time = TextEditingController(),
        icon = TextEditingController(text: '📍'),
        title = TextEditingController(),
        location = TextEditingController(),
        desc = TextEditingController(),
        tag = TextEditingController(),
        duration = TextEditingController(),
        eventImageUrl = TextEditingController();

  final TextEditingController time;
  final TextEditingController icon;
  final TextEditingController title;
  final TextEditingController location;
  final TextEditingController desc;
  final TextEditingController tag;
  final TextEditingController duration;
  final TextEditingController eventImageUrl;

  void dispose() {
    time.dispose();
    icon.dispose();
    title.dispose();
    location.dispose();
    desc.dispose();
    tag.dispose();
    duration.dispose();
    eventImageUrl.dispose();
  }

  Map<String, dynamic> toMap() => {
        'time': time.text.trim(),
        'icon': icon.text.trim().isEmpty ? '📍' : icon.text.trim(),
        'title': title.text.trim(),
        'location': location.text.trim().isEmpty ? null : location.text.trim(),
        'desc': desc.text.trim(),
        'tag': tag.text.trim().isEmpty ? null : tag.text.trim(),
        'duration': duration.text.trim().isEmpty ? null : duration.text.trim(),
        if (eventImageUrl.text.trim().isNotEmpty)
          'image_url': eventImageUrl.text.trim(),
      };
}

class _DayBlock {
  _DayBlock()
      : title = TextEditingController(),
        subtitle = TextEditingController(),
        events = [_EventRow()];

  final TextEditingController title;
  final TextEditingController subtitle;
  final List<_EventRow> events;

  void dispose() {
    title.dispose();
    subtitle.dispose();
    for (final e in events) {
      e.dispose();
    }
  }
}

class _MapStopRow {
  _MapStopRow()
      : icon = TextEditingController(text: '📍'),
        title = TextEditingController(),
        time = TextEditingController(),
        lat = TextEditingController(),
        lng = TextEditingController();

  final TextEditingController icon;
  final TextEditingController title;
  final TextEditingController time;
  final TextEditingController lat;
  final TextEditingController lng;

  void dispose() {
    icon.dispose();
    title.dispose();
    time.dispose();
    lat.dispose();
    lng.dispose();
  }
}

class _AdminAddTourScreenState extends State<AdminAddTourScreen> {
  final _title = TextEditingController();
  final _location = TextEditingController();
  String _categoryChoice = 'Cultural';
  final _heroUrl = TextEditingController();
  final _overviewBgUrl = TextEditingController();
  final _shortDesc = TextEditingController();
  final _overview = TextEditingController();
  final _inclusions = TextEditingController();
  final _exclusions = TextEditingController();
  final _galleryUrls = <String>[];
  final _reviewMarketingUrls = <String>[];
  final _reviewCount = TextEditingController(text: '124');
  final _price = TextEditingController();
  final _currency = TextEditingController(text: 'LKR');
  final _duration = TextEditingController();
  final _maxCap = TextEditingController(text: '10');
  final _weather = TextEditingController(text: '24°C');
  final _rating = TextEditingController(text: '4.8');
  final _sortOrder = TextEditingController(text: '0');
  final _emoji = TextEditingController(text: '🗺');
  final _mapLat = TextEditingController();
  final _mapLng = TextEditingController();
  final _mapDist = TextEditingController(text: '167 km');
  final _mapDrive = TextEditingController(text: '3.5h');
  final _mapPeak = TextEditingController(text: '200m');
  final _mapRoute = TextEditingController(text: 'A9');
  final _itineraryTabImageUrl = TextEditingController();
  final _reviewTabImageUrl = TextEditingController();
  final _mapTabImageUrl = TextEditingController();

  final _days = <_DayBlock>[];
  final _mapStops = <_MapStopRow>[];

  bool _published = true;
  bool _loading = true;
  bool _saving = false;

  bool _vHomeFeatures = false;
  bool _vHiking = false;
  bool _vCycling = false;
  bool _vTrekking = false;
  bool _vTukTuk = false;
  bool _vJeep = false;
  bool _vCookery = false;
  bool _vBookingPopular = false;
  bool _vBookingSeeAll = false;
  bool _vEnvCultural = false;
  bool _vEnvBeach = false;
  bool _vEnvWildlife = false;
  bool _vEnvMountain = false;
  bool _vEnvFood = false;

  @override
  void initState() {
    super.initState();
    _mapStops.add(_MapStopRow());
    if (widget.docId == null) {
      _days.add(_DayBlock());
      _vBookingSeeAll = true;
      _vBookingPopular = true;
      _loading = false;
    } else {
      _load();
    }
  }

  Future<void> _load() async {
    final snap = await FirebaseFirestore.instance
        .collection('tours')
        .doc(widget.docId)
        .get();
    if (!snap.exists || !mounted) {
      setState(() => _loading = false);
      return;
    }
    final d = snap.data() ?? {};

    _title.text = (d['title'] ?? d['tourName'] ?? '') as String;
    _location.text = (d['location'] ?? '') as String;
    _categoryChoice = (d['category'] ?? 'Cultural').toString();
    _heroUrl.text = (d['image_url'] ?? '') as String;
    _overviewBgUrl.text =
        (d['overview_background_image_url'] ?? '').toString();
    _itineraryTabImageUrl.text =
        (d['itinerary_tab_image_url'] ?? '').toString();
    _reviewTabImageUrl.text = (d['review_tab_image_url'] ?? '').toString();
    _shortDesc.text = (d['description'] ?? '') as String;
    _overview.text = (d['overview_body'] ?? d['description'] ?? '') as String;
    _price.text = ((d['price'] ?? d['basePrice']) ?? '').toString();
    _currency.text = (d['currency'] ?? 'LKR') as String;
    _duration.text = (d['duration'] ?? '') as String;
    _maxCap.text = ((d['maxCapacity'] ?? d['max_capacity']) ?? '10').toString();
    _weather.text = (d['weather_note'] ?? '24°C') as String;
    _rating.text = ((d['rating'] ?? 4.8)).toString();
    _sortOrder.text = ((d['sort_order'] ?? 0)).toString();
    _emoji.text = (d['emoji'] ?? '🗺') as String;
    _published = d['published'] as bool? ?? d['isActive'] as bool? ?? true;

    final vis = d['visibility'];
    if (vis is Map) {
      final m = Map<String, dynamic>.from(vis);
      _vHomeFeatures = m['home_features'] == true;
      _vHiking = m['activity_hiking'] == true;
      _vCycling = m['activity_cycling'] == true;
      _vTrekking = m['activity_trekking'] == true;
      _vTukTuk = m['activity_tuk_tuk_ride'] == true;
      _vJeep = m['activity_jeep'] == true;
      _vCookery = m['activity_cookery'] == true;
      _vBookingPopular = m['booking_popular'] == true;
      _vBookingSeeAll = m['booking_see_all'] == true;
      _vEnvCultural = m['environment_cultural'] == true;
      _vEnvBeach = m['environment_beach'] == true;
      _vEnvWildlife = m['environment_wildlife'] == true;
      _vEnvMountain = m['environment_mountain'] == true;
      _vEnvFood = m['environment_food'] == true;
    }

    _reviewCount.text =
        ((d['review_display_count'] ?? 124)).toString();
    _reviewMarketingUrls.clear();
    final rmg = d['review_marketing_gallery_urls'];
    if (rmg is List) {
      _reviewMarketingUrls.addAll(rmg.map((e) => e.toString()));
    }

    final inc = d['inclusions'];
    if (inc is List) {
      _inclusions.text = inc.map((e) => e.toString()).join('\n');
    }
    final exc = d['exclusions'];
    if (exc is List) {
      _exclusions.text = exc.map((e) => e.toString()).join('\n');
    }
    _galleryUrls.clear();
    final gal = d['gallery_urls'];
    if (gal is List) {
      _galleryUrls.addAll(gal.map((e) => e.toString()));
    }

    _mapTabImageUrl.text = (d['map_tab_image_url'] ?? '').toString();
    final map = d['map_config'];
    if (map is Map) {
      final m = Map<String, dynamic>.from(map);
      if (_mapTabImageUrl.text.trim().isEmpty) {
        final tabImg = m['tab_image_url']?.toString().trim();
        if (tabImg != null && tabImg.isNotEmpty) {
          _mapTabImageUrl.text = tabImg;
        }
      }
      _mapLat.text = (m['center_lat'] ?? '').toString();
      _mapLng.text = (m['center_lng'] ?? '').toString();
      _mapDist.text = (m['stat_distance'] ?? '') as String;
      _mapDrive.text = (m['stat_drive'] ?? '') as String;
      _mapPeak.text = (m['stat_peak'] ?? '') as String;
      _mapRoute.text = (m['stat_route'] ?? '') as String;
      final stops = m['stops'];
      for (final r in _mapStops) {
        r.dispose();
      }
      _mapStops.clear();
      if (stops is List && stops.isNotEmpty) {
        for (final s in stops) {
          if (s is! Map) continue;
          final sm = Map<String, dynamic>.from(s);
          final row = _MapStopRow();
          row.icon.text = sm['icon']?.toString() ?? '📍';
          row.title.text = sm['title']?.toString() ?? '';
          row.time.text = sm['time']?.toString() ?? '';
          row.lat.text = (sm['lat'] ?? '').toString();
          row.lng.text = (sm['lng'] ?? '').toString();
          _mapStops.add(row);
        }
      } else {
        _mapStops.add(_MapStopRow());
      }
    }

    for (final old in _days) {
      old.dispose();
    }
    _days.clear();
    final it = d['itinerary_days'];
    if (it is List && it.isNotEmpty) {
      for (final day in it) {
        if (day is! Map) continue;
        final dm = Map<String, dynamic>.from(day);
        final block = _DayBlock();
        block.title.text = dm['title']?.toString() ?? '';
        block.subtitle.text = dm['subtitle']?.toString() ?? '';
        for (final e in block.events) {
          e.dispose();
        }
        block.events.clear();
        final evs = dm['events'];
        if (evs is List && evs.isNotEmpty) {
          for (final e in evs) {
            if (e is! Map) continue;
            final em = Map<String, dynamic>.from(e);
            final row = _EventRow();
            row.time.text = em['time']?.toString() ?? '';
            row.icon.text = em['icon']?.toString() ?? '📍';
            row.title.text = em['title']?.toString() ?? '';
            row.location.text = em['location']?.toString() ?? '';
            row.desc.text = em['desc']?.toString() ?? '';
            row.tag.text = em['tag']?.toString() ?? '';
            row.duration.text = em['duration']?.toString() ?? '';
            row.eventImageUrl.text = em['image_url']?.toString() ?? '';
            block.events.add(row);
          }
        } else {
          block.events.add(_EventRow());
        }
        _days.add(block);
      }
    } else {
      _days.add(_DayBlock());
    }

    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    _title.dispose();
    _location.dispose();
    _heroUrl.dispose();
    _overviewBgUrl.dispose();
    _shortDesc.dispose();
    _overview.dispose();
    _inclusions.dispose();
    _exclusions.dispose();
    _reviewCount.dispose();
    _price.dispose();
    _currency.dispose();
    _duration.dispose();
    _maxCap.dispose();
    _weather.dispose();
    _rating.dispose();
    _sortOrder.dispose();
    _emoji.dispose();
    _mapLat.dispose();
    _mapLng.dispose();
    _mapDist.dispose();
    _mapDrive.dispose();
    _mapPeak.dispose();
    _mapRoute.dispose();
    _itineraryTabImageUrl.dispose();
    _reviewTabImageUrl.dispose();
    _mapTabImageUrl.dispose();
    for (final d in _days) {
      d.dispose();
    }
    for (final s in _mapStops) {
      s.dispose();
    }
    super.dispose();
  }

  List<String> _lines(String raw) => raw
      .split('\n')
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();

  /// Rough UTF-8 byte estimate for embedded image strings (base64 on web) so we stay under Firestore’s 1 MiB cap.
  int _roughPayloadStringBytes() {
    var n = 0;
    void add(String s) => n += s.length;
    add(_title.text);
    add(_location.text);
    add(_heroUrl.text);
    add(_overviewBgUrl.text);
    add(_shortDesc.text);
    add(_overview.text);
    add(_inclusions.text);
    add(_exclusions.text);
    for (final u in _galleryUrls) {
      add(u);
    }
    for (final u in _reviewMarketingUrls) {
      add(u);
    }
    add(_itineraryTabImageUrl.text);
    add(_reviewTabImageUrl.text);
    add(_mapTabImageUrl.text);
    for (final day in _days) {
      add(day.title.text);
      add(day.subtitle.text);
      for (final e in day.events) {
        add(e.time.text);
        add(e.icon.text);
        add(e.title.text);
        add(e.location.text);
        add(e.desc.text);
        add(e.tag.text);
        add(e.duration.text);
        add(e.eventImageUrl.text);
      }
    }
    for (final s in _mapStops) {
      add(s.icon.text);
      add(s.title.text);
      add(s.time.text);
      add(s.lat.text);
      add(s.lng.text);
    }
    return n;
  }

  bool _hasDataImageUrls() {
    bool dataUrl(String s) => AdminTourStorage.isDataImageUrl(s);
    if (dataUrl(_heroUrl.text)) return true;
    if (dataUrl(_overviewBgUrl.text)) return true;
    if (dataUrl(_itineraryTabImageUrl.text)) return true;
    if (dataUrl(_reviewTabImageUrl.text)) return true;
    if (dataUrl(_mapTabImageUrl.text)) return true;
    for (final u in _galleryUrls) {
      if (dataUrl(u)) return true;
    }
    for (final u in _reviewMarketingUrls) {
      if (dataUrl(u)) return true;
    }
    for (final day in _days) {
      for (final e in day.events) {
        if (dataUrl(e.eventImageUrl.text)) return true;
      }
    }
    return false;
  }

  /// Non-empty image fields must be `http://` or `https://` (Option A).
  bool _hasNonHttpTourImageUrl() {
    bool bad(String s) {
      final t = s.trim();
      if (t.isEmpty) return false;
      return !AdminTourStorage.isHttpUrl(t);
    }

    if (bad(_heroUrl.text)) return true;
    if (bad(_overviewBgUrl.text)) return true;
    if (bad(_itineraryTabImageUrl.text)) return true;
    if (bad(_reviewTabImageUrl.text)) return true;
    if (bad(_mapTabImageUrl.text)) return true;
    for (final u in _galleryUrls) {
      if (bad(u)) return true;
    }
    for (final u in _reviewMarketingUrls) {
      if (bad(u)) return true;
    }
    for (final day in _days) {
      for (final e in day.events) {
        if (bad(e.eventImageUrl.text)) return true;
      }
    }
    return false;
  }

  Future<void> _showAddImageUrlDialog({
    required String title,
    required void Function(String url) onAdd,
  }) async {
    final ctrl = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (dialogCtx) {
        final dc = dialogCtx.adminColors;
        return AlertDialog(
          backgroundColor: dc.surface,
          title: Text(title, style: GoogleFonts.dmSans(color: dc.textPrimary)),
          content: TextField(
            controller: ctrl,
            style: GoogleFonts.dmSans(color: dc.textPrimary, fontSize: 13),
            decoration: InputDecoration(
              hintText: 'https://…',
              hintStyle: GoogleFonts.dmSans(color: dc.muted, fontSize: 12),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: dc.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: BrandColors.accent),
              ),
              filled: true,
              fillColor: dc.inputFill,
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: Text('Cancel', style: GoogleFonts.dmSans(color: dc.muted)),
            ),
            FilledButton(
              onPressed: () {
                final u = ctrl.text.trim();
                if (!AdminTourStorage.isHttpUrl(u)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Enter a direct image URL starting with https://',
                        style: GoogleFonts.dmSans(),
                      ),
                    ),
                  );
                  return;
                }
                onAdd(u);
                Navigator.of(dialogCtx).pop();
              },
              style: FilledButton.styleFrom(
                backgroundColor: BrandColors.accent,
                foregroundColor: BrandColors.onAccent,
              ),
              child: Text(
                'Add',
                style: GoogleFonts.dmSans(
                  fontWeight: FontWeight.w700,
                  color: BrandColors.onAccent,
                ),
              ),
            ),
          ],
        );
      },
    );
    ctrl.dispose();
  }

  Future<void> _save() async {
    final title = _title.text.trim();
    if (title.isEmpty) return;

    setState(() => _saving = true);
    try {
      if (_hasDataImageUrls()) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Remove base64 (data:image/…) fields. Use short https:// image links from ImgBB, Imgur, etc.',
              style: GoogleFonts.dmSans(),
            ),
            backgroundColor: const Color(0xFFB71C1C),
          ),
        );
        return;
      }
      if (_hasNonHttpTourImageUrl()) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Every tour image field must be empty or a full link starting with https:// or http:// (direct image URL).',
              style: GoogleFonts.dmSans(),
            ),
            backgroundColor: const Color(0xFFB71C1C),
          ),
        );
        return;
      }

      const maxEmbeddedChars = 950000;
      if (_roughPayloadStringBytes() > maxEmbeddedChars) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Tour data is still too large for Firestore. Shorten descriptions or remove images.',
              style: GoogleFonts.dmSans(),
            ),
          ),
        );
        return;
      }

      final price = double.tryParse(_price.text) ?? 0;
      final rating = double.tryParse(_rating.text) ?? 0;
      final sort = int.tryParse(_sortOrder.text) ?? 0;
      final maxCap = int.tryParse(_maxCap.text) ?? 0;

      final itineraryDays = <Map<String, dynamic>>[];
      for (final day in _days) {
        itineraryDays.add({
          'title': day.title.text.trim(),
          'subtitle': day.subtitle.text.trim(),
          'events': day.events.map((e) => e.toMap()).toList(),
        });
      }

      final stops = <Map<String, dynamic>>[];
      for (final s in _mapStops) {
        final lat = double.tryParse(s.lat.text);
        final lng = double.tryParse(s.lng.text);
        if (s.title.text.trim().isEmpty) continue;
        stops.add({
          'icon': s.icon.text.trim().isEmpty ? '📍' : s.icon.text.trim(),
          'title': s.title.text.trim(),
          'time': s.time.text.trim(),
          'lat': lat,
          'lng': lng,
        });
      }

      final centerLat = double.tryParse(_mapLat.text);
      final centerLng = double.tryParse(_mapLng.text);
      final mapConfig = <String, dynamic>{
        if (centerLat != null) 'center_lat': centerLat,
        if (centerLng != null) 'center_lng': centerLng,
        'stat_distance': _mapDist.text.trim(),
        'stat_drive': _mapDrive.text.trim(),
        'stat_peak': _mapPeak.text.trim(),
        'stat_route': _mapRoute.text.trim(),
        'stops': stops,
      };

      final visibility = <String, dynamic>{
        'home_features': _vHomeFeatures,
        'activity_hiking': _vHiking,
        'activity_cycling': _vCycling,
        'activity_trekking': _vTrekking,
        'activity_tuk_tuk_ride': _vTukTuk,
        'activity_jeep': _vJeep,
        'activity_cookery': _vCookery,
        'booking_popular': _vBookingPopular,
        'booking_see_all': _vBookingSeeAll,
        'environment_cultural': _vEnvCultural,
        'environment_beach': _vEnvBeach,
        'environment_wildlife': _vEnvWildlife,
        'environment_mountain': _vEnvMountain,
        'environment_food': _vEnvFood,
      };

      final payload = <String, dynamic>{
        'tourName': title,
        'title': title,
        'location': _location.text.trim(),
        'category': _categoryChoice,
        'image_url': _heroUrl.text.trim(),
        'overview_background_image_url': _overviewBgUrl.text.trim(),
        'description': _shortDesc.text.trim(),
        'overview_body': _overview.text.trim(),
        'inclusions': _lines(_inclusions.text),
        'exclusions': _lines(_exclusions.text),
        'gallery_urls': List<String>.from(_galleryUrls),
        'review_marketing_gallery_urls': List<String>.from(_reviewMarketingUrls),
        'review_display_count': int.tryParse(_reviewCount.text) ?? 124,
        'itinerary_days': itineraryDays,
        'itinerary_tab_image_url': _itineraryTabImageUrl.text.trim(),
        'review_tab_image_url': _reviewTabImageUrl.text.trim(),
        'map_tab_image_url': _mapTabImageUrl.text.trim(),
        'map_config': mapConfig,
        'weather_note': _weather.text.trim(),
        'basePrice': price,
        'price': price,
        'currency': _currency.text.trim().isEmpty ? 'LKR' : _currency.text.trim(),
        'duration': _duration.text.trim(),
        'maxCapacity': maxCap,
        'max_capacity': maxCap,
        'rating': rating,
        'sort_order': sort,
        'emoji': _emoji.text.trim().isEmpty ? '🗺' : _emoji.text.trim(),
        'featured': _vBookingPopular,
        'featured_rank': 0,
        'visibility': visibility,
        'isActive': _published,
        'published': _published,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final col = FirebaseFirestore.instance.collection('tours');
      if (widget.docId == null) {
        payload['createdAt'] = FieldValue.serverTimestamp();
        await col.add(payload);
        await ActivityLogService.log(
          type: 'tour',
          message: 'Tour added: $title',
        );
      } else {
        await col.doc(widget.docId).update(payload);
        await ActivityLogService.log(
          type: 'tour',
          message: 'Tour updated: $title',
        );
      }

      if (mounted) Navigator.of(context).pop(true);
    } on FirebaseException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _saveErrorMessage(e),
            style: GoogleFonts.dmSans(),
          ),
          backgroundColor: const Color(0xFFB71C1C),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not save tour: $e',
            style: GoogleFonts.dmSans(),
          ),
          backgroundColor: const Color(0xFFB71C1C),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _saveErrorMessage(FirebaseException e) {
    final m = e.message ?? '';
    if (e.code == 'permission-denied') {
      return 'Firestore permission denied. Check security rules for the tours collection.';
    }
    if (m.contains('longer than') ||
        m.contains('1048487') ||
        m.toLowerCase().contains('exceed')) {
      return 'Document too large for Firestore (max 1 MB). Shorten text or use fewer / shorter https:// image links.';
    }
    return 'Could not save: ${e.message ?? e.code}';
  }

  InputDecoration _dec(BuildContext context, String label) {
    final c = context.adminColors;
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.dmSans(color: c.muted, fontSize: 12),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: c.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: BrandColors.accent),
      ),
      filled: true,
      fillColor: c.inputFill,
    );
  }

  TextStyle _valueStyle(BuildContext context) {
    final c = context.adminColors;
    return GoogleFonts.dmSans(color: c.textPrimary, fontSize: 13);
  }

  /// Option A — all tour photos are pasted **https://** links (no Storage upload).
  Widget _tourImagesPolicyBanner(BuildContext context) {
    final c = context.adminColors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: BrandColors.accent.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: BrandColors.accent.withValues(alpha: 0.35),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.link_rounded, size: 20, color: BrandColors.accent),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Tour images everywhere on this page: use direct https:// links only (ImgBB, Imgur, etc.). No device upload, no Firebase Storage, no base64.',
                style: GoogleFonts.dmSans(
                  fontSize: 11.5,
                  color: c.textPrimary,
                  height: 1.45,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.adminColors;
    if (_loading) {
      return Scaffold(
        backgroundColor: c.pageBackground,
        body: const Center(
          child: CircularProgressIndicator(color: BrandColors.accent),
        ),
      );
    }

    return Scaffold(
      backgroundColor: c.pageBackground,
      appBar: AppBar(
        backgroundColor: c.topBarBackground,
        foregroundColor: c.textPrimary,
        elevation: 0,
        title: Text(
          widget.docId == null ? 'Add Tour Package' : 'Edit Tour Package',
          style: GoogleFonts.dmSans(fontWeight: FontWeight.w600),
        ),
        actions: [
          TextButton(
            onPressed: _saving ? null : () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.dmSans(color: c.muted)),
          ),
          const SizedBox(width: 4),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilledButton(
              onPressed: _saving ? null : _showPublishDialog,
              style: FilledButton.styleFrom(
                backgroundColor: BrandColors.accent,
                foregroundColor: BrandColors.onAccent,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              ),
              child: Text(
                'Publish',
                style: GoogleFonts.dmSans(
                  fontWeight: FontWeight.w700,
                  color: BrandColors.onAccent,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _tourImagesPolicyBanner(context),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                const breakpoint = 1000.0;
                if (constraints.maxWidth < breakpoint) {
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    children: [
                      _partShell(
                        context,
                        step: '1',
                        title: 'Overview',
                        subtitle:
                            'Hero & gallery use https:// image URLs → story → white card → pricing',
                        children: _overviewFields(context),
                      ),
                      const SizedBox(height: 16),
                      _partShell(
                        context,
                        step: '2',
                        title: 'Itinerary',
                        subtitle:
                            'Days & events; optional event image = https:// URL',
                        children: _itineraryBody(context),
                      ),
                      const SizedBox(height: 16),
                      _partShell(
                        context,
                        step: '3',
                        title: 'Review',
                        subtitle:
                            'Review count + marketing strip (https:// URLs)',
                        children: _reviewBody(context),
                      ),
                      const SizedBox(height: 16),
                      _partShell(
                        context,
                        step: '4',
                        title: 'Map',
                        subtitle:
                            'Map tab hero (https://) + route stats & stops',
                        children: _mapSectionBody(context),
                      ),
                    ],
                  );
                }
                final border = c.border;
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      flex: 38,
                      child: _editorColumn(
                        context,
                        title: 'Overview',
                        subtitle:
                            'Hero & gallery use https:// image URLs → story → white card → pricing',
                        children: _overviewFields(context),
                      ),
                    ),
                    VerticalDivider(width: 1, thickness: 1, color: border),
                    Expanded(
                      flex: 24,
                      child: _editorColumn(
                        context,
                        title: 'Itinerary',
                        subtitle:
                            'Days & events; optional event image = https:// URL',
                        children: _itineraryBody(context),
                      ),
                    ),
                    VerticalDivider(width: 1, thickness: 1, color: border),
                    Expanded(
                      flex: 20,
                      child: _editorColumn(
                        context,
                        title: 'Review',
                        subtitle:
                            'Review count + marketing strip (https:// URLs)',
                        children: _reviewBody(context),
                      ),
                    ),
                    VerticalDivider(width: 1, thickness: 1, color: border),
                    Expanded(
                      flex: 18,
                      child: _editorColumn(
                        context,
                        title: 'Map',
                        subtitle:
                            'Map tab hero (https://) + route stats & stops',
                        children: _mapSectionBody(context),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Choose where the tour appears in the user app, then write to Firestore (`tours`).
  Future<void> _showPublishDialog() async {
    final rootCtx = context;
    var published = _published;
    var vHome = _vHomeFeatures;
    var vHike = _vHiking;
    var vCycle = _vCycling;
    var vTrek = _vTrekking;
    var vTuk = _vTukTuk;
    var vJeep = _vJeep;
    var vCook = _vCookery;
    var vPop = _vBookingPopular;
    var vSee = _vBookingSeeAll;
    var vCult = _vEnvCultural;
    var vBeach = _vEnvBeach;
    var vWild = _vEnvWildlife;
    var vMount = _vEnvMountain;
    var vFood = _vEnvFood;

    await showDialog<void>(
      context: context,
      barrierDismissible: !_saving,
      builder: (dialogContext) {
        final dc = dialogContext.adminColors;
        return StatefulBuilder(
          builder: (dialogContext, setLocal) {
            Widget cb(String label, bool value, void Function(bool) apply) {
              return CheckboxListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(
                  label,
                  style: GoogleFonts.dmSans(
                    color: dc.textPrimary,
                    fontSize: 13,
                  ),
                ),
                value: value,
                activeColor: BrandColors.accent,
                onChanged: _saving
                    ? null
                    : (v) => setLocal(() => apply(v ?? false)),
              );
            }

            return AlertDialog(
              backgroundColor: dc.dialogBackground,
              title: Text(
                'Publish to app',
                style: GoogleFonts.dmSans(
                  color: dc.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              content: SizedBox(
                width: 420,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Select where this package should appear in the user app. Tour images must already be https:// links (see banner on the editor). Data saves to Firestore `tours`.',
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          color: dc.muted,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          'Published (live in app)',
                          style: GoogleFonts.dmSans(color: dc.textPrimary),
                        ),
                        value: published,
                        activeThumbColor: BrandColors.accent,
                        activeTrackColor:
                            BrandColors.accent.withValues(alpha: 0.35),
                        onChanged: _saving
                            ? null
                            : (v) => setLocal(() => published = v),
                      ),
                      const Divider(),
                      cb('Home — Featured Tours strip', vHome,
                          (v) => vHome = v),
                      const SizedBox(height: 4),
                      Text(
                        'Home — Activities',
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: dc.muted,
                        ),
                      ),
                      cb('  Hiking', vHike, (v) => vHike = v),
                      cb('  Cycling', vCycle, (v) => vCycle = v),
                      cb('  Trekking', vTrek, (v) => vTrek = v),
                      cb('  Tuk tuk ride', vTuk, (v) => vTuk = v),
                      cb('  Jeep', vJeep, (v) => vJeep = v),
                      cb('  Cookery session', vCook, (v) => vCook = v),
                      const SizedBox(height: 4),
                      Text(
                        'Booking / Explore',
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: dc.muted,
                        ),
                      ),
                      cb('Popular Tours (explore dashboard)', vPop,
                          (v) => vPop = v),
                      cb('Discover — See all list', vSee, (v) => vSee = v),
                      const SizedBox(height: 4),
                      Text(
                        'Environment filters (Discover chips)',
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: dc.muted,
                        ),
                      ),
                      cb('Cultural', vCult, (v) => vCult = v),
                      cb('Beach', vBeach, (v) => vBeach = v),
                      cb('Wildlife', vWild, (v) => vWild = v),
                      cb('Mountain', vMount, (v) => vMount = v),
                      cb('Food', vFood, (v) => vFood = v),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed:
                      _saving ? null : () => Navigator.of(dialogContext).pop(),
                  child: Text(
                    'Close',
                    style: GoogleFonts.dmSans(color: dc.muted),
                  ),
                ),
                FilledButton(
                  onPressed: _saving
                      ? null
                      : () async {
                          if (_title.text.trim().isEmpty) {
                            ScaffoldMessenger.of(rootCtx).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Add a tour title before publishing.',
                                  style: GoogleFonts.dmSans(),
                                ),
                              ),
                            );
                            return;
                          }
                          if (_heroUrl.text.trim().isEmpty) {
                            ScaffoldMessenger.of(rootCtx).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Add a hero image URL (https://…) before publishing.',
                                  style: GoogleFonts.dmSans(),
                                ),
                              ),
                            );
                            return;
                          }
                          if (!AdminTourStorage.isHttpUrl(_heroUrl.text)) {
                            ScaffoldMessenger.of(rootCtx).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Hero image must be a direct https:// link (not base64).',
                                  style: GoogleFonts.dmSans(),
                                ),
                              ),
                            );
                            return;
                          }
                          setState(() {
                            _published = published;
                            _vHomeFeatures = vHome;
                            _vHiking = vHike;
                            _vCycling = vCycle;
                            _vTrekking = vTrek;
                            _vTukTuk = vTuk;
                            _vJeep = vJeep;
                            _vCookery = vCook;
                            _vBookingPopular = vPop;
                            _vBookingSeeAll = vSee;
                            _vEnvCultural = vCult;
                            _vEnvBeach = vBeach;
                            _vEnvWildlife = vWild;
                            _vEnvMountain = vMount;
                            _vEnvFood = vFood;
                          });
                          Navigator.of(dialogContext).pop();
                          await _save();
                        },
                  style: FilledButton.styleFrom(
                    backgroundColor: BrandColors.accent,
                    foregroundColor: BrandColors.onAccent,
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: BrandColors.onAccent,
                          ),
                        )
                      : Text(
                          widget.docId == null
                              ? 'Confirm & publish'
                              : 'Confirm & save',
                          style: GoogleFonts.dmSans(
                            fontWeight: FontWeight.w700,
                            color: BrandColors.onAccent,
                          ),
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Order matches user app **Overview** tab: title data → images → story →
  /// white card bullets → gallery → then pricing / listing fields.
  List<Widget> _overviewFields(BuildContext context) {
    final c = context.adminColors;
    Widget section(String t) => Padding(
          padding: const EdgeInsets.only(top: 4, bottom: 8),
          child: Text(
            t,
            style: GoogleFonts.dmSans(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
              color: c.muted,
            ),
          ),
        );

    return [
      section('USER APP — OVERVIEW (TOP → BOTTOM)'),
      TextField(
        controller: _title,
        style: _valueStyle(context),
        decoration: _dec(context, 'Tour title * (centered on Overview)'),
      ),
      const SizedBox(height: 12),
      TextField(
        controller: _emoji,
        style: _valueStyle(context),
        decoration: _dec(context, 'Emoji (admin grid)'),
      ),
      const SizedBox(height: 12),
      TextField(
        controller: _location,
        style: _valueStyle(context),
        decoration: _dec(context, 'Location (under title on Overview)'),
      ),
      const SizedBox(height: 12),
      DropdownButtonFormField<String>(
        initialValue: _categoryChoice,
        style: _valueStyle(context),
        dropdownColor: context.adminColors.surface,
        decoration: _dec(context, 'Category'),
        items: const [
          DropdownMenuItem(value: 'Cultural', child: Text('Cultural')),
          DropdownMenuItem(value: 'Beach', child: Text('Beach')),
          DropdownMenuItem(value: 'Wildlife', child: Text('Wildlife')),
          DropdownMenuItem(value: 'Mountain', child: Text('Mountain')),
          DropdownMenuItem(value: 'Food', child: Text('Food')),
          DropdownMenuItem(value: 'Other', child: Text('Other')),
        ],
        onChanged: (v) => setState(() => _categoryChoice = v ?? 'Cultural'),
      ),
      const SizedBox(height: 12),
      AdminImagePickRow(
        label: 'Hero / header image * — https:// link (top banner, all tabs)',
        urlController: _heroUrl,
      ),
      const SizedBox(height: 12),
      Text(
        'Overview tab — full-width background (optional)',
        style: GoogleFonts.dmSans(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: c.muted,
        ),
      ),
      const SizedBox(height: 6),
      AdminImagePickRow(
        label: 'Overview background (optional) — https:// image URL',
        urlController: _overviewBgUrl,
        compactPreview: true,
      ),
      const SizedBox(height: 16),
      TextField(
        controller: _overview,
        minLines: 5,
        maxLines: 12,
        style: _valueStyle(context),
        decoration: _dec(
          context,
          'Long overview — paragraph under title (mobile)',
        ),
      ),
      const SizedBox(height: 12),
      TextField(
        controller: _inclusions,
        minLines: 3,
        maxLines: 8,
        style: _valueStyle(context),
        decoration: _dec(
          context,
          "What's included — one line per bullet (white card)",
        ),
      ),
      const SizedBox(height: 12),
      TextField(
        controller: _exclusions,
        minLines: 2,
        maxLines: 8,
        style: _valueStyle(context),
        decoration: _dec(
          context,
          "Not included — one line per item (other tabs if used)",
        ),
      ),
      const SizedBox(height: 16),
      _galleryBlock(context),
      section('PRICING & LIST / CHIPS (HEADER AREA)'),
      TextField(
        controller: _shortDesc,
        maxLines: 2,
        style: _valueStyle(context),
        decoration: _dec(context, 'Short description (admin cards)'),
      ),
      const SizedBox(height: 12),
      TextField(
        controller: _price,
        keyboardType: TextInputType.number,
        style: _valueStyle(context),
        decoration: _dec(context, 'Price (number)'),
      ),
      const SizedBox(height: 12),
      TextField(
        controller: _currency,
        style: _valueStyle(context),
        decoration: _dec(context, 'Currency'),
      ),
      const SizedBox(height: 12),
      TextField(
        controller: _duration,
        style: _valueStyle(context),
        decoration: _dec(context, 'Duration (e.g. 4D/3N)'),
      ),
      const SizedBox(height: 12),
      TextField(
        controller: _maxCap,
        keyboardType: TextInputType.number,
        style: _valueStyle(context),
        decoration: _dec(context, 'Max group size'),
      ),
      const SizedBox(height: 12),
      TextField(
        controller: _weather,
        style: _valueStyle(context),
        decoration: _dec(context, 'Weather line (e.g. 24°C)'),
      ),
      const SizedBox(height: 12),
      TextField(
        controller: _rating,
        keyboardType: TextInputType.number,
        style: _valueStyle(context),
        decoration: _dec(context, 'Rating (0–5)'),
      ),
      const SizedBox(height: 12),
      TextField(
        controller: _sortOrder,
        keyboardType: TextInputType.number,
        style: _valueStyle(context),
        decoration: _dec(context, 'Sort order (lower first)'),
      ),
    ];
  }

  /// One scrollable wireframe column (desktop ≥ breakpoint).
  Widget _editorColumn(
    BuildContext context, {
    required String title,
    required String subtitle,
    required List<Widget> children,
  }) {
    final c = context.adminColors;
    return Material(
      color: c.pageBackground,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(12, 14, 12, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: GoogleFonts.dmSans(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: c.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: GoogleFonts.dmSans(
                fontSize: 11,
                color: c.muted,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 14),
            ...children,
          ],
        ),
      ),
    );
  }

  List<Widget> _itineraryBody(BuildContext context) {
    final c = context.adminColors;
    return [
      Text(
        'Itinerary tab — header image (optional)',
        style: GoogleFonts.dmSans(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: c.muted,
        ),
      ),
      const SizedBox(height: 6),
      Text(
        'When set, the user app shows this image (https URL above) in the top banner only while the Itinerary tab is open.',
        style: GoogleFonts.dmSans(fontSize: 11, color: c.muted, height: 1.35),
      ),
      const SizedBox(height: 10),
      AdminImagePickRow(
        label: 'Image URL (https) — Itinerary tab hero',
        urlController: _itineraryTabImageUrl,
        compactPreview: true,
      ),
      const SizedBox(height: 18),
      Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: () {
            setState(() => _days.add(_DayBlock()));
          },
          icon: const Icon(Icons.add, color: BrandColors.accent, size: 18),
          label: Text(
            'Add day',
            style: GoogleFonts.dmSans(
              color: BrandColors.accent,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
      ..._days.asMap().entries.map((e) {
        final i = e.key;
        final day = e.value;
        return Card(
          color: c.surface,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: c.border),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Day ${i + 1}',
                  style: GoogleFonts.dmSans(
                    color: c.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (_days.length > 1)
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      tooltip: 'Remove day',
                      onPressed: () {
                        setState(() {
                          day.dispose();
                          _days.removeAt(i);
                        });
                      },
                      icon: const Icon(Icons.delete_outline,
                          color: Color(0xFFF47067), size: 20),
                    ),
                  ),
                const SizedBox(height: 8),
                TextField(
                  controller: day.title,
                  style: _valueStyle(context),
                  decoration: _dec(context, 'Day title (e.g. Colombo → Sigiriya)'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: day.subtitle,
                  style: _valueStyle(context),
                  decoration: _dec(
                    context,
                    'Subtitle (e.g. March 9 Departure & Arrival)',
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Timeline events',
                  style: GoogleFonts.dmSans(
                    color: c.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                ...day.events.asMap().entries.map((ev) {
                  final j = ev.key;
                  final row = ev.value;
                  return _eventCard(context, day, i, j, row);
                }),
                TextButton.icon(
                  onPressed: () {
                    setState(() => day.events.add(_EventRow()));
                  },
                  icon: const Icon(Icons.add, size: 16, color: BrandColors.accent),
                  label: Text(
                    'Add event',
                    style: GoogleFonts.dmSans(color: BrandColors.accent),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    ];
  }

  Widget _eventCard(
    BuildContext context,
    _DayBlock day,
    int dayIndex,
    int j,
    _EventRow row,
  ) {
    final c = context.adminColors;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: c.inputFill,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Event ${j + 1}',
            style: GoogleFonts.dmSans(color: c.muted, fontSize: 11),
          ),
          if (day.events.length > 1)
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () {
                  setState(() {
                    row.dispose();
                    day.events.removeAt(j);
                  });
                },
                icon: const Icon(Icons.close, size: 18, color: Colors.redAccent),
              ),
            ),
          const SizedBox(height: 6),
          TextField(
            controller: row.time,
            style: _valueStyle(context),
            decoration: _dec(context, 'Time'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: row.icon,
            style: _valueStyle(context),
            decoration: _dec(context, 'Icon (emoji)'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: row.title,
            style: _valueStyle(context),
            decoration: _dec(context, 'Title'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: row.location,
            style: _valueStyle(context),
            decoration: _dec(context, 'Location (optional)'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: row.desc,
            maxLines: 2,
            style: _valueStyle(context),
            decoration: _dec(context, 'Description'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: row.tag,
            style: _valueStyle(context),
            decoration: _dec(context, 'Tag (e.g. Transport included)'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: row.duration,
            style: _valueStyle(context),
            decoration: _dec(context, 'Duration'),
          ),
          const SizedBox(height: 8),
          AdminImagePickRow(
            label: 'Optional image URL for this event (https)',
            urlController: row.eventImageUrl,
            compactPreview: true,
          ),
        ],
      ),
    );
  }

  List<Widget> _mapSectionBody(BuildContext context) {
    final c = context.adminColors;
    return [
      Text(
        'Map tab — header image (optional)',
        style: GoogleFonts.dmSans(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: c.muted,
        ),
      ),
      const SizedBox(height: 6),
      Text(
        'When set, the user app shows this image (https URL above) in the top banner only while the Map tab is open.',
        style: GoogleFonts.dmSans(fontSize: 11, color: c.muted, height: 1.35),
      ),
      const SizedBox(height: 10),
      AdminImagePickRow(
        label: 'Image URL (https) — Map tab hero',
        urlController: _mapTabImageUrl,
        compactPreview: true,
      ),
      const SizedBox(height: 16),
      TextField(
        controller: _mapLat,
        keyboardType: TextInputType.number,
        style: _valueStyle(context),
        decoration: _dec(context, 'Map center latitude'),
      ),
      const SizedBox(height: 12),
      TextField(
        controller: _mapLng,
        keyboardType: TextInputType.number,
        style: _valueStyle(context),
        decoration: _dec(context, 'Map center longitude'),
      ),
      const SizedBox(height: 12),
      TextField(
        controller: _mapDist,
        style: _valueStyle(context),
        decoration: _dec(context, 'Stat: distance'),
      ),
      const SizedBox(height: 12),
      TextField(
        controller: _mapDrive,
        style: _valueStyle(context),
        decoration: _dec(context, 'Stat: drive time'),
      ),
      const SizedBox(height: 12),
      TextField(
        controller: _mapPeak,
        style: _valueStyle(context),
        decoration: _dec(context, 'Stat: peak / height'),
      ),
      const SizedBox(height: 12),
      TextField(
        controller: _mapRoute,
        style: _valueStyle(context),
        decoration: _dec(context, 'Stat: route name'),
      ),
      const SizedBox(height: 12),
      Text(
        'Stops (markers + list)',
        style: GoogleFonts.dmSans(color: c.muted, fontSize: 12),
      ),
      const SizedBox(height: 8),
      ..._mapStops.asMap().entries.map((e) {
        final i = e.key;
        final s = e.value;
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: c.inputFill,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: c.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Stop ${i + 1}', style: GoogleFonts.dmSans(color: c.muted)),
              if (_mapStops.length > 1)
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    onPressed: () {
                      setState(() {
                        s.dispose();
                        _mapStops.removeAt(i);
                      });
                    },
                    icon: const Icon(Icons.delete_outline,
                        color: Color(0xFFF47067), size: 20),
                  ),
                ),
              const SizedBox(height: 8),
              TextField(
                controller: s.icon,
                style: _valueStyle(context),
                decoration: _dec(context, 'Icon (emoji)'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: s.title,
                style: _valueStyle(context),
                decoration: _dec(context, 'Place name'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: s.time,
                style: _valueStyle(context),
                decoration: _dec(context, 'Timing label'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: s.lat,
                keyboardType: TextInputType.number,
                style: _valueStyle(context),
                decoration: _dec(context, 'Latitude'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: s.lng,
                keyboardType: TextInputType.number,
                style: _valueStyle(context),
                decoration: _dec(context, 'Longitude'),
              ),
            ],
          ),
        );
      }),
      Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: () => setState(() => _mapStops.add(_MapStopRow())),
          icon: const Icon(Icons.add, color: BrandColors.accent, size: 18),
          label: Text(
            'Add map stop',
            style: GoogleFonts.dmSans(color: BrandColors.accent),
          ),
        ),
      ),
    ];
  }

  Widget _galleryBlock(BuildContext context) {
    final c = context.adminColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Gallery (Overview tab) — add https:// image URLs',
          style: GoogleFonts.dmSans(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: c.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        ..._galleryUrls.map((url) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    url,
                    height: 120,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () => setState(() => _galleryUrls.remove(url)),
                    icon: const Icon(Icons.delete_outline,
                        color: Color(0xFFF47067), size: 20),
                    label: Text(
                      'Remove',
                      style: GoogleFonts.dmSans(color: const Color(0xFFF47067)),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
        TextButton.icon(
          onPressed: _saving
              ? null
              : () async {
                  await _showAddImageUrlDialog(
                    title: 'Gallery image URL',
                    onAdd: (url) => setState(() => _galleryUrls.add(url)),
                  );
                },
          icon: const Icon(Icons.link_rounded, color: BrandColors.accent, size: 20),
          label: Text(
            'Add gallery image URL',
            style: GoogleFonts.dmSans(color: BrandColors.accent),
          ),
        ),
      ],
    );
  }

  Widget _adminReviewInitialAvatar(String initial) {
    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      color: const Color(0xFFE3F2FD),
      child: Text(
        initial,
        style: GoogleFonts.dmSans(
          fontWeight: FontWeight.w800,
          fontSize: 14,
          color: Colors.black87,
        ),
      ),
    );
  }

  List<Widget> _reviewBody(BuildContext context) {
    final c = context.adminColors;
    return [
      Text(
        'Review tab — header image (optional)',
        style: GoogleFonts.dmSans(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: c.muted,
        ),
      ),
      const SizedBox(height: 6),
      Text(
        'When set, the user app shows this image (https URL above) in the top banner only while the Review tab is open.',
        style: GoogleFonts.dmSans(fontSize: 11, color: c.muted, height: 1.35),
      ),
      const SizedBox(height: 10),
      AdminImagePickRow(
        label: 'Image URL (https) — Review tab hero',
        urlController: _reviewTabImageUrl,
        compactPreview: true,
      ),
      const SizedBox(height: 18),
      TextField(
        controller: _reviewCount,
        keyboardType: TextInputType.number,
        style: _valueStyle(context),
        decoration: _dec(
          context,
          'Review count shown on Review tab (e.g. 124)',
        ),
      ),
      if (widget.docId != null) ...[
        const SizedBox(height: 20),
        Text(
          'Guest reviews (pending)',
          style: GoogleFonts.dmSans(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: c.muted,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Completed-trip reviews appear here. Tap Add to publish them on the tour in the user app.',
          style: GoogleFonts.dmSans(fontSize: 11, color: c.muted, height: 1.35),
        ),
        const SizedBox(height: 12),
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('tours')
              .doc(widget.docId)
              .collection('guest_reviews')
              .where('approved', isEqualTo: false)
              .snapshots(),
          builder: (context, snap) {
            if (snap.hasError) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'Could not load reviews: ${snap.error}',
                  style: GoogleFonts.dmSans(fontSize: 12, color: c.muted),
                ),
              );
            }
            if (snap.connectionState == ConnectionState.waiting &&
                !snap.hasData) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              );
            }
            final docs = snap.data?.docs ?? const [];
            if (docs.isEmpty) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  'No pending reviews.',
                  style: GoogleFonts.dmSans(fontSize: 12, color: c.muted),
                ),
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: docs.map((doc) {
                final d = doc.data();
                final name = (d['user_name'] ?? 'Guest').toString();
                final text =
                    (d['comment_text'] ?? d['text'] ?? '').toString();
                final rating = (d['rating'] as num?)?.toDouble() ?? 0;
                final photo =
                    (d['user_photo_url'] ?? '').toString().trim();
                final img =
                    (d['review_image_url'] ?? '').toString().trim();
                final hasAvatar =
                    photo.startsWith('http') || photo.startsWith('data:');
                final initial = name.trim().isEmpty
                    ? '?'
                    : name.trim().substring(0, 1).toUpperCase();
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  color: c.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: c.border),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: hasAvatar
                                  ? Image.network(
                                      photo,
                                      width: 40,
                                      height: 40,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) =>
                                          _adminReviewInitialAvatar(initial),
                                    )
                                  : _adminReviewInitialAvatar(initial),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: GoogleFonts.dmSans(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                      color: c.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    '${rating.toStringAsFixed(1)} ★',
                                    style: GoogleFonts.dmSans(
                                      fontSize: 11,
                                      color: c.muted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (text.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            text,
                            maxLines: 4,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.dmSans(
                              fontSize: 12,
                              height: 1.4,
                              color: c.textPrimary,
                            ),
                          ),
                        ],
                        if (img.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              img,
                              height: 88,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  const SizedBox.shrink(),
                            ),
                          ),
                        ],
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerRight,
                          child: FilledButton(
                            onPressed: _saving
                                ? null
                                : () async {
                                    try {
                                      await FirebaseFirestore.instance
                                          .collection('tours')
                                          .doc(widget.docId)
                                          .collection('guest_reviews')
                                          .doc(doc.id)
                                          .update({
                                        'approved': true,
                                        'approved_at':
                                            FieldValue.serverTimestamp(),
                                      });
                                    } catch (e) {
                                      if (!context.mounted) return;
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Could not approve: $e',
                                            style: GoogleFonts.dmSans(),
                                          ),
                                        ),
                                      );
                                    }
                                  },
                            style: FilledButton.styleFrom(
                              backgroundColor: BrandColors.accent,
                              foregroundColor: BrandColors.onAccent,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 8,
                              ),
                            ),
                            child: Text(
                              'Add',
                              style: GoogleFonts.dmSans(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
      const SizedBox(height: 16),
      Text(
        'Marketing / sample images — https:// URLs (horizontal strip)',
        style: GoogleFonts.dmSans(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: c.muted,
        ),
      ),
      const SizedBox(height: 8),
      ..._reviewMarketingUrls.map((url) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  url,
                  height: 100,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () =>
                      setState(() => _reviewMarketingUrls.remove(url)),
                  icon: const Icon(Icons.delete_outline,
                      color: Color(0xFFF47067), size: 20),
                  label: Text(
                    'Remove',
                    style: GoogleFonts.dmSans(color: const Color(0xFFF47067)),
                  ),
                ),
              ),
            ],
          ),
        );
      }),
      TextButton.icon(
        onPressed: _saving
            ? null
            : () async {
                await _showAddImageUrlDialog(
                  title: 'Review-strip image URL',
                  onAdd: (url) => setState(() => _reviewMarketingUrls.add(url)),
                );
              },
        icon: const Icon(Icons.link_rounded, color: BrandColors.accent, size: 20),
        label: Text(
          'Add review-strip image URL',
          style: GoogleFonts.dmSans(color: BrandColors.accent),
        ),
      ),
    ];
  }

  Widget _partShell(
    BuildContext context, {
    required String step,
    required String title,
    required String subtitle,
    required List<Widget> children,
  }) {
    final c = context.adminColors;
    return Card(
      color: c.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: c.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              alignment: Alignment.centerLeft,
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: BrandColors.accent.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                step,
                style: GoogleFonts.dmSans(
                  fontWeight: FontWeight.w800,
                  color: BrandColors.accent,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: GoogleFonts.dmSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: c.textPrimary,
              ),
            ),
            Text(
              subtitle,
              style: GoogleFonts.dmSans(fontSize: 11, color: c.muted),
            ),
            const SizedBox(height: 14),
            ...children,
          ],
        ),
      ),
    );
  }

}
