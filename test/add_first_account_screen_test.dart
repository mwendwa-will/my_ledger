import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_ledger/models/enums.dart';
import 'package:my_ledger/screens/onboarding/add_first_account_screen.dart';

void main() {
  for (final scenario in [
    (name: 'short viewport', size: const Size(411.4, 472), keyboard: 0.0),
    (name: 'landscape', size: const Size(640, 360), keyboard: 0.0),
    (name: 'keyboard open', size: const Size(411.4, 780), keyboard: 308.0),
  ]) {
    testWidgets('account form remains accessible with ${scenario.name}',
        (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = scenario.size;
      tester.view.viewInsets = FakeViewPadding(bottom: scenario.keyboard);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetViewInsets);
      var accountName = '';
      var startingBalance = 0.0;

      await tester.pumpWidget(
        MaterialApp(
          home: AddFirstAccountScreen(
            onAccountNameChanged: (value) => accountName = value,
            onAccountTypeChanged: (_) {},
            onStartingBalanceChanged: (value) => startingBalance = value,
            initialAccountName: '',
            initialAccountType: AccountType.checking,
            initialStartingBalance: 0,
            selectedCurrencyCode: 'USD',
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      final nameField = find.byType(TextFormField).first;
      await tester.ensureVisible(nameField);
      await tester.enterText(nameField, 'Main account');
      final balanceField = find.byType(TextFormField).last;
      await tester.ensureVisible(balanceField);
      await tester.enterText(balanceField, '125');
      await tester.pumpAndSettle();

      final preview = find.byType(Card);
      await tester.ensureVisible(preview);
      await tester.pumpAndSettle();
      expect(preview.hitTestable(), findsOneWidget);
      expect(accountName, 'Main account');
      expect(startingBalance, 125);
      expect(tester.takeException(), isNull);
    });
  }
}
