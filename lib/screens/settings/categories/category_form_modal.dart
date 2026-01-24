import 'package:flutter/material.dart';
import '../../../models/category.dart';
import '../../../models/enums.dart';
import '../../../utils/constants.dart'; // Import AppConstants
import '../../../utils/icon_helper.dart';

class CategoryFormModal extends StatefulWidget {

  const CategoryFormModal({
    super.key,
    this.category,
    this.existingCategoryNames,
  });
  final Category? category; // For editing existing category
  final List<String>? existingCategoryNames;

  @override
  State<CategoryFormModal> createState() => _CategoryFormModalState();
}

class _CategoryFormModalState extends State<CategoryFormModal> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TransactionType _selectedType;
  late Color _selectedColor;
  late IconData _selectedIcon;
  bool _includeInBudgets = false;
  late TextEditingController _budgetAmountController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category?.name ?? '');
    _selectedType = widget.category?.type ?? TransactionType.expense;
    _selectedColor = widget.category != null ? Color(widget.category!.color) : Color(AppConstants.defaultCategoryColors[0]);
    _selectedIcon = widget.category != null ? getIconFromCodePoint(widget.category!.iconCodePoint) : Icons.category;
    _includeInBudgets = widget.category?.monthlyBudgetLimit != null;
    _budgetAmountController = TextEditingController(text: widget.category?.monthlyBudgetLimit?.toString() ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _budgetAmountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.category == null ? 'New Category' : 'Edit Category',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _nameController,
                maxLength: 30,
                decoration: InputDecoration(
                  labelText: 'Category Name',
                  hintText: 'e.g., Groceries',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a category name';
                  }
                  if (widget.existingCategoryNames != null &&
                      widget.existingCategoryNames!.contains(value.toLowerCase())) {
                    return 'Category name already exists';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              Text('Type', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              DropdownButtonFormField<TransactionType>(
                initialValue: _selectedType,
                decoration: InputDecoration(
                  labelText: 'Type',
                  border: OutlineInputBorder(),
                ),
                items: TransactionType.values.map((type) {
                  return DropdownMenuItem<TransactionType>(
                    value: type,
                    child: Text(type.toString().split('.').last.capitalize()),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedType = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 20),
              Text('Icon', style: Theme.of(context).textTheme.titleMedium),
              // Icon selection preview
              ListTile(
                leading: Icon(_selectedIcon, color: _selectedColor),
                title: Text('Change Icon'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  final newIcon = await _showIconPicker(context, _selectedIcon);
                  if (newIcon != null) {
                    setState(() {
                      _selectedIcon = newIcon;
                    });
                  }
                },
              ),
              const SizedBox(height: 20),
              Text('Color', style: Theme.of(context).textTheme.titleMedium),
              SizedBox(
                height: 40,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: AppConstants.defaultCategoryColors.length,
                  itemBuilder: (context, index) {
                    final color = Color(AppConstants.defaultCategoryColors[index]);
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedColor = color;
                        });
                      },
                      child: Container(
                        width: 32,
                        height: 32,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _selectedColor == color ? Theme.of(context).colorScheme.primary : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: _selectedColor == color
                            ? Icon(Icons.check, color: Theme.of(context).colorScheme.onPrimary, size: 18)
                            : null,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              SwitchListTile(
                title: const Text('Include in Monthly Budgets'),
                value: _includeInBudgets,
                onChanged: (value) {
                  setState(() {
                    _includeInBudgets = value;
                  });
                },
              ),
              if (_includeInBudgets)
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: TextFormField(
                    controller: _budgetAmountController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Monthly Budget Amount',
                      hintText: 'Optional budget limit',
                      border: OutlineInputBorder(),
                      prefixText: r'$', // Placeholder currency symbol
                    ),
                    validator: (value) {
                      if (_includeInBudgets && (value == null || value.isEmpty || double.tryParse(value) == null)) {
                        return 'Please enter a valid budget amount';
                      }
                      return null;
                    },
                  ),
                ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      final newCategory = Category(
                        id: widget.category?.id,
                        name: _nameController.text.trim(),
                        type: _selectedType,
                        color: _selectedColor.toARGB32(),
                        iconCodePoint: _selectedIcon.codePoint,
                        monthlyBudgetLimit: _includeInBudgets ? double.parse(_budgetAmountController.text) : null,
                      );
                      Navigator.of(context).pop(newCategory);
                    }
                  },
                  child: Text(widget.category == null ? 'Add Category' : 'Save Changes'),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Future<IconData?> _showIconPicker(BuildContext context, IconData currentIcon) async {
    // Simple icon picker — grid with selection.
    return showDialog<IconData>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Icon'),
        content: SizedBox(
          width: double.maxFinite,
          child: GridView.builder(
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              childAspectRatio: 1,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
            ),
            itemCount: _predefinedIcons.length,
            itemBuilder: (context, index) {
              final icon = _predefinedIcons[index];
              return GestureDetector(
                onTap: () => Navigator.of(context).pop(icon),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: currentIcon == icon ? Theme.of(context).colorScheme.primary.withAlpha((0.2 * 255).round()) : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 30),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    return '${this[0].toUpperCase()}${substring(1).toLowerCase()}';
  }
}

// Temporary list of icons for placeholder picker
const List<IconData> _predefinedIcons = [
  Icons.category,
  Icons.shopping_cart,
  Icons.restaurant,
  Icons.directions_car,
  Icons.receipt,
  Icons.shopping_bag,
  Icons.movie,
  Icons.favorite,
  Icons.more_horiz,
  Icons.attach_money,
  Icons.work,
  Icons.trending_up,
  Icons.add,
  Icons.home,
  Icons.school,
  Icons.fitness_center,
  Icons.medical_services,
  Icons.pets,
  Icons.business,
  Icons.flight,
  Icons.fastfood,
  Icons.lightbulb,
  Icons.phone,
  Icons.wifi,
  Icons.build,
  Icons.book,
  Icons.watch,
  Icons.brush,
  Icons.camera_alt,
  Icons.headphones,
  Icons.devices,
];
