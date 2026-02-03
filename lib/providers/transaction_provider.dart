import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../models/transaction_item.dart';
import '../models/transaction_filter.dart';
import '../services/database_service.dart';
import '../utils/milestone_helper.dart';
import 'account_provider.dart';

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

final transactionsProvider =
    AsyncNotifierProvider<TransactionsNotifier, List<TransactionItem>>(() {
  return TransactionsNotifier();
});

class TransactionsNotifier extends AsyncNotifier<List<TransactionItem>> {
  @override
  Future<List<TransactionItem>> build() async {
    final filter = ref.watch(transactionFilterProvider);
    return DatabaseService.instance.getTransactionsFiltered(
      startDate: filter.startDate,
      endDate: filter.endDate,
      minAmount: filter.minAmount,
      maxAmount: filter.maxAmount,
      categoryIds: filter.categoryIds,
      accountIds: filter.accountIds,
      transactionTypes: filter.transactionTypes?.map((t) => t.index).toList(),
      searchQuery: filter.searchQuery,
      orderBy: filter.sortBy == TransactionSortBy.dateDesc
          ? 'date DESC, id DESC'
          : filter.sortBy == TransactionSortBy.dateAsc
              ? 'date ASC, id ASC'
              : filter.sortBy == TransactionSortBy.amountDesc
                  ? 'amount DESC, id DESC'
                  : filter.sortBy == TransactionSortBy.amountAsc
                      ? 'amount ASC, id ASC'
                      : filter.sortBy == TransactionSortBy.categoryAsc
                          ? 'category_id ASC, id DESC' // Simplified sort
                          : 'category_id DESC, id DESC',
    );
  }

  Future<void> addTransaction(
    TransactionItem transaction, {
    BuildContext? context,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await DatabaseService.instance.createTransaction(transaction);
      // Refresh accounts because balances changed
      ref.invalidate(accountsProvider);

      if (context != null && context.mounted) {
        final count = await DatabaseService.instance.getTotalTransactionCount();
        if (context.mounted) {
          await MilestoneHelper.checkTransactionMilestones(context, count);
        }
      }

      // Re-fetch transactions based on current filter
      return build();
    });
  }

  Future<void> updateTransaction(TransactionItem transaction) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await DatabaseService.instance.updateTransaction(transaction);
      ref.invalidate(accountsProvider);
      return build();
    });
  }

  Future<void> deleteTransaction(int id) async {
    state = await AsyncValue.guard(() async {
      await DatabaseService.instance.deleteTransaction(id);
      ref.invalidate(accountsProvider);
      return build();
    });
  }
}
