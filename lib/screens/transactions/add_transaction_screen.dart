import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:math_expressions/math_expressions.dart';
import '../../models/transaction_item.dart';
import '../../models/enums.dart';
import '../../models/category.dart';
import '../../models/account.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/account_provider.dart';
import '../../utils/constants.dart';

class AddTransactionScreen extends ConsumerStatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  ConsumerState<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends ConsumerState<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  
  TransactionType _selectedType = TransactionType.expense;
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  
  DateTime _selectedDate = DateTime.now();
  Category? _selectedCategory;
  Account? _selectedAccount;
  Account? _selectedToAccount; // For transfers

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _calculateAmount() {
    String text = _amountController.text.replaceAll(',', '.');
    if (text.isEmpty) return;
    
    try {
      GrammarParser p = GrammarParser();
      Expression exp = p.parse(text);
      ContextModel cm = ContextModel();
      double eval = exp.evaluate(EvaluationType.REAL, cm);
      _amountController.text = eval.toStringAsFixed(2);
    } catch (e) {
      // Ignore parse errors, user might be typing
    }
  }

  Future<void> _saveTransaction() async {
    // Trigger calculation one last time
    _calculateAmount();

    if (!_formKey.currentState!.validate()) return;
    if (_selectedAccount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an account')),
      );
      return;
    }
    
    if (_selectedType == TransactionType.transfer && _selectedToAccount == null) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a destination account')),
      );
      return;
    }
    
    if (_selectedType != TransactionType.transfer && _selectedCategory == null) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category')),
      );
      return;
    }

    final double amount = double.tryParse(_amountController.text) ?? 0.0;
    if (amount <= 0) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Amount must be positive')),
      );
      return;
    }

    final newTransaction = TransactionItem(
      accountId: _selectedAccount!.id!,
      categoryId: _selectedCategory?.id,
      toAccountId: _selectedToAccount?.id,
      amount: amount,
      type: _selectedType,
      date: _selectedDate,
      note: _noteController.text,
    );

    try {
      await ref.read(transactionsProvider.notifier).addTransaction(newTransaction);
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final accountsAsync = ref.watch(accountsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('New Transaction')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          children: [
            // Type Selector
            SegmentedButton<TransactionType>(
              segments: const [
                ButtonSegment(
                  value: TransactionType.expense,
                  label: Text('Expense'),
                  icon: Icon(Icons.money_off),
                ),
                ButtonSegment(
                  value: TransactionType.income,
                  label: Text('Income'),
                  icon: Icon(Icons.attach_money),
                ),
                ButtonSegment(
                  value: TransactionType.transfer,
                  label: Text('Transfer'),
                  icon: Icon(Icons.swap_horiz),
                ),
              ],
              selected: {_selectedType},
              onSelectionChanged: (Set<TransactionType> newSelection) {
                setState(() {
                  _selectedType = newSelection.first;
                  // Reset category if switching to transfer
                  if (_selectedType == TransactionType.transfer) {
                    _selectedCategory = null;
                  }
                });
              },
            ),
            const SizedBox(height: 24),

            // Amount Field
            TextFormField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true), // No specialized signed/math keyboard on iOS/Android usually, but we handle text
              decoration: InputDecoration(
                labelText: 'Amount',
                prefixText: '\$ ', // Should be dynamic currency
                suffixIcon: IconButton(
                  icon: const Icon(Icons.calculate),
                  onPressed: _calculateAmount,
                  tooltip: 'Calculate',
                ),
                border: const OutlineInputBorder(),
              ),
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              onEditingComplete: _calculateAmount, // Calc on done
            ),
            const SizedBox(height: 16),

            // Accounts
            accountsAsync.when(
              data: (accounts) {
                if (accounts.isEmpty) {
                   return const ListTile(
                     title: Text('No accounts found. Please add an account first.'),
                     leading: Icon(Icons.warning, color: AppColors.warning),
                   );
                }
                
                // If account not selected, default to first
                if (_selectedAccount == null && accounts.isNotEmpty) {
                  // Use microtask to avoid build error
                  Future.microtask(() {
                    if (mounted) setState(() => _selectedAccount = accounts.first);
                  });
                }

                return Column(
                  children: [
                    DropdownButtonFormField<Account>(
                      initialValue: _selectedAccount,
                      decoration: const InputDecoration(
                        labelText: 'Account',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.account_balance_wallet),
                      ),
                      items: accounts.map((acc) {
                        return DropdownMenuItem(
                          value: acc,
                          child: Text(acc.name),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => _selectedAccount = val),
                    ),
                    
                    if (_selectedType == TransactionType.transfer) ...[
                      const SizedBox(height: 16),
                      DropdownButtonFormField<Account>(
                        initialValue: _selectedToAccount,
                        decoration: const InputDecoration(
                          labelText: 'To Account',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.download),
                        ),
                        items: accounts
                            .where((acc) => acc.id != _selectedAccount?.id)
                            .map((acc) {
                          return DropdownMenuItem(
                            value: acc,
                            child: Text(acc.name),
                          );
                        }).toList(),
                        onChanged: (val) => setState(() => _selectedToAccount = val),
                      ),
                    ],
                  ],
                );
              },
              loading: () => const LinearProgressIndicator(),
              error: (err, _) => Text('Error loading accounts: $err'),
            ),
            const SizedBox(height: 16),

            // Category (Hide if transfer)
            if (_selectedType != TransactionType.transfer) ...[
              categoriesAsync.when(
                data: (categories) {
                  // Filter categories by type
                  final filtered = categories.where((c) => c.type == _selectedType).toList();
                  
                  return DropdownButtonFormField<Category>(
                    initialValue: _selectedCategory,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.category),
                    ),
                    items: filtered.map((cat) {
                      return DropdownMenuItem(
                        value: cat,
                        child: Row(
                          children: [
                            Icon(IconData(cat.iconCodePoint, fontFamily: 'MaterialIcons'), color: Color(cat.color)),
                            const SizedBox(width: 8),
                            Text(cat.name),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedCategory = val),
                  );
                },
                loading: () => const LinearProgressIndicator(),
                error: (err, _) => Text('Error loading categories: $err'),
              ),
              const SizedBox(height: 16),
            ],

            // Date Picker
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today),
              title: Text('Date: ${_selectedDate.toLocal().toString().split(' ')[0]}'),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (picked != null) {
                  setState(() => _selectedDate = picked);
                }
              },
              shape: RoundedRectangleBorder(
                side: const BorderSide(color: Colors.grey),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 16),

            // Note
            TextFormField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: 'Note (Optional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.edit),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 32),

            // Save Button
            ElevatedButton(
              onPressed: _saveTransaction,
              child: const Text('Save Transaction'),
            ),
          ],
        ),
      ),
    );
  }
}