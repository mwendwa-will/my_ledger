import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/database_service.dart';
import '../models/category.dart';
import 'category_provider.dart';

class ExpenseBreakdown {
  final Category category;
  final double amount;
  final double percentage;
  
  ExpenseBreakdown(this.category, this.amount, this.percentage);
}

final reportMonthProvider = StateProvider<DateTime>((ref) => DateTime.now());

final expensePieChartProvider = FutureProvider.autoDispose<List<ExpenseBreakdown>>((ref) async {
  final date = ref.watch(reportMonthProvider);
  final categoryAsync = ref.watch(categoryMapProvider);
  final categoryMap = categoryAsync.value ?? {};

  final spending = await DatabaseService.instance.getCategorySpending(date.month, date.year);
  final total = spending.values.fold(0.0, (sum, val) => sum + val);

  if (total == 0) return [];

  List<ExpenseBreakdown> list = [];
  spending.forEach((catId, amount) {
    if (categoryMap.containsKey(catId)) {
      list.add(ExpenseBreakdown(categoryMap[catId]!, amount, (amount / total) * 100));
    }
  });

  list.sort((a, b) => b.amount.compareTo(a.amount));
  return list;
});

class MonthlyTrend {
  final DateTime date;
  final double income;
  final double expense;
  
  MonthlyTrend(this.date, this.income, this.expense);
}

final trendChartProvider = FutureProvider.autoDispose<List<MonthlyTrend>>((ref) async {
  final now = DateTime.now();
  List<MonthlyTrend> trends = [];
  
  for (int i = 5; i >= 0; i--) {
    final date = DateTime(now.year, now.month - i, 1);
    final summary = await DatabaseService.instance.getMonthlySummary(date.month, date.year);
    trends.add(MonthlyTrend(date, summary['income'] ?? 0, summary['expense'] ?? 0));
  }
  
  return trends;
});
