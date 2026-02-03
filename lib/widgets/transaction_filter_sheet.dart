import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/transaction_filter.dart';
import '../models/enums.dart';
import '../providers/category_provider.dart';
import '../providers/account_provider.dart';

/// Bottom sheet for filtering transactions
class TransactionFilterSheet extends ConsumerStatefulWidget {
  const TransactionFilterSheet({
    super.key,
    required this.initialFilter,
    required this.onApply,
  });

  final TransactionFilter initialFilter;
  final ValueChanged<TransactionFilter> onApply;

  @override
  ConsumerState<TransactionFilterSheet> createState() =>
      _TransactionFilterSheetState();
}

class _TransactionFilterSheetState
    extends ConsumerState<TransactionFilterSheet> {
  late TransactionFilter _filter;
  final _minAmountController = TextEditingController();
  final _maxAmountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filter = widget.initialFilter;
    _minAmountController.text = _filter.minAmount?.toStringAsFixed(2) ?? '';
    _maxAmountController.text = _filter.maxAmount?.toStringAsFixed(2) ?? '';
  }

  @override
  void dispose() {
    _minAmountController.dispose();
    _maxAmountController.dispose();
    super.dispose();
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDateRange: _filter.startDate != null && _filter.endDate != null
          ? DateTimeRange(start: _filter.startDate!, end: _filter.endDate!)
          : null,
    );

    if (picked != null) {
      setState(() {
        _filter = _filter.copyWith(
          startDate: picked.start,
          endDate: picked.end,
        );
      });
    }
  }

  void _setQuickDateRange(String range) {
    final now = DateTime.now();
    DateTime? start;
    final DateTime end = DateTime(now.year, now.month, now.day, 23, 59, 59);

    switch (range) {
      case 'today':
        start = DateTime(now.year, now.month, now.day);
        break;
      case 'week':
        start = now.subtract(const Duration(days: 7));
        break;
      case 'month':
        start = DateTime(now.year, now.month, 1);
        break;
      case 'year':
        start = DateTime(now.year, 1, 1);
        break;
    }

    if (start != null) {
      setState(() {
        _filter = _filter.copyWith(startDate: start, endDate: end);
      });
    }
  }

  String _getDateRangeText() {
    if (_filter.startDate == null && _filter.endDate == null) {
      return 'All Time';
    }
    final format = DateFormat('MMM d, yyyy');
    if (_filter.startDate != null && _filter.endDate != null) {
      return '${format.format(_filter.startDate!)} - ${format.format(_filter.endDate!)}';
    }
    if (_filter.startDate != null) {
      return 'From ${format.format(_filter.startDate!)}';
    }
    return 'Until ${format.format(_filter.endDate!)}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categoriesAsync = ref.watch(categoriesProvider);
    final accountsAsync = ref.watch(accountsProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return DecoratedBox(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 8, bottom: 8),
                width: 32,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Filter Transactions',
                      style: theme.textTheme.titleLarge,
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _filter = _filter.clear();
                          _minAmountController.clear();
                          _maxAmountController.clear();
                        });
                      },
                      child: const Text('Clear All'),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Scrollable content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Date Range
                    _buildSection(
                      'Date Range',
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 8,
                            children: [
                              FilterChip(
                                label: const Text('Today'),
                                selected: false,
                                onSelected: (_) => _setQuickDateRange('today'),
                              ),
                              FilterChip(
                                label: const Text('Last 7 Days'),
                                selected: false,
                                onSelected: (_) => _setQuickDateRange('week'),
                              ),
                              FilterChip(
                                label: const Text('This Month'),
                                selected: false,
                                onSelected: (_) => _setQuickDateRange('month'),
                              ),
                              FilterChip(
                                label: const Text('This Year'),
                                selected: false,
                                onSelected: (_) => _setQuickDateRange('year'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed: _selectDateRange,
                            icon: const Icon(Icons.calendar_today),
                            label: Text(_getDateRangeText()),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Amount Range
                    _buildSection(
                      'Amount Range',
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _minAmountController,
                              decoration: const InputDecoration(
                                labelText: 'Min',
                                prefixText: '\$ ',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                              onChanged: (value) {
                                final amount = double.tryParse(value);
                                setState(() {
                                  _filter = _filter.copyWith(minAmount: amount);
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextField(
                              controller: _maxAmountController,
                              decoration: const InputDecoration(
                                labelText: 'Max',
                                prefixText: '\$ ',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                              onChanged: (value) {
                                final amount = double.tryParse(value);
                                setState(() {
                                  _filter = _filter.copyWith(maxAmount: amount);
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Transaction Types
                    _buildSection(
                      'Transaction Type',
                      Wrap(
                        spacing: 8,
                        children: TransactionType.values.map((type) {
                          final isSelected =
                              _filter.transactionTypes?.contains(type) ?? false;
                          return FilterChip(
                            label: Text(_capitalize(type.name)),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                final types = List<TransactionType>.from(
                                  _filter.transactionTypes ?? [],
                                );
                                if (selected) {
                                  types.add(type);
                                } else {
                                  types.remove(type);
                                }
                                _filter = _filter.copyWith(
                                  transactionTypes:
                                      types.isEmpty ? null : types,
                                );
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Categories
                    categoriesAsync.when(
                      data: (categories) => _buildSection(
                        'Categories',
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: categories.map((category) {
                            final isSelected =
                                _filter.categoryIds?.contains(category.id) ??
                                    false;
                            return FilterChip(
                              label: Text(category.name),
                              selected: isSelected,
                              avatar: isSelected
                                  ? null
                                  : CircleAvatar(
                                      backgroundColor: Color(category.color),
                                      radius: 12,
                                    ),
                              onSelected: (selected) {
                                setState(() {
                                  final ids =
                                      List<int>.from(_filter.categoryIds ?? []);
                                  if (selected) {
                                    ids.add(category.id!);
                                  } else {
                                    ids.remove(category.id);
                                  }
                                  _filter = _filter.copyWith(
                                    categoryIds: ids.isEmpty ? null : ids,
                                  );
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ),
                      loading: () => const CircularProgressIndicator(),
                      error: (_, __) => const Text('Error loading categories'),
                    ),

                    const SizedBox(height: 24),

                    // Accounts
                    accountsAsync.when(
                      data: (accounts) => _buildSection(
                        'Accounts',
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: accounts.map((account) {
                            final isSelected =
                                _filter.accountIds?.contains(account.id) ??
                                    false;
                            return FilterChip(
                              label: Text(account.name),
                              selected: isSelected,
                              onSelected: (selected) {
                                setState(() {
                                  final ids =
                                      List<int>.from(_filter.accountIds ?? []);
                                  if (selected) {
                                    ids.add(account.id!);
                                  } else {
                                    ids.remove(account.id);
                                  }
                                  _filter = _filter.copyWith(
                                    accountIds: ids.isEmpty ? null : ids,
                                  );
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ),
                      loading: () => const CircularProgressIndicator(),
                      error: (_, __) => const Text('Error loading accounts'),
                    ),

                    const SizedBox(height: 24),

                    // Sort By
                    _buildSection(
                      'Sort By',
                      DropdownButtonFormField<TransactionSortBy>(
                        initialValue: _filter.sortBy,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                        ),
                        items: TransactionSortBy.values.map((sort) {
                          return DropdownMenuItem(
                            value: sort,
                            child: Text(sort.label),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _filter = _filter.copyWith(sortBy: value);
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),

              // Apply button
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: theme.dividerColor),
                  ),
                ),
                child: SafeArea(
                  top: false,
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () {
                        widget.onApply(_filter);
                        Navigator.pop(context);
                      },
                      child: Text(
                        _filter.hasActiveFilters
                            ? 'Apply ${_filter.activeFilterCount} Filter${_filter.activeFilterCount > 1 ? 's' : ''}'
                            : 'Apply Filters',
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSection(String title, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
}
