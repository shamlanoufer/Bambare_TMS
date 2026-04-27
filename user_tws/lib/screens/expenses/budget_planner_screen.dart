import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme.dart';
import '../../models/expense.dart';
import '../../services/expense_service.dart';

class BudgetPlannerScreen extends StatefulWidget {
  const BudgetPlannerScreen({super.key});

  @override
  State<BudgetPlannerScreen> createState() => _BudgetPlannerScreenState();
}

class _BudgetPlannerScreenState extends State<BudgetPlannerScreen> {
  static const _accent = Color(0xFFFF8A1F);
  static const _bg = Color(0xFFF7F8FA);

  final _expenseSvc = ExpenseService();
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  bool _saving = false;

  final _categories = const ['Food', 'Transport', 'Hotel', 'Shopping', 'Activities'];

  Future<User> _ensureUser() async {
    final u = _auth.currentUser;
    if (u != null) return u;
    final cred = await _auth.signInAnonymously();
    return cred.user!;
  }

  Future<DocumentReference<Map<String, dynamic>>> _userDoc() async {
    final u = await _ensureUser();
    return _db.collection('users').doc(u.uid);
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> _userDocStream() async* {
    final ref = await _userDoc();
    yield* ref.snapshots();
  }

  String _fmtInt(num n) {
    final s = n.round().abs().toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  (IconData icon, Color tile) _catIcon(String label) {
    switch (label.toLowerCase()) {
      case 'food':
        return (Icons.restaurant_rounded, const Color(0xFFF3E5F5));
      case 'transport':
        return (Icons.directions_car_filled_rounded, const Color(0xFFE3F2FD));
      case 'hotel':
        return (Icons.apartment_rounded, const Color(0xFFEDE7F6));
      case 'shopping':
        return (Icons.shopping_bag_rounded, const Color(0xFFE8F5E9));
      case 'activities':
        return (Icons.adjust_rounded, const Color(0xFFFCE4EC));
      default:
        return (Icons.category_rounded, const Color(0xFFECEFF1));
    }
  }

  Color _catColor(String label) {
    switch (label.toLowerCase()) {
      case 'food':
        return const Color(0xFFFF8A1F);
      case 'transport':
        return const Color(0xFF2E6BE6);
      case 'hotel':
        return const Color(0xFF7B61FF);
      case 'shopping':
        return const Color(0xFF2E7D32);
      case 'activities':
        return const Color(0xFFF4B000);
      default:
        return const Color(0xFF6B7280);
    }
  }

  Widget _limitCardFor({
    required String category,
    required double spent,
    required double limit,
  }) {
    final vis = _catIcon(category);
    return _LimitCard(
      label: category,
      icon: vis.$1,
      iconTile: vis.$2,
      color: _catColor(category),
      spent: spent,
      limit: limit,
      fmt: _fmtInt,
    );
  }

  Map<String, double> _defaultLimits() => const {
        'Food': 12000,
        'Transport': 8000,
        'Hotel': 15000,
        'Shopping': 8000,
        'Activities': 7000,
      };

  double _defaultTotalBudget(Map<String, double> limits) =>
      limits.values.fold<double>(0, (a, b) => a + b);

  Future<void> _openEditLimits(
    Map<String, double> limits,
    Map<String, double> spentByCat,
  ) async {
    final ctrls = <String, TextEditingController>{
      for (final c in _categories)
        c: TextEditingController(text: (limits[c] ?? 0).round().toString()),
    };

    Future<void> save() async {
      final next = <String, double>{};
      for (final c in _categories) {
        next[c] = (double.tryParse(ctrls[c]!.text.trim()) ?? 0).clamp(0, 1e12);
      }
      setState(() => _saving = true);
      try {
        final ref = await _userDoc();
        await ref.set({
          'budget_limits': next,
          'budget_updated_at': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        if (mounted) Navigator.of(context).pop();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not update limits. $e')),
        );
      } finally {
        if (mounted) setState(() => _saving = false);
      }
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 10,
              bottom: 16 + MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Edit Budget Limits',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.black,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: _categories.length,
                    separatorBuilder: (_, __) => Divider(
                      height: 1,
                      color: Colors.black.withValues(alpha: 0.06),
                    ),
                    itemBuilder: (context, i) {
                      final c = _categories[i];
                      final vis = _catIcon(c);
                      return _LimitEditRow(
                        label: c,
                        icon: vis.$1,
                        iconTile: vis.$2,
                        spent: spentByCat[c] ?? 0,
                        controller: ctrls[c]!,
                        fmt: _fmtInt,
                      );
                    },
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  height: 54,
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saving ? null : save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _accent,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'Save Budget Limits',
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    for (final c in ctrls.values) {
      c.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final month = DateTime(DateTime.now().year, DateTime.now().month, 1);
    bool inMonth(Expense e) => e.spentAt.year == month.year && e.spentAt.month == month.month;

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        bottom: false,
        child: StreamBuilder<List<Expense>>(
          stream: _expenseSvc.myExpensesStream(),
          builder: (context, expSnap) {
            final expenses = expSnap.data ?? const <Expense>[];
            final monthList = expenses.where(inMonth).toList();
            final spentTotal = monthList.fold<double>(0, (a, e) => a + e.amount);

            final spentByCat = <String, double>{for (final c in _categories) c: 0};
            for (final e in monthList) {
              spentByCat[e.category] = (spentByCat[e.category] ?? 0) + e.amount;
            }

            return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: _userDocStream(),
              builder: (context, userSnap) {
                final d = userSnap.data?.data() ?? <String, dynamic>{};
                final rawLimits = (d['budget_limits'] as Map?)?.cast<String, dynamic>();
                final limits = <String, double>{};
                for (final c in _categories) {
                  final v = rawLimits?[c];
                  limits[c] = (v is num ? v.toDouble() : null) ?? _defaultLimits()[c]!;
                }
                final totalBudget = (d['budget_total'] as num?)?.toDouble() ?? _defaultTotalBudget(limits);
                final remaining = (totalBudget - spentTotal).clamp(0.0, totalBudget);

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
                      child: Row(
                        children: [
                          Material(
                            color: Colors.black.withValues(alpha: 0.10),
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
                                  'Budget Planner',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    color: AppTheme.black,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Set limits per category',
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
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1C1C1F),
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
                          Text(
                            'TOTAL MONTHLY BUDGET',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.8,
                              color: Colors.white.withValues(alpha: 0.70),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'LKR ${_fmtInt(totalBudget)}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 34,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: -0.6,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Text(
                                'Spent: ${_fmtInt(spentTotal)}',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white.withValues(alpha: 0.82),
                                ),
                              ),
                              const SizedBox(width: 18),
                              Text(
                                'Remaining: ${_fmtInt(remaining)}',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white.withValues(alpha: 0.82),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
                        children: [
                          Text(
                            'Category limits',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.black,
                            ),
                          ),
                          const SizedBox(height: 12),
                          for (final c in _categories) ...[
                            _limitCardFor(
                              category: c,
                              spent: spentByCat[c] ?? 0,
                              limit: limits[c] ?? 0,
                            ),
                            const SizedBox(height: 12),
                          ],
                          const SizedBox(height: 10),
                          SizedBox(
                            height: 54,
                            child: ElevatedButton(
                              onPressed: () => _openEditLimits(limits, spentByCat),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _accent,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: Text(
                                'Update Budget Limits',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _LimitCard extends StatelessWidget {
  const _LimitCard({
    required this.label,
    required this.icon,
    required this.iconTile,
    required this.color,
    required this.spent,
    required this.limit,
    required this.fmt,
  });

  final String label;
  final IconData icon;
  final Color iconTile;
  final Color color;
  final double spent;
  final double limit;
  final String Function(num) fmt;

  @override
  Widget build(BuildContext context) {
    final pct = limit <= 0 ? 0.0 : (spent / limit).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconTile,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.black,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'LKR ${fmt(spent)} of ${fmt(limit)}',
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
                '${(pct * 100).round()}%',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF1F2A37),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 6,
              backgroundColor: Colors.black.withValues(alpha: 0.06),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}

class _LimitEditRow extends StatelessWidget {
  const _LimitEditRow({
    required this.label,
    required this.icon,
    required this.iconTile,
    required this.spent,
    required this.controller,
    required this.fmt,
  });

  final String label;
  final IconData icon;
  final Color iconTile;
  final double spent;
  final TextEditingController controller;
  final String Function(num) fmt;

  static const _accent = Color(0xFFFF8A1F);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconTile,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: AppTheme.black, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.black,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Spent: LKR ${fmt(spent)}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.grey,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 92,
            child: TextField(
              controller: controller,
              textAlign: TextAlign.right,
              keyboardType: TextInputType.number,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: AppTheme.black,
              ),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.10)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.10)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _accent, width: 1.4),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

