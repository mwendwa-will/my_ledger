import 'package:csv/csv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_ledger/models/enums.dart';
import 'package:my_ledger/models/transaction_item.dart';
import 'package:my_ledger/services/export_service.dart';

void main() {
  test('CSV export neutralizes formula-leading user-controlled text', () async {
    final csv = await ExportService.exportToCSV(
      transactions: [
        TransactionItem(
          accountId: 1,
          categoryId: 2,
          amount: 12,
          type: TransactionType.expense,
          date: DateTime(2025, 1, 2),
          note: ' \t=HYPERLINK("https://example.invalid")',
        ),
      ],
      accountNames: {1: '+SUM(1,2)'},
      categoryNames: {2: 'Groceries'},
    );

    final rows = const CsvToListConverter().convert(csv);
    expect(rows[1][3], "'+SUM(1,2)");
    expect(rows[1][6], "' \t=HYPERLINK(\"https://example.invalid\")");
    expect(rows[1][4], 'Groceries');
  });

  test('CSV export leaves ordinary negative numbers numeric', () async {
    final csv = await ExportService.exportToCSV(
      transactions: [
        TransactionItem(
          accountId: 1,
          amount: -12,
          type: TransactionType.expense,
          date: DateTime(2025, 1, 2),
        ),
      ],
    );

    final rows = const CsvToListConverter().convert(csv);
    expect(rows[1][2], -12.0);
  });

  test('CSV export neutralizes formula markers after a BOM', () async {
    final csv = await ExportService.exportToCSV(
      transactions: [
        TransactionItem(
          accountId: 1,
          amount: 12,
          type: TransactionType.expense,
          date: DateTime(2025, 1, 2),
        ),
      ],
      accountNames: {1: '\uFEFF@SUM(1,2)'},
    );

    final rows = const CsvToListConverter().convert(csv);
    expect(rows[1][3], "'\uFEFF@SUM(1,2)");
  });
}
