import 'package:flutter/material.dart';
import '../models/transaction.dart';

class FinanceViewModel extends ChangeNotifier {
  final List<Transaction> _transactions = [
    Transaction(
      id: '1',
      title: 'Salário',
      amount: 5000.0,
      date: DateTime.now().subtract(const Duration(days: 2)),
      type: TransactionType.income,
      category: 'Salário',
    ),
    Transaction(
      id: '2',
      title: 'Supermercado',
      amount: 450.0,
      date: DateTime.now().subtract(const Duration(days: 1)),
      type: TransactionType.expense,
      category: 'Alimentação',
    ),
    Transaction(
      id: '3',
      title: 'Internet',
      amount: 100.0,
      date: DateTime.now(),
      type: TransactionType.expense,
      category: 'Contas',
    ),
    Transaction(
      id: '4',
      title: 'Academia',
      amount: 120.0,
      date: DateTime.now().subtract(const Duration(days: 3)),
      type: TransactionType.expense,
      category: 'Saúde',
    ),
  ];

  List<Transaction> get transactions {
    final copy = [..._transactions];
    copy.sort((a, b) => b.date.compareTo(a.date));
    return copy;
  }

  double get balance => totalIncome - totalExpense;

  double get totalIncome {
    return _transactions
        .where((tx) => tx.type == TransactionType.income)
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  double get totalExpense {
    return _transactions
        .where((tx) => tx.type == TransactionType.expense)
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  void addTransaction(Transaction transaction) {
    _transactions.add(transaction);
    notifyListeners();
  }
}
