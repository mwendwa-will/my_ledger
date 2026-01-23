import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/account_provider.dart';
import '../../providers/settings_provider.dart';
import '../../utils/constants.dart';
import '../../utils/formatters.dart';
import '../../models/enums.dart';
import '../settings/settings_screen.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(dashboardProvider);
    final totalBalance = ref.watch(totalBalanceProvider);
    final currency = ref.watch(currencySymbolProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
            },
          )
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(dashboardProvider);
          ref.invalidate(accountsProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Net Worth Card
              _buildNetWorthCard(context, totalBalance, currency),
              const SizedBox(height: 16),
              
              // Monthly Summary
              dashboardAsync.when(
                data: (data) => _buildSummaryCards(context, data, currency),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Text('Error: $err'),
              ),
              const SizedBox(height: 24),
              
              // Recent Transactions Header
              const Text(
                'Recent Transactions',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              
              // Recent Transactions List
              dashboardAsync.when(
                data: (data) => _buildRecentTransactions(context, data, currency),
                loading: () => const SizedBox.shrink(), // Already showing loader above
                error: (_, __) => const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNetWorthCard(BuildContext context, double balance, String currency) {
    return Card(
      color: AppColors.primary,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Total Balance',
              style: TextStyle(color: AppColors.onPrimary, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Text(
              Formatters.formatCurrency(balance, symbol: currency),
              style: const TextStyle(
                color: AppColors.onPrimary,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards(BuildContext context, DashboardData data, String currency) {
    return Row(
      children: [
        Expanded(
          child: _buildInfoCard(
            context,
            'Income',
            data.income,
            AppColors.income,
            Icons.arrow_downward,
            currency,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildInfoCard(
            context,
            'Expense',
            data.expense,
            AppColors.expense,
            Icons.arrow_upward,
            currency,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(
    BuildContext context, 
    String title, 
    double amount, 
    Color color, 
    IconData icon, 
    String currency
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
        border: Border.all(color: Colors.grey.withAlpha(51)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 4),
              Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            Formatters.formatCurrency(amount, symbol: currency),
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTransactions(BuildContext context, DashboardData data, String currency) {
    if (data.recentTransactions.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        alignment: Alignment.center,
        child: const Text('No transactions yet. Tap + to add one!'),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: data.recentTransactions.length,
      itemBuilder: (context, index) {
        final tx = data.recentTransactions[index];
        final isExpense = tx.type == TransactionType.expense;
        final color = isExpense ? AppColors.expense : (tx.type == TransactionType.income ? AppColors.income : AppColors.transfer);
        
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: color.withAlpha(26),
              child: Icon(
                _getIconForType(tx.type),
                color: color,
                size: 20,
              ),
            ),
            title: Text(tx.note?.isNotEmpty == true ? tx.note! : 'Transaction'),
            subtitle: Text(Formatters.formatShortDate(tx.date)),
            trailing: Text(
              '${isExpense ? "-" : "+"}${Formatters.formatCurrency(tx.amount, symbol: currency)}',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      },
    );
  }

  IconData _getIconForType(TransactionType type) {
    switch (type) {
      case TransactionType.income: return Icons.arrow_downward;
      case TransactionType.expense: return Icons.arrow_upward;
      case TransactionType.transfer: return Icons.swap_horiz;
    }
  }
}
