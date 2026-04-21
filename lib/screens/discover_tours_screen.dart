import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/tour.dart';
import '../services/tour_service.dart';
import 'tour_detail_screen.dart';

class DiscoverToursScreen extends StatefulWidget {
  const DiscoverToursScreen({super.key, this.initialCategory});

  final String? initialCategory;

  static const _searchFill = Color(0xFFF2F0EB);
  static const _priceGreen = Color(0xFF2E7D32);

  @override
  State<DiscoverToursScreen> createState() => _DiscoverToursScreenState();
}

class _DiscoverToursScreenState extends State<DiscoverToursScreen> {
  final _tourService = TourService();

  static const _bg = Color(0xFFFFFBF0);
  static const _accent = Color(0xFFE8B800);

  late String _selectedCategory;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory ?? 'All';
  }
  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.paddingOf(context).top;
    final bottomSafe = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: _bg,
      body: Column(
        children: [
          // Custom Header
          Padding(
            padding: EdgeInsets.fromLTRB(16, topPad + 12, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Discover Tours',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    const _SettingsButton(),
                  ],
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.only(left: 40),
                  child: Text(
                    'Find your adventure',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black45,
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
                const Expanded(child: _SearchBar()),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _accent,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.tune_rounded, color: Colors.white, size: 22),
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
              ],
            ),
          ),

          // Tour List
          Expanded(
            child: StreamBuilder<List<Tour>>(
              stream: _tourService.popularToursStream(),
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
                final displayTours = snapshot.data ?? [];
                final filteredTours = displayTours.where((t) {
                  if (_selectedCategory == 'All') return true;
                  return t.category.toLowerCase() ==
                      _selectedCategory.toLowerCase();
                }).toList();

                if (displayTours.isEmpty) {
                  return const Center(
                    child: Text(
                      'No tours yet. Add documents to the "tours" collection in Firebase (admin).',
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                if (filteredTours.isEmpty) {
                  return const Center(
                    child: Text('No tours found matching this category.'),
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
    );
  }
}

class _SettingsButton extends StatelessWidget {
  const _SettingsButton();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFFFBE697),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(Icons.settings_outlined, color: Colors.black87, size: 22),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: DiscoverToursScreen._searchFill,
        borderRadius: BorderRadius.circular(16),
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search tours, destinations...',
          hintStyle: GoogleFonts.plusJakartaSans(
            color: Colors.black38,
            fontSize: 14,
          ),
          prefixIcon: const Icon(Icons.search, color: Colors.black45, size: 22),
          suffixIcon: const Icon(Icons.mic_none_rounded, color: Colors.black45),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
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
            color: isSelected ? const Color(0xFFE8B800) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isSelected ? Colors.transparent : Colors.black12),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? Colors.white : Colors.black54,
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
