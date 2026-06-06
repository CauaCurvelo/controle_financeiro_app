import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/transaction.dart';
import '../services/db_helper.dart';
import '../services/cloud_sync_service.dart';
import 'auth_provider.dart';

final financeProvider = NotifierProvider<FinanceNotifier, FinanceState>(FinanceNotifier.new);

class FinanceState {
  final List<TransactionItem> transactions;
  final bool isLoading;

  FinanceState({
    this.transactions = const [],
    this.isLoading = false,
  });

  FinanceState copyWith({
    List<TransactionItem>? transactions,
    bool? isLoading,
  }) {
    return FinanceState(
      transactions: transactions ?? this.transactions,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  double get balance => totalIncome - totalExpense;

  double get totalIncome => transactions
      .where((tx) => tx.type == TransactionType.income)
      .fold(0.0, (sum, item) => sum + item.amount);

  double get totalExpense => transactions
      .where((tx) => tx.type == TransactionType.expense)
      .fold(0.0, (sum, item) => sum + item.amount);
}

class FinanceNotifier extends Notifier<FinanceState> {
  int? get userId => ref.watch(authProvider).userId;

  @override
  FinanceState build() {
    if (userId != null) {
      Future.microtask(() => _loadTransactions());
      return FinanceState(isLoading: true);
    }
    return FinanceState(isLoading: false);
  }

  Future<void> _loadTransactions() async {
    if (userId == null) return;
    state = state.copyWith(isLoading: true);
    try {
      final transactions = await DBHelper().getTransactions(userId!);
      state = state.copyWith(transactions: transactions, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> addTransaction(TransactionItem transaction) async {
    if (userId == null) return;
    await DBHelper().insertTransaction(transaction, userId!);
    await _loadTransactions();
    CloudSyncService.syncToCloud(userId!, state.transactions);
  }

  Future<void> deleteTransaction(String id) async {
    if (userId == null) return;
    await DBHelper().deleteTransaction(id);
    await _loadTransactions();
    CloudSyncService.syncToCloud(userId!, state.transactions);
  }
  
  Future<void> updateTransaction(TransactionItem transaction) async {
    if (userId == null) return;
    await DBHelper().insertTransaction(transaction, userId!); // insertTransaction faz upsert
    await _loadTransactions();
    CloudSyncService.syncToCloud(userId!, state.transactions);
  }
}
