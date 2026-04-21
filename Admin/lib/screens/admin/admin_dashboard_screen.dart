import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/admin_theme_colors.dart';
import '../../theme/brand_colors.dart';
import '../../theme/theme_scope.dart';
import '../../widgets/admin_profile_bar.dart';
import 'admin_add_tour_screen.dart';
import 'admin_bookings_screen.dart';
import 'admin_tours_screen.dart';
import 'admin_users_screen.dart';
import 'admin_hotels_screen.dart';
import 'admin_reports_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedIndex = 0;

  final List<_NavItem> _navItems = [
    const _NavItem(icon: Icons.dashboard_rounded, label: 'Dashboard'),
    const _NavItem(icon: Icons.luggage_rounded, label: 'Tours'),
    const _NavItem(icon: Icons.calendar_today_rounded, label: 'Bookings'),
    const _NavItem(icon: Icons.people_rounded, label: 'Users'),
    const _NavItem(icon: Icons.hotel_rounded, label: 'Hotels'),
    const _NavItem(icon: Icons.bar_chart_rounded, label: 'Reports'),
  ];

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 1:
        return const AdminToursScreen();
      case 2:
        return const AdminBookingsScreen();
      case 3:
        return const AdminUsersScreen();
      case 4:
        return const AdminHotelsScreen();
      case 5:
        return const AdminReportsScreen();
      default:
        return const _DashboardHome();
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.adminColors;
    return Scaffold(
      backgroundColor: c.pageBackground,
      body: Row(
        children: [
          // Sidebar
          Container(
            width: 220,
            color: c.sidebarBackground,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Logo — yellow badge, "Bambare" only (no icon)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 32, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFD40D),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'Bambare',
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1B1B2F),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'ADMIN PANEL',
                        style: GoogleFonts.dmSans(
                          fontSize: 9,
                          letterSpacing: 1.5,
                          color: c.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(color: c.border, height: 1),
                const SizedBox(height: 12),
                // Nav label
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                  child: Text(
                    'MAIN MENU',
                    style: GoogleFonts.dmSans(
                      fontSize: 9,
                      letterSpacing: 1.5,
                      color: c.muted,
                    ),
                  ),
                ),
                // Nav items
                ...List.generate(_navItems.length, (i) {
                  final item = _navItems[i];
                  final isActive = _selectedIndex == i;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedIndex = i),
                    child: Container(
                      margin: const EdgeInsets.fromLTRB(12, 2, 12, 2),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isActive
                            ? BrandColors.accent.withOpacity(0.28)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            item.icon,
                            size: 18,
                            color: isActive
                                ? BrandColors.onAccent
                                : c.muted,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            item.label,
                            style: GoogleFonts.dmSans(
                              fontSize: 13,
                              fontWeight: isActive
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              color: isActive
                                  ? BrandColors.onAccent
                                  : c.muted,
                            ),
                          ),
                          if (isActive) ...[
                            const Spacer(),
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: BrandColors.accent,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }),
                const Spacer(),
                Divider(color: c.border, height: 1),
                // Theme toggle
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                  child: GestureDetector(
                    onTap: () => ThemeScope.of(context).toggle(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Theme.of(context).brightness == Brightness.dark
                                ? Icons.light_mode_outlined
                                : Icons.dark_mode_outlined,
                            size: 18,
                            color: const Color(0xFF58A6FF),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            Theme.of(context).brightness == Brightness.dark
                                ? 'Light mode'
                                : 'Dark mode',
                            style: GoogleFonts.dmSans(
                              fontSize: 13,
                              color: const Color(0xFF58A6FF),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Logout
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: GestureDetector(
                    onTap: () async {
                      await FirebaseAuth.instance.signOut();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.logout_rounded,
                            size: 18,
                            color: Color(0xFFF47067),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Logout',
                            style: GoogleFonts.dmSans(
                              fontSize: 13,
                              color: const Color(0xFFF47067),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Main content
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
//  Dashboard Home (KPI + Recent Bookings + Activity)
// ──────────────────────────────────────────────────────────────
class _DashboardHome extends StatelessWidget {
  const _DashboardHome();

  @override
  Widget build(BuildContext context) {
    final c = context.adminColors;
    return Column(
      children: [
        // Top bar
        Container(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
          decoration: BoxDecoration(
            color: c.topBarBackground,
            border: Border(
              bottom: BorderSide(color: c.border, width: 1),
            ),
          ),
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Admin Dashboard',
                    style: GoogleFonts.dmSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: c.textPrimary,
                    ),
                  ),
                  Text(
                    'Bambare Travel Management System',
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      color: c.muted,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: c.inputFill,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: c.border),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.search_rounded,
                      size: 15,
                      color: c.muted,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Search anything…',
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        color: c.muted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: c.inputFill,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: c.border),
                ),
                child: Icon(
                  Icons.notifications_outlined,
                  size: 18,
                  color: c.muted,
                ),
              ),
              const SizedBox(width: 12),
              const AdminProfileBar(),
            ],
          ),
        ),
        // Scrollable content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _KpiRow(),
                const SizedBox(height: 20),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 5, child: _RecentBookingsCard()),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const _LatestTourPackageCard(),
                          const SizedBox(height: 16),
                          _RecentActivityCard(),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _TopDestinationsCard()),
                    SizedBox(width: 16),
                    Expanded(child: _UpcomingToursCard()),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────────
//  KPI Row – live counts from Firestore
// ──────────────────────────────────────────────────────────────
class _KpiRow extends StatelessWidget {
  const _KpiRow();

  Stream<int> _count(String col) =>
      FirebaseFirestore.instance.collection(col).snapshots().map(
        (s) => s.size,
      );

  Stream<double> _revenue() => FirebaseFirestore.instance
      .collection('bookings')
      .where('status', isEqualTo: 'confirmed')
      .snapshots()
      .map(
        (s) => s.docs.fold(
          0.0,
          (acc, d) => acc + ((d.data()['totalAmount'] ?? 0) as num).toDouble(),
        ),
      );

  Stream<int> _activeToursCount() => FirebaseFirestore.instance
      .collection('tours')
      .where('isActive', isEqualTo: true)
      .snapshots()
      .map((s) => s.size);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: StreamBuilder<int>(
            stream: _count('bookings'),
            builder: (_, snap) => _KpiCard(
              icon: Icons.calendar_today_rounded,
              iconColor: BrandColors.accent,
              label: 'Total Bookings',
              value: '${snap.data ?? 0}',
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: StreamBuilder<int>(
            stream: _count('users'),
            builder: (_, snap) => _KpiCard(
              icon: Icons.people_rounded,
              iconColor: const Color(0xFF58A6FF),
              label: 'Registered Users',
              value: '${snap.data ?? 0}',
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: StreamBuilder<double>(
            stream: _revenue(),
            builder: (_, snap) {
              final v = snap.data ?? 0;
              final display = v >= 1000000
                  ? 'LKR ${(v / 1000000).toStringAsFixed(1)}M'
                  : 'LKR ${v.toStringAsFixed(0)}';
              return _KpiCard(
                icon: Icons.attach_money_rounded,
                iconColor: const Color(0xFFF0A94A),
                label: 'Total Revenue (confirmed)',
                value: display,
              );
            },
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: StreamBuilder<int>(
            stream: _activeToursCount(),
            builder: (_, snap) => _KpiCard(
              icon: Icons.map_rounded,
              iconColor: const Color(0xFFBC8CFF),
              label: 'Active Tour Packages',
              value: '${snap.data ?? 0}',
            ),
          ),
        ),
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  const _KpiCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.adminColors;
    return Container(
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
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, size: 18, color: iconColor),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.dmSans(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: c.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 11,
              color: c.muted,
            ),
          ),
        ],
      ),
    );
  }
}

String _formatCreatedAgo(dynamic ts) {
  if (ts == null) return '';
  if (ts is! Timestamp) return '';
  final dt = ts.toDate();
  final diff = DateTime.now().difference(dt);
  if (diff.inMinutes < 1) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
  if (diff.inHours < 24) return '${diff.inHours} hr ago';
  if (diff.inDays < 7) return '${diff.inDays} days ago';
  return '${(diff.inDays / 7).floor()} wk ago';
}

/// Same chrome as [_RecentActivityCard]: right column, newest tour by [createdAt].
class _LatestTourPackageCard extends StatelessWidget {
  const _LatestTourPackageCard();

  /// Square hero thumb — larger read, compact column width via dashboard flex.
  static const double _thumb = 96;

  @override
  Widget build(BuildContext context) {
    final c = context.adminColors;
    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Latest tour package',
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: c.textPrimary,
                  ),
                ),
                Text(
                  'Edit →',
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    color: const Color(0xFF58A6FF),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('tours')
                .orderBy('createdAt', descending: true)
                .limit(1)
                .snapshots(),
            builder: (context, snap) {
              if (snap.hasError) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  child: Center(
                    child: Text(
                      'Could not load latest tour.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        color: c.muted,
                        height: 1.4,
                      ),
                    ),
                  ),
                );
              }
              if (!snap.hasData) {
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: BrandColors.accent,
                        strokeWidth: 2,
                      ),
                    ),
                  ),
                );
              }
              final docs = snap.data!.docs;
              if (docs.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  child: Center(
                    child: Text(
                      'No tour packages yet. Add one under Tours — the newest will appear here.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        color: c.muted,
                        height: 1.4,
                      ),
                    ),
                  ),
                );
              }

              final doc = docs.first;
              final d = doc.data();
              final title =
                  (d['tourName'] ?? d['title'] ?? 'Tour').toString().trim();
              final heroUrl =
                  (d['image_url'] ?? d['imageUrl'] ?? '').toString().trim();
              final location = (d['location'] ?? '').toString().trim();
              final price = d['basePrice'] ?? d['price'] ?? 0;
              final currency =
                  (d['currency'] ?? 'LKR').toString().trim().isEmpty
                      ? 'LKR'
                      : (d['currency'] ?? 'LKR').toString().trim();
              final when = _formatCreatedAgo(d['createdAt']);

              final primaryLine = title.isEmpty ? 'Untitled tour' : title;
              final secondaryParts = <String>[
                if (location.isNotEmpty) location,
                '$currency $price',
                if (when.isNotEmpty) when,
              ];

              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    Navigator.of(context).push<void>(
                      MaterialPageRoute<void>(
                        builder: (_) => AdminAddTourScreen(docId: doc.id),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: c.border, width: 0.5),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: _thumb,
                          height: _thumb,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: c.border, width: 1),
                            color: c.inputFill,
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: heroUrl.isNotEmpty
                              ? Image.network(
                                  heroUrl,
                                  fit: BoxFit.cover,
                                  width: _thumb,
                                  height: _thumb,
                                  errorBuilder: (_, __, ___) => const Center(
                                    child: Icon(
                                      Icons.tour_outlined,
                                      size: 36,
                                      color: Color(0xFFBC8CFF),
                                    ),
                                  ),
                                )
                              : const Center(
                                  child: Icon(
                                    Icons.tour_outlined,
                                    size: 36,
                                    color: Color(0xFFBC8CFF),
                                  ),
                                ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                primaryLine,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.dmSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: c.textPrimary,
                                  height: 1.35,
                                ),
                              ),
                              if (secondaryParts.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text(
                                  secondaryParts.join(' · '),
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.dmSans(
                                    fontSize: 11,
                                    color: c.muted,
                                    height: 1.35,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
//  Recent Bookings Card – live from Firestore
// ──────────────────────────────────────────────────────────────
class _RecentBookingsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = context.adminColors;
    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Bookings',
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: c.textPrimary,
                  ),
                ),
                Text(
                  'View all →',
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    color: const Color(0xFF58A6FF),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('bookings')
                .orderBy('createdAt', descending: true)
                .limit(6)
                .snapshots(),
            builder: (context, snap) {
              if (!snap.hasData) {
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: BrandColors.accent,
                      strokeWidth: 2,
                    ),
                  ),
                );
              }
              final docs = snap.data!.docs;
              if (docs.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Text(
                      'No bookings yet',
                      style: GoogleFonts.dmSans(color: c.muted),
                    ),
                  ),
                );
              }
              return Column(
                children: docs.map((doc) {
                  final d = doc.data() as Map<String, dynamic>;
                  final name = d['customerName'] ?? 'Unknown';
                  final tour = d['tourName'] ?? 'Tour';
                  final amount = d['totalAmount'] ?? 0;
                  final status = (d['status'] ?? 'pending').toString();
                  final initials = name.length >= 2
                      ? name.substring(0, 2).toUpperCase()
                      : 'NA';
                  return _BookingRow(
                    initials: initials,
                    name: name,
                    tour: tour,
                    amount: 'LKR ${amount.toString()}',
                    status: status,
                  );
                }).toList(),
              );
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _BookingRow extends StatelessWidget {
  final String initials;
  final String name;
  final String tour;
  final String amount;
  final String status;

  const _BookingRow({
    required this.initials,
    required this.name,
    required this.tour,
    required this.amount,
    required this.status,
  });

  Color get _statusColor {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return BrandColors.accent;
      case 'cancelled':
        return const Color(0xFFF47067);
      default:
        return const Color(0xFFF0A94A);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.adminColors;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: c.border, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: _statusColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                initials,
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _statusColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: c.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  tour,
                  style: GoogleFonts.dmSans(
                    fontSize: 10,
                    color: c.muted,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: GoogleFonts.dmSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: c.textPrimary,
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: _statusColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              status[0].toUpperCase() + status.substring(1),
              style: GoogleFonts.dmSans(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: _statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
//  Recent Activity Card
// ──────────────────────────────────────────────────────────────
class _RecentActivityCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = context.adminColors;
    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Text(
              'Recent Activity',
              style: GoogleFonts.dmSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: c.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 12),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('activity_log')
                .orderBy('timestamp', descending: true)
                .limit(6)
                .snapshots(),
            builder: (context, snap) {
              if (!snap.hasData) {
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: BrandColors.accent,
                      strokeWidth: 2,
                    ),
                  ),
                );
              }
              final docs = snap.data!.docs;
              if (docs.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  child: Center(
                    child: Text(
                      'No activity yet. Actions from this admin panel will appear here.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        color: c.muted,
                        height: 1.4,
                      ),
                    ),
                  ),
                );
              }
              return Column(
                children: docs.map((doc) {
                  final d = doc.data() as Map<String, dynamic>;
                  return _ActivityRow(
                    icon: _iconForType(d['type'] ?? ''),
                    iconBg: _bgForType(d['type'] ?? ''),
                    message: d['message'] ?? '',
                    time: _formatTime(d['timestamp']),
                  );
                }).toList(),
              );
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'booking':
        return Icons.calendar_today_rounded;
      case 'user':
        return Icons.person_rounded;
      case 'payment':
        return Icons.attach_money_rounded;
      case 'cancel':
        return Icons.cancel_outlined;
      case 'tour':
        return Icons.tour_outlined;
      case 'hotel':
        return Icons.hotel_rounded;
      default:
        return Icons.info_outline;
    }
  }

  Color _bgForType(String type) {
    switch (type) {
      case 'booking':
        return BrandColors.accent;
      case 'user':
        return const Color(0xFF58A6FF);
      case 'payment':
        return const Color(0xFFF0A94A);
      case 'cancel':
        return const Color(0xFFF47067);
      case 'tour':
        return const Color(0xFFBC8CFF);
      case 'hotel':
        return const Color(0xFFF0A94A);
      default:
        return const Color(0xFFBC8CFF);
    }
  }

  String _formatTime(dynamic ts) {
    if (ts == null) return '';
    final dt = (ts as Timestamp).toDate();
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hr ago';
    return '${diff.inDays}d ago';
  }
}

