import 'enums.dart';

class Account {

  Account({
    this.id,
    required this.name,
    required this.type,
    required this.initialBalance,
    required this.currentBalance,
    required this.color,
    required this.iconCodePoint,
    this.isArchived = false,
  });

  factory Account.fromMap(Map<String, dynamic> map) {
    return Account(
      id: map['id'],
      name: map['name'],
      type: AccountType.values[map['type']],
      initialBalance: map['initial_balance'],
      currentBalance: map['current_balance'],
      color: map['color'],
      iconCodePoint: map['icon_code_point'],
      isArchived: map['is_archived'] == 1,
    );
  }
  final int? id;
  final String name;
  final AccountType type;
  final double initialBalance;
  final double currentBalance;
  final int color; // Store as int (0xFF...)
  final int iconCodePoint; // Store icon code point
  final bool isArchived;

  Account copyWith({
    int? id,
    String? name,
    AccountType? type,
    double? initialBalance,
    double? currentBalance,
    int? color,
    int? iconCodePoint,
    bool? isArchived,
  }) {
    return Account(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      initialBalance: initialBalance ?? this.initialBalance,
      currentBalance: currentBalance ?? this.currentBalance,
      color: color ?? this.color,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      isArchived: isArchived ?? this.isArchived,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type.index, // Store enum as int index
      'initial_balance': initialBalance,
      'current_balance': currentBalance,
      'color': color,
      'icon_code_point': iconCodePoint,
      'is_archived': isArchived ? 1 : 0,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Account) return false;
    if (id != null && other.id != null) {
      return id == other.id;
    }
    return false;
  }

  @override
  int get hashCode => id?.hashCode ?? identityHashCode(this);
}
