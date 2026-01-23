class Budget {

  Budget({
    this.id,
    required this.categoryId,
    required this.amount,
    required this.month,
    required this.year,
    this.spent,
  });

  factory Budget.fromMap(Map<String, dynamic> map) {
    return Budget(
      id: map['id'],
      categoryId: map['category_id'],
      amount: map['amount'],
      month: map['month'],
      year: map['year'],
      spent: map['spent'], // This might be injected from a join query
    );
  }
  final int? id;
  final int categoryId;
  final double amount;
  final int month; // 1-12
  final int year; // 2024, etc.
  
  // Not persisted, but useful for UI calculation
  final double? spent;

  Budget copyWith({
    int? id,
    int? categoryId,
    double? amount,
    int? month,
    int? year,
    double? spent,
  }) {
    return Budget(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      amount: amount ?? this.amount,
      month: month ?? this.month,
      year: year ?? this.year,
      spent: spent ?? this.spent,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category_id': categoryId,
      'amount': amount,
      'month': month,
      'year': year,
    };
  }
}
