import 'package:flutter/material.dart';
import '../utils/currency_helper.dart';

/// Animated balance preview showing current → new balance with color-coded arrows
class BalancePreviewCard extends StatelessWidget {
  const BalancePreviewCard({
    super.key,
    required this.currentBalance,
    required this.newBalance,
    required this.currencyCode,
    this.accountName,
  });

  final double currentBalance;
  final double newBalance;
  final String currencyCode;
  final String? accountName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final balanceDiff = newBalance - currentBalance;

    Color balanceColor;
    IconData? arrowIcon;

    if (balanceDiff < 0) {
      balanceColor = theme.colorScheme.error;
      arrowIcon = Icons.arrow_downward;
    } else if (balanceDiff > 0) {
      balanceColor = theme.colorScheme.secondary;
      arrowIcon = Icons.arrow_upward;
    } else {
      balanceColor = theme.colorScheme.onSurface.withValues(alpha: 0.6);
      arrowIcon = null;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: balanceColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: balanceColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  accountName ?? 'Current Balance',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  CurrencyHelper.format(currentBalance, currencyCode: currencyCode),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (arrowIcon != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Icon(arrowIcon, color: balanceColor, size: 20),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'New Balance',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 4),
                TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 300),
                  tween: Tween(begin: currentBalance, end: newBalance),
                  builder: (context, value, child) {
                    return Text(
                      CurrencyHelper.format(value, currencyCode: currencyCode),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: balanceColor,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Balance preview for transfer transactions showing both accounts
class TransferBalancePreview extends StatelessWidget {
  const TransferBalancePreview({
    super.key,
    required this.fromAccount,
    required this.toAccount,
    required this.amount,
    required this.currencyCode,
  });

  final String fromAccount;
  final String toAccount;
  final double amount;
  final String currencyCode;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            _buildAccountRow(
              context: context,
              label: 'From: $fromAccount',
              amount: -amount,
            ),
            const Divider(height: 16),
            _buildAccountRow(
              context: context,
              label: 'To: $toAccount',
              amount: amount,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountRow({
    required BuildContext context,
    required String label,
    required double amount,
  }) {
    final theme = Theme.of(context);
    final isDecrease = amount < 0;
    final color =
        isDecrease ? theme.colorScheme.error : theme.colorScheme.secondary;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodyMedium,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Row(
          children: [
            Icon(
              isDecrease ? Icons.remove : Icons.add,
              size: 16,
              color: color,
            ),
            const SizedBox(width: 4),
            Text(
              CurrencyHelper.format(amount.abs(), currencyCode: currencyCode),
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
