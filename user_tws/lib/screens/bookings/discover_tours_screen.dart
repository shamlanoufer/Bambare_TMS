import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/booking_background.dart';
import '../../models/tour.dart';
import '../../services/tour_service.dart';
import 'tour_detail_screen.dart';

class DiscoverToursScreen extends StatefulWidget {
<<<<<<< HEAD
  const DiscoverToursScreen({super.key, this.initialCategory, this.initialQuery});

  final String? initialCategory;
  final String? initialQuery;
=======
  const DiscoverToursScreen({super.key, this.initialCategory});

  final String? initialCategory;
>>>>>>> a28bf1f775365ea426a204b88ca42cc04604a505

  static const _priceGreen = Color(0xFF2E7D32);

  @override
  State<DiscoverToursScreen> createState() => _DiscoverToursScreenState();
}

class _DiscoverToursScreenState extends State<DiscoverToursScreen> {
  final _tourService = TourService();
<<<<<<< HEAD
  final _searchCtrl = TextEditingController();
=======
>>>>>>> a28bf1f775365ea426a204b88ca42cc04604a505

  static const _accent = Color(0xFFE8B800);
  static const _ink = Colors.black87;

  late String _selectedCategory;
<<<<<<< HEAD
  late String _searchQuery;
  final Set<String> _filterCategories = <String>{};
  final Set<String> _filterDurations = <String>{};
  final Set<String> _filterGroupTypes = <String>{};
  static const double _minPrice = 4000;
  static const double _maxPrice = 45000;
  RangeValues _priceRange = const RangeValues(_minPrice, _maxPrice);
  double _minRating = 0;
=======
>>>>>>> a28bf1f775365ea426a204b88ca42cc04604a505

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory ?? 'All';
<<<<<<< HEAD
    _searchQuery = (widget.initialQuery ?? '').trim();
    _searchCtrl.text = _searchQuery;
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  String _fmtInt(num n) {
    final s = n.round().abs().toString();
    final b = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
      b.write(s[i]);
    }
    return b.toString();
  }

  bool _matchesDuration(Tour t) {
    if (_filterDurations.isEmpty) return true;
    final hay = '${t.title} ${t.locationLabel} ${t.category}'.toLowerCase();
    for (final d in _filterDurations) {
      final key = d.toLowerCase();
      if (hay.contains(key) ||
          (key == 'half day' && hay.contains('half-day')) ||
          (key == 'full day' && hay.contains('full-day'))) {
        return true;
      }
    }
    return false;
  }

  bool _matchesGroupType(Tour t) {
    if (_filterGroupTypes.isEmpty) return true;
    final hay = '${t.title} ${t.locationLabel} ${t.category}'.toLowerCase();
    for (final g in _filterGroupTypes) {
      if (hay.contains(g.toLowerCase())) return true;
    }
    return false;
  }

  bool _matchesFilterPanel(Tour t) {
    if (_filterCategories.isNotEmpty &&
        !_filterCategories.contains(t.category.toLowerCase())) {
      return false;
    }
    if (t.price < _priceRange.start || t.price > _priceRange.end) {
      return false;
    }
    if (t.rating < _minRating) return false;
    if (!_matchesDuration(t)) return false;
    if (!_matchesGroupType(t)) return false;
    return true;
  }

  Future<void> _openFilterSheet() async {
    final tmpCats = Set<String>.from(_filterCategories);
    final tmpDurations = Set<String>.from(_filterDurations);
    final tmpGroups = Set<String>.from(_filterGroupTypes);
    var tmpPrice = _priceRange;
    var tmpMinRating = _minRating;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            Widget chip(String label, bool selected, VoidCallback onTap) {
              return Padding(
                padding: const EdgeInsets.only(right: 8, bottom: 8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(999),
                  onTap: onTap,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8C247),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: selected ? Colors.black87 : Colors.transparent,
                        width: 1.2,
                      ),
                    ),
                    child: Text(
                      label,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
              );
            }

            Widget sectionCard(String title, List<Widget> children) {
              return Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4EEDC),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 10),
                    Wrap(children: children),
                  ],
                ),
              );
            }

            return SafeArea(
              child: Container(
                height: MediaQuery.sizeOf(context).height * 0.88,
                decoration: const BoxDecoration(
                  color: Color(0xFFF8F8F8),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 12),
                  child: Column(
                    children: [
                      Container(width: 40, height: 4, color: Colors.black26),
                      const SizedBox(height: 8),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              sectionCard('Category', [
                                for (final c in const ['Nature', 'Cultural', 'Beach', 'Wildlife', 'Adventure', 'Wellness', 'Events', 'Food', 'Mountain'])
                                  chip(c, tmpCats.contains(c.toLowerCase()), () {
                                    setModalState(() {
                                      final key = c.toLowerCase();
                                      if (!tmpCats.add(key)) tmpCats.remove(key);
                                    });
                                  }),
                              ]),
                              sectionCard('Duration', [
                                for (final d in const ['Half Day', 'Full Day', '2-3 Days', '4+ Days'])
                                  chip(d, tmpDurations.contains(d), () {
                                    setModalState(() {
                                      if (!tmpDurations.add(d)) tmpDurations.remove(d);
                                    });
                                  }),
                              ]),
                              Container(
                                width: double.infinity,
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF4EEDC),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Price Range', style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700)),
                                    RangeSlider(
                                      values: tmpPrice,
                                      min: _minPrice,
                                      max: _maxPrice,
                                      divisions: 41,
                                      activeColor: _accent,
                                      onChanged: (v) => setModalState(() => tmpPrice = v),
                                    ),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('LKR ${_fmtInt(tmpPrice.start)}'),
                                        Text('LKR ${_fmtInt(tmpPrice.end)}'),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              sectionCard('Minimum Rating', [
                                for (final r in const [0.0, 3.0, 4.0, 4.5])
                                  chip(
                                    r == 0 ? 'Any' : '${r.toStringAsFixed(r == 4.5 ? 1 : 0)}+',
                                    tmpMinRating == r,
                                    () => setModalState(() => tmpMinRating = r),
                                  ),
                              ]),
                              sectionCard('Group type', [
                                for (final g in const ['Private', 'Group', 'Family', 'Couple'])
                                  chip(g, tmpGroups.contains(g.toLowerCase()), () {
                                    setModalState(() {
                                      final key = g.toLowerCase();
                                      if (!tmpGroups.add(key)) tmpGroups.remove(key);
                                    });
                                  }),
                              ]),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: () {
                            setState(() {
                              _filterCategories
                                ..clear()
                                ..addAll(tmpCats);
                              _filterDurations
                                ..clear()
                                ..addAll(tmpDurations);
                              _filterGroupTypes
                                ..clear()
                                ..addAll(tmpGroups);
                              _priceRange = tmpPrice;
                              _minRating = tmpMinRating;
                            });
                            Navigator.of(ctx).pop();
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: _accent,
                            foregroundColor: Colors.black87,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                          ),
                          child: Text(
                            'Apply Filter',
                            style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
=======
>>>>>>> a28bf1f775365ea426a204b88ca42cc04604a505
  }
  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.paddingOf(context).top;
    final bottomSafe = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: BookingBackgroundLayer(
        child: Column(
        children: [
          // Custom Header
          Padding(
            padding: EdgeInsets.fromLTRB(16, topPad + 24, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded),
                      color: _ink,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                      tooltip: 'Back',
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Discover Tours',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: _ink,
                        ),
                      ),
                    ),
<<<<<<< HEAD
=======
                    const _SettingsButton(),
>>>>>>> a28bf1f775365ea426a204b88ca42cc04604a505
                  ],
                ),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.only(left: 40),
                  child: Text(
                    'Find your adventure',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black54,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Search & Filter
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
<<<<<<< HEAD
                Expanded(
                  child: _SearchBar(
                    controller: _searchCtrl,
                    onChanged: (v) => setState(() => _searchQuery = v.trim()),
                  ),
                ),
                const SizedBox(width: 12),
                InkWell(
                  onTap: _openFilterSheet,
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _accent,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.tune_rounded, color: _ink, size: 22),
                  ),
=======
                const Expanded(child: _SearchBar()),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _accent,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.tune_rounded, color: _ink, size: 22),
>>>>>>> a28bf1f775365ea426a204b88ca42cc04604a505
                ),
              ],
            ),
          ),

          // Categories
          const SizedBox(height: 16),
          SizedBox(
            height: 42,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                _CategoryChip(
                  label: 'All',
                  isSelected: _selectedCategory == 'All',
                  onTap: () => setState(() => _selectedCategory = 'All'),
                ),
                _CategoryChip(
                  label: 'Cultural',
                  isSelected: _selectedCategory == 'Cultural',
                  onTap: () => setState(() => _selectedCategory = 'Cultural'),
                ),
                _CategoryChip(
                  label: 'Beach',
                  isSelected: _selectedCategory == 'Beach',
                  onTap: () => setState(() => _selectedCategory = 'Beach'),
                ),
                _CategoryChip(
                  label: 'Wildlife',
                  isSelected: _selectedCategory == 'Wildlife',
                  onTap: () => setState(() => _selectedCategory = 'Wildlife'),
                ),
                _CategoryChip(
                  label: 'Mountain',
                  isSelected: _selectedCategory == 'Mountain',
                  onTap: () => setState(() => _selectedCategory = 'Mountain'),
                ),
                _CategoryChip(
                  label: 'Food',
                  isSelected: _selectedCategory == 'Food',
                  onTap: () => setState(() => _selectedCategory = 'Food'),
                ),
              ],
            ),
          ),

          // Tour List
          Expanded(
            child: StreamBuilder<List<Tour>>(
              stream: _tourService.allPublishedToursStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(color: _accent),
                  );
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Could not load tours.\n${snapshot.error}',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }
                final displayTours = snapshot.data ?? <Tour>[];
<<<<<<< HEAD
                final query = _searchQuery.toLowerCase();
                final queryTokens = query
                    .split(RegExp(r'\s+'))
                    .map((e) => e.trim())
                    .where((e) => e.isNotEmpty)
                    .toList();
=======
>>>>>>> a28bf1f775365ea426a204b88ca42cc04604a505
                final filteredTours = displayTours.where((t) {
                  if (_selectedCategory == 'All') return true;
                  final sel = _selectedCategory.toLowerCase();
                  if (t.category.toLowerCase() == sel) return true;
                  return t.visibility.matchesDiscoverCategory(_selectedCategory);
<<<<<<< HEAD
                }).where((t) {
                  if (query.isEmpty) return true;
                  final hay = '${t.title} ${t.locationLabel} ${t.category}'.toLowerCase();
                  return queryTokens.any(hay.contains);
                }).where(_matchesFilterPanel).toList();
=======
                }).toList();
