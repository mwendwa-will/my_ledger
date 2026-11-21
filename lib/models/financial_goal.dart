class FinancialGoal {
  const FinancialGoal({
    this.id,
    required this.name,
    required this.targetAmount,
    this.currentAmount = 0,
    this.targetDate,
    this.accountId,
    this.categoryId,
  });

  factory FinancialGoal.fromMap(Map<String, dynamic> map) => FinancialGoal(
        id: map['id'] as int?,
        name: map['name'] as String,
        targetAmount: (map['target_amount'] as num).toDouble(),
        currentAmount: (map['current_amount'] as num).toDouble(),
        targetDate: map['target_date'] == null
            ? null
            : DateTime.parse(map['target_date'] as String),
        accountId: map['account_id'] as int?,
        categoryId: map['category_id'] as int?,
      );

  final int? id;
  final String name;
  final double targetAmount;
  final double currentAmount;
  final DateTime? targetDate;
  final int? accountId;
  final int? categoryId;

  double get progress => targetAmount > 0
      ? (currentAmount / targetAmount).clamp(0, 1).toDouble()
      : 0;

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'target_amount': targetAmount,
        'current_amount': currentAmount,
        'target_date': targetDate?.toIso8601String(),
        'account_id': accountId,
        'category_id': categoryId,
      };
}
