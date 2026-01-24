import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/account.dart';
import '../../models/enums.dart';
import '../../providers/account_provider.dart';
import '../../utils/constants.dart';

class AddAccountScreen extends ConsumerStatefulWidget { // If null, create new

  const AddAccountScreen({super.key, this.accountToEdit});
  final Account? accountToEdit;

  @override
  ConsumerState<AddAccountScreen> createState() => _AddAccountScreenState();
}

class _AddAccountScreenState extends ConsumerState<AddAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _balanceController = TextEditingController();
  AccountType _selectedType = AccountType.checking;
  
  // Simple color picker
  final List<Color> _colors = [
    Colors.blue, Colors.green, Colors.red, Colors.orange, 
    Colors.purple, Colors.teal, Colors.indigo, Colors.brown,
  ];
  late Color _selectedColor;

  @override
  void initState() {
    super.initState();
    if (widget.accountToEdit != null) {
      _nameController.text = widget.accountToEdit!.name;
      _balanceController.text = widget.accountToEdit!.initialBalance.toString();
      _selectedType = widget.accountToEdit!.type;
      _selectedColor = Color(widget.accountToEdit!.color);
    } else {
      _selectedColor = _colors.first;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    
    final name = _nameController.text;
    final initialBalance = double.tryParse(_balanceController.text) ?? 0.0;
    
    // Determine icon based on type (simplified)
    int iconCode;
    switch (_selectedType) {
      case AccountType.checking: iconCode = Icons.credit_card.codePoint; break;
      case AccountType.savings: iconCode = Icons.savings.codePoint; break;
      case AccountType.creditCard: iconCode = Icons.credit_score.codePoint; break;
      case AccountType.cash: iconCode = Icons.attach_money.codePoint; break;
      case AccountType.investment: iconCode = Icons.trending_up.codePoint; break;
      default: iconCode = Icons.account_balance_wallet.codePoint; break;
    }

    final newAccount = Account(
      id: widget.accountToEdit?.id,
      name: name,
      type: _selectedType,
      initialBalance: initialBalance,
      currentBalance: widget.accountToEdit != null 
          ? (widget.accountToEdit!.currentBalance - widget.accountToEdit!.initialBalance + initialBalance) // Adjust current balance if initial changed
          : initialBalance,
      color: _selectedColor.toARGB32(),
      iconCodePoint: iconCode,
    );

    try {
      if (widget.accountToEdit != null) {
        await ref.read(accountsProvider.notifier).updateAccount(newAccount);
      } else {
        await ref.read(accountsProvider.notifier).addAccount(newAccount);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.accountToEdit != null ? 'Edit Account' : 'Add Account'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Account Name',
                hintText: 'e.g., Checking',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.drive_file_rename_outline),
              ),
              validator: (val) => val == null || val.isEmpty ? 'Please enter a name' : null,
            ),
            const SizedBox(height: 16),
            
            DropdownButtonFormField<AccountType>(
              initialValue: _selectedType,
              decoration: InputDecoration(
                labelText: 'Account Type',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.account_tree_outlined),
              ),
              items: AccountType.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(type.displayName),
                );
              }).toList(),
              onChanged: (val) => setState(() => _selectedType = val!),
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _balanceController,
              decoration: InputDecoration(
                labelText: 'Initial Balance',
                border: const OutlineInputBorder(),
                prefixText: r'$ ',
                helperText: widget.accountToEdit == null ? 'Initial balance can be set now' : null,
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (val) => double.tryParse(val ?? '') == null ? 'Invalid amount' : null,
              enabled: widget.accountToEdit == null, // Prevent changing initial balance on edit to avoid confusion logic for now, or handle carefully
            ),
            if (widget.accountToEdit != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Initial balance cannot be changed after creation.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurface.withAlpha((0.6 * 255).round()), fontSize: 12),
                ),
              ),
            const SizedBox(height: 24),
            
            Text('Color Code', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),

            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _colors.map((color) {
                final isSelected = _selectedColor == color;
                return GestureDetector(
                  onTap: () => setState(() => _selectedColor = color),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: isSelected ? Border.all(color: Theme.of(context).colorScheme.onSurface, width: 3) : null,
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).shadowColor.withAlpha((0.1 * 255).round()),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: isSelected ? Icon(Icons.check, color: Theme.of(context).colorScheme.onPrimary) : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),
            
            ElevatedButton(
              onPressed: _save,
              child: const Text('Save Account'),
            ),
          ],
        ),
      ),
    );
  }
}
