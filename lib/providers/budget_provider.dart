import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/budget.dart';
import '../models/category.dart';
import '../models/enums.dart';
import '../services/database_service.dart';
import 'category_provider.dart';

class BudgetView {
  final Category category;
  final double budgetAmount; // 0 if no budget set
  final double spentAmount;
  
  BudgetView({
    required this.category,
    required this.budgetAmount,
    required this.spentAmount,
  });
  
  double get progress => budgetAmount > 0 ? spentAmount / budgetAmount : (spentAmount > 0 ? 1.0 : 0.0);
  double get remaining => budgetAmount - spentAmount;
}

final budgetMonthProvider = StateProvider<DateTime>((ref) => DateTime.now());

final budgetsViewProvider = FutureProvider.autoDispose<List<BudgetView>>((ref) async {
  final date = ref.watch(budgetMonthProvider);
  final categories = await ref.watch(categoriesProvider.future);
  final expenseCategories = categories.where((c) => c.type == TransactionType.expense).toList();
  
  final budgets = await DatabaseService.instance.getBudgetsForMonth(date.month, date.year);
  final spending = await DatabaseService.instance.getCategorySpending(date.month, date.year);
  
  List<BudgetView> views = [];
  
  for (var cat in expenseCategories) {
    final budget = budgets.firstWhere(
      (b) => b.categoryId == cat.id, 
      orElse: () => Budget(categoryId: cat.id!, amount: 0, month: date.month, year: date.year)
    );
    
    final spent = spending[cat.id] ?? 0.0;
    
    views.add(BudgetView(
      category: cat,
      budgetAmount: budget.amount,
      spentAmount: spent,
    ));
  }
  
  // Sort by highest spent or highest budget
  views.sort((a, b) => b.spentAmount.compareTo(a.spentAmount));
  
  return views;
});

class BudgetNotifier {
  static Future<void> setBudget(WidgetRef ref, Budget budget) async {
    await DatabaseService.instance.setBudget(budget);
    ref.invalidate(budgetsViewProvider);
  }
}