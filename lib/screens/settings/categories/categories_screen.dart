import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/category.dart';
import '../../../providers/category_provider.dart';
import 'category_form_modal.dart';
import '../../../services/database_service.dart';
import '../../../utils/constants.dart';
import '../../../utils/icon_helper.dart';

class CategoriesScreen extends ConsumerStatefulWidget {
  const CategoriesScreen({super.key});

  @override
  ConsumerState<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends ConsumerState<CategoriesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _showArchived = false;
  List<Category> _currentCategories = []; // Local state for reordering

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _showCategoryForm(BuildContext context, WidgetRef ref, {Category? category}) async {
    final allCategories = await ref.read(categoriesProvider.future);
    if (!context.mounted) return;
    final existingCategoryNames = allCategories
        .where((cat) => cat.id != category?.id) // Exclude current category name if editing
        .map((cat) => cat.name.toLowerCase())
        .toList();

    final newCategory = await showModalBottomSheet<Category>(
      context: context,
      isScrollControlled: true,
      builder: (context) => CategoryFormModal(
        category: category,
        existingCategoryNames: existingCategoryNames,
      ),
    );

    if (newCategory != null) {
      if (category == null) {
        // Add new category
        await ref.read(categoriesProvider.notifier).addCategory(newCategory);
      } else {
        // Update existing category
        await ref.read(categoriesProvider.notifier).updateCategory(newCategory.copyWith(id: category.id));
      }
    }
  }

