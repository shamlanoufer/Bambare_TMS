import 'package:flutter/material.dart';
import '../main.dart';
import '../data/expense_store.dart';
import 'add_expense_screen.dart';

class ExpenseDetailsScreen extends StatefulWidget {
  final Expense expense;
  const ExpenseDetailsScreen({super.key, required this.expense});

  @override
  State<ExpenseDetailsScreen> createState() => _ExpenseDetailsScreenState();
}

class _ExpenseDetailsScreenState extends State<ExpenseDetailsScreen> {
  final _store = ExpenseStore();
  late Expense _expense;

  @override
  void initState() {
    super.initState();
    _expense = widget.expense;
    _store.addListener(_refresh);
  }

  @override
  void dispose() {
    _store.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    final updated = _store.all.where((e) => e.id == _expense.id).toList();
    if (updated.isNotEmpty) {
      setState(() => _expense = updated.first);
    }
  }

  void _delete() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Expense', style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text('Are you sure you want to delete this expense?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.black54)),
          ),
          TextButton(
            onPressed: () {
              _store.deleteExpense(_expense.id);
              Navigator.pop(context); // close dialog
              Navigator.pop(context); // go back to list
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Expense deleted'), backgroundColor: AppTheme.red),
              );
            },
            child: const Text('Delete', style: TextStyle(color: AppTheme.red, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const lkrToUsd = 321.80;
    const lkrToEur = 348.0;
    const lkrToGbp = 410.0;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Header
          Container(
            color: AppTheme.cyan.withValues(alpha: 0.35),
            padding: const EdgeInsets.fromLTRB(20, 56, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.arrow_back, color: Colors.black),
                ),
                const SizedBox(height: 12),
                const Text('Expense Details', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Main Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: AppTheme.yellowLight, borderRadius: BorderRadius.circular(20)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(_expense.category.emoji, style: const TextStyle(fontSize: 30)),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('LKR ${_expense.amount.toStringAsFixed(2)}',
                                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                                Text(_expense.category.label,
                                    style: const TextStyle(fontSize: 12, color: Colors.black54)),
                              ],
                            ),
                          ],
                        ),
                        const Divider(height: 24, color: Color(0xFFE0D4A0)),
                        _Row('Note', _expense.note.isEmpty ? '—' : _expense.note),
                        _Row('Category', '${_expense.category.emoji} ${_expense.category.label}'),
                        _Row('Payment', '${_expense.payment.emoji} ${_expense.payment.label}'),
                        _Row('Date', _formatDate(_expense.date)),
                        _Row('Trip', _expense.trip),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Equivalent Values
                  const Text('Equivalent Values',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black54)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _CurrCard('USD', (_expense.amount / lkrToUsd).toStringAsFixed(2)),
                      const SizedBox(width: 8),
                      _CurrCard('EUR', (_expense.amount / lkrToEur).toStringAsFixed(2)),
                      const SizedBox(width: 8),
                      _CurrCard('GBP', (_expense.amount / lkrToGbp).toStringAsFixed(2)),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            await Navigator.push(context,
                                MaterialPageRoute(builder: (_) => AddExpenseScreen(existing: _expense)));
                            setState(() {});
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(color: AppTheme.yellow, borderRadius: BorderRadius.circular(16)),
                            child: const Center(
                              child: Text('Edit', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: _delete,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              color: AppTheme.red.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppTheme.red.withValues(alpha: 0.3)),
                            ),
                            child: const Center(
                              child: Text('Delete', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.red)),
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
    );
  }

  String _formatDate(DateTime d) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final min = d.minute.toString().padLeft(2, '0');
    final ampm = d.hour >= 12 ? 'PM' : 'AM';
    return '${months[d.month - 1]} ${d.day}, ${d.year} · $h:$min $ampm';
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  const _Row(this.label, this.value);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: Colors.black54)),
        Flexible(
          child: Text(value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        ),
      ],
    ),
  );
}

class _CurrCard extends StatelessWidget {
  final String currency;
  final String value;
  const _CurrCard(this.currency, this.value);

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(color: AppTheme.yellowLight, borderRadius: BorderRadius.circular(14)),
      child: Column(
        children: [
          Text(currency, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.black54)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        ],
      ),
    ),
  );
}