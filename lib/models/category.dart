import 'enums.dart';

class Category {
  // New field for reordering

  Category({
    this.id,
    required this.name,
    required this.type,
    required this.color,
    required this.iconCodePoint,
    this.isArchived = false,
    this.monthlyBudgetLimit,
    this.sortOrder = 0, // Default sort order
    this.parentId,
  });

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'],
      name: map['name'],
      type: TransactionType.values[map['type']],
      color: map['color'],
      iconCodePoint: map['icon_code_point'],
      isArchived: map['is_archived'] == 1,
      monthlyBudgetLimit: map['monthly_budget_limit'],
      sortOrder:
          map['sort_order'] ?? 0, // Handle existing data without sort_order
      parentId: map['parent_id'],
    );
  }
  final int? id;
  final String name;
  final TransactionType type; // Only income or expense
  final int color;
  final int iconCodePoint;
  final bool isArchived;
  final double?
      monthlyBudgetLimit; // Optional budget link directly in category for simplicity in v1
  final int sortOrder;
  final int? parentId;

  Category copyWith({
    int? id,
    String? name,
    TransactionType? type,
    int? color,
    int? iconCodePoint,
    bool? isArchived,
    double? monthlyBudgetLimit,
    int? sortOrder,
    int? parentId,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      color: color ?? this.color,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      isArchived: isArchived ?? this.isArchived,
      monthlyBudgetLimit: monthlyBudgetLimit ?? this.monthlyBudgetLimit,
      sortOrder: sortOrder ?? this.sortOrder,
      parentId: parentId ?? this.parentId,
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
      'sort_order': sortOrder,
      'parent_id': parentId,
    };
  }
}
