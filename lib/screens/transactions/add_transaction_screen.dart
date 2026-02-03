import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter/semantics.dart';
import '../../providers/category_provider.dart';
import '../../utils/currency_helper.dart'; // Added import
import '../../utils/icon_helper.dart';
import '../../utils/analytics.dart';
import '../../utils/strings.dart';
import '../../utils/expression_parser.dart';

import '../../models/account.dart';
import '../../models/category.dart';
import '../../models/enums.dart';
import '../../models/transaction_item.dart';
import '../../providers/account_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/transaction_provider.dart';

import '../../widgets/category_selector.dart';
import '../../widgets/numpad.dart';
import '../../widgets/bottom_sheet_action_bar.dart';
import '../../widgets/date_picker_chip.dart';
import '../../widgets/enhanced_input_decoration.dart';
import '../../widgets/balance_preview_card.dart';
import '../../widgets/transaction_preview_card.dart';

class AddTransactionScreen extends ConsumerStatefulWidget {
  const AddTransactionScreen({super.key, this.transaction});
  final TransactionItem? transaction;

  @override
  ConsumerState<AddTransactionScreen> createState() =>
      _AddTransactionScreenState();
}

// Local intent to handle dismiss shortcut (Escape key)
class DismissIntent extends Intent {}

class _AddTransactionScreenState extends ConsumerState<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();

  TransactionType _selectedType = TransactionType.expense;
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  Category? _selectedCategory;
  Account? _selectedAccount;
  Account? _selectedToAccount;
  double _currentBalancePreview = 0.0;

  // For edit mode restoration
  int? _editTransactionAccountId;
  int? _editTransactionCategoryId;
  int? _editTransactionToAccountId;

  Timer? _balancePreviewDebounce;
  double? _lastAnnouncedBalance;
  late FocusNode _amountFocusNode;

  @override
  void initState() {
    super.initState();
    _amountController.addListener(_updateBalancePreview);
    _noteController.addListener(() => setState(() {}));
    _amountFocusNode = FocusNode();

    // Scroll controller for keyboard dismissal
    _scrollController.addListener(() {
      FocusScope.of(context).unfocus();
    });

    // If editing an existing transaction, prefill fields
    final t = widget.transaction;
    if (t != null) {
      _selectedType = t.type;
      _amountController.text = t.amount.toStringAsFixed(2);
      _noteController.text = t.note ?? '';
      _selectedDate = t.date;
      _editTransactionAccountId = t.accountId;
      _editTransactionCategoryId = t.categoryId;
      _editTransactionToAccountId = t.toAccountId;
    }

    // Schedule initialization after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeDefaultValues();
    });
  }

  @override
  void dispose() {
    _balancePreviewDebounce?.cancel();
    _amountController.removeListener(_updateBalancePreview);
    _amountController.dispose();
    _amountFocusNode.dispose();
    _noteController.removeListener(() => setState(() {}));
    _noteController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _initializeDefaultValues() {
    final accountsAsync = ref.read(accountsProvider);
    final categoriesAsync = ref.read(categoriesProvider);

    accountsAsync.whenData((accounts) {
      if (accounts.isEmpty) return;

      // Restore account from edit mode or use first account
      final account = _editTransactionAccountId != null
          ? accounts.firstWhere(
              (a) => a.id == _editTransactionAccountId,
              orElse: () => accounts.first,
            )
          : accounts.first;

      // Restore toAccount for transfers
      Account? toAccount;
      if (_editTransactionToAccountId != null) {
        toAccount = accounts.firstWhere(
          (a) => a.id == _editTransactionToAccountId,
          orElse: () => accounts.length > 1 ? accounts[1] : accounts.first,
        );
      }

      setState(() {
        _selectedAccount = account;
        _selectedToAccount = toAccount;
        _updateBalancePreview();
      });
    });

    // Restore category from edit mode
    categoriesAsync.whenData((categories) {
      if (categories.isEmpty) return;
      final category = categories.firstWhere(
        (c) => c.id == _editTransactionCategoryId,
        orElse: () => categories.first,
      );
      setState(() => _selectedCategory = category);
    });
  }

  void _updateBalancePreview() {
    _balancePreviewDebounce?.cancel();
    _balancePreviewDebounce = Timer(
      const Duration(milliseconds: 200),
      _recalculateBalancePreview,
    );
  }

  void _recalculateBalancePreview() {
    if (_selectedAccount == null) {
      setState(() => _currentBalancePreview = 0.0);
      return;
    }

    final currentBalance = _selectedAccount!.currentBalance;
    final amount = ExpressionParser.tryParse(_amountController.text) ?? 0.0;

    double newPreview;
    if (_selectedType == TransactionType.expense) {
      newPreview = currentBalance - amount;
    } else if (_selectedType == TransactionType.income) {
      newPreview = currentBalance + amount;
    } else {
      newPreview = currentBalance - amount;
    }

    // Announce changes for accessibility (debounced)
    if (_lastAnnouncedBalance == null ||
        (_lastAnnouncedBalance! - newPreview).abs() > 0.01) {
      SemanticsService.sendAnnouncement(
        View.of(context),
        'Balance preview ${newPreview.toStringAsFixed(2)}',
        TextDirection.ltr,
      );
      _lastAnnouncedBalance = newPreview;
    }

    setState(() {
      _currentBalancePreview = newPreview;
    });
  }

  void _onNumpadKeyPressed(String key) {
    _amountFocusNode.requestFocus();
    HapticFeedback.lightImpact();

    setState(() {
      if (key == 'backspace') {
        if (_amountController.text.isNotEmpty) {
          _amountController.text = _amountController.text
              .substring(0, _amountController.text.length - 1);
        }
      } else if (key == 'clear') {
        _amountController.text = '';
      } else if (key == '(' || key == ')') {
        _amountController.text += key;
      } else if (key == '.') {
        if (!_amountController.text.contains('.')) {
          _amountController.text += key;
        }
      } else if (key == '+' || key == '-' || key == '*' || key == '/') {
        final txt = _amountController.text;
        if (txt.isEmpty) {
          // ignore leading operator
        } else if (txt.endsWith('+') ||
            txt.endsWith('-') ||
            txt.endsWith('*') ||
            txt.endsWith('/')) {
          // replace last operator
          _amountController.text = txt.substring(0, txt.length - 1) + key;
        } else {
          _amountController.text = txt + key;
        }
      } else {
        // Digits and quick amounts
        final currentText = _amountController.text;
        if (key == '5' || key == '10' || key == '25' || key == '50') {
          if (currentText.isEmpty ||
              currentText.endsWith('+') ||
              currentText.endsWith('-') ||
              currentText.endsWith('*') ||
              currentText.endsWith('/')) {
            _amountController.text = key;
          } else {
            _amountController.text += key;
          }
        } else {
          _amountController.text += key;
        }
      }
      _updateBalancePreview();
    });
  }

  bool _isSaveEnabled() {
    if (_selectedAccount == null) return false;
    if (_selectedType == TransactionType.transfer &&
        _selectedToAccount == null) {
      return false;
    }
    if (_selectedType == TransactionType.transfer &&
        _selectedToAccount?.id == _selectedAccount?.id) {
      return false;
    }
    if (_selectedType != TransactionType.transfer &&
        _selectedCategory == null) {
      return false;
    }

    final text = _amountController.text.trim();
    if (text.isEmpty) return false;

    final val = ExpressionParser.tryParse(text);
    if (val == null) return false;

    return val > 0;
  }

  Future<void> _saveTransaction() async {
    final String text = _amountController.text;
    final finalAmount = ExpressionParser.tryParse(text);

    if (finalAmount == null) {
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

    if (_selectedType == TransactionType.transfer &&
        _selectedToAccount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a destination account')),
      );
      return;
    }

    if (_selectedType != TransactionType.transfer &&
        _selectedCategory == null) {
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
      id: widget.transaction?.id,
      accountId: _selectedAccount!.id!,
      categoryId: _selectedCategory?.id,
      toAccountId: _selectedToAccount?.id,
      amount: finalAmount,
      type: _selectedType,
      date: _selectedDate,
      note: _noteController.text,
    );

    try {
      if (widget.transaction != null && widget.transaction!.id != null) {
        Analytics.logEvent(
          'transaction_update',
          {'id': widget.transaction!.id},
        );
        await ref
            .read(transactionsProvider.notifier)
            .updateTransaction(newTransaction);
      } else {
        Analytics.logEvent('transaction_add');
        await ref
            .read(transactionsProvider.notifier)
            .addTransaction(newTransaction, context: context);
      }
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

  Widget _buildDragHandle() {
    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 8),
      width: 32,
      height: 4,
      decoration: BoxDecoration(
        color: Theme.of(context).dividerColor,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            widget.transaction != null
                ? 'Edit Transaction'
                : Strings.newTransaction,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
            tooltip: Strings.closeTransactionForm,
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionTypeSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SegmentedButton<TransactionType>(
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
            _updateBalancePreview();
            if (_selectedType == TransactionType.transfer) {
              _selectedCategory = null;
            }
          });
        },
      ),
    );
  }

  Widget _buildAmountAndDateRow(String currencySymbol) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Semantics(
                label: 'Transaction amount',
                hint:
                    'Enter amount using number pad below. Current value: ${_amountController.text.isEmpty ? "empty" : _amountController.text}',
                readOnly: true,
                child: TextFormField(
                  focusNode: _amountFocusNode,
                  controller: _amountController,
                  readOnly: true,
                  decoration: EnhancedInputDecoration.createForAmount(
                    context: context,
                    currencySymbol: currencySymbol,
                  ),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            DatePickerChip(
              selectedDate: _selectedDate,
              onDateSelected: (date) {
                setState(() => _selectedDate = date);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpressionPreview(String currencySymbol) {
    final result = ExpressionParser.tryParse(_amountController.text);

    if (_amountController.text.isEmpty || result == null) {
      return const SizedBox.shrink();
    }

    // Only show if expression contains operators
    if (!ExpressionParser.hasOperators(_amountController.text)) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Text(
        '${_amountController.text} = $currencySymbol${result.toStringAsFixed(2)}',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w500,
            ),
      ),
    );
  }

  Widget _buildBalancePreview(String currencyCode) {
    if (_selectedAccount == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Semantics(
        container: true,
        liveRegion: true,
        child: BalancePreviewCard(
          currentBalance: _selectedAccount!.currentBalance,
          newBalance: _currentBalancePreview,
          currencyCode: currencyCode,
          accountName: _selectedAccount!.name,
        ),
      ),
    );
  }

  Widget _buildAccountSection() {
    final accountsAsync = ref.watch(accountsProvider);

    return accountsAsync.when(
      data: (accounts) {
        if (accounts.isEmpty) {
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ListTile(
              title:
                  const Text('No accounts found. Please add an account first.'),
              leading: Icon(
                Icons.warning,
                color: Theme.of(context).colorScheme.tertiary,
              ),
            ),
          );
        }

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                DropdownButtonFormField<Account>(
                  initialValue: _selectedAccount,
                  decoration: EnhancedInputDecoration.createForDropdown(
                    context: context,
                    labelText: 'Account',
                    hintText: 'Select source account',
                    prefixIcon: const Icon(Icons.account_balance_wallet),
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
                      _updateBalancePreview();
                    });
                  },
                ),
                if (_selectedType == TransactionType.transfer) ...[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<Account>(
                    initialValue: _selectedToAccount,
                    decoration: EnhancedInputDecoration.createForDropdown(
                      context: context,
                      labelText: 'To Account',
                      hintText: 'Destination account for transfer',
                      prefixIcon: const Icon(Icons.download),
                    ),
                    items: accounts
                        .where((acc) => acc.id != _selectedAccount?.id)
                        .map((acc) {
                      return DropdownMenuItem(
                        value: acc,
                        child: Text(acc.name),
                      );
                    }).toList(),
                    onChanged: (val) =>
                        setState(() => _selectedToAccount = val),
                  ),
                ],
              ],
            ),
          ),
        );
      },
      loading: () => const LinearProgressIndicator(),
      error: (err, _) => Text('Error loading accounts: $err'),
    );
  }

  Widget _buildCategorySection() {
    if (_selectedType == TransactionType.transfer) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        // Frequent categories
        Builder(
          builder: (ctx) {
            final suggestionsAsync = ref.watch(
              frequentCategoriesProvider(_selectedType),
            );
            return suggestionsAsync.when(
              data: (list) {
                if (list.isEmpty) return const SizedBox.shrink();

                final noteQuery = _noteController.text.trim().toLowerCase();
                final ordered = <Category>[...list];
                if (noteQuery.isNotEmpty) {
                  ordered.sort((a, b) {
                    final aMatch = a.name.toLowerCase().contains(noteQuery);
                    final bMatch = b.name.toLowerCase().contains(noteQuery);
                    if (aMatch && !bMatch) return -1;
                    if (!aMatch && bMatch) return 1;
                    return a.name.compareTo(b.name);
                  });
                }

                return Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: SizedBox(
                    height: 88,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: ordered.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, idx) {
                        final c = ordered[idx];
                        final isSelected = _selectedCategory?.id == c.id;
                        return GestureDetector(
                          onTap: () {
                            setState(() => _selectedCategory = c);
                            SemanticsService.sendAnnouncement(
                              View.of(context),
                              '${c.name} selected',
                              TextDirection.ltr,
                            );
                          },
                          child: Container(
                            decoration: isSelected
                                ? BoxDecoration(
                                    border: Border.all(
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      width: 2,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  )
                                : null,
                            padding: const EdgeInsets.all(4),
                            child: Column(
                              children: [
                                CircleAvatar(
                                  radius: 22,
                                  backgroundColor: Color(c.color),
                                  child: Icon(
                                    getIconFromCodePoint(c.iconCodePoint),
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                SizedBox(
                                  width: 72,
                                  child: Text(
                                    c.name,
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            );
          },
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: CategorySelector(
            transactionType: _selectedType,
            selectedCategory: _selectedCategory,
            onCategorySelected: (category) {
              setState(() => _selectedCategory = category);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildNoteField() {
    const maxLength = 200;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: TextFormField(
          controller: _noteController,
          decoration: EnhancedInputDecoration.create(
            context: context,
            labelText: 'Note (Optional)',
            hintText: 'Add details about this transaction',
            prefixIcon: const Icon(Icons.edit_note),
          ).copyWith(
            counterText: '${_noteController.text.length}/$maxLength',
          ),
          maxLength: maxLength,
          maxLines: 3,
          onChanged: (value) {
            setState(() {}); // Update counter
          },
        ),
      ),
    );
  }

  Widget _buildTransactionPreview(String currencyCode) {
    if (!_isSaveEnabled()) return const SizedBox.shrink();

    final amount = ExpressionParser.tryParse(_amountController.text) ?? 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Semantics(
        container: true,
        liveRegion: true,
        child: TransactionPreviewCard(
          type: _selectedType,
          amount: amount,
          currencyCode: currencyCode,
          date: _selectedDate,
          accountName: _selectedAccount?.name,
          toAccountName: _selectedToAccount?.name,
          categoryName: _selectedCategory?.name,
          note: _noteController.text.isNotEmpty ? _noteController.text : null,
          newBalance: _currentBalancePreview,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyCode = ref.watch(currencyCodeProvider);
    final currencySymbol = CurrencyHelper.getSymbol(currencyCode);

    return SafeArea(
      child: Column(
        children: [
          // TOP - Fixed Header
          _buildDragHandle(),
          _buildHeader(),
          _buildTransactionTypeSelector(),
          const Divider(height: 1),

          // MIDDLE - Scrollable Content
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    _buildAmountAndDateRow(currencySymbol),
                    _buildExpressionPreview(currencySymbol),
                    _buildBalancePreview(currencyCode),
                    const SizedBox(height: 8),
                    Numpad(
                      onKeyPressed: _onNumpadKeyPressed,
                      currencyCode: currencyCode,
                    ),
                    const SizedBox(height: 16),
                    _buildAccountSection(),
                    const SizedBox(height: 16),
                    _buildCategorySection(),
                    const SizedBox(height: 16),
                    _buildNoteField(),
                    const SizedBox(height: 16),
                    _buildTransactionPreview(currencyCode),
                    SizedBox(
                      height: 80 + MediaQuery.of(context).viewInsets.bottom,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // BOTTOM - Fixed Action Bar
          BottomSheetActionBar(
            child: Semantics(
              button: true,
              enabled: _isSaveEnabled(),
              label: widget.transaction != null
                  ? 'Save changes to transaction'
                  : 'Add new transaction',
              hint: _isSaveEnabled()
                  ? 'Double tap to save'
                  : 'Complete required fields to enable',
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSaveEnabled() ? _saveTransaction : null,
                  child: Text(
                    widget.transaction != null
                        ? 'Save Changes'
                        : 'Add Transaction',
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
