import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme.dart';
import '../../models/expense.dart';
import '../../services/expense_service.dart';
import 'currency_converter_screen.dart';
import 'expense_detail_screen.dart';
import 'add_expense_screen.dart';
import 'monthly_report_screen.dart';
import 'budget_planner_screen.dart';

class ExpensesHomeScreen extends StatelessWidget {
  const ExpensesHomeScreen({super.key});

  static const _accent = Color(0xFFFF8A1F);
  // Use the same yellow for header box + floating buttons.
  static const _boxAccent = Color(0xFFF2C94C);
  static const _sectionTitle = Color(0xFF2C3E50);
  static const _card = Color(0xFFFFFFFF);
  static const _budget = 50000.0;
  static const _navClearance = 120.0; // keep above bottom nav bar

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.paddingOf(context).bottom;
    final svc = ExpenseService();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: SafeArea(
        bottom: false,
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
              fit: StackFit.expand,
              children: [
                // Background image like reference.
                Positioned.fill(
                  child: Image.asset(
                    'images/home/4.png',
                    fit: BoxFit.cover,
                  ),
                ),
                // Soft fade so cards read well.
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withValues(alpha: 0.25),
                          Colors.white.withValues(alpha: 0.82),
                          Colors.white.withValues(alpha: 0.98),
                        ],
                      ),
                    ),
                  ),
                ),
                ListView(
                  padding: EdgeInsets.fromLTRB(0, 0, 0, 110 + bottomPad),
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                      child: _TripBudgetCard(
                      title: '$monthTitle · Colombo trip',
                      total: total,
                      budget: _budget,
                      currency: 'LKR',
                      remainingPct: remainingPct,
                    ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                      child: _TopTabsBar(
                        selected: _TopTab.byCategory,
                        onTap: (t) {
                          if (t == _TopTab.monthlyReport) {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => const MonthlyReportScreen(),
                              ),
                            );
                          } else if (t == _TopTab.budgetPlanner) {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => const BudgetPlannerScreen(),
                              ),
                            );
                          }
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'By category',
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: _sectionTitle,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _CategoryGrid(items: normalized),
                          const SizedBox(height: 22),
                    Row(
                      children: [
                              Expanded(
                                child: Text(
                          'Recent transactions',
                          style: GoogleFonts.plusJakartaSans(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: _sectionTitle,
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (_) => const _AllExpensesScreen(),
                                    ),
                                  );
                                },
                                style: TextButton.styleFrom(
                                  foregroundColor: _accent,
                                  padding: const EdgeInsets.only(left: 8, right: 0),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(
                                  'See all',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                          ),
                        ],
                      ),
                          const SizedBox(height: 12),
                          if (snap.connectionState == ConnectionState.waiting && !snap.hasData)
                            const Center(
                              child: Padding(
                              padding: EdgeInsets.all(28),
                                child: CircularProgressIndicator(
                                  color: _accent,
                                  strokeWidth: 2,
                                ),
                              ),
                            )
                          else if (list.isEmpty)
                            Container(
                              width: double.infinity,
                                  padding: const EdgeInsets.all(22),
                              decoration: BoxDecoration(
                                color: _card,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.06),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
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
                          else
                            Column(
                                  children: [
                                for (final e in list.take(3))
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: _ExpenseCard(
                                        expense: e,
                                        onTap: () {
                                          Navigator.of(context).push(
                                            MaterialPageRoute<void>(
                                              builder: (_) => ExpenseDetailScreen(expense: e),
                                            ),
                                          );
                                        },
                                      ),
                                        ),
                                    ],
                            ),
                                  ],
                                ),
                    ),
                  ],
                ),

                Positioned(
                  right: 22,
                  bottom: _navClearance + bottomPad,
                  child: Material(
                    elevation: 8,
                    shadowColor: Colors.black.withValues(alpha: 0.25),
                    shape: const CircleBorder(),
                    color: _boxAccent,
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                            builder: (_) => const AddExpenseScreen(),
                        ),
                      );
                    },
                      child: const SizedBox(
                        width: 58,
                        height: 58,
                        child: Icon(Icons.add_rounded, color: Colors.white, size: 30),
                      ),
                    ),
                  ),
                ),

                Positioned(
                  right: 22,
                  bottom: _navClearance + bottomPad + 74,
                  child: Material(
                    elevation: 8,
                    shadowColor: Colors.black.withValues(alpha: 0.22),
                    shape: const CircleBorder(),
                    color: _boxAccent,
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const CurrencyConverterScreen(),
                          ),
                        );
                      },
                      child: const SizedBox(
                        width: 58,
                        height: 58,
                        child: Icon(
                          Icons.currency_exchange_rounded,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                    ),
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

  // Match reference: five main buckets + Other in grid.
  return <_CategoryItem>[
    _CategoryItem('Food', g('Food')),
    _CategoryItem('Transport', g('Transport')),
    _CategoryItem('Hotel', g('Hotel') + g('Accommodation')),
    _CategoryItem('Shopping', g('Shopping')),
    _CategoryItem('Activities', g('Activities')),
    _CategoryItem('Other', g('Other')),
  ];
}

