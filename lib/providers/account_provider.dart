import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/account.dart';
import '../services/database_service.dart';

final accountsProvider = AsyncNotifierProvider<AccountsNotifier, List<Account>>(() {
  return AccountsNotifier();
});

class AccountsNotifier extends AsyncNotifier<List<Account>> {
  @override
  Future<List<Account>> build() async {
    return DatabaseService.instance.getAllAccounts();
  }

  Future<void> addAccount(Account account) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await DatabaseService.instance.createAccount(account);
      return DatabaseService.instance.getAllAccounts();
    });
  }
  
  Future<void> updateAccount(Account account) async {
    state = await AsyncValue.guard(() async {
      await DatabaseService.instance.updateAccount(account);
      return DatabaseService.instance.getAllAccounts();
    });
  }

  Future<void> deleteAccount(int id) async {
    state = await AsyncValue.guard(() async {
      await DatabaseService.instance.deleteAccount(id);
      return DatabaseService.instance.getAllAccounts();
    });
  }
}

final totalBalanceProvider = Provider<double>((ref) {
  final accountsAsync = ref.watch(accountsProvider);
  return accountsAsync.maybeWhen(
    data: (accounts) => accounts.fold(0, (sum, account) => sum + account.currentBalance),
    orElse: () => 0.0,
  );
});

final accountMapProvider = Provider<AsyncValue<Map<int, Account>>>((ref) {
  final accountsAsync = ref.watch(accountsProvider);
  return accountsAsync.whenData((accounts) {
    return {for (final a in accounts) a.id!: a};
  });
});