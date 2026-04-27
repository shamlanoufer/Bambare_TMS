import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/expense.dart';

class ExpenseService {
  ExpenseService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _db = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  Future<User> _ensureUser() async {
    final existing = _auth.currentUser;
    if (existing != null) return existing;
    final cred = await _auth.signInAnonymously();
    return cred.user!;
  }

  CollectionReference<Map<String, dynamic>> _col(String uid) =>
      _db.collection('users').doc(uid).collection('expenses');

  Stream<List<Expense>> myExpensesStream() async* {
    final user = await _ensureUser();
    yield* _col(user.uid).snapshots().map((snap) {
      final list = snap.docs.map(Expense.fromDoc).toList()
        ..sort((a, b) => b.spentAt.compareTo(a.spentAt));
      return list;
    });
  }

  Future<void> addExpense({
    required double amount,
    required String currency,
    required String category,
    required String note,
    required String paymentMethod,
    required DateTime spentAt,
  }) async {
    final user = await _ensureUser();
    await _col(user.uid).add({
      'amount': amount,
      'currency': currency,
      'category': category,
      'note': note,
      'payment_method': paymentMethod,
      'spent_at': Timestamp.fromDate(spentAt),
      'created_at': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateExpense(
    String expenseId, {
    double? amount,
    String? currency,
    String? category,
    String? note,
    String? paymentMethod,
    DateTime? spentAt,
  }) async {
    final user = await _ensureUser();
    final patch = <String, dynamic>{};
    if (amount != null) patch['amount'] = amount;
    if (currency != null) patch['currency'] = currency;
    if (category != null) patch['category'] = category;
    if (note != null) patch['note'] = note;
    if (paymentMethod != null) patch['payment_method'] = paymentMethod;
    if (spentAt != null) patch['spent_at'] = Timestamp.fromDate(spentAt);
    if (patch.isEmpty) return;
    await _col(user.uid).doc(expenseId).update(patch);
  }

  Future<void> deleteExpense(String expenseId) async {
    final user = await _ensureUser();
    await _col(user.uid).doc(expenseId).delete();
  }
}

