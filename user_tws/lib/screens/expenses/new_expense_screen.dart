import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme.dart';
import '../../services/expense_service.dart';

class NewExpenseScreen extends StatefulWidget {
  const NewExpenseScreen({super.key});

  @override
  State<NewExpenseScreen> createState() => _NewExpenseScreenState();
}

class _NewExpenseScreenState extends State<NewExpenseScreen> {
  final _svc = ExpenseService();

  final _amount = TextEditingController();
  final _note = TextEditingController();

  String _category = 'Food';
  String _payment = 'Card';
  DateTime _date = DateTime.now();
  bool _saving = false;

  static const _accent = Color(0xFFFF8A1F);
  static const _bg = Color(0xFFF5F5F0);
  static const _fieldBg = Color(0xFFFFF1E8);

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
    final amt = double.tryParse(_amount.text.trim()) ?? 0;
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

  String _dateLabel(DateTime d) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            // Orange header
            Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
              decoration: const BoxDecoration(
                color: _accent,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(22),
                  bottomRight: Radius.circular(22),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Material(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: const CircleBorder(),
                    child: IconButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded),
                      color: Colors.white,
                      iconSize: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Add Expense',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _dateLabel(_date),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.white.withValues(alpha: 0.92),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
                children: [
                  const _SectionLabel('AMOUNT (LKR)'),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: _fieldBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.black.withValues(alpha: 0.06),
                      ),
                    ),
                    child: TextField(
                      controller: _amount,
                      keyboardType: TextInputType.number,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                        color: _accent,
                        height: 1.1,
                      ),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: '1,200',
                        hintStyle: GoogleFonts.plusJakartaSans(
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                          color: _accent.withValues(alpha: 0.35),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Row(
                    children: [
                      _RateChip(label: '≈ USD 4.02'),
                      SizedBox(width: 10),
                      _RateChip(label: '≈ EUR 3.71'),
                      SizedBox(width: 10),
                      _RateChip(label: '≈ GBP 3.18'),
                    ],
                  ),
                  const SizedBox(height: 14),

                  const _SectionLabel('CATEGORY'),
                  const SizedBox(height: 8),
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
                        icon: Icons.directions_bus_filled_rounded,
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
                        icon: Icons.celebration_rounded,
                        selected: _category == 'Activities',
                        onTap: () => setState(() => _category = 'Activities'),
                      ),
                      _Pill(
                        label: 'Other',
                        icon: Icons.push_pin_rounded,
                        selected: _category == 'Other',
                        onTap: () => setState(() => _category = 'Other'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  const _SectionLabel('NOTE (OPTIONAL)'),
                  const SizedBox(height: 8),
                  _TextFieldBox(
                    controller: _note,
                    hint: 'Lunch at Nuga Gama',
                  ),
                  const SizedBox(height: 14),

                  const _SectionLabel('DATE'),
                  const SizedBox(height: 8),
                  _PickerBox(
                    text: _dateLabel(_date),
                    onTap: _pickDate,
                  ),
                  const SizedBox(height: 14),

                  const _SectionLabel('PAID VIA'),
                  const SizedBox(height: 8),
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
                          label: 'Mobile Pay',
                          icon: Icons.phone_iphone_rounded,
                          selected: _payment == 'Mobile Pay',
                          onTap: () => setState(() => _payment = 'Mobile Pay'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _accent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: _saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              'Save Expense',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 52,
                    child: OutlinedButton(
                      onPressed: _saving ? null : () => Navigator.of(context).maybePop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.grey,
                        side: BorderSide(color: Colors.black.withValues(alpha: 0.10)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ],
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

class _RateChip extends StatelessWidget {
  const _RateChip({required this.label});
  final String label;
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: AppTheme.grey,
            ),
          ),
        ),
      ),
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
          border: Border.all(
            color: selected ? _accent : Colors.black.withValues(alpha: 0.10),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: selected ? Colors.white : AppTheme.grey,
            ),
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
          color: selected ? _accent : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? _accent : Colors.black.withValues(alpha: 0.10),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: selected ? Colors.white : AppTheme.grey,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: selected ? Colors.white : AppTheme.grey,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TextFieldBox extends StatelessWidget {
  const _TextFieldBox({required this.controller, required this.hint});
  final TextEditingController controller;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
      ),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hint,
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
    );
  }
}

class _PickerBox extends StatelessWidget {
  const _PickerBox({required this.text, required this.onTap});
  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                text,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.black,
                ),
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppTheme.grey),
          ],
        ),
      ),
    );
  }
}
