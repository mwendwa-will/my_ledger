import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/account.dart';
import '../services/database_service.dart';

final accountsProvider =
    AsyncNotifierProvider<AccountsNotifier, List<Account>>(() {
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

  Future<void> deleteAccount(int accountId, {int? reassignToAccountId}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final transactionCount =
          await DatabaseService.instance.countTransactionsForAccount(accountId);

      if (transactionCount > 0 && reassignToAccountId == null) {
        throw Exception('Account has $transactionCount transactions. '
            'Cannot delete without reassigning.');
      }

      await DatabaseService.instance.deleteAccount(
        accountId,
        reassignToAccountId: reassignToAccountId,
      );
      return DatabaseService.instance.getAllAccounts();
    });
  }

  Future<void> archiveAccount(int accountId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final account = await DatabaseService.instance.getAccount(accountId);
      if (account == null) {
        throw Exception('Account not found');
      }
      final updated = account.copyWith(isArchived: true);
      await DatabaseService.instance.updateAccount(updated);
      return DatabaseService.instance.getAllAccounts();
    });
  }

  Future<void> unarchiveAccount(int accountId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final account = await DatabaseService.instance.getAccount(accountId);
      if (account == null) {
        throw Exception('Account not found');
      }
      final updated = account.copyWith(isArchived: false);
      await DatabaseService.instance.updateAccount(updated);
      return DatabaseService.instance.getAllAccounts();
    });
  }
}

final activeAccountsProvider = Provider<AsyncValue<List<Account>>>((ref) {
  final accountsAsync = ref.watch(accountsProvider);
  return accountsAsync.whenData((accounts) {
    return accounts.where((account) => !account.isArchived).toList();
  });
});

final totalBalanceProvider = Provider<double>((ref) {
  final accountsAsync = ref.watch(accountsProvider);
  return accountsAsync.maybeWhen(
    data: (accounts) => accounts
        .where((account) => !account.isArchived)
        .fold(0, (sum, account) => sum + account.currentBalance),
    orElse: () => 0.0,
  );
});

final accountMapProvider = Provider<AsyncValue<Map<int, Account>>>((ref) {
  final accountsAsync = ref.watch(accountsProvider);
  return accountsAsync.whenData((accounts) {
    return {for (final a in accounts) a.id!: a};
  });
});
