import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:math_expressions/math_expressions.dart'; // Still needed for math expression evaluation

import '../../models/account.dart';
import '../../models/category.dart';
import '../../models/enums.dart';
import '../../models/transaction_item.dart';
import '../../providers/account_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/settings_provider.dart'; // Import for currency
import '../../providers/transaction_provider.dart';
import '../../utils/constants.dart';
import '../../widgets/category_selector.dart';
import '../../widgets/numpad.dart'; // Import Numpad widget

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
  double _currentBalancePreview = 0.0; // Real-time balance preview

  @override
  void initState() {
    super.initState();
    _amountController.addListener(_updateBalancePreview);
  }

  @override
  void dispose() {
    _amountController.removeListener(_updateBalancePreview);
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _updateBalancePreview() {
    if (_selectedAccount == null) {
      setState(() {
        _currentBalancePreview = 0.0;
      });
      return;
    }

    double currentAccountBalance = _selectedAccount!.currentBalance;
    double enteredAmount = 0.0;
    try {
      Parser p = Parser();
      Expression exp = p.parse(_amountController.text.replaceAll(',', '.'));
      ContextModel cm = ContextModel();
      enteredAmount = exp.evaluate(EvaluationType.REAL, cm);
    } catch (e) {
      // Ignore parse errors, user might be typing an incomplete expression
      enteredAmount = 0.0;
    }

    setState(() {
      if (_selectedType == TransactionType.expense) {
        _currentBalancePreview = currentAccountBalance - enteredAmount;
      } else if (_selectedType == TransactionType.income) {
        _currentBalancePreview = currentAccountBalance + enteredAmount;
      } else if (_selectedType == TransactionType.transfer) {
        _currentBalancePreview = currentAccountBalance - enteredAmount;
        // For transfer, also show recipient balance if possible
      }
    });
  }

  void _onNumpadKeyPressed(String key) {
    setState(() {
      if (key == 'backspace') {
        if (_amountController.text.isNotEmpty) {
          _amountController.text = _amountController.text.substring(0, _amountController.text.length - 1);
        }
      } else if (key == '.') {
        if (!_amountController.text.contains('.')) {
          _amountController.text += key;
        }
      } else if (key == '+' || key == '-' || key == '*' || key == '/') {
         if (_amountController.text.isNotEmpty && !_amountController.text.endsWith(key)) {
            _amountController.text += key;
         }
      } else { // Digits and quick amounts
        String currentText = _amountController.text;
        if (key == '5' || key == '10' || key == '25' || key == '50') {
          // If the amount field is empty or just contains an operator,
          // replace it with the quick amount. Otherwise, append.
          if (currentText.isEmpty || currentText.endsWith('+') || currentText.endsWith('-') || currentText.endsWith('*') || currentText.endsWith('/')) {
            _amountController.text = key;
          } else {
            _amountController.text += key;
          }
        } else {
          _amountController.text += key;
        }
      }
      _updateBalancePreview(); // Update preview on every key press
    });
  }

  Future<void> _saveTransaction() async {
    // Final evaluation before saving
    String text = _amountController.text.replaceAll(',', '.');
    double finalAmount = 0.0;
    try {
      Parser p = Parser();
      Expression exp = p.parse(text);
      ContextModel cm = ContextModel();
      finalAmount = exp.evaluate(EvaluationType.REAL, cm);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid amount expression')),
      );
      return;
    }


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

    if (finalAmount <= 0) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Amount must be positive')),
      );
      return;
    }

    final newTransaction = TransactionItem(
      accountId: _selectedAccount!.id!,
      categoryId: _selectedCategory?.id,
      toAccountId: _selectedToAccount?.id,
      amount: finalAmount, // Use the final calculated amount
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
    final currencySymbol = ref.watch(currencyCodeProvider.notifier).currentCurrencySymbol;


    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: AppConstants.defaultPadding,
          right: AppConstants.defaultPadding,
          top: AppConstants.defaultPadding,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'New Transaction',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                  tooltip: 'Close transaction form', // Add a tooltip for visual users
                ),
              ],
            ),
            const SizedBox(height: 16),
            Form(
              key: _formKey,
              child: Column(
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
                        _updateBalancePreview(); // Update preview on type change
                        // Reset category if switching to transfer
                        if (_selectedType == TransactionType.transfer) {
                          _selectedCategory = null;
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 24),

                  // Amount Field (Read-only for custom numpad)
                  TextFormField(
                    controller: _amountController,
                    readOnly: true, // Make read-only for custom numpad
                    decoration: InputDecoration(
                      labelText: 'Amount',
                      prefixText: '$currencySymbol ', // Dynamic currency symbol
                      border: const OutlineInputBorder(),
                    ),
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter an amount';
                      }
                      // Use math_expressions to validate if the amount is a valid expression
                      try {
                        Parser p = Parser();
                        Expression exp = p.parse(value.replaceAll(',', '.'));
                        ContextModel cm = ContextModel();
                        exp.evaluate(EvaluationType.REAL, cm);
                      } catch (e) {
                        return 'Invalid amount expression';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  // Balance Preview
                  accountsAsync.when(
                    data: (accounts) {
                      if (accounts.isEmpty || _selectedAccount == null) {
                        return const SizedBox.shrink();
                      }
                      
                      final displayBalance = _selectedAccount!.currentBalance;
                      Color balanceColor = Colors.grey;
                      if (_currentBalancePreview < displayBalance) {
                        balanceColor = AppColors.expense;
                      } else if (_currentBalancePreview > displayBalance) {
                        balanceColor = AppColors.income;
                      }

                      return Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Current: $currencySymbol${displayBalance.toStringAsFixed(2)} | New: $currencySymbol${_currentBalancePreview.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 14,
                            color: balanceColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    },
                    loading: () => const SizedBox.shrink(),
                    error: (err, _) => const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 8),

                  // Numpad
                  Numpad(
                    onKeyPressed: _onNumpadKeyPressed,
                    currencySymbol: currencySymbol,
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
                      if (_selectedAccount == null) { // Only assign if null
                        _selectedAccount = accounts.first;
                        _updateBalancePreview(); // Update preview after setting default account
                      }

                      return Column(
                        children: [
                          DropdownButtonFormField<Account>(
                            value: _selectedAccount,
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
                            onChanged: (val) {
                              setState(() {
                                _selectedAccount = val;
                                _updateBalancePreview(); // Update preview on account change
                              });
                            },
                          ),
                          
                          if (_selectedType == TransactionType.transfer) ...[
                            const SizedBox(height: 16),
                            DropdownButtonFormField<Account>(
                              value: _selectedToAccount,
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
                    CategorySelector(
                      transactionType: _selectedType,
                      selectedCategory: _selectedCategory,
                      onCategorySelected: (category) {
                        setState(() {
                          _selectedCategory = category;
                        });
                      },
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
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saveTransaction,
                      child: const Text('Save Transaction'),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}