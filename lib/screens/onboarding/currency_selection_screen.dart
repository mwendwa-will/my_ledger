import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Keep for existing ref.watch if needed, but not for direct set.

class CurrencySelectionScreen extends ConsumerStatefulWidget {

  const CurrencySelectionScreen({
    super.key,
    required this.onCurrencySelected,
    required this.initialCurrencyCode,
  });
  final Function(String) onCurrencySelected;
  final String initialCurrencyCode;

  @override
  ConsumerState<CurrencySelectionScreen> createState() => _CurrencySelectionScreenState();
}

class _CurrencySelectionScreenState extends ConsumerState<CurrencySelectionScreen> {
  final List<Map<String, String>> _currencies = [
    {'name': 'US Dollar', 'symbol': r'$', 'code': 'USD'},
    {'name': 'Euro', 'symbol': '€', 'code': 'EUR'},
    {'name': 'British Pound', 'symbol': '£', 'code': 'GBP'},
    {'name': 'Japanese Yen', 'symbol': '¥', 'code': 'JPY'},
    {'name': 'Indian Rupee', 'symbol': '₹', 'code': 'INR'},
  ];

  late String _selectedCurrencyCode;

  @override
  void initState() {
    super.initState();
    _selectedCurrencyCode = widget.initialCurrencyCode;
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
              'What currency do you use?',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            Expanded(
              child: ListView.builder(
                  itemCount: _currencies.length,
                  itemBuilder: (context, index) {
                    final currency = _currencies[index];
                    final code = currency['code']!;
                    return Card(
                      child: ListTile(
                        title: Text(currency['name']!),
                        subtitle: Text(currency['code']!),
                        trailing: _selectedCurrencyCode == code ? const Icon(Icons.check) : null,
                        leading: Text(
                          currency['symbol']!,
                          style: const TextStyle(fontSize: 24),
                        ),
                        onTap: () {
                          setState(() {
                            _selectedCurrencyCode = code;
                          });
                          widget.onCurrencySelected(code);
                        },
                      ),
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