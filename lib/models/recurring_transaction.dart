import 'enums.dart';

class RecurringTransaction {
  final int? id;
  final int accountId;
  final int? categoryId;
  final int? toAccountId; // For recurring transfers
  final double amount;
  final TransactionType type;
  final RecurringFrequency frequency;
  final DateTime startDate;
  final DateTime nextDueDate;
  final String? note;
  final bool isActive;

  RecurringTransaction({
    this.id,
    required this.accountId,
    this.categoryId,
    this.toAccountId,
    required this.amount,
    required this.type,
    required this.frequency,
    required this.startDate,
    required this.nextDueDate,
    this.note,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'account_id': accountId,
      'category_id': categoryId,
      'to_account_id': toAccountId,
      'amount': amount,
      'type': type.index,
      'frequency': frequency.index,
      'start_date': startDate.toIso8601String(),
      'next_due_date': nextDueDate.toIso8601String(),
      'note': note,
      'is_active': isActive ? 1 : 0,
    };
  }

  factory RecurringTransaction.fromMap(Map<String, dynamic> map) {
    return RecurringTransaction(
      id: map['id'],
      accountId: map['account_id'],
      categoryId: map['category_id'],
      toAccountId: map['to_account_id'],
      amount: map['amount'],
      type: TransactionType.values[map['type']],
      frequency: RecurringFrequency.values[map['frequency']],
      startDate: DateTime.parse(map['start_date']),
      nextDueDate: DateTime.parse(map['next_due_date']),
      note: map['note'],
      isActive: map['is_active'] == 1,
    );
  }
  
  String get frequencyDescription {
    switch (frequency) {
      case RecurringFrequency.daily: return 'Daily';
      case RecurringFrequency.weekly: return 'Weekly';
      case RecurringFrequency.biWeekly: return 'Every 2 Weeks';
      case RecurringFrequency.monthly: return 'Monthly';
      case RecurringFrequency.quarterly: return 'Quarterly';
      case RecurringFrequency.yearly: return 'Yearly';
    }
  }
}
