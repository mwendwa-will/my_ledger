class DebtPlan {
  const DebtPlan({
    this.id,
    required this.name,
    required this.balance,
    this.annualInterestRate = 0,
    this.minimumPayment = 0,
    this.dueDay,
    this.accountId,
  });

  factory DebtPlan.fromMap(Map<String, dynamic> map) => DebtPlan(
        id: map['id'] as int?,
        name: map['name'] as String,
        balance: (map['balance'] as num).toDouble(),
        annualInterestRate: (map['annual_interest_rate'] as num).toDouble(),
        minimumPayment: (map['minimum_payment'] as num).toDouble(),
        dueDay: map['due_day'] as int?,
        accountId: map['account_id'] as int?,
      );

  final int? id;
  final String name;
  final double balance;
  final double annualInterestRate;
  final double minimumPayment;
  final int? dueDay;
  final int? accountId;

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'balance': balance,
        'annual_interest_rate': annualInterestRate,
        'minimum_payment': minimumPayment,
        'due_day': dueDay,
        'account_id': accountId,
      };
}
