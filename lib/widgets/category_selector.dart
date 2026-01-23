import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/category.dart';
import '../models/enums.dart';
import '../providers/category_provider.dart';
import '../utils/constants.dart';

class CategorySelector extends ConsumerStatefulWidget {

  const CategorySelector({
    super.key,
    required this.transactionType,
    this.selectedCategory,
    required this.onCategorySelected,
  });
  final TransactionType transactionType;
  final Category? selectedCategory;
  final ValueChanged<Category?> onCategorySelected;

  @override
  ConsumerState<CategorySelector> createState() => _CategorySelectorState();
}

class _CategorySelectorState extends ConsumerState<CategorySelector> {
  Widget _buildCategoryItem(BuildContext context, Category category, bool isSelected) {
    return Semantics(
      label: '${category.name} category, ${isSelected ? 'selected' : 'not selected'}',
      selected: isSelected,
      button: true,
      child: GestureDetector(
        onTap: () => widget.onCategorySelected(category),
        child: Column(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: Color(category.color),
              child: Icon(
                IconData(category.iconCodePoint, fontFamily: 'MaterialIcons'),
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              category.name,
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final frequentCategoriesAsync = ref.watch(frequentCategoriesProvider(widget.transactionType));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Frequent Categories Section
        frequentCategoriesAsync.when(
          data: (frequentCategories) {
            if (frequentCategories.isEmpty) {
              return const SizedBox.shrink();
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Frequent Categories', style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: AppConstants.smallPadding),
                SizedBox(
                  height: 100, // Fixed height for horizontal list
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: frequentCategories.length,
                    separatorBuilder: (context, index) => const SizedBox(width: AppConstants.smallPadding),
                    itemBuilder: (context, index) {
                      final category = frequentCategories[index];
                      final isSelected = category.id == widget.selectedCategory?.id;
                      return _buildCategoryItem(context, category, isSelected);
                    },
                  ),
                ),
                const SizedBox(height: AppConstants.defaultPadding),
              ],
            );
          },
          loading: () => const LinearProgressIndicator(),
          error: (err, stack) => Text('Error loading frequent categories: $err'),
        ),

        // All Categories Section
        Text('All Categories', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: AppConstants.smallPadding),
        categoriesAsync.when(
          data: (categories) {
            final filteredCategories = categories
                .where((cat) => cat.type == widget.transactionType)
                .toList();

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                childAspectRatio: 1,
                mainAxisSpacing: AppConstants.smallPadding,
                crossAxisSpacing: AppConstants.smallPadding,
              ),
              itemCount: filteredCategories.length,
              itemBuilder: (context, index) {
                final category = filteredCategories[index];
                final isSelected = category.id == widget.selectedCategory?.id;
                return _buildCategoryItem(context, category, isSelected);
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Error: $err')),
        ),
      ],
    );
  }
}
