enum TransactionType {
  income,
  expense,
  transfer,
}

enum AccountType {
  checking,
  savings,
  creditCard,
  cash,
  investment,
  other,
}

enum RecurringFrequency {
  daily,
  weekly,
  biWeekly,
  monthly,
  quarterly,
  yearly,
}

// Extensions to get nice strings for UI
extension TransactionTypeExtension on TransactionType {
  String get displayName {
    switch (this) {
      case TransactionType.income:
        return 'Income';
      case TransactionType.expense:
        return 'Expense';
      case TransactionType.transfer:
        return 'Transfer';
    }
  }
}

extension AccountTypeExtension on AccountType {
  String get displayName {
    switch (this) {
      case AccountType.checking:
        return 'Checking';
      case AccountType.savings:
        return 'Savings';
      case AccountType.creditCard:
        return 'Credit Card';
      case AccountType.cash:
        return 'Cash';
      case AccountType.investment:
        return 'Investment';
      case AccountType.other:
        return 'Other';
    }
  }
}