String _formatThousands(num n) {
  final s = n.round().abs().toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
    buf.write(s[i]);
  }
  return buf.toString();
}

String _formatCompactK(double v) {
  if (v <= 0) return '0';
  if (v < 1000) return v.round().toString();
  final k = v / 1000;
  final t = k >= 10 ? k.toStringAsFixed(0) : k.toStringAsFixed(1);
  return '${t}k';
}

class _TripBudgetCard extends StatelessWidget {
  const _TripBudgetCard({
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

  static const _yellow = Color(0xFFF2C94C);
  static const _yellow2 = Color(0xFFF6D365);

  @override
  Widget build(BuildContext context) {
    final spentPct = budget <= 0 ? 0.0 : (total / budget).clamp(0.0, 1.0);
    final remainingWhole = (remainingPct * 100).round();
    final totalLabel = '$currency ${_formatThousands(total)}';
    final budgetLabel = '$currency ${_formatThousands(budget)}';

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_yellow2, _yellow],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.black.withValues(alpha: 0.78),
                  ),
                ),
              ),
              Container(
                width: 86,
                height: 56,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$remainingWhole%',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: Colors.black.withValues(alpha: 0.85),
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Remaining',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Colors.black.withValues(alpha: 0.65),
                        height: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            totalLabel,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 30,
              fontWeight: FontWeight.w900,
              color: Colors.black.withValues(alpha: 0.88),
              letterSpacing: -0.6,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${(spentPct * 100).round()}% of $budgetLabel budget spent',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.black.withValues(alpha: 0.65),
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: spentPct,
              minHeight: 7,
              backgroundColor: Colors.black.withValues(alpha: 0.08),
              valueColor: AlwaysStoppedAnimation<Color>(
                Colors.black.withValues(alpha: 0.35),
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
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Colors.black.withValues(alpha: 0.65),
                ),
              ),
              Text(
                budgetLabel,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Colors.black.withValues(alpha: 0.65),
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
  const _CategoryGrid({required this.items});
  final List<_CategoryItem> items;

  /// Icon, icon color, soft circle background behind icon.
  (IconData, Color, Color) _style(String label) {
    switch (label.toLowerCase()) {
      case 'food':
        return (Icons.restaurant_rounded, const Color(0xFF7B1FA2), const Color(0xFFF3E5F5));
      case 'transport':
        return (Icons.directions_car_filled_rounded, const Color(0xFFD32F2F), const Color(0xFFFFEBEE));
      case 'hotel':
        return (Icons.apartment_rounded, const Color(0xFFE65100), const Color(0xFFFFF3E0));
      case 'shopping':
        return (Icons.shopping_bag_rounded, const Color(0xFF1565C0), const Color(0xFFE3F2FD));
      case 'activities':
        return (Icons.adjust_rounded, const Color(0xFFC2185B), const Color(0xFFFCE4EC));
      default:
        return (Icons.category_rounded, const Color(0xFF546E7A), const Color(0xFFECEFF1));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Narrower track + square tiles (width/height ≈ 1) so white cards read smaller; icon chip unchanged.
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
        childAspectRatio: 1,
      children: [
        for (final it in items)
            Material(
              color: Colors.white,
              elevation: 2,
              shadowColor: Colors.black.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                      width: 44,
                      height: 44,
                  decoration: BoxDecoration(
                        color: _style(it.label).$3,
                        borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    _style(it.label).$1,
                        size: 24,
                        color: _style(it.label).$2,
                  ),
                ),
                    const SizedBox(height: 6),
                Text(
                  it.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF5C6B7A),
                      ),
                    ),
                    const SizedBox(height: 2),
                Text(
                      _formatCompactK(it.amount),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                        fontWeight: FontWeight.w800,
                    color: AppTheme.black,
                  ),
                ),
              ],
                ),
            ),
          ),
      ],
      ),
    );
  }
}

