import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math' as math;
import 'dart:convert';
import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import 'package:universal_html/html.dart' as html;
import '../../theme/admin_theme_colors.dart';
import '../../theme/brand_colors.dart';
import '../../theme/theme_scope.dart';
import '../../widgets/admin_profile_bar.dart';
import 'admin_add_tour_screen.dart';
import 'admin_bookings_screen.dart';
import 'admin_notifications_screen.dart';
import 'admin_tours_screen.dart';
import 'admin_users_screen.dart';
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
    const _NavItem(icon: Icons.bar_chart_rounded, label: 'Reports'),
    const _NavItem(icon: Icons.notifications_outlined, label: 'Notifications'),
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
        return const AdminReportsScreen();
      case 5:
        return const AdminNotificationsScreen();
      default:
        return _DashboardHome(
          onNav: (i) => setState(() => _selectedIndex = i),
        );
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
  final Function(int) onNav;
  const _DashboardHome({required this.onNav});

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
                    Expanded(
                      flex: 5,
                      child: Column(
                        children: [
                          const _RevenueOverviewCard(),
                          const SizedBox(height: 20),
                          _RecentBookingsCard(onViewAll: () => onNav(2)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      flex: 3,
                      child: Column(
                        children: [
                          _TopDestinationsCard(onViewAll: () => onNav(1)),
                          const SizedBox(height: 20),
                          const _LatestTourPackageCard(),
                          const SizedBox(height: 20),
                          _RecentActivityCard(),
                        ],
                      ),
                    ),
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
      .snapshots()
      .map(
        (s) => s.docs.fold(
          0.0,
          (acc, d) {
            final data = d.data();
            final status = (data['status'] ?? '').toString().toLowerCase();
            if (status != 'confirmed') return acc;
            final amount = (data['totalAmount'] ?? data['total_price'] ?? 0) as num;
            return acc + amount.toDouble();
          },
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

// ──────────────────────────────────────────────────────────────
//  Revenue Overview Card
// ──────────────────────────────────────────────────────────────
class _RevenueOverviewCard extends StatelessWidget {
  const _RevenueOverviewCard();

  @override
  Widget build(BuildContext context) {
    final c = context.adminColors;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Revenue Overview',
                style: GoogleFonts.dmSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: c.textPrimary,
                ),
              ),
              Row(
                children: [
                  Text(
                    'Monthly 2026',
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      color: c.muted,
                    ),
                  ),
                  const SizedBox(width: 12),
                  InkWell(
                    onTap: () => _exportToCSV(context),
                    child: Text(
                      'Export CSV',
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: BrandColors.accent,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 240,
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('bookings').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox();
                
                final docs = snapshot.data!.docs;
                final monthlyRevenue = List.generate(12, (_) => 0.0);
                final monthlyPotential = List.generate(12, (_) => 0.0);
                
                for (final doc in docs) {
                  final data = doc.data() as Map<String, dynamic>;
                  final ts = data['created_at'] ?? data['createdAt'];
                  if (ts is! Timestamp) continue;
                  
                  final date = ts.toDate();
                  if (date.year != 2026) continue;
                  
                  final month = date.month - 1;
                  final amount = (data['total_price'] ?? data['totalAmount'] ?? 0) as num;
                  final status = (data['status'] ?? '').toString().toLowerCase();
                  
                  if (status == 'confirmed' || status == 'completed') {
                    monthlyRevenue[month] += amount.toDouble();
                  }
                  monthlyPotential[month] += amount.toDouble();
                }

                return LineChart(
                  LineChartData(
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      getDrawingHorizontalLine: (value) => FlLine(
                        color: c.border.withOpacity(0.5),
                        strokeWidth: 1,
                      ),
                    ),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                          getTitlesWidget: (value, meta) {
                            if (value % 200000 != 0) return const SizedBox();
                            return Text(
                              '${(value / 1000).toInt()}k',
                              style: GoogleFonts.dmSans(fontSize: 10, color: c.muted),
                            );
                          },
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
                            if (value.toInt() < 0 || value.toInt() >= 12) return const SizedBox();
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                months[value.toInt()],
                                style: GoogleFonts.dmSans(fontSize: 10, color: c.muted),
                              ),
                            );
                          },
                        ),
                      ),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: monthlyPotential.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList(),
                        isCurved: true,
                        color: const Color(0xFF58A6FF),
                        barWidth: 3,
                        isStrokeCapRound: true,
                        dotData: const FlDotData(show: true),
                        belowBarData: BarAreaData(
                          show: true,
                          color: const Color(0xFF58A6FF).withOpacity(0.1),
                        ),
                      ),
                      LineChartBarData(
                        spots: monthlyRevenue.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList(),
                        isCurved: true,
                        color: BrandColors.accent,
                        barWidth: 3,
                        isStrokeCapRound: true,
                        dotData: const FlDotData(show: true),
                        belowBarData: BarAreaData(
                          show: true,
                          color: BrandColors.accent.withOpacity(0.1),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 32),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('bookings').snapshots(),
            builder: (context, snapshot) {
              int completed = 0;
              int upcoming = 0;
              int cancelled = 0;
              
              if (snapshot.hasData) {
                for (final doc in snapshot.data!.docs) {
                  final data = doc.data() as Map<String, dynamic>;
                  final status = (data['status'] ?? '').toString().toLowerCase();
                  // Dashboard cards:
                  // - Upcoming = Confirmed bookings (future/current trips)
                  // - Completed = Completed
                  // - Cancelled = Cancelled/Canceled
                  if (status == 'completed' || status.contains('complete')) {
                    completed++;
                  } else if (status == 'confirmed') {
                    upcoming++;
                  } else if (status == 'cancelled' || status == 'canceled') {
                    cancelled++;
                  }
                }
              }
              
              return Row(
                children: [
                  Expanded(
                    child: _StatusBox(
                      value: '$completed',
                      label: 'Completed',
                      color: BrandColors.accent,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _StatusBox(
                      value: '$upcoming',
                      label: 'Upcoming',
                      color: const Color(0xFF58A6FF),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _StatusBox(
                      value: '$cancelled',
                      label: 'Cancelled',
                      color: const Color(0xFFF47067),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _exportToCSV(BuildContext context) async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('bookings').get();
      final docs = snapshot.docs;

      if (docs.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No bookings found to export.')),
          );
        }
        return;
      }

      List<List<dynamic>> rows = [];
      
      // Header row
      rows.add([
        'Booking ID',
        'Date',
        'Customer Name',
        'Tour Package',
        'Status',
        'Amount (LKR)',
        'Reference'
      ]);

      for (var doc in docs) {
        final data = doc.data();
        final ts = data['created_at'] ?? data['createdAt'];
        String dateStr = 'N/A';
        if (ts is Timestamp) {
          dateStr = DateFormat('yyyy-MM-dd HH:mm').format(ts.toDate());
        }

        final customer = data['customerName'] ?? data['lead_first_name'] ?? 'Guest';
        final tour = data['tourName'] ?? data['tour_title'] ?? 'Unknown Tour';
        final status = (data['status'] ?? 'Pending').toString();
        final amount = data['totalAmount'] ?? data['total_price'] ?? 0;
        final ref = doc.id;

        rows.add([
          ref.substring(math.max(0, ref.length - 6)).toUpperCase(),
          dateStr,
          customer,
          tour,
          status,
          amount,
          ref
        ]);
      }

      String csvString = csv.encode(rows);
      
      // Download logic for Web
      final bytes = utf8.encode(csvString);
      final blob = html.Blob([bytes], 'text/csv');
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.document.createElement('a') as html.AnchorElement
        ..href = url
        ..style.display = 'none'
        ..download = 'Bambare_Revenue_Report_${DateFormat('yyyyMMdd').format(DateTime.now())}.csv';
      
      html.document.body!.children.add(anchor);
      anchor.click();
      
      html.document.body!.children.remove(anchor);
      html.Url.revokeObjectUrl(url);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Report exported successfully!')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }
}

class _StatusBox extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _StatusBox({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.adminColors;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: c.inputFill,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.border),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.dmSans(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: c.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 12,
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
      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('tours')
            .orderBy('createdAt', descending: true)
            .limit(1)
            .snapshots(),
        builder: (context, snap) {
          final docs = snap.data?.docs ?? [];
          final doc = docs.isNotEmpty ? docs.first : null;
          final d = doc?.data();

          return Column(
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
                    if (doc != null)
                      InkWell(
                        onTap: () {
                          Navigator.of(context).push<void>(
                            MaterialPageRoute<void>(
                              builder: (_) => AdminAddTourScreen(docId: doc.id),
                            ),
                          );
                        },
                        child: Text(
                          'Edit →',
                          style: GoogleFonts.dmSans(
                            fontSize: 11,
                            color: const Color(0xFF58A6FF),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              if (snap.hasError)
                Padding(
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
                )
              else if (!snap.hasData)
                const Padding(
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
                )
              else if (docs.isEmpty)
                Padding(
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
                )
              else
                Builder(builder: (context) {
                  final title = (d!['tourName'] ?? d['title'] ?? 'Tour').toString().trim();
                  final heroUrl = (d['image_url'] ?? d['imageUrl'] ?? '').toString().trim();
                  final location = (d['location'] ?? '').toString().trim();
                  final price = d['basePrice'] ?? d['price'] ?? 0;
                  final currency = (d['currency'] ?? 'LKR').toString().trim().isEmpty
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
                            builder: (_) => AdminAddTourScreen(docId: doc!.id),
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
                }),
              ],
            );
          },
        ),
      );
    }
}

// ──────────────────────────────────────────────────────────────
//  Recent Bookings Card – live from Firestore
// ──────────────────────────────────────────────────────────────
class _RecentBookingsCard extends StatelessWidget {
  final VoidCallback onViewAll;
  const _RecentBookingsCard({required this.onViewAll});

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
                InkWell(
                  onTap: onViewAll,
                  child: Text(
                    'View all →',
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
                      color: const Color(0xFF58A6FF),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('bookings')
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

              // Sort in memory to handle mixed createdAt / created_at fields
              final sortedDocs = List<QueryDocumentSnapshot>.from(docs);
              sortedDocs.sort((a, b) {
                final ad = a.data() as Map<String, dynamic>;
                final bd = b.data() as Map<String, dynamic>;
                final at = ad['createdAt'] ?? ad['created_at'];
                final bt = bd['createdAt'] ?? bd['created_at'];
                final ats = at is Timestamp ? at : Timestamp(0, 0);
                final bts = bt is Timestamp ? bt : Timestamp(0, 0);
                return bts.compareTo(ats);
              });

              final recentDocs = sortedDocs.take(6).toList();

              return Column(
                children: recentDocs.map((doc) {
                  final d = doc.data() as Map<String, dynamic>;
                  
                  // Handle mixed field names for customer
                  String name = (d['customerName'] ?? '').toString().trim();
                  if (name.isEmpty) {
                    final f = (d['lead_first_name'] ?? '').toString().trim();
                    final l = (d['lead_last_name'] ?? '').toString().trim();
                    name = '$f $l'.trim();
                  }
                  if (name.isEmpty) name = 'Unknown';

                  // Handle mixed field names for tour
                  final tour = (d['tourName'] ?? d['tour_title'] ?? 'Tour').toString();
                  
                  // Handle mixed field names for amount
                  final amount = d['totalAmount'] ?? d['total_price'] ?? 0;
                  
                  final status = (d['status'] ?? 'pending').toString();
                  final initials = name.length >= 2
                      ? name.substring(0, 2).toUpperCase()
                      : name.isNotEmpty ? name[0].toUpperCase() : 'NA';
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
// ──────────────────────────────────────────────────────────────
//  Top tours by booking volume (from real bookings)
// ──────────────────────────────────────────────────────────────
class _TopDestinationsCard extends StatelessWidget {
  final VoidCallback onViewAll;
  const _TopDestinationsCard({required this.onViewAll});

  @override
  Widget build(BuildContext context) {
    final c = context.adminColors;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Top Destinations',
                style: GoogleFonts.dmSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: c.textPrimary,
                ),
              ),
              InkWell(
                onTap: onViewAll,
                child: Text(
                  'View all',
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    color: const Color(0xFF58A6FF),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('bookings').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox();
              
              final counts = <String, _DestData>{};
              for (final doc in snapshot.data!.docs) {
                final d = doc.data() as Map<String, dynamic>;
                final name = (d['tourName'] ?? d['tour_title'] ?? '').toString();
                final location = (d['location'] ?? '').toString();
                if (name.isEmpty) continue;
                
                if (counts.containsKey(name)) {
                  counts[name]!.count++;
                } else {
                  counts[name] = _DestData(name: name, location: location, count: 1);
                }
              }
              
              if (counts.isEmpty) return const Center(child: Text('No data'));
              
              final sorted = counts.values.toList()..sort((a, b) => b.count.compareTo(a.count));
              final top = sorted.take(5).toList();
              final maxCount = top.first.count;
              
              const colors = [
                Color(0xFF2EA043),
                Color(0xFF58A6FF),
                Color(0xFFF0A94A),
                Color(0xFFBC8CFF),
                Color(0xFFF47067),
              ];

              return Column(
                children: List.generate(top.length, (index) {
                  final data = top[index];
                  return _DestinationItem(
                    rank: index + 1,
                    name: data.name,
                    location: data.location,
                    percentage: (data.count / maxCount * 100).toInt(),
                    color: colors[index % colors.length],
                  );
                }),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _DestData {
  final String name;
  final String location;
  int count;
  _DestData({required this.name, required this.location, required this.count});
}

class _DestinationItem extends StatelessWidget {
  final int rank;
  final String name;
  final String location;
  final int percentage;
  final Color color;

  const _DestinationItem({
    required this.rank,
    required this.name,
    required this.location,
    required this.percentage,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.adminColors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: c.inputFill,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '$rank',
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: c.muted,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: GoogleFonts.dmSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: c.textPrimary,
                          ),
                        ),
                        Text(
                          location,
                          style: GoogleFonts.dmSans(
                            fontSize: 11,
                            color: c.muted,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '$percentage%',
                      style: GoogleFonts.dmSans(
                        fontSize: 11,
                        color: c.muted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Stack(
                  children: [
                    Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: c.inputFill,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: percentage / 100,
                      child: Container(
                        height: 4,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
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
