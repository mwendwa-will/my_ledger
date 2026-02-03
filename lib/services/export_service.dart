import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../models/transaction_item.dart';
import '../models/enums.dart';
import '../services/database_service.dart';

/// Service for exporting transaction data
class ExportService {
  /// Export transactions to CSV format
  static Future<String> exportToCSV({
    required List<TransactionItem> transactions,
    Map<int, String>? categoryNames,
    Map<int, String>? accountNames,
  }) async {
    final List<List<dynamic>> rows = [];

    // Header row
    rows.add([
      'Date',
      'Type',
      'Amount',
      'Account',
      'Category',
      'To Account',
      'Note',
      'Reconciled',
    ]);

    // Data rows
    for (final transaction in transactions) {
      rows.add([
        DateFormat('yyyy-MM-dd').format(transaction.date),
        _getTypeName(transaction.type),
        transaction.amount.toStringAsFixed(2),
        accountNames?[transaction.accountId] ?? 'Unknown',
        transaction.categoryId != null
            ? (categoryNames?[transaction.categoryId] ?? 'Unknown')
            : '',
        transaction.toAccountId != null
            ? (accountNames?[transaction.toAccountId] ?? 'Unknown')
            : '',
        transaction.note ?? '',
        transaction.isReconciled ? 'Yes' : 'No',
      ]);
    }

    return const ListToCsvConverter().convert(rows);
  }

  /// Save CSV to device and return file path
  static Future<String> saveCSVToDevice(String csvContent,
      {String filename = 'transactions',}) async {
    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final file = File('${directory.path}/${filename}_$timestamp.csv');
    await file.writeAsString(csvContent);
    return file.path;
  }

  /// Share CSV file
  static Future<void> shareCSV(String csvContent,
      {String filename = 'transactions',}) async {
    final directory = await getTemporaryDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final file = File('${directory.path}/${filename}_$timestamp.csv');
    await file.writeAsString(csvContent);

    await SharePlus.instance.share(ShareParams(
      files: [XFile(file.path)],
      subject: 'Transaction Export',
      text: 'Exported transactions from MyLedger',
    ),);
  }

  /// Export transactions with full details (fetches category and account names)
  static Future<String> exportTransactionsWithDetails({
    DateTime? startDate,
    DateTime? endDate,
    int? categoryId,
    int? accountId,
    String? searchQuery,
  }) async {
    // Fetch transactions
    final transactions = await DatabaseService.instance.getTransactions(
      startDate: startDate,
      endDate: endDate,
      categoryId: categoryId,
      accountId: accountId,
      searchQuery: searchQuery,
      limit: 10000, // Export all matching transactions
    );

    // Fetch all categories and accounts for name mapping
    final categories = await DatabaseService.instance.getAllCategories();
    final accounts = await DatabaseService.instance.getAllAccounts();

    final categoryMap = {for (final c in categories) c.id!: c.name};
    final accountMap = {for (final a in accounts) a.id!: a.name};

    return exportToCSV(
      transactions: transactions,
      categoryNames: categoryMap,
      accountNames: accountMap,
    );
  }

  static String _getTypeName(TransactionType type) {
    switch (type) {
      case TransactionType.income:
        return 'Income';
      case TransactionType.expense:
        return 'Expense';
      case TransactionType.transfer:
        return 'Transfer';
    }
  }
}
