import 'package:flutter/material.dart';
import '../../models/enums.dart';

class QuickCategoriesScreen extends StatefulWidget {

  const QuickCategoriesScreen({
    super.key,
    required this.onCategoriesSelected,
  });
  final Function(List<Map<String, dynamic>>) onCategoriesSelected;

  @override
  State<QuickCategoriesScreen> createState() => _QuickCategoriesScreenState();
}

class _QuickCategoriesScreenState extends State<QuickCategoriesScreen> {
  // Define default categories with their icons, colors, and type
  final List<Map<String, dynamic>> _defaultCategories = [
    // Expense Categories
    {'name': 'Groceries', 'icon': Icons.shopping_cart, 'color': Colors.green, 'type': TransactionType.expense},
    {'name': 'Dining', 'icon': Icons.restaurant, 'color': Colors.orange, 'type': TransactionType.expense},
    {'name': 'Transport', 'icon': Icons.directions_car, 'color': Colors.blue, 'type': TransactionType.expense},
    {'name': 'Bills', 'icon': Icons.receipt, 'color': Colors.purple, 'type': TransactionType.expense},
    {'name': 'Shopping', 'icon': Icons.shopping_bag, 'color': Colors.pink, 'type': TransactionType.expense},
    {'name': 'Entertainment', 'icon': Icons.movie, 'color': Colors.deepPurple, 'type': TransactionType.expense},
    {'name': 'Health', 'icon': Icons.favorite, 'color': Colors.red, 'type': TransactionType.expense},
    {'name': 'Other Expenses', 'icon': Icons.more_horiz, 'color': Colors.grey, 'type': TransactionType.expense},
    // Income Categories
    {'name': 'Salary', 'icon': Icons.attach_money, 'color': Colors.teal, 'type': TransactionType.income},
    {'name': 'Freelance', 'icon': Icons.work, 'color': Colors.indigo, 'type': TransactionType.income},
    {'name': 'Investments', 'icon': Icons.trending_up, 'color': Colors.lightGreen, 'type': TransactionType.income},
    {'name': 'Other Income', 'icon': Icons.add, 'color': Colors.blueGrey, 'type': TransactionType.income},
  ];

  final Set<Map<String, dynamic>> _selectedCategories = {};

  @override
  void initState() {
    super.initState();
    // Select all categories by default
    _selectedCategories.addAll(_defaultCategories);
    widget.onCategoriesSelected(_selectedCategories.toList());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Choose your categories',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            const Text(
              'You can customize these anytime in settings.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 2.5,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                ),
                itemCount: _defaultCategories.length,
                itemBuilder: (context, index) {
                  final category = _defaultCategories[index];
                  return FilterChip(
                    avatar: Icon(category['icon'], color: category['color']),
                    label: Text(category['name']),
                    selected: _selectedCategories.contains(category),
                    onSelected: (bool selected) {
                      setState(() {
                        if (selected) {
                          _selectedCategories.add(category);
                        } else {
                          _selectedCategories.remove(category);
                        }
                        widget.onCategoriesSelected(_selectedCategories.toList());
                      });
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}