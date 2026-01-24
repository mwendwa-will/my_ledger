import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_ledger/utils/icon_helper.dart';
import '../../providers/account_provider.dart';
import '../../providers/settings_provider.dart';
import '../../utils/constants.dart';
import '../../utils/formatters.dart';
import 'add_account_screen.dart';

class AccountsScreen extends ConsumerWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountsAsync = ref.watch(accountsProvider);
    final currency = ref.watch(currencySymbolProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Accounts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddAccountScreen()),
              );
            },
          ),
        ],
      ),
      body: accountsAsync.when(
        data: (accounts) {
          if (accounts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                    Icon(Icons.account_balance_wallet_outlined, size: 64, color: Theme.of(context).colorScheme.onSurface.withAlpha((0.5 * 255).round())),
                    Text('No accounts yet', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Theme.of(context).colorScheme.onSurface.withAlpha((0.65 * 255).round()), fontSize: 18)),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AddAccountScreen()),
                      );
                    },
                    child: const Text('Add Your First Account'),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            itemCount: accounts.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final account = accounts[index];
              return Dismissible(
                key: Key('account_${account.id}'),
                direction: DismissDirection.endToStart,
                confirmDismiss: (direction) async {
                  return showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Delete Account?'),
                      content: Text('Are you sure you want to delete "${account.name}"? This action cannot be undone.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(true),
                          style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  );
                },
                onDismissed: (direction) async {
                  final messenger = ScaffoldMessenger.of(context);
                  try {
                    await ref.read(accountsProvider.notifier).deleteAccount(account.id!);
                    messenger.showSnackBar(const SnackBar(content: Text('Account deleted')));
                  } catch (e) {
                    final _ = ref.refresh(accountsProvider);
                    messenger.showSnackBar(SnackBar(content: Text('Cannot delete: ${e.toString().replaceAll("Exception: ", "")}')));
                  }
                },
                background: Container(
                  color: Theme.of(context).colorScheme.error,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  child: Icon(Icons.delete, color: Theme.of(context).colorScheme.onError),
                ),
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: Builder(builder: (ctx) {
                      final col = Color(account.color);
                      return CircleAvatar(
                        backgroundColor: col.withAlpha((0.2 * 255).round()),
                        child: Icon(getIconFromCodePoint(account.iconCodePoint), color: col),
                      );
                    },),
                    title: Text(account.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(account.type.name.toUpperCase()), // Simplified enum display
                      trailing: Text(
                      Formatters.formatCurrency(account.currentBalance, symbol: currency),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => AddAccountScreen(accountToEdit: account)),
                      );
                    },
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }
}