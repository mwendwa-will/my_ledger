import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/account.dart';
import '../../models/category.dart';
import '../../models/enums.dart';
import '../../models/transaction_item.dart';
import '../../providers/account_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../utils/constants.dart';
import '../../utils/icon_helper.dart';
import '../../utils/formatters.dart';
import 'add_transaction_screen.dart';

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  bool _isInSelectionMode = false; // New state for selection mode
  final Set<int> _selectedTransactionIds = {}; // New state for selected transactions

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

  void _toggleSelectionMode() {
    setState(() {
      _isInSelectionMode = !_isInSelectionMode;
      if (!_isInSelectionMode) {
        _selectedTransactionIds.clear(); // Clear selection when exiting mode
      }
    });
  }

  Future<void> _deleteSelectedTransactions() async {
    final messenger = ScaffoldMessenger.of(context);
    final count = _selectedTransactionIds.length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Transactions?'),
        content: Text('Are you sure you want to delete $count selected transactions?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text('Delete', style: TextStyle(color: Theme.of(context).colorScheme.error))),
        ],
      ),
    ) ?? false;

    if (confirmed) {
      for (final id in _selectedTransactionIds) {
        await ref.read(transactionsProvider.notifier).deleteTransaction(id);
      }
      messenger.showSnackBar(
        SnackBar(content: Text('$count transactions deleted')),
      );
      _toggleSelectionMode(); // Exit selection mode after deletion
    }
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
      ),);
    }
  }

  @override
  Widget build(BuildContext context) {
    final transactionsAsync = ref.watch(transactionsProvider);
    final categoryMapAsync = ref.watch(categoryMapProvider);
    final accountMapAsync = ref.watch(accountMapProvider);
    final currency = ref.watch(currencyCodeProvider.notifier).currentCurrencySymbol;

    return Scaffold(
      appBar: AppBar(
        title: _isInSelectionMode
            ? Text('${_selectedTransactionIds.length} Selected')
            : (_isSearching 
                ? TextField(
                    controller: _searchController,
                    autofocus: true,
                    decoration: const InputDecoration(
                      hintText: 'Search...',
                      border: InputBorder.none,
                    ),
                    onChanged: _onSearchChanged,
                  )
                : const Text('Transactions')),
        actions: [
          if (_isInSelectionMode) ...[
            IconButton(icon: const Icon(Icons.cancel), onPressed: _toggleSelectionMode, tooltip: 'Cancel selection'),
            IconButton(icon: const Icon(Icons.delete), onPressed: _deleteSelectedTransactions, tooltip: 'Delete selected transactions'),
          ] else if (_isSearching) ...[
            IconButton(icon: const Icon(Icons.close), onPressed: _clearSearch),
          ] else ...[
            IconButton(icon: const Icon(Icons.search), onPressed: () => setState(() => _isSearching = true)),
            IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: _showFilterSheet,
            ),
          ],
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
          
          // Group transactions by date
          final Map<DateTime, List<TransactionItem>> groupedTransactions = {};
          for (final tx in transactions) {
            final date = DateTime(tx.date.year, tx.date.month, tx.date.day);
            if (!groupedTransactions.containsKey(date)) {
              groupedTransactions[date] = [];
            }
            groupedTransactions[date]!.add(tx);
          }

          final sortedDates = groupedTransactions.keys.toList()..sort((a, b) => b.compareTo(a));

          return CustomScrollView(
            slivers: [
              ...sortedDates.map((date) {
                final txs = groupedTransactions[date]!;
                return SliverMainAxisGroup(
                  slivers: [
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: _SliverDateHeaderDelegate(
                        date: date,
                        context: context,
                      ),
                    ),
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final tx = txs[index];

                          Category? category;
                          Account? toAccount;

                          if (categoryMapAsync.value != null && tx.categoryId != null) {
                            category = categoryMapAsync.value![tx.categoryId];
                          }
                          if (accountMapAsync.value != null && tx.toAccountId != null) {
                            toAccount = accountMapAsync.value![tx.toAccountId];
                          }

                          return _buildTransactionListTile(context, ref, tx, category, toAccount, currency);
                        },
                        childCount: txs.length,
                      ),
                    ),
                  ],
                );
              }),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildTransactionListTile(
    BuildContext context,
    WidgetRef ref,
    TransactionItem tx,
    Category? category,
    Account? toAccount,
    String currency,
  ) {
    final isExpense = tx.type == TransactionType.expense;
    final color = isExpense ? Theme.of(context).colorScheme.error : (tx.type == TransactionType.income ? Theme.of(context).colorScheme.secondary : Theme.of(context).colorScheme.tertiary);
    final isSelected = _selectedTransactionIds.contains(tx.id);

    return GestureDetector(
      onLongPress: () {
        setState(() {
          _isInSelectionMode = true;
          if (_selectedTransactionIds.contains(tx.id)) {
            _selectedTransactionIds.remove(tx.id);
          } else {
            _selectedTransactionIds.add(tx.id!);
          }
        });
      },
      onTap: () {
        if (_isInSelectionMode) {
          setState(() {
            if (_selectedTransactionIds.contains(tx.id)) {
              _selectedTransactionIds.remove(tx.id);
            } else {
              _selectedTransactionIds.add(tx.id!);
            }
          });
        }
      },
      child: Dismissible(
        key: Key('tx_${tx.id}'),
        direction: DismissDirection.endToStart,
        background: Container(
          color: Theme.of(context).colorScheme.error,
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          child: Icon(Icons.delete, color: Theme.of(context).colorScheme.onError),
        ),
        confirmDismiss: (_) async {
          return await showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Delete Transaction?'),
              content: Text('Delete this ${Formatters.formatCurrency(tx.amount, symbol: currency)} transaction?'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text('Delete', style: TextStyle(color: Theme.of(context).colorScheme.error))),
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
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: isSelected ? Theme.of(context).colorScheme.primaryContainer.withAlpha((0.3 * 255).round()) : Theme.of(context).cardColor, // Highlight selected
            border: Border(
              left: BorderSide(
                color: category != null ? Color(category.color) : _getColor(context, tx.type),
                width: 5,
              ),
            ),
          ),
          child: Theme( // Wrap with Theme to customize ExpansionTile colors if needed
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              key: PageStorageKey('expansion_tile_${tx.id}'), // Keep expansion state across rebuilds
              tilePadding: const EdgeInsets.symmetric(horizontal: AppConstants.defaultPadding),
              leading: _isInSelectionMode
                  ? Checkbox(
                      value: isSelected,
                      onChanged: (bool? value) {
                        setState(() {
                          if (value == true) {
                            _selectedTransactionIds.add(tx.id!);
                          } else {
                            _selectedTransactionIds.remove(tx.id);
                          }
                        });
                      },
                    )
                  : CircleAvatar(
                      backgroundColor: color.withAlpha(26),
                      child: Icon(
                        category != null ? getIconFromCodePoint(category.iconCodePoint) : _getIcon(tx.type),
                        color: category != null ? Color(category.color) : _getColor(context, tx.type),
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
                  color: _getColor(context, tx.type),
                  fontWeight: FontWeight.bold,
                ),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppConstants.defaultPadding, vertical: AppConstants.smallPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (tx.note?.isNotEmpty == true) ...[
                        Text('Note: ${tx.note!}'),
                        const SizedBox(height: AppConstants.smallPadding),
                      ],
                      Text('Account: ${ref.watch(accountMapProvider).value?[tx.accountId]?.name ?? 'Unknown'}'),
                      const SizedBox(height: AppConstants.smallPadding),
                      if (tx.type == TransactionType.transfer)
                        Text('To Account: ${toAccount?.name ?? 'Unknown'}')
                      else
                        Text('Category: ${category?.name ?? 'Uncategorized'}'),
                      const SizedBox(height: AppConstants.defaultPadding),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: () async {
                            // Open edit screen prefilled
                            final navigator = Navigator.of(context);
                            await navigator.push(
                              MaterialPageRoute(
                                builder: (_) => AddTransactionScreen(transaction: tx),
                                fullscreenDialog: true,
                              ),
                            );
                            // After edit, refresh transactions
                            ref.invalidate(transactionsProvider);
                          },
                          icon: const Icon(Icons.edit),
                          label: const Text('Edit Transaction'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Removed unused helper `_isSameDay` to satisfy analyzer (was not referenced)

  Color _getColor(BuildContext context, TransactionType type) {
    switch (type) {
      case TransactionType.income:
        return Theme.of(context).colorScheme.secondary;
      case TransactionType.expense:
        return Theme.of(context).colorScheme.error;
      case TransactionType.transfer:
        return Theme.of(context).colorScheme.tertiary;
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

class _SliverDateHeaderDelegate extends SliverPersistentHeaderDelegate { // Pass context to access theme

  const _SliverDateHeaderDelegate({required this.date, required this.context});
  final DateTime date;
  final BuildContext context;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Theme.of(context).colorScheme.surface, // Use theme surface color for header background
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.defaultPadding, vertical: AppConstants.smallPadding),
      alignment: Alignment.centerLeft,
      child: Text(
        Formatters.formatDate(date),
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  @override
  double get maxExtent => 50; // Max height of header
  @override
  double get minExtent => 50; // Min height of header
  @override
  bool shouldRebuild(covariant _SliverDateHeaderDelegate oldDelegate) {
    return oldDelegate.date != date || oldDelegate.context != context;
  }
}
