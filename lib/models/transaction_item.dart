import 'enums.dart';

class TransactionItem {
  final int? id;
  final int accountId;
  final int? categoryId; // Nullable for transfers
  final int? toAccountId; // Only for transfers
  final double amount;
  final TransactionType type;
  final DateTime date;
  final String? note;
  final String? imagePath; // Local path to receipt image
  final bool isReconciled;
  
  // For transfers: link the two transactions (withdrawal and deposit)
  // For splits: link to parent transaction
  final int? relatedTransactionId; 

  TransactionItem({
    this.id,
    required this.accountId,
    this.categoryId,
    this.toAccountId,
    required this.amount,
    required this.type,
    required this.date,
    this.note,
    this.imagePath,
    this.isReconciled = false,
    this.relatedTransactionId,
  });

  TransactionItem copyWith({
    int? id,
    int? accountId,
    int? categoryId,
    int? toAccountId,
    double? amount,
    TransactionType? type,
    DateTime? date,
    String? note,
    String? imagePath,
    bool? isReconciled,
    int? relatedTransactionId,
  }) {
    return TransactionItem(
      id: id ?? this.id,
      accountId: accountId ?? this.accountId,
      categoryId: categoryId ?? this.categoryId,
      toAccountId: toAccountId ?? this.toAccountId,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      date: date ?? this.date,
      note: note ?? this.note,
      imagePath: imagePath ?? this.imagePath,
      isReconciled: isReconciled ?? this.isReconciled,
      relatedTransactionId: relatedTransactionId ?? this.relatedTransactionId,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'account_id': accountId,
      'category_id': categoryId,
      'to_account_id': toAccountId,
      'amount': amount,
      'type': type.index,
      'date': date.toIso8601String(), // Store as ISO string
      'note': note,
      'image_path': imagePath,
      'is_reconciled': isReconciled ? 1 : 0,
      'related_transaction_id': relatedTransactionId,
    };
  }

  factory TransactionItem.fromMap(Map<String, dynamic> map) {
    return TransactionItem(
      id: map['id'],
      accountId: map['account_id'],
      categoryId: map['category_id'],
      toAccountId: map['to_account_id'],
      amount: map['amount'],
      type: TransactionType.values[map['type']],
      date: DateTime.parse(map['date']),
      note: map['note'],
      imagePath: map['image_path'],
      isReconciled: map['is_reconciled'] == 1,
      relatedTransactionId: map['related_transaction_id'],
    );
  }
}
