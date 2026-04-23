import 'package:cloud_firestore/cloud_firestore.dart';

class Expense {
  const Expense({
    required this.id,
    required this.amount,
    required this.currency,
    required this.category,
    required this.note,
    required this.paymentMethod,
    required this.spentAt,
    required this.createdAt,
  });

  final String id;
  final double amount;
  final String currency;
  final String category;
  final String note;
  final String paymentMethod;
  final DateTime spentAt;
  final DateTime createdAt;

  factory Expense.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    final spentTs = d['spent_at'];
    final createdTs = d['created_at'];
    DateTime spent = DateTime.now();
    if (spentTs is Timestamp) spent = spentTs.toDate();
    DateTime created = DateTime.fromMillisecondsSinceEpoch(0);
    if (createdTs is Timestamp) created = createdTs.toDate();
    return Expense(
      id: doc.id,
      amount: (d['amount'] as num?)?.toDouble() ??
          (d['total'] as num?)?.toDouble() ??
          0,
      currency: (d['currency'] as String? ?? 'LKR').trim().isEmpty
          ? 'LKR'
          : (d['currency'] as String? ?? 'LKR').trim(),
      category: (d['category'] as String? ?? 'Other').trim(),
      note: (d['note'] as String? ?? d['title'] as String? ?? '').trim(),
      paymentMethod: (d['payment_method'] as String? ?? 'Cash').trim(),
      spentAt: spent,
      createdAt: created,
    );
  }
}

