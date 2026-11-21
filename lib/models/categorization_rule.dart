class CategorizationRule {
  const CategorizationRule({
    this.id,
    required this.matchText,
    required this.categoryId,
    this.isActive = true,
  });

  factory CategorizationRule.fromMap(Map<String, dynamic> map) =>
      CategorizationRule(
        id: map['id'] as int?,
        matchText: map['match_text'] as String,
        categoryId: map['category_id'] as int,
        isActive: map['is_active'] == 1,
      );

  final int? id;
  final String matchText;
  final int categoryId;
  final bool isActive;

  Map<String, dynamic> toMap() => {
        'id': id,
        'match_text': matchText,
        'category_id': categoryId,
        'is_active': isActive ? 1 : 0,
      };
}
