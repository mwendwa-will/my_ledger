import 'package:flutter/material.dart';
import '../../../models/categorization_rule.dart';
import '../../../models/category.dart';
import '../../../models/enums.dart';
import '../../../services/database_service.dart';

class CategorizationRulesScreen extends StatefulWidget {
  const CategorizationRulesScreen({super.key});

  @override
  State<CategorizationRulesScreen> createState() =>
      _CategorizationRulesScreenState();
}

class _CategorizationRulesScreenState extends State<CategorizationRulesScreen> {
  late Future<List<CategorizationRule>> _rules;
  List<Category> _categories = [];

  @override
  void initState() {
    super.initState();
    _rules = _load();
  }

  Future<List<CategorizationRule>> _load() async {
    _categories = await DatabaseService.instance.getAllCategories();
    return DatabaseService.instance.getCategorizationRules();
  }

  void _reload() => setState(() => _rules = _load());

  Future<void> _addRule() async {
    final matchController = TextEditingController();
    int? categoryId;
    final categories =
        _categories.where((category) => !category.isArchived).toList();
    final result = await showDialog<CategorizationRule>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('New categorization rule'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: matchController,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Description contains',
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                initialValue: categoryId,
                decoration: const InputDecoration(labelText: 'Category'),
                items: categories
                    .map(
                      (category) => DropdownMenuItem(
                        value: category.id,
                        child: Text(category.name),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setDialogState(() => categoryId = value),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final text = matchController.text.trim();
                if (text.isEmpty || categoryId == null) return;
                Navigator.pop(
                  context,
                  CategorizationRule(matchText: text, categoryId: categoryId!),
                );
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    matchController.dispose();
    if (result == null) return;
    await DatabaseService.instance.saveCategorizationRule(result);
    if (mounted) _reload();
  }

  String _typeName(int categoryId) {
    final category = _categories.where((item) => item.id == categoryId);
    if (category.isEmpty) return 'Unavailable category';
    final type = category.first.type;
    return type == TransactionType.expense ? 'Expense' : 'Income';
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Categorization Rules')),
        body: FutureBuilder<List<CategorizationRule>>(
          future: _rules,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                  child: Text('Could not load rules: ${snapshot.error}'),);
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final rules = snapshot.data!;
            if (rules.isEmpty) {
              return const Center(
                child: Text(
                    'Add a rule to suggest categories from transaction notes.',),
              );
            }
            return ListView.builder(
              itemCount: rules.length,
              itemBuilder: (context, index) {
                final rule = rules[index];
                final category = _categories.where(
                  (item) => item.id == rule.categoryId,
                );
                return ListTile(
                  title: Text('Contains "${rule.matchText}"'),
                  subtitle: Text(
                    '${category.isEmpty ? 'Unavailable category' : category.first.name} · ${_typeName(rule.categoryId)}',
                  ),
                  trailing: IconButton(
                    tooltip: 'Delete rule',
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () async {
                      await DatabaseService.instance.deleteCategorizationRule(
                        rule.id!,
                      );
                      if (mounted) _reload();
                    },
                  ),
                );
              },
            );
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _addRule,
          child: const Icon(Icons.add),
        ),
      );
}
