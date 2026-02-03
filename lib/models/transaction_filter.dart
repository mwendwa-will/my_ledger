import 'enums.dart';

/// Filter model for transaction queries
class TransactionFilter {
  const TransactionFilter({
    this.startDate,
    this.endDate,
    this.minAmount,
    this.maxAmount,
    this.categoryIds,
    this.accountIds,
    this.transactionTypes,
    this.searchQuery,
    this.sortBy = TransactionSortBy.dateDesc,
  });

  final DateTime? startDate;
  final DateTime? endDate;
  final double? minAmount;
  final double? maxAmount;
  final List<int>? categoryIds;
  final List<int>? accountIds;
  final List<TransactionType>? transactionTypes;
  final String? searchQuery;
  final TransactionSortBy sortBy;

  /// Check if any filters are active
  bool get hasActiveFilters {
    return startDate != null ||
        endDate != null ||
        minAmount != null ||
        maxAmount != null ||
        (categoryIds != null && categoryIds!.isNotEmpty) ||
        (accountIds != null && accountIds!.isNotEmpty) ||
        (transactionTypes != null && transactionTypes!.isNotEmpty) ||
        (searchQuery != null && searchQuery!.isNotEmpty);
  }

  /// Count of active filters
  int get activeFilterCount {
    int count = 0;
    if (startDate != null || endDate != null) count++;
    if (minAmount != null || maxAmount != null) count++;
    if (categoryIds != null && categoryIds!.isNotEmpty) count++;
    if (accountIds != null && accountIds!.isNotEmpty) count++;
    if (transactionTypes != null && transactionTypes!.isNotEmpty) count++;
    if (searchQuery != null && searchQuery!.isNotEmpty) count++;
    return count;
  }

  TransactionFilter copyWith({
    DateTime? startDate,
    DateTime? endDate,
    double? minAmount,
    double? maxAmount,
    List<int>? categoryIds,
    List<int>? accountIds,
    List<TransactionType>? transactionTypes,
    String? searchQuery,
    TransactionSortBy? sortBy,
  }) {
    return TransactionFilter(
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      minAmount: minAmount ?? this.minAmount,
      maxAmount: maxAmount ?? this.maxAmount,
      categoryIds: categoryIds ?? this.categoryIds,
      accountIds: accountIds ?? this.accountIds,
      transactionTypes: transactionTypes ?? this.transactionTypes,
      searchQuery: searchQuery ?? this.searchQuery,
      sortBy: sortBy ?? this.sortBy,
    );
  }

  /// Clear all filters
  TransactionFilter clear() {
    return const TransactionFilter();
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TransactionFilter &&
        other.startDate == startDate &&
        other.endDate == endDate &&
        other.minAmount == minAmount &&
        other.maxAmount == maxAmount &&
        _listEquals(other.categoryIds, categoryIds) &&
        _listEquals(other.accountIds, accountIds) &&
        _listEquals(other.transactionTypes, transactionTypes) &&
        other.searchQuery == searchQuery &&
        other.sortBy == sortBy;
  }

  bool _listEquals<T>(List<T>? a, List<T>? b) {
    if (a == null) return b == null;
    if (b == null || a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode {
    return Object.hash(
      startDate,
      endDate,
      minAmount,
      maxAmount,
      Object.hashAll(categoryIds ?? []),
      Object.hashAll(accountIds ?? []),
      Object.hashAll(transactionTypes ?? []),
      searchQuery,
      sortBy,
    );
  }
}

/// Sort options for transactions
enum TransactionSortBy {
  dateDesc('Date (Newest First)'),
  dateAsc('Date (Oldest First)'),
  amountDesc('Amount (Highest First)'),
  amountAsc('Amount (Lowest First)'),
  categoryAsc('Category (A-Z)'),
  categoryDesc('Category (Z-A)');

  const TransactionSortBy(this.label);
  final String label;
}
