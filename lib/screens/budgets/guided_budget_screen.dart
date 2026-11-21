import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/account.dart';
import '../../models/budget.dart';
import '../../models/category.dart';
import '../../models/enums.dart';
import '../../providers/account_provider.dart';
import '../../providers/budget_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/settings_provider.dart';
import '../../utils/formatters.dart';

class GuidedBudgetScreen extends ConsumerStatefulWidget {
  const GuidedBudgetScreen({super.key});

  @override
  ConsumerState<GuidedBudgetScreen> createState() => _GuidedBudgetScreenState();
}

class _GuidedBudgetScreenState extends ConsumerState<GuidedBudgetScreen> {
  final Map<int, TextEditingController> _controllers = {};
  bool _isSaving = false;

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  double _availableCash(List<Account> accounts) {
    return accounts
        .where((account) =>
            account.type == AccountType.checking ||
            account.type == AccountType.savings ||
            account.type == AccountType.cash,)
        .fold<double>(0, (total, account) => total + account.currentBalance);
  }

  Future<void> _save(
    List<Category> categories,
    DateTime month,
  ) async {
    final amounts = <Budget>[];
    for (final category in categories) {
      final amount = double.tryParse(_controllers[category.id]!.text);
      if (amount == null || amount < 0 || !amount.isFinite) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('Enter a valid non-negative amount for each category.'),),
        );
        return;
      }
      amounts.add(
        Budget(
          categoryId: category.id!,
          amount: amount,
          month: month.month,
          year: month.year,
        ),
      );
    }

    setState(() => _isSaving = true);
    try {
      for (final budget in amounts) {
        await BudgetNotifier.setBudget(ref, budget);
      }
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save budget plan: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final accountsAsync = ref.watch(accountsProvider);
    final budgetsAsync = ref.watch(budgetsViewProvider);
    final month = ref.watch(budgetMonthProvider);
    final currency = ref.watch(currencySymbolProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Guided Budget Setup')),
      body: categoriesAsync.when(
        data: (allCategories) {
          if (budgetsAsync.isLoading && !budgetsAsync.hasValue) {
            return const Center(child: CircularProgressIndicator());
          }
          if (budgetsAsync.hasError && !budgetsAsync.hasValue) {
            return Center(
              child:
                  Text('Could not load current budgets: ${budgetsAsync.error}'),
            );
          }
          final categories = allCategories.where((category) {
            if (category.type != TransactionType.expense ||
                category.isArchived) {
              return false;
            }
            return !allCategories.any((child) => child.parentId == category.id);
          }).toList();

          final existingBudgets = budgetsAsync.asData?.value ?? [];
          for (final category in categories) {
            if (_controllers.containsKey(category.id)) continue;
            final matching = existingBudgets
                .where((view) => view.category.id == category.id)
                .toList();
            _controllers[category.id!] = TextEditingController(
              text: matching.isEmpty
                  ? '0'
                  : matching.first.budgetAmount.toStringAsFixed(2),
            );
          }

          return accountsAsync.when(
            data: (accounts) {
              final available = _availableCash(accounts);
              final allocated = categories.fold<double>(
                0,
                (sum, category) =>
                    sum +
                    (double.tryParse(_controllers[category.id]!.text) ?? 0),
              );
              final remainder = available - allocated;

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Start with available cash',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Available now, including cash carried from earlier months: ${Formatters.formatCurrency(available, symbol: currency)}',
                            ),
                            Text(
                              'Assigned: ${Formatters.formatCurrency(allocated, symbol: currency)}',
                            ),
                            Text(
                              remainder >= 0
                                  ? 'Still to assign: ${Formatters.formatCurrency(remainder, symbol: currency)}'
                                  : 'Over-assigned: ${Formatters.formatCurrency(remainder.abs(), symbol: currency)}',
                              style: TextStyle(
                                color: remainder < 0
                                    ? Theme.of(context).colorScheme.error
                                    : null,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Give available cash a job. Amounts are allocations for the selected budget month; spending remains tracked separately.',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: categories
                          .map(
                            (category) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: TextField(
                                controller: _controllers[category.id],
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                decoration: InputDecoration(
                                  labelText: category.parentId == null
                                      ? category.name
                                      : '  ${category.name}',
                                  prefixText: '$currency ',
                                  border: const OutlineInputBorder(),
                                ),
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed:
                              _isSaving ? null : () => _save(categories, month),
                          child: Text(
                            _isSaving ? 'Saving…' : 'Save budget plan',
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) =>
                Center(child: Text('Could not load accounts: $error')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) =>
            Center(child: Text('Could not load categories: $error')),
      ),
    );
  }
}
