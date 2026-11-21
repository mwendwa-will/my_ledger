import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../services/database_service.dart';
import '../models/account.dart';
import '../models/category.dart';
import 'account_provider.dart';
import 'category_provider.dart';

class ExpenseBreakdown {
  
  ExpenseBreakdown(this.category, this.amount, this.percentage);
  final Category category;
  final double amount;
  final double percentage;
}

final reportMonthProvider = StateProvider<DateTime>((ref) => DateTime.now());
final reportYearProvider = StateProvider<int>((ref) => DateTime.now().year);

final annualSummaryProvider =
    FutureProvider.autoDispose<Map<String, double>>((ref) {
  final year = ref.watch(reportYearProvider);
  return DatabaseService.instance.getAnnualSummary(year);
});

class AnnualAccountActivity {
  const AnnualAccountActivity(this.account, this.netActivity);
  final Account account;
  final double netActivity;
}

final annualAccountActivityProvider =
    FutureProvider.autoDispose<List<AnnualAccountActivity>>((ref) async {
  final year = ref.watch(reportYearProvider);
  final accounts = await ref.watch(accountsProvider.future);
  final activity =
      await DatabaseService.instance.getAnnualAccountActivity(year);
  return accounts
      .where((account) => activity.containsKey(account.id))
      .map((account) => AnnualAccountActivity(
            account,
            activity[account.id] ?? 0,
          ),)
      .toList();
});

class AnnualExpenseBreakdown {
  const AnnualExpenseBreakdown(this.category, this.amount, this.parentName);
  final Category category;
  final double amount;
  final String? parentName;
}

final annualExpenseBreakdownProvider =
    FutureProvider.autoDispose<List<AnnualExpenseBreakdown>>((ref) async {
  final year = ref.watch(reportYearProvider);
  final allCategories = await ref.watch(categoriesProvider.future);
  final categories = {
    for (final category in allCategories)
      if (category.id != null) category.id!: category,
  };
  final spending =
      await DatabaseService.instance.getAnnualCategorySpending(year);
  return spending.entries
      .where((entry) => categories.containsKey(entry.key))
      .map((entry) {
        final category = categories[entry.key]!;
        return AnnualExpenseBreakdown(
          category,
          entry.value,
          categories[category.parentId]?.name,
        );
      })
      .toList()
    ..sort((a, b) => b.amount.compareTo(a.amount));
});

final expensePieChartProvider = FutureProvider.autoDispose<List<ExpenseBreakdown>>((ref) async {
  final date = ref.watch(reportMonthProvider);
  final categoryAsync = ref.watch(categoryMapProvider);
  final categoryMap = categoryAsync.value ?? {};

  final spending = await DatabaseService.instance.getCategorySpending(date.month, date.year);
  final total = spending.values.fold(0.0, (sum, val) => sum + val);

  if (total == 0) return [];

  final List<ExpenseBreakdown> list = [];
  spending.forEach((catId, amount) {
    if (categoryMap.containsKey(catId)) {
      list.add(ExpenseBreakdown(categoryMap[catId]!, amount, (amount / total) * 100));
    }
  });

  list.sort((a, b) => b.amount.compareTo(a.amount));
  return list;
});

class MonthlyTrend {
  
  MonthlyTrend(this.date, this.income, this.expense);
  final DateTime date;
  final double income;
  final double expense;
}

final trendChartProvider = FutureProvider.autoDispose<List<MonthlyTrend>>((ref) async {
  final now = DateTime.now();
  final List<MonthlyTrend> trends = [];
  
  for (int i = 5; i >= 0; i--) {
    final date = DateTime(now.year, now.month - i, 1);
    final summary = await DatabaseService.instance.getMonthlySummary(date.month, date.year);
    trends.add(MonthlyTrend(date, summary['income'] ?? 0, summary['expense'] ?? 0));
  }
  
  return trends;
});
