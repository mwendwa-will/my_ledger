import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/budget_provider.dart';
import '../../providers/settings_provider.dart';
import '../../models/budget.dart';
import '../../utils/constants.dart';
import '../../utils/formatters.dart';

class BudgetsScreen extends ConsumerWidget {
  const BudgetsScreen({super.key});

  void _editBudget(BuildContext context, WidgetRef ref, BudgetView view, DateTime date) {
    final controller = TextEditingController(text: view.budgetAmount > 0 ? view.budgetAmount.toString() : '');
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Set Budget for ${view.category.name}'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Budget Limit',
            prefixText: '\$ ',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(controller.text) ?? 0.0;
              final budget = Budget(
                categoryId: view.category.id!,
                amount: amount,
                month: date.month,
                year: date.year,
              );
              BudgetNotifier.setBudget(ref, budget);
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgetsAsync = ref.watch(budgetsViewProvider);
    final date = ref.watch(budgetMonthProvider);
    final currency = ref.watch(currencySymbolProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Budgets'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () {
                    ref.read(budgetMonthProvider.notifier).state = DateTime(date.year, date.month - 1);
                  },
                ),
                Text(
                  Formatters.formatDate(date).split(',')[0].replaceFirst(' ', ', '), // "Jan 2024" rough hack or proper format
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () {
                    ref.read(budgetMonthProvider.notifier).state = DateTime(date.year, date.month + 1);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      body: budgetsAsync.when(
        data: (views) {
          if (views.isEmpty) {
            return const Center(child: Text('No expense categories found.'));
          }
          
          return ListView.builder(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            itemCount: views.length,
            itemBuilder: (context, index) {
              final view = views[index];
              final progress = view.progress;
              Color progressColor = AppColors.income; // Good
              if (progress >= 1.0) {
                progressColor = AppColors.error;
              } else if (progress >= 0.8) {progressColor = AppColors.warning;}
              
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: InkWell(
                  onTap: () => _editBudget(context, ref, view, date),
                  borderRadius: BorderRadius.circular(AppConstants.cardRadius),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: Color(view.category.color).withAlpha(51),
                              child: Icon(IconData(view.category.iconCodePoint, fontFamily: 'MaterialIcons'), color: Color(view.category.color), size: 16),
                            ),
                            const SizedBox(width: 12),
                            Expanded(child: Text(view.category.name, style: const TextStyle(fontWeight: FontWeight.bold))),
                            if (view.budgetAmount > 0)
                              Text(
                                '${Formatters.formatCurrency(view.spentAmount, symbol: currency)} / ${Formatters.formatCurrency(view.budgetAmount, symbol: currency)}',
                                style: TextStyle(
                                  color: progress >= 1.0 ? AppColors.error : Colors.grey[700],
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            else
                              Text(
                                Formatters.formatCurrency(view.spentAmount, symbol: currency),
                                style: const TextStyle(color: Colors.grey),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (view.budgetAmount > 0)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              LinearProgressIndicator(
                                value: progress > 1 ? 1 : progress,
                                backgroundColor: Colors.grey[200],
                                color: progressColor,
                                minHeight: 8,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              const SizedBox(height: 4),
                              if (view.remaining < 0)
                                Text(
                                  'Over by ${Formatters.formatCurrency(view.remaining.abs(), symbol: currency)}',
                                  style: const TextStyle(color: AppColors.error, fontSize: 12),
                                )
                              else
                                Text(
                                  '${Formatters.formatCurrency(view.remaining, symbol: currency)} left',
                                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                ),
                            ],
                          )
                        else
                          Row(
                            children: [
                              const Spacer(),
                              TextButton.icon(
                                onPressed: () => _editBudget(context, ref, view, date),
                                icon: const Icon(Icons.add_circle_outline, size: 16),
                                label: const Text('Set Limit'),
                                style: TextButton.styleFrom(
                                  visualDensity: VisualDensity.compact,
                                  foregroundColor: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }
}