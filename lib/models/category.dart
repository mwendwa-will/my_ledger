import 'enums.dart';

class Category {
  final int? id;
  final String name;
  final TransactionType type; // Only income or expense
  final int color;
  final int iconCodePoint;
  final bool isArchived;
  final double? monthlyBudgetLimit; // Optional budget link directly in category for simplicity in v1

  Category({
    this.id,
    required this.name,
    required this.type,
    required this.color,
    required this.iconCodePoint,
    this.isArchived = false,
    this.monthlyBudgetLimit,
  });

  Category copyWith({
    int? id,
    String? name,
    TransactionType? type,
    int? color,
    int? iconCodePoint,
    bool? isArchived,
    double? monthlyBudgetLimit,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      color: color ?? this.color,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      isArchived: isArchived ?? this.isArchived,
      monthlyBudgetLimit: monthlyBudgetLimit ?? this.monthlyBudgetLimit,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type.index,
      'color': color,
      'icon_code_point': iconCodePoint,
      'is_archived': isArchived ? 1 : 0,
      'monthly_budget_limit': monthlyBudgetLimit,
    };
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'],
      name: map['name'],
      type: TransactionType.values[map['type']],
      color: map['color'],
      iconCodePoint: map['icon_code_point'],
      isArchived: map['is_archived'] == 1,
      monthlyBudgetLimit: map['monthly_budget_limit'],
    );
  }
}
