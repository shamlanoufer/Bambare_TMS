// lib/data/expense_store.dart
// Central in-memory CRUD store — swap for SQLite/Hive later

import 'package:flutter/material.dart';

enum ExpenseCategory { food, transport, accommodation, shopping, activities, other }

enum PaymentMethod { card, cash, mobilePay }

extension CategoryExt on ExpenseCategory {
  String get label {
    switch (this) {
      case ExpenseCategory.food: return 'Food & Drinks';
      case ExpenseCategory.transport: return 'Transport';
      case ExpenseCategory.accommodation: return 'Accommodation';
      case ExpenseCategory.shopping: return 'Shopping';
      case ExpenseCategory.activities: return 'Activities';
      case ExpenseCategory.other: return 'Other';
    }
  }

  String get emoji {
    switch (this) {
      case ExpenseCategory.food: return '🥗';
      case ExpenseCategory.transport: return '🚲';
      case ExpenseCategory.accommodation: return '🏨';
      case ExpenseCategory.shopping: return '🛍️';
      case ExpenseCategory.activities: return '🎭';
      case ExpenseCategory.other: return '📦';
    }
  }

  Color get color {
    switch (this) {
      case ExpenseCategory.food: return const Color(0xFF92C687);
      case ExpenseCategory.transport: return const Color(0xFFFF9000);
      case ExpenseCategory.accommodation: return const Color(0xFF42BFF4);
      case ExpenseCategory.shopping: return const Color(0xFFF775C1);
      case ExpenseCategory.activities: return const Color(0xFFF7CE45);
      case ExpenseCategory.other: return const Color(0xFFD9D9D9);
    }
  }
}

extension PaymentExt on PaymentMethod {
  String get label {
    switch (this) {
      case PaymentMethod.card: return 'Card';
      case PaymentMethod.cash: return 'Cash';
      case PaymentMethod.mobilePay: return 'Mobile Pay';
    }
  }

  String get emoji {
    switch (this) {
      case PaymentMethod.card: return '💳';
      case PaymentMethod.cash: return '💵';
      case PaymentMethod.mobilePay: return '📱';
    }
  }
}

class Expense {
  final String id;
  final double amount;
  final ExpenseCategory category;
  final PaymentMethod payment;
  final String note;
  final DateTime date;
  final String trip;

  Expense({
    required this.id,
    required this.amount,
    required this.category,
    required this.payment,
    required this.note,
    required this.date,
    required this.trip,
  });

  Expense copyWith({
    double? amount,
    ExpenseCategory? category,
    PaymentMethod? payment,
    String? note,
    DateTime? date,
    String? trip,
  }) {
    return Expense(
      id: id,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      payment: payment ?? this.payment,
      note: note ?? this.note,
      date: date ?? this.date,
      trip: trip ?? this.trip,
    );
  }
}

class ExpenseStore extends ChangeNotifier {
  static final ExpenseStore _instance = ExpenseStore._internal();
  factory ExpenseStore() => _instance;
  ExpenseStore._internal();

  final List<Expense> _expenses = [
    Expense(
      id: '1',
      amount: 1100,
      category: ExpenseCategory.food,
      payment: PaymentMethod.card,
      note: 'Lunch in Kandy',
      date: DateTime(2026, 3, 24, 13, 30),
      trip: 'Kandy',
    ),
    Expense(
      id: '2',
      amount: 320,
      category: ExpenseCategory.transport,
      payment: PaymentMethod.cash,
      note: 'Tuk-tuk to Kandy',
      date: DateTime(2026, 3, 24, 15, 15),
      trip: 'Kandy',
    ),
    Expense(
      id: '3',
      amount: 850,
      category: ExpenseCategory.food,
      payment: PaymentMethod.card,
      note: 'Dine out for dinner',
      date: DateTime(2026, 3, 23, 19, 30),
      trip: 'Colombo',
    ),
    Expense(
      id: '4',
      amount: 5000,
      category: ExpenseCategory.accommodation,
      payment: PaymentMethod.card,
      note: 'Hotel in Galle',
      date: DateTime(2026, 3, 22, 14, 0),
      trip: 'Galle',
    ),
    Expense(
      id: '5',
      amount: 2500,
      category: ExpenseCategory.shopping,
      payment: PaymentMethod.cash,
      note: 'Souvenirs',
      date: DateTime(2026, 3, 21, 11, 0),
      trip: 'Galle',
    ),
  ];

  List<Expense> get all => List.unmodifiable(_expenses);

  List<Expense> get sorted {
    final list = [..._expenses];
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  double get totalSpent => _expenses.fold(0, (sum, e) => sum + e.amount);

  double totalForCategory(ExpenseCategory cat) =>
      _expenses.where((e) => e.category == cat).fold(0, (sum, e) => sum + e.amount);

  List<Expense> byCategory(ExpenseCategory? cat) {
    if (cat == null) return sorted;
    return sorted.where((e) => e.category == cat).toList();
  }

  List<Expense> search(String query) {
    final q = query.toLowerCase();
    return sorted.where((e) =>
    e.note.toLowerCase().contains(q) ||
        e.category.label.toLowerCase().contains(q) ||
        e.trip.toLowerCase().contains(q)).toList();
  }

  // CREATE
  void addExpense(Expense expense) {
    _expenses.add(expense);
    notifyListeners();
  }

  // UPDATE
  void updateExpense(Expense updated) {
    final idx = _expenses.indexWhere((e) => e.id == updated.id);
    if (idx != -1) {
      _expenses[idx] = updated;
      notifyListeners();
    }
  }

  // DELETE
  void deleteExpense(String id) {
    _expenses.removeWhere((e) => e.id == id);
    notifyListeners();
  }

  String generateId() => DateTime.now().millisecondsSinceEpoch.toString();
}