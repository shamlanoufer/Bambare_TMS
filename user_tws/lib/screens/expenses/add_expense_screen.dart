import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme.dart';
import '../../services/expense_service.dart';

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _svc = ExpenseService();
  final _amount = TextEditingController();
  final _note = TextEditingController();

  String _category = 'Food';
  String _payment = 'Card';
  DateTime _date = DateTime.now();
  bool _saving = false;

  static const _accent = Color(0xFFFF8A1F);
  static const _bg = Color(0xFFF7F8FA);

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (d != null) setState(() => _date = d);
  }

  Future<void> _save() async {
    final amt = double.tryParse(_amount.text.trim().replaceAll(',', '')) ?? 0;
    if (amt <= 0) return;
    setState(() => _saving = true);
    try {
      await _svc.addExpense(
        amount: amt,
        currency: 'LKR',
        category: _category,
        note: _note.text.trim(),
        paymentMethod: _payment,
        spentAt: _date,
      );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save expense. $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _dateLabelLong(DateTime d) {
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
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  String _dateLabelShort(DateTime d) {
    final mm = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return '$mm/$dd/${d.year}';
  }

  bool get _canSave {
    final amt = double.tryParse(_amount.text.trim().replaceAll(',', '')) ?? 0;
    return amt > 0 && !_saving;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
          children: [
            Row(
              children: [
                Material(
                  color: const Color(0xFFF3F3F3),
                  shape: const CircleBorder(),
                  child: IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded),
                    iconSize: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Add Expense',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.black,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _dateLabelLong(_date),
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
            const SizedBox(height: 16),
            _Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SectionLabel('AMOUNT (LKR)'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _amount,
                    keyboardType: TextInputType.number,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      color: Colors.black.withValues(alpha: 0.55),
                      height: 1.05,
                    ),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: '0',
                      hintStyle: GoogleFonts.plusJakartaSans(
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        color: Colors.black.withValues(alpha: 0.22),
                      ),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SectionLabel('CATEGORY'),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _Pill(
                        label: 'Food',
                        icon: Icons.restaurant_rounded,
                        selected: _category == 'Food',
                        onTap: () => setState(() => _category = 'Food'),
                      ),
                      _Pill(
                        label: 'Transport',
                        icon: Icons.directions_car_filled_rounded,
                        selected: _category == 'Transport',
                        onTap: () => setState(() => _category = 'Transport'),
                      ),
                      _Pill(
                        label: 'Hotel',
                        icon: Icons.apartment_rounded,
                        selected: _category == 'Hotel',
                        onTap: () => setState(() => _category = 'Hotel'),
                      ),
                      _Pill(
                        label: 'Shopping',
                        icon: Icons.shopping_bag_rounded,
                        selected: _category == 'Shopping',
                        onTap: () => setState(() => _category = 'Shopping'),
                      ),
                      _Pill(
                        label: 'Activities',
                        icon: Icons.adjust_rounded,
                        selected: _category == 'Activities',
                        onTap: () => setState(() => _category = 'Activities'),
                      ),
                      _Pill(
                        label: 'Other',
                        icon: Icons.category_rounded,
                        selected: _category == 'Other',
                        onTap: () => setState(() => _category = 'Other'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SectionLabel('NOTE (OPTIONAL)'),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _note,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: 'What was this expense for?',
                      hintStyle: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.black.withValues(alpha: 0.30),
                      ),
                    ),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.black,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SectionLabel('PAID VIA'),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _PayPill(
                          label: 'Card',
                          icon: Icons.credit_card_rounded,
                          selected: _payment == 'Card',
                          onTap: () => setState(() => _payment = 'Card'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _PayPill(
                          label: 'Cash',
                          icon: Icons.payments_rounded,
                          selected: _payment == 'Cash',
                          onTap: () => setState(() => _payment = 'Cash'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _PayPill(
                          label: 'Mobile\nPay',
                          icon: Icons.phone_iphone_rounded,
                          selected: _payment == 'Mobile Pay',
                          onTap: () => setState(() => _payment = 'Mobile Pay'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _Card(
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: _pickDate,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const _SectionLabel('DATE'),
                            const SizedBox(height: 10),
                            Text(
                              _dateLabelShort(_date),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                color: AppTheme.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.calendar_month_rounded, color: AppTheme.grey),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: 54,
              child: ElevatedButton(
                onPressed: _canSave ? _save : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accent,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: _accent.withValues(alpha: 0.35),
                  disabledForegroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(
                        'Save Expense',
                        style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w900),
                      ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 54,
              child: OutlinedButton(
                onPressed: _saving ? null : () => Navigator.of(context).maybePop(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.grey,
                  side: BorderSide(color: Colors.black.withValues(alpha: 0.10)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w900),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 11,
        fontWeight: FontWeight.w900,
        color: AppTheme.grey,
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  static const _accent = Color(0xFFFF8A1F);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? _accent : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: selected ? _accent : Colors.black.withValues(alpha: 0.10)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: selected ? Colors.white : AppTheme.grey),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: selected ? Colors.white : AppTheme.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PayPill extends StatelessWidget {
  const _PayPill({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  static const _accent = Color(0xFFFF8A1F);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            width: selected ? 1.6 : 1,
            color: selected ? _accent : Colors.black.withValues(alpha: 0.10),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: selected ? _accent : AppTheme.grey),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: selected ? _accent : AppTheme.grey,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

