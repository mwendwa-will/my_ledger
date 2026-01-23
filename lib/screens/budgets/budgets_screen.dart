import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/budget_provider.dart';
import '../../providers/settings_provider.dart';
import '../../models/budget.dart';
import '../../utils/constants.dart';
import '../../utils/formatters.dart';
import '../../widgets/gradient_progress_bar.dart'; // Import GradientProgressBar

class BudgetsScreen extends ConsumerStatefulWidget {
  const BudgetsScreen({super.key});

  @override
  ConsumerState<BudgetsScreen> createState() => _BudgetsScreenState();
}

class _BudgetsScreenState extends ConsumerState<BudgetsScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0, end: 8).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

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
            prefixText: r'$ ',
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
  Widget build(BuildContext context) {
    final budgetsAsync = ref.watch(budgetsViewProvider);
    final date = ref.watch(budgetMonthProvider);
    final currency = ref.watch(currencyCodeProvider.notifier).currentCurrencySymbol;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Budgets'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
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
              
              List<Color> gradientColors;
              if (progress >= 1.0) {
                gradientColors = [AppColors.error, AppColors.errorContainer]; // Red for over budget
              } else if (progress >= 0.8) {
                gradientColors = [AppColors.warning, Colors.amber.shade200]; // Yellow for approaching
              } else {
                gradientColors = [AppColors.income, Colors.green.shade200]; // Green for under budget
              }
              
              return AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    elevation: progress >= 1.0 ? _pulseAnimation.value : 1, // Animate elevation for over budget
                    shadowColor: progress >= 1.0 ? AppColors.error : null, // Set shadow color
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppConstants.cardRadius),
                      side: progress >= 1.0
                          ? BorderSide(color: AppColors.error, width: _pulseAnimation.value / 2 + 1) // Pulsating border
                          : BorderSide.none,
                    ),
                    child: child,
                  );
                },
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
                              GradientProgressBar(
                                value: progress.clamp(0.0, 1.0),
                                colors: gradientColors,
                                borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
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
                              // Previous month comparison
                              if (view.previousMonthSpentAmount != null) ...[
                                const SizedBox(height: AppConstants.smallPadding),
                                Row(
                                  children: [
                                    const Text('Prev Month: ', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                    Text(
                                      Formatters.formatCurrency(view.previousMonthSpentAmount!, symbol: currency),
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
                                    const SizedBox(width: AppConstants.smallPadding),
                                    _buildTrendIndicator(view.spentAmount, view.previousMonthSpentAmount!),
                                  ],
                                ),
                              ],
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

  Widget _buildTrendIndicator(double current, double previous) {
    if (current > previous) {
      return const Icon(Icons.arrow_upward, size: 16, color: AppColors.expense);
    } else if (current < previous) {
      return const Icon(Icons.arrow_downward, size: 16, color: AppColors.income);
    } else {
      return const Icon(Icons.trending_flat, size: 16, color: Colors.grey);
    }
  }
}