import 'package:flutter/material.dart';
import '../../models/enums.dart';

class AddFirstAccountScreen extends StatefulWidget {

  const AddFirstAccountScreen({
    super.key,
    required this.onAccountNameChanged,
    required this.onAccountTypeChanged,
    required this.onStartingBalanceChanged,
    required this.initialAccountName,
    required this.initialAccountType,
    required this.initialStartingBalance,
  });
  final Function(String) onAccountNameChanged;
  final Function(AccountType) onAccountTypeChanged;
  final Function(double) onStartingBalanceChanged;
  final String initialAccountName;
  final AccountType initialAccountType;
  final double initialStartingBalance;

  @override
  State<AddFirstAccountScreen> createState() => _AddFirstAccountScreenState();
}

class _AddFirstAccountScreenState extends State<AddFirstAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late AccountType _selectedType;
  late TextEditingController _balanceController;

  final Map<String, IconData> _accountTypes = {
    'Checking': Icons.account_balance,
    'Savings': Icons.savings,
    'Cash': Icons.money,
    'Credit Card': Icons.credit_card,
  };

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialAccountName);
    _selectedType = widget.initialAccountType;
    _balanceController = TextEditingController(text: widget.initialStartingBalance == 0.0 ? '' : widget.initialStartingBalance.toString());

    _nameController.addListener(() {
      widget.onAccountNameChanged(_nameController.text);
      setState(() {}); // To update preview
    });
    _balanceController.addListener(() {
      widget.onStartingBalanceChanged(double.tryParse(_balanceController.text) ?? 0.0);
      setState(() {}); // To update preview
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(40),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Add your main account',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              const Text(
                'You can add more accounts later',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Account Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an account name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<AccountType>(
                initialValue: _selectedType,
                decoration: const InputDecoration(
                  labelText: 'Account Type',
                  border: OutlineInputBorder(),
                ),
                items: AccountType.values.map((AccountType type) {
                  return DropdownMenuItem<AccountType>(
                    value: type,
                    child: Row(
                      children: [
                        Icon(_accountTypes[type.displayName]),
                        const SizedBox(width: 10),
                        Text(type.displayName),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedType = value;
                    });
                    widget.onAccountTypeChanged(value);
                  }
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _balanceController,
                decoration: const InputDecoration(
                  labelText: 'Starting Balance (Optional)',
                  border: OutlineInputBorder(),
                  prefixText: r'$',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 40),
              const Text(
                'Preview:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Card(
                elevation: 2,
                child: ListTile(
                  leading: Icon(_accountTypes[_selectedType.name]),
                  title: Text(_nameController.text),
                  subtitle: Text(_selectedType.name.substring(0,1).toUpperCase() + _selectedType.name.substring(1)),
                  trailing: Text(
                    '\$${(double.tryParse(_balanceController.text) ?? 0.00).toStringAsFixed(2)}',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold,),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}