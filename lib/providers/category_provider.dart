import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/category.dart';
import '../models/enums.dart';
import '../services/database_service.dart';

class CategoriesNotifier extends AsyncNotifier<List<Category>> {
  @override
  Future<List<Category>> build() async {
    return DatabaseService.instance.getAllCategories();
  }

  Future<void> addCategory(Category category) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await DatabaseService.instance.createCategory(category);
      return DatabaseService.instance.getAllCategories();
    });
  }

  Future<void> updateCategory(Category category) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await DatabaseService.instance.updateCategory(category);
      return DatabaseService.instance.getAllCategories();
    });
  }

  Future<void> deleteCategory(int categoryId, {int? reassignToCategoryId}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final transactionCount = await DatabaseService.instance.countTransactionsForCategory(categoryId);
      if (transactionCount > 0 && reassignToCategoryId == null) {
        // If there are transactions and no reassignment category is provided,
        // throw an exception to let the UI handle the options (reassign/uncategorize/archive)
        throw Exception('Category has $transactionCount associated transactions. Cannot delete without reassigning or uncategorizing.');
      }
      
      await DatabaseService.instance.deleteCategory(categoryId, reassignToCategoryId: reassignToCategoryId);
      return DatabaseService.instance.getAllCategories();
    });
  }

  Future<void> updateCategoryOrder(List<Category> categories) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await DatabaseService.instance.updateCategoryOrder(categories);
      // No need to fetch all categories again, just update the state with the new order
      return categories; 
    });
  }
}

final categoriesProvider = AsyncNotifierProvider<CategoriesNotifier, List<Category>>(() {
  return CategoriesNotifier();
});

final categoryMapProvider = Provider<AsyncValue<Map<int, Category>>>((ref) {
  final categoriesAsync = ref.watch(categoriesProvider);
  return categoriesAsync.whenData((categories) {
    return {for (final c in categories.where((c) => c.id != null)) c.id!: c};
  });
});

// Frequent / common categories helper - small list for quick selection
final frequentCategoriesProvider = FutureProvider.family<List<Category>, TransactionType>((ref, type) async {
  final all = await ref.watch(categoriesProvider.future);
  return all.where((c) => c.type == type).take(6).toList();
});