import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../models/transaction_item.dart';
import '../services/database_service.dart';
import 'account_provider.dart';

class TransactionFilter {

  TransactionFilter({
    this.startDate,
    this.endDate,
    this.categoryId,
    this.accountId,
    this.searchQuery,
  });
  final DateTime? startDate;
  final DateTime? endDate;
  final int? categoryId;
  final int? accountId;
  final String? searchQuery;

  TransactionFilter copyWith({
    DateTime? startDate,
    DateTime? endDate,
    int? categoryId,
    int? accountId,
    String? searchQuery,
  }) {
    return TransactionFilter(
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      categoryId: categoryId ?? this.categoryId,
      accountId: accountId ?? this.accountId,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

final transactionFilterProvider = StateProvider<TransactionFilter>((ref) {
  // Default to current month? Or all time?
  // Let's default to current month to be performant
  final now = DateTime.now();
  final startOfMonth = DateTime(now.year, now.month, 1);
  final endOfMonth = DateTime(now.year, now.month + 1, 0);
  
  return TransactionFilter(
    startDate: startOfMonth,
    endDate: endOfMonth,
  );
});

final transactionsProvider = AsyncNotifierProvider<TransactionsNotifier, List<TransactionItem>>(() {
  return TransactionsNotifier();
});

class TransactionsNotifier extends AsyncNotifier<List<TransactionItem>> {
  @override
  Future<List<TransactionItem>> build() async {
    final filter = ref.watch(transactionFilterProvider);
    return DatabaseService.instance.getTransactions(
      startDate: filter.startDate,
      endDate: filter.endDate,
      categoryId: filter.categoryId,
      accountId: filter.accountId,
      searchQuery: filter.searchQuery,
    );
  }

  Future<void> addTransaction(TransactionItem transaction) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await DatabaseService.instance.createTransaction(transaction);
      // Refresh accounts because balances changed
      ref.invalidate(accountsProvider);
      
      // Re-fetch transactions based on current filter
      final filter = ref.read(transactionFilterProvider);
      return DatabaseService.instance.getTransactions(
        startDate: filter.startDate,
        endDate: filter.endDate,
        categoryId: filter.categoryId,
        accountId: filter.accountId,
        searchQuery: filter.searchQuery,
      );
    });
  }

  Future<void> deleteTransaction(int id) async {
    state = await AsyncValue.guard(() async {
      await DatabaseService.instance.deleteTransaction(id);
      ref.invalidate(accountsProvider);
      
      final filter = ref.read(transactionFilterProvider);
      return DatabaseService.instance.getTransactions(
        startDate: filter.startDate,
        endDate: filter.endDate,
        categoryId: filter.categoryId,
        accountId: filter.accountId,
        searchQuery: filter.searchQuery,
      );
    });
  }
}
