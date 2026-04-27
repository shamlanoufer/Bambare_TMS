import 'package:flutter/material.dart';
import '../main.dart';
import '../data/expense_store.dart';

class AddExpenseScreen extends StatefulWidget {
  final Expense? existing; // pass for EDIT mode
  const AddExpenseScreen({super.key, this.existing});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _store = ExpenseStore();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  ExpenseCategory _category = ExpenseCategory.food;
  PaymentMethod _payment = PaymentMethod.card;
  DateTime _date = DateTime.now();

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      final e = widget.existing!;
      _amountController.text = e.amount.toStringAsFixed(2);
      _noteController.text = e.note;
      _category = e.category;
      _payment = e.payment;
      _date = e.date;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _save() {
    final raw = _amountController.text.replaceAll(',', '');
    final amount = double.tryParse(raw);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount'), backgroundColor: AppTheme.red),
      );
      return;
    }

    if (_isEdit) {
      _store.updateExpense(widget.existing!.copyWith(
        amount: amount,
        category: _category,
        payment: _payment,
        note: _noteController.text,
        date: _date,
      ));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Expense updated!'), backgroundColor: AppTheme.green),
      );
    } else {
      _store.addExpense(Expense(
        id: _store.generateId(),
        amount: amount,
        category: _category,
        payment: _payment,
        note: _noteController.text,
        date: _date,
        trip: 'Colombo',
      ));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Expense saved!'), backgroundColor: AppTheme.green),
      );
    }
    Navigator.pop(context);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2024),
      lastDate: DateTime(2027),
    );
    if (picked != null) setState(() => _date = picked);
  }

  @override
  Widget build(BuildContext context) {
    // Rough USD equivalent
    final amt = double.tryParse(_amountController.text.replaceAll(',', '')) ?? 0;
    final usd = (amt / 321.80).toStringAsFixed(2);
    final eur = (amt / 348.0).toStringAsFixed(2);
    final gbp = (amt / 410.0).toStringAsFixed(2);

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
                Text(_isEdit ? 'Edit Expense' : 'Add Expense',
                    style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
                Text(
                  '${_date.day} ${_monthName(_date.month)}, ${_date.year}',
                  style: const TextStyle(fontSize: 14, color: Colors.black54),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Amount
                  const Text('AMOUNT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: Colors.black54)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(color: AppTheme.yellowLight, borderRadius: BorderRadius.circular(16)),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _amountController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            onChanged: (_) => setState(() {}),
                            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
                            decoration: const InputDecoration(border: InputBorder.none, isDense: true),
                          ),
                        ),
                        const Text('LKR', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black54)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Currency equivalents
                  if (amt > 0)
                    Row(
                      children: [
                        _Chip('≈ USD $usd'),
                        const SizedBox(width: 8),
                        _Chip('≈ EUR $eur'),
                        const SizedBox(width: 8),
                        _Chip('≈ GBP $gbp'),
                      ],
                    ),
                  const SizedBox(height: 24),

                  // Category
                  const Text('CATEGORY', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: Colors.black54)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ExpenseCategory.values.map((cat) {
                      final sel = _category == cat;
                      return GestureDetector(
                        onTap: () => setState(() => _category = cat),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: sel ? AppTheme.yellow : AppTheme.yellowLight,
                            borderRadius: BorderRadius.circular(20),
                            border: sel ? Border.all(color: AppTheme.yellow, width: 2) : null,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(cat.emoji, style: const TextStyle(fontSize: 15)),
                              const SizedBox(width: 6),
                              Text(cat.label.split(' ').first,
                                  style: TextStyle(fontSize: 13, fontWeight: sel ? FontWeight.w700 : FontWeight.w500)),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // Note
                  const Text('NOTE (OPTIONAL)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: Colors.black54)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: AppTheme.yellowLight, borderRadius: BorderRadius.circular(16)),
                    child: TextField(
                      controller: _noteController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                        hintText: 'Add a note...',
                        hintStyle: TextStyle(color: Colors.black38),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Date
                  const Text('DATE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: Colors.black54)),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _pickDate,
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: AppTheme.yellowLight, borderRadius: BorderRadius.circular(16)),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today_outlined, size: 18, color: Colors.black54),
                          const SizedBox(width: 10),
                          Text('${_date.day} ${_monthName(_date.month)}, ${_date.year}',
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                          const Spacer(),
                          const Icon(Icons.chevron_right, size: 18, color: Colors.black38),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Payment
                  const Text('PAID VIA', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: Colors.black54)),
                  const SizedBox(height: 12),
                  Row(
                    children: PaymentMethod.values.map((p) {
                      final sel = _payment == p;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _payment = p),
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: sel ? AppTheme.yellow : AppTheme.yellowLight,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Column(
                              children: [
                                Text(p.emoji, style: const TextStyle(fontSize: 20)),
                                const SizedBox(height: 4),
                                Text(p.label,
                                    style: TextStyle(fontSize: 12, fontWeight: sel ? FontWeight.w700 : FontWeight.w500)),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 32),

                  // Buttons
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: GestureDetector(
                          onTap: _save,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(color: AppTheme.yellow, borderRadius: BorderRadius.circular(50)),
                            child: Center(
                              child: Text(_isEdit ? 'Update Expense' : 'Save Expense',
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(color: AppTheme.lightGray, borderRadius: BorderRadius.circular(50)),
                            child: const Center(
                              child: Text('Cancel',
                                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black54)),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _monthName(int m) => ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'][m - 1];
}

class _Chip extends StatelessWidget {
  final String label;
  const _Chip(this.label);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(color: AppTheme.yellowLight, borderRadius: BorderRadius.circular(20)),
    child: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
  );
}