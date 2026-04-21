import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/admin_theme_colors.dart';
import '../../theme/brand_colors.dart';
import '../../widgets/admin_profile_bar.dart';

class AdminReportsScreen extends StatelessWidget {
  const AdminReportsScreen({super.key});

  Future<Map<String, dynamic>> _fetchStats() async {
    final bookingsSnap =
        await FirebaseFirestore.instance.collection('bookings').get();
    final usersSnap =
        await FirebaseFirestore.instance.collection('users').get();
    final toursSnap =
        await FirebaseFirestore.instance.collection('tours').get();
    final hotelsSnap =
        await FirebaseFirestore.instance.collection('hotels').get();

    int confirmed = 0, pending = 0, cancelled = 0;
    double revenue = 0;

    for (final doc in bookingsSnap.docs) {
      final d = doc.data();
      final status = (d['status'] ?? '').toString().toLowerCase();
      if (status == 'confirmed') {
        confirmed++;
        revenue += ((d['totalAmount'] ?? 0) as num).toDouble();
      } else if (status == 'pending') {
        pending++;
      } else if (status == 'cancelled') {
        cancelled++;
      }
    }

    return {
      'totalBookings': bookingsSnap.size,
      'confirmed': confirmed,
      'pending': pending,
      'cancelled': cancelled,
      'revenue': revenue,
      'totalUsers': usersSnap.size,
      'totalTours': toursSnap.size,
      'totalHotels': hotelsSnap.size,
    };
  }

  @override
  Widget build(BuildContext context) {
    final c = context.adminColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
              Text(
                'Reports & Analytics',
                style: GoogleFonts.dmSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: c.textPrimary,
                ),
              ),
              const Spacer(),
              const AdminProfileBar(),
            ],
          ),
        ),
        Expanded(
          child: FutureBuilder<Map<String, dynamic>>(
            future: _fetchStats(),
            builder: (context, snap) {
              if (!snap.hasData) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: BrandColors.accent,
                    strokeWidth: 2,
                  ),
                );
              }
              final s = snap.data!;
              final revenue = s['revenue'] as double;
              final revenueDisplay = revenue >= 1000000
                  ? 'LKR ${(revenue / 1000000).toStringAsFixed(2)}M'
                  : 'LKR ${revenue.toStringAsFixed(0)}';

              return SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'System Overview',
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: c.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        _ReportCard(
                          label: 'Total Bookings',
                          value: '${s['totalBookings']}',
                          icon: Icons.calendar_today_rounded,
                          color: BrandColors.accent,
                        ),
                        const SizedBox(width: 14),
                        _ReportCard(
                          label: 'Total Revenue',
                          value: revenueDisplay,
                          icon: Icons.attach_money_rounded,
                          color: const Color(0xFFF0A94A),
                        ),
                        const SizedBox(width: 14),
                        _ReportCard(
                          label: 'Registered Users',
                          value: '${s['totalUsers']}',
                          icon: Icons.people_rounded,
                          color: const Color(0xFF58A6FF),
                        ),
                        const SizedBox(width: 14),
                        _ReportCard(
                          label: 'Active Tours',
                          value: '${s['totalTours']}',
                          icon: Icons.map_rounded,
                          color: const Color(0xFFBC8CFF),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Booking Status Breakdown',
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: c.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: c.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: c.border),
                      ),
                      child: Column(
                        children: [
                          _StatusBar(
                            label: 'Confirmed',
                            count: s['confirmed'],
                            total: s['totalBookings'],
                            color: BrandColors.accent,
                          ),
                          const SizedBox(height: 14),
                          _StatusBar(
                            label: 'Pending',
                            count: s['pending'],
                            total: s['totalBookings'],
                            color: const Color(0xFFF0A94A),
                          ),
                          const SizedBox(height: 14),
                          _StatusBar(
                            label: 'Cancelled',
                            count: s['cancelled'],
                            total: s['totalBookings'],
                            color: const Color(0xFFF47067),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: _InfoCard(
                            title: 'Hotels Listed',
                            value: '${s['totalHotels']}',
                            icon: Icons.hotel_rounded,
                            color: const Color(0xFFF0A94A),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _InfoCard(
                            title: 'Tour Packages',
                            value: '${s['totalTours']}',
                            icon: Icons.luggage_rounded,
                            color: BrandColors.accent,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _InfoCard(
                            title: 'Confirmed Bookings',
                            value: '${s['confirmed']}',
                            icon: Icons.check_circle_outline,
                            color: const Color(0xFF58A6FF),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ReportCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _ReportCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.adminColors;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: c.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon, size: 18, color: color),
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
      ),
    );
  }
}

class _StatusBar extends StatelessWidget {
  final String label;
  final int count;
  final int total;
  final Color color;

  const _StatusBar({
    required this.label,
    required this.count,
    required this.total,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.adminColors;
    final pct = total > 0 ? count / total : 0.0;
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 12,
              color: c.textPrimary,
            ),
          ),
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
        Text(
          '$count  (${(pct * 100).toStringAsFixed(1)}%)',
          style: GoogleFonts.dmSans(
            fontSize: 11,
            color: c.muted,
          ),
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _InfoCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
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
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: GoogleFonts.dmSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: c.textPrimary,
                ),
              ),
              Text(
                title,
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  color: c.muted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
