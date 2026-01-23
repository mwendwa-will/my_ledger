import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/category.dart';
import '../services/database_service.dart';

final categoriesProvider = AsyncNotifierProvider<CategoriesNotifier, List<Category>>(() {
  return CategoriesNotifier();
});

class CategoriesNotifier extends AsyncNotifier<List<Category>> {
  @override
  Future<List<Category>> build() async {
    return await DatabaseService.instance.getAllCategories();
  }

  Future<void> addCategory(Category category) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await DatabaseService.instance.createCategory(category);
      return await DatabaseService.instance.getAllCategories();
    });
  }
}

final categoryMapProvider = Provider<AsyncValue<Map<int, Category>>>((ref) {
  final categoriesAsync = ref.watch(categoriesProvider);
  return categoriesAsync.whenData((categories) {
    return {for (var c in categories) c.id!: c};
  });
});