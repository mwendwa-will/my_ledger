import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_ledger/widgets/biometric_gate.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('does not request authentication when biometric lock is off',
      (tester) async {
    SharedPreferences.setMockInitialValues({'biometric_enabled': false});
    var authenticationCalls = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: BiometricGate(
          child: const Text('Ledger'),
          authenticate: () async {
            authenticationCalls++;
            return true;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Ledger'), findsOneWidget);
    expect(authenticationCalls, 0);
  });

  testWidgets('gates ledger content until authentication succeeds',
      (tester) async {
    SharedPreferences.setMockInitialValues({'biometric_enabled': true});
    var authenticated = false;

    await tester.pumpWidget(
      MaterialApp(
        home: BiometricGate(
          child: const Text('Ledger'),
          authenticate: () async => authenticated,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Ledger'), findsNothing);
    expect(find.text('Try again'), findsOneWidget);

    authenticated = true;
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(find.text('Ledger'), findsOneWidget);
  });

  testWidgets('relocks the ledger after the app is backgrounded',
      (tester) async {
    SharedPreferences.setMockInitialValues({'biometric_enabled': true});
    var authenticationCalls = 0;
    final secondAuthentication = Completer<bool>();

    await tester.pumpWidget(
      MaterialApp(
        home: BiometricGate(
          child: const Text('Ledger'),
          authenticate: () async {
            authenticationCalls++;
            if (authenticationCalls == 1) return true;
            return secondAuthentication.future;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Ledger'), findsOneWidget);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 10));
    expect(authenticationCalls, 2);
    expect(find.text('Ledger'), findsNothing);

    secondAuthentication.complete(true);
    await tester.pumpAndSettle();
    expect(find.text('Ledger'), findsOneWidget);
  });
}
