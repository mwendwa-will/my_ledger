import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/account_provider.dart';
import '../../providers/settings_provider.dart';
import '../../models/enums.dart';
import '../../models/category.dart';
import '../../models/account.dart';
import '../../utils/constants.dart';
import '../../utils/formatters.dart';

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    ref.read(transactionFilterProvider.notifier).update((state) => state.copyWith(searchQuery: query));
  }

  void _clearSearch() {
    _searchController.clear();
    _onSearchChanged('');
    setState(() => _isSearching = false);
  }

  Future<void> _showFilterSheet() async {
    final currentFilter = ref.read(transactionFilterProvider);
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDateRange: currentFilter.startDate != null && currentFilter.endDate != null 
          ? DateTimeRange(start: currentFilter.startDate!, end: currentFilter.endDate!) 
          : null,
    );

    if (picked != null) {
      ref.read(transactionFilterProvider.notifier).update((state) => state.copyWith(
        startDate: picked.start,
        endDate: picked.end,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final transactionsAsync = ref.watch(transactionsProvider);
    final categoryMapAsync = ref.watch(categoryMapProvider);
    final accountMapAsync = ref.watch(accountMapProvider);
    final currency = ref.watch(currencySymbolProvider);

    return Scaffold(
      appBar: AppBar(
        title: _isSearching 
          ? TextField(
              controller: _searchController,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Search...',
                border: InputBorder.none,
              ),
              onChanged: _onSearchChanged,
            )
          : const Text('Transactions'),
        actions: [
          if (_isSearching)
            IconButton(icon: const Icon(Icons.close), onPressed: _clearSearch)
          else
            IconButton(icon: const Icon(Icons.search), onPressed: () => setState(() => _isSearching = true)),
          
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterSheet,
          ),
        ],
      ),
      body: transactionsAsync.when(
        data: (transactions) {
          if (transactions.isEmpty) {
             if (_isSearching || ref.watch(transactionFilterProvider).searchQuery != null) {
               return const Center(child: Text('No transactions found matching your criteria.'));
             }
             return const Center(child: Text('No transactions yet.'));
          }
          
          return ListView.builder(
            itemCount: transactions.length,
            itemBuilder: (context, index) {
              final tx = transactions[index];
              final showHeader = index == 0 || !_isSameDay(transactions[index - 1].date, tx.date);

              Category? category;
              Account? toAccount;

              if (categoryMapAsync.value != null && tx.categoryId != null) {
                category = categoryMapAsync.value![tx.categoryId];
              }
              if (accountMapAsync.value != null && tx.toAccountId != null) {
                toAccount = accountMapAsync.value![tx.toAccountId];
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (showHeader)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Text(
                        Formatters.formatDate(tx.date),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  Dismissible(
                    key: Key('tx_${tx.id}'),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      color: AppColors.error,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    confirmDismiss: (_) async {
                      return await showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Delete Transaction?'),
                          content: Text('Delete this ${Formatters.formatCurrency(tx.amount, symbol: currency)} transaction?'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                            TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
                          ],
                        ),
                      );
                    },
                    onDismissed: (_) async {
                       final messenger = ScaffoldMessenger.of(context);
                       final deletedTx = tx;
                       await ref.read(transactionsProvider.notifier).deleteTransaction(tx.id!);
                       messenger.showSnackBar(
                         SnackBar(
                           content: const Text('Transaction deleted'),
                           action: SnackBarAction(
                             label: 'Undo',
                             onPressed: () {
                               // Re-add as new transaction (original ID is lost but data is preserved)
                               unawaited(ref.read(transactionsProvider.notifier).addTransaction(deletedTx.copyWith(id: null)));
                             },
                           ),
                         ),
                       );
                    },
                    child: ListTile(
                      leading: CircleAvatar(
                         backgroundColor: _getColor(tx.type).withAlpha(26),
                         child: Icon(
                           category != null ? IconData(category.iconCodePoint, fontFamily: 'MaterialIcons') : _getIcon(tx.type),
                           color: category != null ? Color(category.color) : _getColor(tx.type),
                           size: 20,
                         ),
                      ),
                      title: Text(
                        tx.note?.isNotEmpty == true ? tx.note! : (category?.name ?? 'Untitled'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      subtitle: Text(
                        tx.type == TransactionType.transfer
                          ? 'Transfer to ${toAccount?.name ?? 'Unknown Account'}'
                          : (category?.name ?? 'Uncategorized'),
                      ),
                      trailing: Text(
                        '${tx.type == TransactionType.expense || tx.type == TransactionType.transfer ? "-" : "+"}${Formatters.formatCurrency(tx.amount, symbol: currency)}',
                        style: TextStyle(
                          color: _getColor(tx.type),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const Divider(height: 1, indent: 72),
                ],
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Color _getColor(TransactionType type) {
    switch (type) {
      case TransactionType.income: return AppColors.income;
      case TransactionType.expense: return AppColors.expense;
      case TransactionType.transfer: return AppColors.transfer;
    }
  }

  IconData _getIcon(TransactionType type) {
     switch (type) {
      case TransactionType.income: return Icons.arrow_downward;
      case TransactionType.expense: return Icons.arrow_upward;
      case TransactionType.transfer: return Icons.swap_horiz;
    }
  }
}
