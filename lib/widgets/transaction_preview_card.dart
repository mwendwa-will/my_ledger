import 'package:flutter/material.dart';
import '../models/enums.dart';
import '../utils/currency_helper.dart';

/// Summary card showing all transaction details before saving
class TransactionPreviewCard extends StatelessWidget {
  const TransactionPreviewCard({
    super.key,
    required this.type,
    required this.amount,
    required this.currencyCode,
    required this.date,
    this.accountName,
    this.toAccountName,
    this.categoryName,
    this.note,
    this.newBalance,
  });

  final TransactionType type;
  final double amount;
  final String currencyCode;
  final DateTime date;
  final String? accountName;
  final String? toAccountName;
  final String? categoryName;
  final String? note;
  final double? newBalance;

  IconData _getTransactionTypeIcon() {
    switch (type) {
      case TransactionType.expense:
        return Icons.money_off;
      case TransactionType.income:
        return Icons.attach_money;
      case TransactionType.transfer:
        return Icons.swap_horiz;
    }
  }

  String _getDayOfWeek(DateTime date) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[date.weekday - 1];
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getTransactionTypeIcon(),
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Transaction Preview',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const Divider(height: 16),
            _buildPreviewRow(
              context,
              'Type',
              _capitalize(type.toString().split('.').last),
            ),
            if (categoryName != null)
              _buildPreviewRow(context, 'Category', categoryName!),
            _buildPreviewRow(
              context,
              'Amount',
              CurrencyHelper.format(amount, currencyCode: currencyCode),
              isBold: true,
            ),
            if (accountName != null)
              _buildPreviewRow(context, 'From Account', accountName!),
            if (toAccountName != null)
              _buildPreviewRow(context, 'To Account', toAccountName!),
            _buildPreviewRow(
              context,
              'Date',
              '${_getDayOfWeek(date)}, ${date.toLocal().toString().split(' ')[0]}',
            ),
            if (note != null && note!.isNotEmpty)
              _buildPreviewRow(context, 'Note', note!),
            if (newBalance != null) ...[
              const Divider(height: 16),
              _buildPreviewRow(
                context,
                'New Balance',
                CurrencyHelper.format(newBalance!, currencyCode: currencyCode),
                isBold: true,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewRow(
    BuildContext context,
    String label,
    String value, {
    bool isBold = false,
  }) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(width: 16),
          Flexible(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}