  Future<void> _showDeleteCategoryOptions(BuildContext context, WidgetRef ref, Category category, int transactionCount) async {
    final allCategories = await ref.read(categoriesProvider.future);
    if (!context.mounted) return;
    final otherCategories = allCategories.where((cat) => cat.id != category.id).toList();

    int? selectedReassignCategoryId;

    await showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (BuildContext modalContext, StateSetter setModalState) {
            return Container(
              padding: const EdgeInsets.all(AppConstants.defaultPadding),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'This category has $transactionCount transactions.',
                    style: Theme.of(modalContext).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppConstants.smallPadding),
                  const Text('What do you want to do with these transactions?'),
                  const SizedBox(height: AppConstants.defaultPadding),
                  if (otherCategories.isNotEmpty)
                    DropdownButtonFormField<int>(
                      initialValue: selectedReassignCategoryId,
                      decoration: const InputDecoration(
                        labelText: 'Move transactions to...',
                        border: OutlineInputBorder(),
                      ),
                      items: otherCategories
                          .map((cat) => DropdownMenuItem(
                                value: cat.id,
                                child: Text(cat.name),
                              ),)
                          .toList(),
                      onChanged: (value) {
                        setModalState(() {
                          selectedReassignCategoryId = value;
                        });
                      },
                    ),
                  const SizedBox(height: AppConstants.smallPadding),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () async {
                        Navigator.pop(ctx); // Close bottom sheet
                        if (selectedReassignCategoryId != null) {
                          await ref.read(categoriesProvider.notifier).deleteCategory(
                            category.id!,
                            reassignToCategoryId: selectedReassignCategoryId,
                          );
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('${category.name} deleted, transactions moved.')),
                          );
                        } else {
                          // This case should ideally not be reached if reassign category is mandatory
                          // For now, let's just show an error or cancel
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please select a category to reassign transactions.')),
                          );
                        }
                      },
                      child: const Text('Move & Delete Category'),
                    ),
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () async {
                        Navigator.pop(ctx);
                        await ref.read(categoriesProvider.notifier).archiveCategory(category.id!);
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('${category.name} archived.')),
                        );
                      },
                      child: const Text('Archive Category'),
                    ),
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () async {
                        Navigator.pop(ctx); // Close bottom sheet
                        await ref.read(categoriesProvider.notifier).deleteCategory(category.id!);
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('${category.name} deleted, transactions uncategorized.')),
                        );
                      },
                      child: const Text('Delete & Uncategorize Transactions'),
                    ),
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories'),
        actions: [
          IconButton(
            icon: Icon(_showArchived ? Icons.unarchive : Icons.archive_outlined),
            tooltip: _showArchived ? 'Show active' : 'Show archived',
            onPressed: () async {
              final all = await ref.read(categoriesProvider.future);
              setState(() {
                _showArchived = !_showArchived;
                _currentCategories = all.where((c) => c.isArchived == _showArchived).toList();
              });
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.smallPadding),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search categories...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                border: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(25)),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
        ),
      ),
      body: categoriesAsync.when(
        data: (categories) {
          // Initialize _currentCategories only once or when categories change significantly
          if (_currentCategories.isEmpty || categories.length != _currentCategories.length) {
            _currentCategories = List.from(categories.where((c) => c.isArchived == _showArchived));
          }

          final filteredCategories = _currentCategories.where((cat) {
            return cat.name.toLowerCase().contains(_searchQuery.toLowerCase());
          }).toList();

          return ReorderableListView.builder(
            padding: const EdgeInsets.symmetric(vertical: AppConstants.defaultPadding),
            itemCount: filteredCategories.length,
            itemBuilder: (context, index) {
              final category = filteredCategories[index];
              return _buildCategoryListTile(context, ref, category, index);
            },
            onReorder: (int oldIndex, int newIndex) {
              setState(() {
                if (oldIndex < newIndex) {
                  newIndex -= 1;
                }
                final item = _currentCategories.removeAt(oldIndex);
                _currentCategories.insert(newIndex, item);
                
                // Update sortOrder for all affected categories locally
                for (var i = 0; i < _currentCategories.length; i++) {
                  _currentCategories[i] = _currentCategories[i].copyWith(sortOrder: i);
                }
              });
              // Persist the new order to the database
              ref.read(categoriesProvider.notifier).updateCategoryOrder(_currentCategories);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCategoryForm(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCategoryListTile(BuildContext context, WidgetRef ref, Category category, int index) {
    return ReorderableDelayedDragStartListener(
      key: ValueKey(category.id!), // Use category ID as unique key for ReorderableListView
      index: index,
      child: Dismissible(
        key: ValueKey('dismissible-${category.id!}'), // Unique key for Dismissible
        direction: DismissDirection.endToStart,
        background: Container(
          color: Theme.of(context).colorScheme.error,
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Icon(Icons.delete, color: Theme.of(context).colorScheme.onError),
        ),
        confirmDismiss: (direction) async {
          final transactionCount = await DatabaseService.instance.countTransactionsForCategory(category.id!);
          if (!context.mounted) return false;
          if (transactionCount > 0) {
            await _showDeleteCategoryOptions(context, ref, category, transactionCount);
            return false; // Prevent immediate dismiss, let modal handle deletion
          } else {
            // No transactions, confirm simple delete
            return await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Delete Category?'),
                content: Text('Are you sure you want to delete "${category.name}"?'),
                actions: [
                  TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
                  TextButton(
                    onPressed: () {
                      Navigator.of(ctx).pop(true);
                      ref.read(categoriesProvider.notifier).deleteCategory(category.id!);
                    },
                    style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
                    child: const Text('Delete'),
                  ),
                ],
              ),
            ) ?? false;
          }
        },
        onDismissed: (direction) {
          // This will only be called if confirmDismiss returns true and there are no transactions
          // or if confirmDismiss handles the deletion itself and returns false initially.
          // The actual deletion is handled in confirmDismiss.
        },
            child: Semantics(
          label: '${category.name} ${category.type.name} category. Tap to edit. Swipe to delete. Drag to reorder.',
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Color(category.color),
              child: Icon(getIconFromCodePoint(category.iconCodePoint), color: Theme.of(context).colorScheme.onPrimary),
            ),
            title: Text(category.name),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (category.isArchived)
                  IconButton(
                    icon: const Icon(Icons.unarchive),
                    tooltip: 'Unarchive',
                    onPressed: () async {
                      await ref.read(categoriesProvider.notifier).unarchiveCategory(category.id!);
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('${category.name} unarchived.')),
                      );
                    },
                  ),
                const Icon(Icons.drag_handle),
              ],
            ),
            onTap: () => _showCategoryForm(context, ref, category: category),
          ),
        ),
      ),
    );
  }
}