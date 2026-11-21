import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_ledger/models/account.dart';
import 'package:my_ledger/models/category.dart';
import 'package:my_ledger/models/transaction_filter.dart';
import 'package:my_ledger/providers/account_provider.dart';
import 'package:my_ledger/providers/category_provider.dart';
import 'package:my_ledger/providers/settings_provider.dart';
import 'package:my_ledger/screens/settings/categories/category_form_modal.dart';
import 'package:my_ledger/utils/currency_helper.dart';
import 'package:my_ledger/widgets/transaction_filter_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _EmptyAccounts extends AccountsNotifier {
  @override
  Future<List<Account>> build() async => [];
}

class _EmptyCategories extends CategoriesNotifier {
  @override
  Future<List<Category>> build() async => [];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('currency symbol reacts to persisted startup currency and later changes',
      () async {
    SharedPreferences.setMockInitialValues({'currency_code': 'KES'});
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final symbols = <String>[];
    container.listen(
      currencySymbolProvider,
      (_, symbol) => symbols.add(symbol),
      fireImmediately: true,
    );
    await Future<void>.delayed(Duration.zero);
    expect(container.read(currencyCodeProvider), 'KES');
    expect(container.read(currencySymbolProvider), CurrencyHelper.getSymbol('KES'));
    expect(symbols.last, CurrencyHelper.getSymbol('KES'));

    await container.read(currencyCodeProvider.notifier).setCurrencyCode('EUR');
    expect(container.read(currencySymbolProvider), CurrencyHelper.getSymbol('EUR'));
    expect(symbols.last, CurrencyHelper.getSymbol('EUR'));
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('currency_code'), 'EUR');
  });

  test('startup load cannot overwrite a currency selected immediately', () async {
    SharedPreferences.setMockInitialValues({'currency_code': 'USD'});
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await container.read(currencyCodeProvider.notifier).setCurrencyCode('KES');
    expect(container.read(currencyCodeProvider), 'KES');
    expect(container.read(currencySymbolProvider), CurrencyHelper.getSymbol('KES'));
  });

  testWidgets('filter amount fields react to global currency changes',
      (tester) async {
    SharedPreferences.setMockInitialValues({'currency_code': 'KES'});
    final container = ProviderContainer(
      overrides: [
        accountsProvider.overrideWith(_EmptyAccounts.new),
        categoriesProvider.overrideWith(_EmptyCategories.new),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(
            body: TransactionFilterSheet(
              initialFilter: const TransactionFilter(),
              onApply: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    List<String?> prefixes() => tester
        .widgetList<TextField>(find.byType(TextField))
        .where((field) => ['Min', 'Max'].contains(field.decoration?.labelText))
        .map((field) => field.decoration?.prefixText)
        .toList();

    expect(prefixes(), List.filled(2, '${CurrencyHelper.getSymbol('KES')} '));
    await container.read(currencyCodeProvider.notifier).setCurrencyCode('EUR');
    await tester.pumpAndSettle();
    expect(prefixes(), List.filled(2, '${CurrencyHelper.getSymbol('EUR')} '));
    expect(tester.takeException(), isNull);
  });

  testWidgets('category budget entry uses and reacts to global currency',
      (tester) async {
    SharedPreferences.setMockInitialValues({'currency_code': 'KES'});
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(body: CategoryFormModal()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byType(SwitchListTile));
    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();

    String? prefix() => tester
        .widgetList<TextField>(find.byType(TextField))
        .singleWhere(
          (field) => field.decoration?.labelText == 'Monthly Budget Amount',
        )
        .decoration
        ?.prefixText;

    expect(prefix(), CurrencyHelper.getSymbol('KES'));
    await container.read(currencyCodeProvider.notifier).setCurrencyCode('EUR');
    await tester.pumpAndSettle();
    expect(prefix(), CurrencyHelper.getSymbol('EUR'));
    expect(tester.takeException(), isNull);
  });
}