(_ExpenseVisual visual, String dayPart, String timePart) _expenseMeta(Expense expense) {
  final visual = _categoryVisual(expense.category);
  final t = expense.spentAt;
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
  final String dayPart;
  if (d == today) {
    dayPart = 'Today';
  } else if (d == today.subtract(const Duration(days: 1))) {
    dayPart = 'Yesterday';
  } else {
    dayPart = '${t.day}/${t.month}/${t.year}';
  }
  return (visual, dayPart, timeStr);
}

class _ExpenseVisual {
  const _ExpenseVisual(this.icon, this.iconColor, this.tileBg);
  final IconData icon;
  final Color iconColor;
  final Color tileBg;
}

_ExpenseVisual _categoryVisual(String cat) {
    final c = cat.toLowerCase();
  if (c.contains('food')) {
    return const _ExpenseVisual(Icons.restaurant_rounded, Color(0xFF7B1FA2), Color(0xFFF3E5F5));
  }
  if (c.contains('transport') || c.contains('travel')) {
    return const _ExpenseVisual(Icons.directions_car_filled_rounded, Color(0xFFD32F2F), Color(0xFFFFEBEE));
  }
  if (c.contains('shopping')) {
    return const _ExpenseVisual(Icons.shopping_bag_rounded, Color(0xFF1565C0), Color(0xFFE3F2FD));
  }
  if (c.contains('activity')) {
    return const _ExpenseVisual(Icons.adjust_rounded, Color(0xFFC2185B), Color(0xFFFCE4EC));
  }
  if (c.contains('hotel') || c.contains('accommodation')) {
    return const _ExpenseVisual(Icons.apartment_rounded, Color(0xFFE65100), Color(0xFFFFF3E0));
  }
  return const _ExpenseVisual(Icons.receipt_long_rounded, Color(0xFF546E7A), Color(0xFFECEFF1));
}

class _ExpenseCard extends StatelessWidget {
  const _ExpenseCard({required this.expense, required this.onTap});
  final Expense expense;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final meta = _expenseMeta(expense);
    final visual = meta.$1;
    final dayPart = meta.$2;
    final timePart = meta.$3;
    final amt = _formatThousands(expense.amount);

    return Material(
      color: Colors.white,
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Row(
          children: [
            Container(
                width: 44,
                height: 44,
              decoration: BoxDecoration(
                  color: visual.tileBg,
                borderRadius: BorderRadius.circular(12),
              ),
                child: Icon(visual.icon, color: visual.iconColor, size: 22),
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
                        fontSize: 14,
                      fontWeight: FontWeight.w800,
                        color: const Color(0xFF2C3E50),
                    ),
                  ),
                    const SizedBox(height: 3),
                  Text(
                      '$dayPart • $timePart • ${expense.category}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                        color: const Color(0xFF8A9BA8),
                    ),
                  ),
                ],
              ),
            ),
              const SizedBox(width: 8),
            Text(
                '-${expense.currency} $amt',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFFE53935),
              ),
            ),
          ],
          ),
        ),
      ),
    );
  }
}

class _AllExpensesScreen extends StatefulWidget {
  const _AllExpensesScreen();

  @override
  State<_AllExpensesScreen> createState() => _AllExpensesScreenState();
}

class _AllExpensesScreenState extends State<_AllExpensesScreen> {
  static const _accent = Color(0xFFFF8A1F);
  static const _bg = Color(0xFFF7F8FA);

  final _search = TextEditingController();
  final _catCtrl = ScrollController();
  String _category = 'All';
  String _payment = 'All';

  @override
  void dispose() {
    _search.dispose();
    _catCtrl.dispose();
    super.dispose();
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

  String _time12h(DateTime t) {
  var h = t.hour;
  final m = t.minute.toString().padLeft(2, '0');
  final ap = h >= 12 ? 'PM' : 'AM';
  if (h == 0) {
    h = 12;
  } else if (h > 12) {
    h -= 12;
  }
    return '$h:$m $ap';
  }

  String _dayHeader(DateTime t) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(t.year, t.month, t.day);
    if (d == today) return 'Today · ${t.day} ${_shortMonth(t.month)}';
    if (d == today.subtract(const Duration(days: 1))) {
      return 'Yesterday · ${t.day} ${_shortMonth(t.month)}';
    }
    return '${t.day} ${_shortMonth(t.month)} ${t.year}';
  }

