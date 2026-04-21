import 'package:flutter/material.dart';
import '../main.dart';
import '../data/expense_store.dart';

class MonthlyReportScreen extends StatefulWidget {
  const MonthlyReportScreen({super.key});

  @override
  State<MonthlyReportScreen> createState() => _MonthlyReportScreenState();
}

class _MonthlyReportScreenState extends State<MonthlyReportScreen> {
  final _store = ExpenseStore();

  @override
  void initState() {
    super.initState();
    _store.addListener(_refresh);
  }

  @override
  void dispose() {
    _store.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() => setState(() {});

  double _getTotalForMonth(int year, int month) {
    return _store.all
        .where((expense) =>
    expense.date.year == year && expense.date.month == month)
        .fold(0.0, (sum, expense) => sum + expense.amount);
  }

  int _getCountForMonth(int year, int month) {
    return _store.all
        .where((expense) =>
    expense.date.year == year && expense.date.month == month)
        .length;
  }

  double _getTotalForCategoryCurrentMonth(ExpenseCategory cat) {
    final now = DateTime.now();
    return _store.all
        .where((e) =>
    e.category == cat &&
        e.date.year == now.year &&
        e.date.month == now.month)
        .fold(0.0, (sum, e) => sum + e.amount);
  }

  List<Map<String, dynamic>> _getLast3MonthsData() {
    final now = DateTime.now();
    final months = <Map<String, dynamic>>[];

    for (int i = 2; i >= 0; i--) {
      final date = DateTime(now.year, now.month - i, 1);
      final total = _getTotalForMonth(date.year, date.month);

      final monthNames = [
        'Jan','Feb','Mar','Apr','May','Jun',
        'Jul','Aug','Sep','Oct','Nov','Dec'
      ];

      months.add({
        'label': monthNames[date.month - 1],
        'amount': total,
        'isCurrentMonth': i == 0,
      });
    }

    return months;
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final currentMonthTotal = _getTotalForMonth(now.year, now.month);
    final currentMonthCount = _getCountForMonth(now.year, now.month);
    final monthsData = _getLast3MonthsData();

    final maxBar = monthsData.fold(
        0.0, (max, m) => m['amount'] > max ? m['amount'] : max);
    final maxBarAdjusted = maxBar < 5000 ? 5000.0 : maxBar;

    final monthNames = [
      'January','February','March','April','May','June',
      'July','August','September','October','November','December'
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // Header
            Container(
              color: AppTheme.cyan.withValues(alpha: 0.35),
              padding: const EdgeInsets.fromLTRB(20, 56, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${monthNames[now.month - 1]} ${now.year} Report',
                      style: const TextStyle(
                          fontSize: 26, fontWeight: FontWeight.w800)),
                  const Text('Colombo · Kandy · Galle',
                      style: TextStyle(fontSize: 14, color: Colors.black54)),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // Total Spent
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('TOTAL SPENT',
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.2,
                                    color: Colors.black54)),
                            const SizedBox(height: 6),
                            const Text('LKR',
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black54)),
                            Text(currentMonthTotal.toStringAsFixed(2),
                                style: const TextStyle(
                                    fontSize: 30, fontWeight: FontWeight.w800)),
                            Text('$currentMonthCount expenses recorded',
                                style: const TextStyle(
                                    fontSize: 11, color: Colors.black38)),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  // ===== FIXED GRAPH =====
                  const Text('3-Month Comparison',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 16),

                  Container(
                    height: 220,
                    padding: const EdgeInsets.fromLTRB(12, 16, 16, 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.07),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [

                        // Y AXIS LINE
                        Column(
                          children: [
                            Expanded(
                              child: Container(
                                width: 1.5,
                                color: Colors.black26,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(width: 8),

                        // GRAPH
                        Expanded(
                          child: Stack(
                            children: [

                              // GRID LINES
                              Column(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: List.generate(4, (_) {
                                  return Container(
                                    height: 1,
                                    color: Colors.black12,
                                  );
                                }),
                              ),

                              // BARS + X AXIS
                              Column(
                                children: [
                                  Expanded(
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                      children: monthsData.map((m) {
                                        final amount = m['amount'] as double;
                                        final isCurrent = m['isCurrentMonth'] as bool;

                                        return _Bar(
                                          heightFactor: maxBarAdjusted > 0
                                              ? (amount / maxBarAdjusted).clamp(0.05, 1.0)
                                              : 0.05,
                                          color: isCurrent
                                              ? AppTheme.red
                                              : AppTheme.lightGray,
                                          label: m['label'],
                                          amount: amount > 0
                                              ? '${(amount / 1000).toStringAsFixed(1)}k'
                                              : '0',
                                          isActive: isCurrent,
                                        );
                                      }).toList(),
                                    ),
                                  ),

                                  const SizedBox(height: 6),

                                  // X AXIS
                                  Container(
                                    height: 2,
                                    color: Colors.black26,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Breakdown (UNCHANGED)
                  const Text('Breakdown By Category',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 16),

                  ...ExpenseCategory.values.map((cat) {
                    final amt = _getTotalForCategoryCurrentMonth(cat);
                    final pct = currentMonthTotal > 0 ? amt / currentMonthTotal : 0.0;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(cat.emoji),
                              const SizedBox(width: 6),
                              Expanded(child: Text(cat.label)),
                              Text('${(pct * 100).toStringAsFixed(1)}%'),
                              const SizedBox(width: 8),
                              Text('${amt.toStringAsFixed(0)} LKR',
                                  style: const TextStyle(fontSize: 11, color: Colors.black54)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          LinearProgressIndicator(
                            value: pct,
                            minHeight: 10,
                            backgroundColor: AppTheme.lightGray,
                            valueColor: AlwaysStoppedAnimation(cat.color),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ===== FIXED BAR =====
class _Bar extends StatelessWidget {
  final double heightFactor;
  final Color color;
  final String label;
  final String amount;
  final bool isActive;

  const _Bar({
    required this.heightFactor,
    required this.color,
    required this.label,
    required this.amount,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(amount,
            style: TextStyle(
                fontSize: 9,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                color: isActive ? Colors.black87 : Colors.black45)),
        const SizedBox(height: 4),

        Flexible(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: FractionallySizedBox(
              heightFactor: heightFactor,
              child: Container(
                width: 44,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 6),

        Text(label,
            style: TextStyle(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500)),
      ],
    );
  }
}