import 'package:fl_chart/fl_chart.dart'; // Import fl_chart
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/account.dart'; // Import Account model
import '../../models/category.dart'; // Import Category model
import '../../models/enums.dart';
import '../../providers/account_provider.dart';
import '../../providers/category_provider.dart'; // Import category provider
import '../../providers/dashboard_provider.dart';
import '../../providers/settings_provider.dart';
import '../../utils/constants.dart';
import '../../utils/currency_helper.dart'; // Import
import '../../utils/formatters.dart';
import '../settings/settings_screen.dart';
import '../../utils/icon_helper.dart'; // Import icon helper

/// The main dashboard screen of the application.
/// 
/// This screen displays the user's financial overview and uses 
/// [ConsumerStatefulWidget] to listen to provider updates.
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int touchedIndex = -1; // State to track touched pie chart section

  @override
  Widget build(BuildContext context) {
    final dashboardAsync = ref.watch(dashboardProvider);
    final totalBalance = ref.watch(totalBalanceProvider);
    final currencyCode = ref.watch(currencyCodeProvider); // Watch code instead of symbol

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
            },
            tooltip: 'Open settings',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref..invalidate(dashboardProvider)
          ..invalidate(accountsProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Net Worth Card
              _buildNetWorthCard(context, totalBalance, currencyCode),
              const SizedBox(height: 16),

              // Summary Cards
              dashboardAsync.when(
                data: (data) => _buildSummaryCards(context, data, currencyCode),
                loading: () => const SizedBox.shrink(),
                error: (err, stack) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 16),

              // Spending by Category Chart
              dashboardAsync.when(
                data: (data) => _buildSpendingByCategoryChart(context, ref, data),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Text('Error: $err'),
              ),
              const SizedBox(height: 24),

              // Budget Categories
              dashboardAsync.when(
                data: (data) => _buildBudgetCategories(context, ref, data, currencyCode),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Text('Error: $err'),
              ),
              const SizedBox(height: 24),
              
              // Recent Transactions Header
              Text(
                'Recent Transactions',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              
              // Recent Transactions List
              dashboardAsync.when(
                data: (data) => _buildRecentTransactions(
                  context,
                  data,
                  currencyCode,
                  ref.watch(categoryMapProvider),
                  ref.watch(accountsProvider),
                ),
                loading: () => const SizedBox.shrink(), // Already showing loader above
                error: (_, __) => const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNetWorthCard(BuildContext context, double balance, String currencyCode) {
    return Card(
      color: Theme.of(context).colorScheme.primary,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Total Balance',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              CurrencyHelper.format(balance, currencyCode: currencyCode),
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                color: Theme.of(context).colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 32,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards(BuildContext context, DashboardData data, String currencyCode) {
    return Row(
      children: [
        Expanded(
          child: _buildInfoCard(
            context,
            'Income',
            data.income,
            Theme.of(context).colorScheme.secondary,
            Icons.arrow_downward,
            currencyCode,
            previousAmount: data.previousMonthIncome,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildInfoCard(
            context,
            'Expense',
            data.expense,
            Theme.of(context).colorScheme.error,
            Icons.arrow_upward,
            currencyCode,
            previousAmount: data.previousMonthExpense,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(
    BuildContext context, 
    String title, 
    double amount, 
    Color color, 
    IconData icon, 
    String currencyCode,
    {double? previousAmount,} // New optional parameter
  ) {
    IconData trendIcon = Icons.trending_flat;
    Color trendColor = Theme.of(context).colorScheme.onSurface.withAlpha((0.6 * 255).round());

    if (previousAmount != null) {
      if (amount > previousAmount) {
        trendIcon = Icons.arrow_upward;
        trendColor = (title == 'Income') ? Theme.of(context).colorScheme.secondary : Theme.of(context).colorScheme.error;
      } else if (amount < previousAmount) {
        trendIcon = Icons.arrow_downward;
        trendColor = (title == 'Income') ? Theme.of(context).colorScheme.error : Theme.of(context).colorScheme.secondary;
      }
      // If amount == previousAmount, default Icons.trending_flat and grey is fine
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
        border: Border.all(color: Theme.of(context).dividerColor.withAlpha(51)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 4),
              Text(
                title,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Theme.of(context).colorScheme.onSurface.withAlpha((0.65 * 255).round()), fontSize: 12),
              ),
              if (previousAmount != null) ...[
                const SizedBox(width: 4),
                Icon(trendIcon, color: trendColor, size: 16),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Text(
            CurrencyHelper.format(amount, currencyCode: currencyCode),
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpendingByCategoryChart(BuildContext context, WidgetRef ref, DashboardData data) {
    final categoryMapAsync = ref.watch(categoryMapProvider);
    final currencySymbol = ref.watch(currencyCodeProvider.notifier).currentCurrencySymbol;

    return categoryMapAsync.when(
      data: (categoryMap) {
        final expenseSpending = data.categorySpending.entries
            .where((entry) => categoryMap[entry.key]?.type == TransactionType.expense)
            .toList();

        if (expenseSpending.isEmpty) {
          return const SizedBox.shrink();
        }

        final double totalExpense = expenseSpending.fold(0, (sum, entry) => sum + entry.value);

        final sections = expenseSpending.asMap().entries.map((entry) {
          final index = entry.key;
          final expenseEntry = entry.value;
          final category = categoryMap[expenseEntry.key];
          if (category == null) {
            return null;
          }

          final isTouched = index == touchedIndex;
          final double fontSize = isTouched ? 18 : 14;
          final double radius = isTouched ? 60 : 50;
          final String sectionLabel = '${category.name}, ${Formatters.formatCurrency(expenseEntry.value, symbol: currencySymbol)}, ${(expenseEntry.value / totalExpense * 100).toStringAsFixed(1)} percent';

          return PieChartSectionData(
            color: Color(category.color),
            value: expenseEntry.value,
            title: isTouched ? Formatters.formatCurrency(expenseEntry.value, symbol: currencySymbol) : '${(expenseEntry.value / totalExpense * 100).toStringAsFixed(1)}%',
            radius: radius,
                titleStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
            badgeWidget: isTouched
                ? Semantics(
                    label: sectionLabel, // Semantic label for the touched section's badge
                    child: Icon(
                                getIconFromCodePoint(category.iconCodePoint),
                      color: Theme.of(context).colorScheme.onPrimary,
                      size: 25,
                    ),
                  )
                : null,
            badgePositionPercentageOffset: 1,
          );
        }).whereType<PieChartSectionData>().toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                'Spending by Category',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            const SizedBox(height: 16),
            Semantics(
              label: 'Monthly spending by category chart', // Overall chart label
              child: SizedBox(
                height: 200,
                child: PieChart(
                  PieChartData(
                    sections: sections,
                    borderData: FlBorderData(show: false),
                    sectionsSpace: 2,
                    centerSpaceRadius: 40,
                    pieTouchData: PieTouchData(
                      touchCallback: (FlTouchEvent event, pieTouchResponse) {
                        setState(() {
                          if (!event.isInterestedForInteractions ||
                              pieTouchResponse == null ||
                              pieTouchResponse.touchedSection == null) {
                            touchedIndex = -1;
 SemanticsService.sendAnnouncement(
    View.of(context),
    'Chart selection cleared',
    TextDirection.ltr,
    assertiveness: Assertiveness.polite,
  );                            return;
                          }
                          touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                          final touchedSection = pieTouchResponse.touchedSection!.touchedSection;
                          if (touchedSection != null) {
                            final category = categoryMap[expenseSpending[touchedIndex].key];
                            if (category != null) {
                             SemanticsService.sendAnnouncement(
  View.of(context),
  '${category.name} selected, ${Formatters.formatCurrency(touchedSection.value, symbol: currencySymbol)}, ${(touchedSection.value / totalExpense * 100).toStringAsFixed(1)} percent',
  TextDirection.ltr,
);
                            }
                          }
                        });
                      },
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Legend
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: expenseSpending.asMap().entries.map((entry) {
                final index = entry.key;
                final expenseEntry = entry.value;
                final category = categoryMap[expenseEntry.key];
                if (category == null) {
                  return const SizedBox.shrink();
                }
                
                final String legendLabel = '${category.name}, ${Formatters.formatCurrency(expenseEntry.value, symbol: currencySymbol)}, ${(expenseEntry.value / totalExpense * 100).toStringAsFixed(1)} percent';

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      touchedIndex = index;
                    });
SemanticsService.sendAnnouncement(
  View.of(context),
  '$legendLabel selected',
  TextDirection.ltr,
);                  },
                  child: Semantics(
                    label: legendLabel, // Semantic label for legend item
                    selected: index == touchedIndex,
                    button: true,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: index == touchedIndex ? Theme.of(context).colorScheme.primary.withAlpha((0.1 * 255).round()) : Colors.transparent,
                        borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(category.color),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${category.name} (${Formatters.formatCurrency(expenseEntry.value, symbol: currencySymbol)})',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: index == touchedIndex ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Text('Error: $err'),
    );
  }
  Widget _buildBudgetCategories(BuildContext context, WidgetRef ref, DashboardData data, String currencyCode) {
    final categoryMapAsync = ref.watch(categoryMapProvider);

    return categoryMapAsync.when(
      data: (categoryMap) {
        final expenseBudgets = data.budgets.where((b) => b.amount > 0 && categoryMap[b.categoryId]?.type == TransactionType.expense).toList();

        if (expenseBudgets.isEmpty) {
          return const SizedBox.shrink(); // Or a message "No budgets set up"
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Budget Categories',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: AppConstants.defaultPadding,
                mainAxisSpacing: AppConstants.defaultPadding,
                childAspectRatio: 1.5,
              ),
              itemCount: expenseBudgets.length,
              itemBuilder: (context, index) {
                final budget = expenseBudgets[index];
                final category = categoryMap[budget.categoryId];
                if (category == null) {
                  return const SizedBox.shrink();
                }

                final spent = budget.spent ?? 0.0;
                final remaining = budget.amount - spent;
                final percentage = spent / budget.amount;
                final progressColor = percentage > 1.0
                  ? Theme.of(context).colorScheme.error
                  : Theme.of(context).colorScheme.primary;

                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppConstants.smallPadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: Color(category.color),
                              child: Icon(
                                  getIconFromCodePoint(category.iconCodePoint),
                                  color: Colors.white,
                                  size: 16,
                                ),
                            ),
                            const SizedBox(width: AppConstants.smallPadding),
                            Expanded(
                              child: Text(
                                category.name,
                                style: Theme.of(context).textTheme.titleSmall,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppConstants.smallPadding),
                        Expanded(
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              CircularProgressIndicator(
                                value: percentage.clamp(0.0, 1.0),
                                backgroundColor: Colors.grey.shade300,
                                valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                                strokeWidth: 8,
                              ),
                              Text(
                                '${(percentage * 100).toStringAsFixed(0)}%',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppConstants.smallPadding),
                        Text(
                          '${CurrencyHelper.format(remaining, currencyCode: currencyCode)} left',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: remaining < 0 ? Theme.of(context).colorScheme.error : Theme.of(context).colorScheme.secondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Text('Error: $err'),
    );
  }

  Widget _buildRecentTransactions(
    BuildContext context, 
    DashboardData data, 
    String currencyCode,
    AsyncValue<Map<int, Category>> categoryMapAsync,
    AsyncValue<List<Account>> accountsAsync,
  ) {
    if (data.recentTransactions.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        alignment: Alignment.center,
        child: Text('No transactions yet. Tap + to add one!', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: data.recentTransactions.length,
      itemBuilder: (context, index) {
        final tx = data.recentTransactions[index];
        final isExpense = tx.type == TransactionType.expense;
        final color = isExpense
          ? Theme.of(context).colorScheme.error
          : (tx.type == TransactionType.income
            ? Theme.of(context).colorScheme.secondary
            : Theme.of(context).colorScheme.tertiary);
        
        final accountsMap = accountsAsync.value?.fold<Map<int, Account>>({}, (map, account) {
          if (account.id != null) {
            map[account.id!] = account;
          }
          return map;
        }) ?? {};

        final String transactionLabel = 
          '${tx.type.name} transaction of ${CurrencyHelper.format(tx.amount, currencyCode: currencyCode)}. '
          'Category: ${categoryMapAsync.value?[tx.categoryId]?.name ?? 'Uncategorized'}. '
          'Account: ${accountsMap[tx.accountId]?.name ?? 'Unknown'}. '
          'Date: ${Formatters.formatShortDate(tx.date)}. '
          '${tx.note?.isNotEmpty == true ? 'Note: ${tx.note!}.' : ''}';

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: Semantics(
            label: transactionLabel,
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: color.withAlpha(26),
                child: Icon(
                  _getIconForType(tx.type),
                  color: color,
                  size: 20,
                ),
              ),
              title: Text(tx.note?.isNotEmpty == true ? tx.note! : 'Transaction'),
              subtitle: Text(Formatters.formatShortDate(tx.date)),
              trailing: Text(
                '${isExpense ? "-" : "+"}${CurrencyHelper.format(tx.amount, currencyCode: currencyCode)}',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  IconData _getIconForType(TransactionType type) {
    switch (type) {
      case TransactionType.income: return Icons.arrow_downward;
      case TransactionType.expense: return Icons.arrow_upward;
      case TransactionType.transfer: return Icons.swap_horiz;
    }
  }
}