  String _shortMonth(int m) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[m - 1];
  }

  List<String> _categories() {
    // Always show same chips as reference, even if no data yet.
    return const ['All', 'Food', 'Transport', 'Hotel', 'Shopping', 'Activities', 'Other'];
  }

  List<Expense> _filtered(List<Expense> src) {
    final q = _search.text.trim().toLowerCase();
    final list = List<Expense>.from(src);
    list.sort((a, b) => b.spentAt.compareTo(a.spentAt));
    return list.where((e) {
      if (_category != 'All' && e.category != _category) return false;
      if (_payment != 'All' && e.paymentMethod != _payment) return false;
      if (q.isEmpty) return true;
      final hay = '${e.note} ${e.category} ${e.paymentMethod}'.toLowerCase();
      return hay.contains(q);
    }).toList();
  }

  Future<void> _openFilter() async {
    final v = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) {
        const items = ['All', 'Card', 'Cash', 'Mobile Pay'];
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Filter',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.black,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final it in items)
                      ChoiceChip(
                        label: Text(it),
                        selected: _payment == it,
                        selectedColor: _accent,
                        labelStyle: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w800,
                          color: _payment == it ? Colors.white : AppTheme.black,
                        ),
                        onSelected: (_) => Navigator.of(context).pop(it),
                        side: BorderSide(color: Colors.black.withValues(alpha: 0.10)),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
    if (!mounted || v == null) return;
    setState(() => _payment = v);
  }

  @override
  Widget build(BuildContext context) {
    final cats = _categories();
    final svc = ExpenseService();

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        bottom: false,
        child: StreamBuilder<List<Expense>>(
          stream: svc.myExpensesStream(),
          builder: (context, snap) {
            final all = snap.data ?? const <Expense>[];
            final expenses = _filtered(all);
            final now = DateTime.now();
            final sub = '${_monthTitle(now)} · ${expenses.length} entries';

            final grouped = <String, List<Expense>>{};
            for (final e in expenses) {
              final k = _dayHeader(e.spentAt);
              (grouped[k] ??= []).add(e);
            }

            return Stack(
              fit: StackFit.expand,
              children: [
                Positioned.fill(
                  child: Image.asset(
                    'images/home/4.png',
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withValues(alpha: 0.25),
                          Colors.white.withValues(alpha: 0.82),
                          Colors.white.withValues(alpha: 0.98),
                        ],
                      ),
                    ),
                  ),
                ),
                Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
                      child: Row(
                        children: [
                          Material(
                            color: Colors.white.withValues(alpha: 0.85),
                            shape: const CircleBorder(),
                            child: IconButton(
                              onPressed: () => Navigator.of(context).maybePop(),
                              icon: const Icon(Icons.arrow_back_ios_new_rounded),
                              iconSize: 18,
                              color: AppTheme.black,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'All Expenses',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    color: AppTheme.black,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  sub,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
                        children: [
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.search_rounded, color: AppTheme.grey, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller: _search,
                                  onChanged: (_) => setState(() {}),
                                  decoration: InputDecoration(
                                    border: InputBorder.none,
                                    hintText: 'Search expenses...',
                                    hintStyle: GoogleFonts.plusJakartaSans(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.black.withValues(alpha: 0.35),
                                    ),
                                  ),
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.black,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _openFilter,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _accent,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Text(
                            'Filter',
                            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w900),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 40,
                    child: ListView.separated(
                      controller: _catCtrl,
                      scrollDirection: Axis.horizontal,
                      itemCount: cats.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (context, i) {
                        final c = cats[i];
                        final selected = _category == c;
                        return InkWell(
                          borderRadius: BorderRadius.circular(999),
                          onTap: () => setState(() => _category = c),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: selected ? _accent : Colors.white,
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: selected ? _accent : Colors.black.withValues(alpha: 0.10),
                              ),
                            ),
                            child: Text(
                              c,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                color: selected ? Colors.white : AppTheme.grey,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 6),
                  _ChipScrollIndicator(controller: _catCtrl),
                  const SizedBox(height: 12),
                  if (expenses.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 30),
                      child: Center(
                        child: Text(
                          'No expenses yet.\nAdd expenses to see them here.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            height: 1.35,
                            color: AppTheme.grey,
                          ),
                        ),
                      ),
                    ),
                  for (final entry in grouped.entries) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(2, 6, 2, 10),
                      child: Text(
                        entry.key,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.grey,
                        ),
                      ),
                    ),
                    for (final e in entry.value)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _AllExpenseRow(
                          expense: e,
                          timeLabel: _time12h(e.spentAt),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => ExpenseDetailScreen(expense: e),
                              ),
                            );
                          },
                        ),
                      ),
                    const SizedBox(height: 6),
                  ],
                  const SizedBox(height: 80),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _AllExpenseRow extends StatelessWidget {
  const _AllExpenseRow({
    required this.expense,
    required this.timeLabel,
    required this.onTap,
  });

  final Expense expense;
  final String timeLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final visual = _categoryVisual(expense.category);
    final amt = _formatThousands(expense.amount);

    return Material(
      color: Colors.white,
      elevation: 1,
      shadowColor: Colors.black.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: visual.tileBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(visual.icon, color: visual.iconColor, size: 22),
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
                        fontWeight: FontWeight.w900,
                        color: AppTheme.black,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '$timeLabel · ${expense.category} · ${expense.paymentMethod}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.grey,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '-$amt',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFFE53935),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChipScrollIndicator extends StatefulWidget {
  const _ChipScrollIndicator({required this.controller});
  final ScrollController controller;

  @override
  State<_ChipScrollIndicator> createState() => _ChipScrollIndicatorState();
}

class _ChipScrollIndicatorState extends State<_ChipScrollIndicator> {
  static const _trackH = 8.0;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onScroll);
  }

  @override
  void didUpdateWidget(covariant _ChipScrollIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onScroll);
      widget.controller.addListener(_onScroll);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onScroll);
    super.dispose();
  }

  void _onScroll() {
    if (!mounted) return;
    setState(() {});
  }

  void _nudge(double dx) {
    if (!widget.controller.hasClients) return;
    final next = (widget.controller.offset + dx).clamp(
      0.0,
      widget.controller.position.maxScrollExtent,
    );
    widget.controller.animateTo(
      next,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final has = widget.controller.hasClients;
    final max = has ? widget.controller.position.maxScrollExtent : 0.0;
    final off = has ? widget.controller.offset : 0.0;

    final t = (max <= 0) ? 0.0 : (off / max).clamp(0.0, 1.0);
    // Thumb width similar to reference.
    const thumbW = 110.0;

    return Row(
      children: [
        InkWell(
          onTap: () => _nudge(-120),
          borderRadius: BorderRadius.circular(10),
          child: const Padding(
            padding: EdgeInsets.all(6),
            child: Icon(Icons.chevron_left_rounded, size: 18, color: AppTheme.grey),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: LayoutBuilder(
            builder: (context, c) {
              final trackW = c.maxWidth;
              final left = (trackW - thumbW) * t;
              return SizedBox(
                height: 18,
                child: Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    Container(
                      height: _trackH,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    Positioned(
                      left: left.isNaN ? 0 : left,
                      child: Container(
                        width: thumbW,
                        height: _trackH,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.45),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 6),
        InkWell(
          onTap: () => _nudge(120),
          borderRadius: BorderRadius.circular(10),
          child: const Padding(
            padding: EdgeInsets.all(6),
            child: Icon(Icons.chevron_right_rounded, size: 18, color: AppTheme.grey),
          ),
        ),
      ],
    );
  }
}

enum _TopTab { byCategory, monthlyReport, budgetPlanner }

class _TopTabsBar extends StatelessWidget {
  const _TopTabsBar({
    required this.selected,
    required this.onTap,
  });

  final _TopTab selected;
  final ValueChanged<_TopTab> onTap;

  static const _yellow = Color(0xFFF2C94C);

  @override
  Widget build(BuildContext context) {
    Widget pill(String label, _TopTab tab) {
      final isSel = selected == tab;
      return Expanded(
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => onTap(tab),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(
              color: isSel ? Colors.white : Colors.black.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSel ? Colors.black.withValues(alpha: 0.08) : Colors.transparent,
              ),
            ),
            child: Center(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: Colors.black.withValues(alpha: 0.75),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _yellow.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          pill('By Category', _TopTab.byCategory),
          const SizedBox(width: 10),
          pill('Monthly report', _TopTab.monthlyReport),
          const SizedBox(width: 10),
          pill('Budget planner', _TopTab.budgetPlanner),
        ],
      ),
    );
  }
}

