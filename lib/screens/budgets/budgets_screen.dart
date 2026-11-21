import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/budget_provider.dart';
import '../../providers/settings_provider.dart';
import '../../models/budget.dart';
import '../../models/account.dart';
import '../../models/enums.dart';
import '../../providers/account_provider.dart';
import '../../utils/constants.dart';
import '../../utils/icon_helper.dart';
import '../../utils/formatters.dart';
import '../../widgets/gradient_progress_bar.dart'; // Import GradientProgressBar
import 'guided_budget_screen.dart';

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
    ),);
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
      builder: (ctx) => Consumer(
        builder: (context, ref, _) => AlertDialog(
          title: Text('Set Budget for ${view.category.name}'),
          content: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Budget Limit',
              prefixText: '${ref.watch(currencySymbolProvider)} ',
              border: const OutlineInputBorder(),
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final budgetsAsync = ref.watch(budgetsViewProvider);
    final accountsAsync = ref.watch(accountsProvider);
    final date = ref.watch(budgetMonthProvider);
    final currency = ref.watch(currencySymbolProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Budgets'),
        actions: [
          IconButton(
            tooltip: 'Guided budget setup',
            icon: const Icon(Icons.assistant_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const GuidedBudgetScreen(),
              ),
            ),
          ),
        ],
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
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, fontSize: 18),
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
          return ListView.builder(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            itemCount: views.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return _buildZeroBasedSummary(views, accountsAsync, currency);
              }
              final view = views[index - 1];
              final progress = view.progress;
              
              List<Color> gradientColors;
              if (progress >= 1.0) {
                gradientColors = [Theme.of(context).colorScheme.error, Theme.of(context).colorScheme.errorContainer]; // Red for over budget
              } else if (progress >= 0.8) {
                gradientColors = [Theme.of(context).colorScheme.secondary, Theme.of(context).colorScheme.secondaryContainer]; // Yellow-ish for approaching
              } else {
                gradientColors = [Theme.of(context).colorScheme.secondary, Theme.of(context).colorScheme.secondaryContainer]; // Green-ish for under budget mapped to secondary
              }
              
              return AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    elevation: progress >= 1.0 ? _pulseAnimation.value : 1, // Animate elevation for over budget
                      shadowColor: progress >= 1.0 ? Theme.of(context).colorScheme.error : null, // Set shadow color
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppConstants.cardRadius),
                      side: progress >= 1.0
                        ? BorderSide(color: Theme.of(context).colorScheme.error, width: _pulseAnimation.value / 2 + 1) // Pulsating border
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
                              child: Icon(getIconFromCodePoint(view.category.iconCodePoint), color: Color(view.category.color), size: 16),
                            ),
                            const SizedBox(width: 12),
                            Expanded(child: Text(view.category.name, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold))),
                            if (view.budgetAmount > 0)
                              Text(
                                '${Formatters.formatCurrency(view.spentAmount, symbol: currency)} / ${Formatters.formatCurrency(view.budgetAmount, symbol: currency)}',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: progress >= 1.0 ? Theme.of(context).colorScheme.error : Theme.of(context).colorScheme.onSurface.withAlpha((0.65 * 255).round()),
                                      fontWeight: FontWeight.bold,
                                    ),
                              )
                            else
                              Text(
                                Formatters.formatCurrency(view.spentAmount, symbol: currency),
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurface.withAlpha((0.65 * 255).round())),
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
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.error, fontSize: 12),
                                )
                              else
                                Text(
                                  '${Formatters.formatCurrency(view.remaining, symbol: currency)} left',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurface.withAlpha((0.6 * 255).round()), fontSize: 12),
                                ),
                              // Previous month comparison
                              if (view.previousMonthSpentAmount != null) ...[
                                const SizedBox(height: AppConstants.smallPadding),
                                Row(
                                  children: [
                                    Text('Prev Month: ', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurface.withAlpha((0.65 * 255).round()), fontSize: 12)),
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
                                  foregroundColor: Theme.of(context).colorScheme.primary,
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

  Widget _buildZeroBasedSummary(
    List<BudgetView> views,
    AsyncValue<List<Account>> accountsAsync,
    String currency,
  ) {
    return accountsAsync.when(
      data: (accounts) {
        final available = accounts
            .where((account) =>
                account.type == AccountType.checking ||
                account.type == AccountType.savings ||
                account.type == AccountType.cash,)
            .fold<double>(0, (sum, account) => sum + account.currentBalance);
        final assigned = views.fold<double>(0, (sum, view) {
          final hasSubcategories = views.any(
            (child) => child.category.parentId == view.category.id,
          );
          return sum + (hasSubcategories ? 0 : view.budgetAmount);
        });
        final remaining = available - assigned;
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Zero-based plan - available cash includes carryover',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 6),
                Text(
                  'Available: ${Formatters.formatCurrency(available, symbol: currency)}',
                ),
                Text(
                  'Allocated: ${Formatters.formatCurrency(assigned, symbol: currency)}',
                ),
                Text(
                  remaining >= 0
                      ? 'Unallocated: ${Formatters.formatCurrency(remaining, symbol: currency)}'
                      : 'Over-allocated: ${Formatters.formatCurrency(remaining.abs(), symbol: currency)}',
                  style: TextStyle(
                    color: remaining < 0
                        ? Theme.of(context).colorScheme.error
                        : null,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (views.isEmpty) const Text('No expense categories found.'),
              ],
            ),
          ),
        );
      },
      loading: () => const LinearProgressIndicator(),
      error: (error, _) => Text('Could not calculate available cash: $error'),
    );
  }

  Widget _buildTrendIndicator(double current, double previous) {
    if (current > previous) {
      return Icon(Icons.arrow_upward, size: 16, color: Theme.of(context).colorScheme.error);
    } else if (current < previous) {
      return Icon(Icons.arrow_downward, size: 16, color: Theme.of(context).colorScheme.secondary);
    } else {
      return Icon(Icons.trending_flat, size: 16, color: Theme.of(context).colorScheme.onSurface.withAlpha((0.6 * 255).round()));
    }
  }
}