>>>>>>> a28bf1f775365ea426a204b88ca42cc04604a505

                if (displayTours.isEmpty) {
                  return const Center(
                    child: Text(
                      'No tours yet. Add documents to the "tours" collection in Firebase (admin).',
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                if (filteredTours.isEmpty) {
<<<<<<< HEAD
                  final hasQuery = query.isNotEmpty;
                  final msg = hasQuery
                      ? 'No tours found for "$_searchQuery".'
                      : 'No tours found matching this category.';
                  return Center(
                    child: Text(msg),
=======
                  return const Center(
                    child: Text('No tours found matching this category.'),
>>>>>>> a28bf1f775365ea426a204b88ca42cc04604a505
                  );
                }

                return ListView.separated(
                  padding: EdgeInsets.fromLTRB(20, 20, 20, 28 + bottomSafe),
                  itemCount: filteredTours.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    return _DiscoverTourCard(tour: filteredTours[index]);
                  },
                );
              },
            ),
          ),
        ],
        ),
      ),
    );
  }
}

<<<<<<< HEAD
class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.controller,
    required this.onChanged,
  });

  static const double _radius = 26;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
=======
class _SettingsButton extends StatelessWidget {
  const _SettingsButton();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.75),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {},
        child: const Padding(
          padding: EdgeInsets.all(8),
          child: Icon(Icons.settings_outlined, color: Colors.black87, size: 22),
        ),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar();

  static const double _radius = 26;