class _ActivityRow extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final String message;
  final String time;

  const _ActivityRow({
    required this.icon,
    required this.iconBg,
    required this.message,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.adminColors;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: c.border, width: 0.5),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: iconBg.withOpacity(0.15),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Icon(icon, size: 14, color: iconBg),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message,
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    color: c.textBody,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  time,
                  style: GoogleFonts.dmSans(
                    fontSize: 10,
                    color: c.muted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
//  Top tours by booking volume (from real bookings)
// ──────────────────────────────────────────────────────────────
class _TopDestinationsCard extends StatelessWidget {
  const _TopDestinationsCard();

  static const _palette = <Color>[
    BrandColors.accent,
    Color(0xFF58A6FF),
    Color(0xFFF0A94A),
    Color(0xFFBC8CFF),
    Color(0xFFF47067),
  ];

  @override
  Widget build(BuildContext context) {
    final c = context.adminColors;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Top tours (by bookings)',
            style: GoogleFonts.dmSans(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: c.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Based on tour names in your bookings',
            style: GoogleFonts.dmSans(
              fontSize: 10,
              color: c.muted,
            ),
          ),
          const SizedBox(height: 10),
          StreamBuilder<QuerySnapshot>(
            stream:
                FirebaseFirestore.instance.collection('bookings').snapshots(),
            builder: (context, snap) {
              if (!snap.hasData) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: BrandColors.accent,
                      strokeWidth: 2,
                    ),
                  ),
                );
              }
              final counts = <String, int>{};
              for (final doc in snap.data!.docs) {
                final m = doc.data() as Map<String, dynamic>;
                final name = (m['tourName'] ?? '').toString().trim();
                if (name.isEmpty) continue;
                counts[name] = (counts[name] ?? 0) + 1;
              }
              if (counts.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: Text(
                      'No bookings yet. Add bookings to see popular tours.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        color: c.muted,
                      ),
                    ),
                  ),
                );
              }
              final sorted = counts.entries.toList()
                ..sort((a, b) => b.value.compareTo(a.value));
              final top = sorted.take(5).toList();
              final maxCount = top.first.value;
              return Column(
                children: top.asMap().entries.map((e) {
                  final i = e.key;
                  final entry = e.value;
                  final pct =
                      maxCount > 0 ? entry.value / maxCount : 0.0;
                  return _DestBar(
                    entry.key,
                    '${entry.value} booking${entry.value == 1 ? '' : 's'}',
                    pct,
                    _palette[i % _palette.length],
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _DestBar extends StatelessWidget {
  final String name;
  final String location;
  final double pct;
  final Color color;

  const _DestBar(this.name, this.location, this.pct, this.color);

  @override
  Widget build(BuildContext context) {
    final c = context.adminColors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: c.inputFill,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(
              child: Text(
                name.isNotEmpty
                    ? String.fromCharCode(name.runes.first)
                    : '?',
                style: GoogleFonts.dmSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: c.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '${(pct * 100).toInt()}%',
                      style: GoogleFonts.dmSans(
                        fontSize: 11,
                        color: c.muted,
                      ),
                    ),
                  ],
                ),
                if (location.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    location,
                    style: GoogleFonts.dmSans(
                      fontSize: 10,
                      color: c.muted,
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: pct,
                    minHeight: 4,
                    backgroundColor: c.inputFill,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
//  Upcoming Tours Card – live from Firestore
// ──────────────────────────────────────────────────────────────
class _UpcomingToursCard extends StatelessWidget {
  const _UpcomingToursCard();

  @override
  Widget build(BuildContext context) {
    final c = context.adminColors;
    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Upcoming Tours',
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: c.textPrimary,
                  ),
                ),
                Text(
                  'Manage →',
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    color: const Color(0xFF58A6FF),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('tours')
                .where('isActive', isEqualTo: true)
                .limit(5)
                .snapshots(),
            builder: (context, snap) {
              if (!snap.hasData) {
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: BrandColors.accent,
                      strokeWidth: 2,
                    ),
                  ),
                );
              }
              final docs = snap.data!.docs;
              if (docs.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  child: Center(
                    child: Text(
                      'No active tours yet. Add tours under Tours.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        color: c.muted,
                      ),
                    ),
                  ),
                );
              }
              return Column(
                children: docs.map((doc) {
                  final d = doc.data() as Map<String, dynamic>;
                  return _TourRow(
                    emoji: d['emoji'] ?? '🗺',
                    name: d['tourName'] ?? 'Tour',
                    detail:
                        '${d['duration'] ?? ''} · ${d['bookedCount'] ?? 0} booked',
                    price: 'LKR ${d['basePrice'] ?? 0}',
                  );
                }).toList(),
              );
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _TourRow extends StatelessWidget {
  final String emoji;
  final String name;
  final String detail;
  final String price;

  const _TourRow({
    required this.emoji,
    required this.name,
    required this.detail,
    required this.price,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.adminColors;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: c.border, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: c.inputFill,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(emoji, style: const TextStyle(fontSize: 18)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: c.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  detail,
                  style: GoogleFonts.dmSans(
                    fontSize: 10,
                    color: c.muted,
                  ),
                ),
              ],
            ),
          ),
          Text(
            price,
            style: GoogleFonts.dmSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: BrandColors.accent,
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}
