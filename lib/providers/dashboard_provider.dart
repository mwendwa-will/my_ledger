import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/transaction_item.dart';
import '../models/budget.dart';
import '../services/database_service.dart';

class DashboardData {

  DashboardData({
    required this.income,
    required this.expense,
    required this.previousMonthIncome,
    required this.previousMonthExpense,
    required this.recentTransactions,
    required this.budgets,
    required this.categorySpending,
  });
  final double income;
  final double expense;
  final double previousMonthIncome; // New
  final double previousMonthExpense; // New
  final List<TransactionItem> recentTransactions;
  final List<Budget> budgets;
  final Map<int, double> categorySpending;
}

final dashboardProvider = FutureProvider.autoDispose<DashboardData>((ref) async {
  final now = DateTime.now();
  final summary = await DatabaseService.instance.getMonthlySummary(now.month, now.year);
  
  // Calculate previous month
  final previousMonthDate = DateTime(now.year, now.month - 1, 1);
  final previousMonthSummary = await DatabaseService.instance.getMonthlySummary(previousMonthDate.month, previousMonthDate.year);

  final transactions = await DatabaseService.instance.getTransactions(limit: 5);
  final budgets = await DatabaseService.instance.getBudgetsForMonth(now.month, now.year);
  final categorySpending = await DatabaseService.instance.getCategorySpending(now.month, now.year);
  
  return DashboardData(
    income: summary['income'] ?? 0.0,
    expense: summary['expense'] ?? 0.0,
    previousMonthIncome: previousMonthSummary['income'] ?? 0.0,
    previousMonthExpense: previousMonthSummary['expense'] ?? 0.0,
    recentTransactions: transactions,
    budgets: budgets,
    categorySpending: categorySpending,
  );
});