>>>>>>> a28bf1f775365ea426a204b88ca42cc04604a505

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(_radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(_radius),
            color: Colors.white.withValues(alpha: 0.75),
            border: Border.all(
              color: Colors.black.withValues(alpha: 0.10),
              width: 1,
            ),
          ),
          child: TextField(
<<<<<<< HEAD
            controller: controller,
            textInputAction: TextInputAction.search,
            onChanged: onChanged,
=======
            readOnly: true,
>>>>>>> a28bf1f775365ea426a204b88ca42cc04604a505
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: Colors.black87,
            ),
            decoration: InputDecoration(
              hintText: 'Search tours, destinations...',
              hintStyle: GoogleFonts.plusJakartaSans(
                color: Colors.black54,
                fontSize: 14,
              ),
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: Colors.black54,
                size: 22,
              ),
<<<<<<< HEAD
              suffixIcon: IconButton(
                icon: const Icon(
                  Icons.close_rounded,
                  color: Colors.black54,
                  size: 20,
                ),
                onPressed: () {
                  if (controller.text.isEmpty) return;
                  controller.clear();
                  onChanged('');
                },
=======
              suffixIcon: const Icon(
                Icons.mic_none_rounded,
                color: Colors.black54,
                size: 22,
>>>>>>> a28bf1f775365ea426a204b88ca42cc04604a505
              ),
              filled: true,
              fillColor: Colors.transparent,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFFE8B800)
                : Colors.white.withValues(alpha: 0.70),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? Colors.transparent
                  : Colors.black.withValues(alpha: 0.08),
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ),
      ),
    );
  }
}

class _DiscoverTourCard extends StatelessWidget {
  const _DiscoverTourCard({required this.tour});

  final Tour tour;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TourDetailScreen(tour: tour),
          ),
        );
      },
      child: Container(
      height: 140,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          // Left: Image
          SizedBox(
            width: 120,
            height: 140,
            child: _TourImage(source: tour.imageUrl),
          ),
          // Right: Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category tag
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF9E0),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      tour.category.toLowerCase().capitalize(),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Title
                  Text(
                    tour.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Location
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: Colors.redAccent, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        tour.locationLabel,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.black45,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  // Price and Book button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        tour.formattedPrice,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: DiscoverToursScreen._priceGreen,
                        ),
                      ),
                      GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TourDetailScreen(tour: tour),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFBE697),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Book',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }

}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1).toLowerCase()}';
  }
}

class _TourImage extends StatelessWidget {
  const _TourImage({required this.source});
  final String source;
  @override
  Widget build(BuildContext context) {
    if (source.isEmpty) {
      return Container(color: Colors.grey.shade300, child: const Icon(Icons.image_not_supported));
    }
    if (source.startsWith('http')) {
      return Image.network(source, fit: BoxFit.cover);
    }
    // Handle local assets
    return Image.asset(
      source,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: Colors.grey.shade200,
          child: const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
        );
      },
    );
  }
}
