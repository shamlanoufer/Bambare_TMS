import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme.dart';
import '../../models/expense.dart';
import '../../services/expense_service.dart';
import 'expense_detail_screen.dart';
import 'new_expense_screen.dart';

class ExpensesHomeScreen extends StatelessWidget {
  const ExpensesHomeScreen({super.key});

  static const _accent = Color(0xFFFF8A1F);
  static const _card = Color(0xFFFFFFFF);
  static const _budget = 50000.0;
  static const _navClearance = 120.0; // keep above bottom nav bar

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.paddingOf(context).bottom;
    final svc = ExpenseService();

    return Scaffold(
      backgroundColor: AppTheme.white,
      body: SafeArea(
        child: StreamBuilder<List<Expense>>(
          stream: svc.myExpensesStream(),
          builder: (context, snap) {
            final list = snap.data ?? const <Expense>[];
            final total = list.fold<double>(0, (a, e) => a + e.amount);
            final remaining = (_budget - total).clamp(0.0, _budget);
            final remainingPct =
                _budget <= 0 ? 0.0 : (remaining / _budget).clamp(0.0, 1.0);
            final byCategory = <String, double>{};
            for (final e in list) {
              byCategory[e.category] = (byCategory[e.category] ?? 0) + e.amount;
            }
            final normalized = _normalizedCategories(byCategory);
            final monthTitle = _monthTitle(DateTime.now());

            return Stack(
              children: [
                ListView(
                  padding: EdgeInsets.fromLTRB(20, 18, 20, 110 + bottomPad),
                  children: [
                    Text(
                      'Expenses',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.black,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 14),

                    _MonthlyHeaderCard(
                      title: '$monthTitle · Colombo trip',
                      total: total,
                      budget: _budget,
                      currency: 'LKR',
                      remainingPct: remainingPct,
                    ),
                    const SizedBox(height: 14),

                    Row(
                      children: [
                        Text(
                          'By category',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.black,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _CategoryGrid(
                      items: normalized,
                      currency: 'LKR',
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Text(
                          'Recent transactions',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.black,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    Container(
                      decoration: BoxDecoration(
                        color: _card,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: snap.connectionState == ConnectionState.waiting &&
                              !snap.hasData
                          ? const Padding(
                              padding: EdgeInsets.all(28),
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: _accent,
                                  strokeWidth: 2,
                                ),
                              ),
                            )
                          : list.isEmpty
                              ? Padding(
                                  padding: const EdgeInsets.all(22),
                                  child: Text(
                                    'No expenses yet.\nTap + to add your first expense.',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 13,
                                      height: 1.4,
                                      color: AppTheme.grey,
                                    ),
                                  ),
                                )
                              : Column(
                                  children: [
                                    for (final e in list.take(3)) ...[
                                      _ExpenseRow(
                                        expense: e,
                                        onTap: () {
                                          Navigator.of(context).push(
                                            MaterialPageRoute<void>(
                                              builder: (_) => ExpenseDetailScreen(expense: e),
                                            ),
                                          );
                                        },
                                      ),
                                      if (e.id != list.take(3).last.id)
                                        Divider(
                                          height: 1,
                                          color: Colors.black.withValues(alpha: 0.06),
                                        ),
                                    ],
                                  ],
                                ),
                    ),
                  ],
                ),

                Positioned(
                  right: 22,
                  bottom: _navClearance + bottomPad,
                  child: FloatingActionButton(
                    backgroundColor: _accent,
                    foregroundColor: Colors.white,
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const NewExpenseScreen(),
                        ),
                      );
                    },
                    child: const Icon(Icons.add_rounded, size: 28),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

String _monthTitle(DateTime d) {
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

List<_CategoryItem> _normalizedCategories(Map<String, double> raw) {
  double g(String k) => raw.entries
      .where((e) => e.key.toLowerCase() == k.toLowerCase())
      .fold<double>(0, (a, e) => a + e.value);

  // Keep fixed order like reference.
  final items = <_CategoryItem>[
    _CategoryItem('Food', g('Food')),
    _CategoryItem('Transport', g('Transport')),
    _CategoryItem('Hotel', g('Hotel') + g('Accommodation')),
    _CategoryItem('Shopping', g('Shopping')),
    _CategoryItem('Activities', g('Activities')),
    _CategoryItem('Other', g('Other')),
  ];
  return items;
}

class _MonthlyHeaderCard extends StatelessWidget {
  const _MonthlyHeaderCard({
    required this.title,
    required this.total,
    required this.budget,
    required this.currency,
    required this.remainingPct,
  });

  final String title;
  final double total;
  final double budget;
  final String currency;
  final double remainingPct;

  static const _accent = Color(0xFFFF8A1F);

  @override
  Widget build(BuildContext context) {
    final spentPct = budget <= 0 ? 0.0 : (total / budget).clamp(0.0, 1.0);
    final remainingLabel = '${(remainingPct * 100).round()}%';
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFA13C), _accent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withValues(alpha: 0.92),
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      remainingLabel,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'remaining',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '$currency ${total.toStringAsFixed(0)}',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -0.6,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${(spentPct * 100).round()}% of $currency ${budget.toStringAsFixed(0)} budget',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.white.withValues(alpha: 0.92),
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: spentPct,
              minHeight: 7,
              backgroundColor: Colors.white.withValues(alpha: 0.25),
              valueColor: AlwaysStoppedAnimation<Color>(
                Colors.white.withValues(alpha: 0.85),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$currency 0',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
              Text(
                '$currency ${budget.toStringAsFixed(0)}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CategoryItem {
  const _CategoryItem(this.label, this.amount);
  final String label;
  final double amount;
}

class _CategoryGrid extends StatelessWidget {
  const _CategoryGrid({required this.items, required this.currency});
  final List<_CategoryItem> items;
  final String currency;

  (IconData, Color, Color) _style(String label) {
    switch (label.toLowerCase()) {
      case 'food':
        return (
          Icons.restaurant_rounded,
          const Color(0xFFFFF1E8),
          const Color(0xFFFF8A1F),
        );
      case 'transport':
        return (
          Icons.directions_bus_filled_rounded,
          const Color(0xFFEFF7F3),
          const Color(0xFF2E7D32),
        );
      case 'hotel':
        return (
          Icons.apartment_rounded,
          const Color(0xFFEFF4FF),
          const Color(0xFF1565C0),
        );
      case 'shopping':
        return (
          Icons.shopping_bag_rounded,
          const Color(0xFFEFF4FF),
          const Color(0xFF5E35B1),
        );
      case 'activities':
        return (
          Icons.celebration_rounded,
          const Color(0xFFFFF7DF),
          const Color(0xFFB8860B),
        );
      default:
        return (
          Icons.push_pin_rounded,
          const Color(0xFFF3F3F3),
          const Color(0xFF616161),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.05,
      children: [
        for (final it in items)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            decoration: BoxDecoration(
              color: _style(it.label).$2,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _style(it.label).$1,
                    size: 18,
                    color: _style(it.label).$3,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  it.label,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  it.amount.toStringAsFixed(0),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.black,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _ExpenseRow extends StatelessWidget {
  const _ExpenseRow({required this.expense, required this.onTap});
  final Expense expense;
  final VoidCallback onTap;

  IconData _icon(String cat) {
    final c = cat.toLowerCase();
    if (c.contains('food')) return Icons.restaurant_rounded;
    if (c.contains('transport') || c.contains('travel')) return Icons.directions_car_rounded;
    if (c.contains('shopping')) return Icons.shopping_bag_rounded;
    if (c.contains('activity')) return Icons.local_activity_rounded;
    if (c.contains('hotel') || c.contains('accommodation')) return Icons.hotel_rounded;
    return Icons.receipt_long_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final timeLabel = _relativeTime(expense.spentAt);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFFFFE6D2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(_icon(expense.category), color: const Color(0xFFFF8A1F), size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    expense.note.isEmpty ? expense.category : expense.note,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.black,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$timeLabel · ${expense.category}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.grey,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '-${expense.currency} ${expense.amount.toStringAsFixed(0)}',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: const Color(0xFFC62828),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _relativeTime(DateTime t) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final d = DateTime(t.year, t.month, t.day);
  var h = t.hour;
  final m = t.minute.toString().padLeft(2, '0');
  final ap = h >= 12 ? 'PM' : 'AM';
  if (h == 0) {
    h = 12;
  } else if (h > 12) {
    h -= 12;
  }
  final timeStr = '$h:$m $ap';
  if (d == today) return 'Today, $timeStr';
  final y = today.subtract(const Duration(days: 1));
  if (d == y) return 'Yesterday';
  return '${t.day}/${t.month}/${t.year}';
}

