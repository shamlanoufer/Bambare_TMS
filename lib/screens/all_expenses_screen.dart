import 'package:flutter/material.dart';
import '../main.dart';
import '../data/expense_store.dart';
import 'expense_details_screen.dart';
import 'add_expense_screen.dart';
import 'currency_converter_screen.dart';

class AllExpensesScreen extends StatefulWidget {
  const AllExpensesScreen({super.key});

  @override
  State<AllExpensesScreen> createState() => _AllExpensesScreenState();
}

class _AllExpensesScreenState extends State<AllExpensesScreen> {
  final _store = ExpenseStore();
  final _searchController = TextEditingController();
  ExpenseCategory? _filterCategory;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _store.addListener(_refresh);
  }

  @override
  void dispose() {
    _store.removeListener(_refresh);
    _searchController.dispose();
    super.dispose();
  }

  void _refresh() => setState(() {});

  List<Expense> get _filtered {
    List<Expense> list = _filterCategory == null
        ? _store.sorted
        : _store.byCategory(_filterCategory);
    if (_query.isNotEmpty) {
      list = list.where((e) =>
      e.note.toLowerCase().contains(_query) ||
          e.category.label.toLowerCase().contains(_query) ||
          e.trip.toLowerCase().contains(_query)).toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final expenses = _filtered;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Header
          Container(
            color: AppTheme.cyan.withValues(alpha: 0.35),
            padding: const EdgeInsets.fromLTRB(20, 56, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('All Expenses', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
                Text('March 2026 – ${_store.all.length} Entries',
                    style: const TextStyle(fontSize: 13, color: Colors.black54)),
                const SizedBox(height: 16),
                // Search bar
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.search, size: 18, color: Colors.black54),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                onChanged: (v) => setState(() => _query = v.toLowerCase()),
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                  hintText: 'Search expenses...',
                                  hintStyle: TextStyle(fontSize: 13, color: Colors.black38),
                                ),
                              ),
                            ),
                            if (_query.isNotEmpty)
                              GestureDetector(
                                onTap: () {
                                  _searchController.clear();
                                  setState(() => _query = '');
                                },
                                child: const Icon(Icons.close, size: 16, color: Colors.black38),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Category filter chips
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: [
                _FilterChip(
                  label: 'All (${_store.all.length})',
                  selected: _filterCategory == null,
                  onTap: () => setState(() => _filterCategory = null),
                ),
                ...ExpenseCategory.values.map((cat) => _FilterChip(
                  label: '${cat.emoji} ${cat.label.split(' ').first}',
                  selected: _filterCategory == cat,
                  onTap: () => setState(() => _filterCategory = _filterCategory == cat ? null : cat),
                )),
              ],
            ),
          ),

          // Expense list
          Expanded(
            child: expenses.isEmpty
                ? const Center(
              child: Text('No expenses found', style: TextStyle(color: Colors.black38)),
            )
                : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: expenses.length,
              itemBuilder: (_, i) {
                final e = expenses[i];
                return GestureDetector(
                  onTap: () async {
                    await Navigator.push(context,
                        MaterialPageRoute(builder: (_) => ExpenseDetailsScreen(expense: e)));
                    setState(() {});
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.yellowLight,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: e.category.color.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(e.category.emoji, style: const TextStyle(fontSize: 18)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                e.note.isEmpty ? e.category.label : e.note,
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                              ),
                              Text(
                                '${e.payment.emoji} ${e.payment.label} · ${e.trip}',
                                style: const TextStyle(fontSize: 11, color: Colors.black54),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('-${e.amount.toStringAsFixed(0)} LKR',
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                            Text(_shortDate(e.date),
                                style: const TextStyle(fontSize: 10, color: Colors.black38)),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.small(
            heroTag: 'converter',
            backgroundColor: AppTheme.cyan,
            foregroundColor: Colors.white,
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const CurrencyConverterScreen())),
            child: const Icon(Icons.currency_exchange, size: 20),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: 'add',
            backgroundColor: AppTheme.yellow,
            foregroundColor: Colors.black,
            onPressed: () async {
              await Navigator.push(context, MaterialPageRoute(builder: (_) => const AddExpenseScreen()));
              setState(() {});
            },
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }

  String _shortDate(DateTime d) {
    const m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${m[d.month - 1]} ${d.day}';
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FilterChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: selected ? AppTheme.yellow : AppTheme.yellowLight,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: TextStyle(fontSize: 12, fontWeight: selected ? FontWeight.w700 : FontWeight.w500)),
    ),
  );
}