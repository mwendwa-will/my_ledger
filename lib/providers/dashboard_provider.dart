import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/transaction_item.dart';
import '../services/database_service.dart';

class DashboardData {
  final double income;
  final double expense;
  final List<TransactionItem> recentTransactions;

  DashboardData({
    required this.income,
    required this.expense,
    required this.recentTransactions,
  });
}

final dashboardProvider = FutureProvider.autoDispose<DashboardData>((ref) async {
  final now = DateTime.now();
  final summary = await DatabaseService.instance.getMonthlySummary(now.month, now.year);
  final transactions = await DatabaseService.instance.getTransactions(limit: 5);
  
  return DashboardData(
    income: summary['income'] ?? 0.0,
    expense: summary['expense'] ?? 0.0,
    recentTransactions: transactions,
  );
});
