import 'package:flutter/material.dart';
import '../main.dart';
import '../data/expense_store.dart';
import 'add_expense_screen.dart';
import 'expense_details_screen.dart';
import 'currency_converter_screen.dart';

class ExpenseTrackingScreen extends StatefulWidget {
  const ExpenseTrackingScreen({super.key});

  @override
  State<ExpenseTrackingScreen> createState() => _ExpenseTrackingScreenState();
}

class _ExpenseTrackingScreenState extends State<ExpenseTrackingScreen> {
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

  @override
  Widget build(BuildContext context) {
    final expenses = _store.sorted;
    final total = _store.totalSpent;
    const budget = 90000.0;
    final budgetFraction = (total / budget).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hero Header
                Container(
                  width: double.infinity,
                  color: AppTheme.cyan.withValues(alpha: 0.35),
                  padding: const EdgeInsets.fromLTRB(20, 60, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('March 2026 – Colombo trip',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.black54)),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('LKR ${total.toStringAsFixed(0)}',
                                  style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800)),
                              Text('${(budgetFraction * 100).toStringAsFixed(0)}% of LKR 90,000 budget',
                                  style: const TextStyle(fontSize: 11, color: Colors.black54)),
                            ],
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppTheme.green,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${((1 - budgetFraction) * 100).toStringAsFixed(0)}%\nLeft',
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: budgetFraction,
                          minHeight: 8,
                          backgroundColor: Colors.white.withValues(alpha: 0.5),
                          valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.red),
                        ),
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category Grid
                      const Text('By Category',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 14),
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 3,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 1.15,
                        children: ExpenseCategory.values.map((cat) {
                          final amt = _store.totalForCategory(cat);
                          return Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppTheme.yellowLight,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(cat.emoji, style: const TextStyle(fontSize: 20)),
                                const Spacer(),
                                Text(cat.label.split(' ').first,
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                                Text('${amt.toStringAsFixed(0)} LKR',
                                    style: const TextStyle(fontSize: 10, color: Colors.black54)),
                              ],
                            ),
                          );
                        }).toList(),
                      ),

                      // Recent Transactions
                      const SizedBox(height: 24),
                      const Text('Recent Transactions',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 12),
                      if (expenses.isEmpty)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: Text('No expenses yet. Tap + to add one.',
                                style: TextStyle(color: Colors.black38)),
                          ),
                        )
                      else
                        ...expenses.take(5).map((e) => _TransactionTile(
                          expense: e,
                          onTap: () async {
                            await Navigator.push(context,
                                MaterialPageRoute(builder: (_) => ExpenseDetailsScreen(expense: e)));
                            setState(() {});
                          },
                        )),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // FABs — Add Expense + Currency Converter
          Positioned(
            bottom: 16,
            right: 20,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Currency converter FAB (smaller, above)
                GestureDetector(
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const CurrencyConverterScreen())),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.cyan,
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 8, offset: const Offset(0, 3))],
                    ),
                    child: const Icon(Icons.currency_exchange, color: Colors.white, size: 22),
                  ),
                ),
                const SizedBox(height: 12),
                // Add Expense FAB (primary)
                GestureDetector(
                  onTap: () async {
                    await Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const AddExpenseScreen()));
                    setState(() {});
                  },
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.yellow,
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 8, offset: const Offset(0, 3))],
                    ),
                    child: const Icon(Icons.add, color: Colors.black, size: 28),
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

class _TransactionTile extends StatelessWidget {
  final Expense expense;
  final VoidCallback onTap;
  const _TransactionTile({required this.expense, required this.onTap});

  String _formatDate(DateTime d) {
    final now = DateTime.now();
    final t = '${d.hour % 12 == 0 ? 12 : d.hour % 12}:${d.minute.toString().padLeft(2, '0')} ${d.hour >= 12 ? 'PM' : 'AM'}';
    if (d.day == now.day && d.month == now.month) return 'Today, $t';
    if (d.day == now.day - 1 && d.month == now.month) return 'Yesterday, $t';
    return '${d.day}/${d.month}/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: AppTheme.yellowLight, borderRadius: BorderRadius.circular(14)),
        child: Row(
          children: [
            Text(expense.category.emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(expense.note.isEmpty ? expense.category.label : expense.note,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  Text(_formatDate(expense.date),
                      style: const TextStyle(fontSize: 11, color: Colors.black54)),
                ],
              ),
            ),
            Text('-${expense.amount.toStringAsFixed(0)}',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}