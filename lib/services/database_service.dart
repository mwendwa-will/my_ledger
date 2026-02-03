import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/account.dart';
import '../models/category.dart';
import '../models/transaction_item.dart';
import '../models/budget.dart';
import '../models/enums.dart';
import '../utils/constants.dart';

class DatabaseService {
  DatabaseService._init();
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB(AppConstants.dbName);
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onConfigure: _onConfigure,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    // Migration to add `sort_order` column to categories (version 2)
    if (oldVersion < 2) {
      try {
        await db.execute(
          'ALTER TABLE categories ADD COLUMN sort_order INTEGER NOT NULL DEFAULT 0',
        );
      } catch (e) {
        // If the column already exists or another error occurs, ignore to avoid crashing upgrades
      }
    }
  }

  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _createDB(Database db, int version) async {
    // Accounts
    await db.execute('''
      CREATE TABLE accounts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        type INTEGER NOT NULL,
        initial_balance REAL NOT NULL,
        current_balance REAL NOT NULL,
        color INTEGER NOT NULL,
        icon_code_point INTEGER NOT NULL,
        is_archived INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // Categories
    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        type INTEGER NOT NULL,
        color INTEGER NOT NULL,
        icon_code_point INTEGER NOT NULL,
        is_archived INTEGER NOT NULL DEFAULT 0,
        monthly_budget_limit REAL,
        sort_order INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // Transactions
    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        account_id INTEGER NOT NULL,
        category_id INTEGER,
        to_account_id INTEGER,
        amount REAL NOT NULL,
        type INTEGER NOT NULL,
        date TEXT NOT NULL,
        note TEXT,
        image_path TEXT,
        is_reconciled INTEGER NOT NULL DEFAULT 0,
        related_transaction_id INTEGER,
        FOREIGN KEY (account_id) REFERENCES accounts (id) ON DELETE RESTRICT,
        FOREIGN KEY (to_account_id) REFERENCES accounts (id) ON DELETE RESTRICT,
        FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE RESTRICT
      )
    ''');

    // Tags
    await db.execute('''
      CREATE TABLE tags (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        color INTEGER NOT NULL
      )
    ''');

    // Transaction Tags (Many-to-Many)
    await db.execute('''
      CREATE TABLE transaction_tags (
        transaction_id INTEGER NOT NULL,
        tag_id INTEGER NOT NULL,
        PRIMARY KEY (transaction_id, tag_id),
        FOREIGN KEY (transaction_id) REFERENCES transactions (id) ON DELETE CASCADE,
        FOREIGN KEY (tag_id) REFERENCES tags (id) ON DELETE CASCADE
      )
    ''');

    // Budgets
    await db.execute('''
      CREATE TABLE budgets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category_id INTEGER NOT NULL,
        amount REAL NOT NULL,
        month INTEGER NOT NULL,
        year INTEGER NOT NULL,
        FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE CASCADE
      )
    ''');

    // Recurring Transactions
    await db.execute('''
      CREATE TABLE recurring_transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        account_id INTEGER NOT NULL,
        category_id INTEGER,
        to_account_id INTEGER,
        amount REAL NOT NULL,
        type INTEGER NOT NULL,
        frequency INTEGER NOT NULL,
        start_date TEXT NOT NULL,
        next_due_date TEXT NOT NULL,
        note TEXT,
        is_active INTEGER NOT NULL DEFAULT 1,
        FOREIGN KEY (account_id) REFERENCES accounts (id) ON DELETE RESTRICT,
        FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE RESTRICT
      )
    ''');

    // Seed default categories
    await _seedCategories(db);
  }

  Future<void> _seedCategories(Database db) async {
    final List<Map<String, dynamic>> defs = [
      {
        'name': 'Groceries',
        'type': TransactionType.expense,
        'iconKey': 'Groceries',
      },
      {'name': 'Rent', 'type': TransactionType.expense, 'iconKey': 'Rent'},
      {
        'name': 'Utilities',
        'type': TransactionType.expense,
        'iconKey': 'Utilities',
      },
      {'name': 'Dining', 'type': TransactionType.expense, 'iconKey': 'Dining'},
      {
        'name': 'Transportation',
        'type': TransactionType.expense,
        'iconKey': 'Transportation',
      },
      {
        'name': 'Entertainment',
        'type': TransactionType.expense,
        'iconKey': 'Entertainment',
      },
      {
        'name': 'Healthcare',
        'type': TransactionType.expense,
        'iconKey': 'Healthcare',
      },
      {
        'name': 'Shopping',
        'type': TransactionType.expense,
        'iconKey': 'Shopping',
      },
      {'name': 'Salary', 'type': TransactionType.income, 'iconKey': 'Salary'},
      {
        'name': 'Freelance',
        'type': TransactionType.income,
        'iconKey': 'Freelance',
      },
      {
        'name': 'Investments',
        'type': TransactionType.income,
        'iconKey': 'Investments',
      },
    ];

    for (int i = 0; i < defs.length; i++) {
      final def = defs[i];
      final category = Category(
        name: def['name'] as String,
        type: def['type'] as TransactionType,
        color: AppConstants.defaultCategoryColors[
            i % AppConstants.defaultCategoryColors.length],
        iconCodePoint:
            AppConstants.defaultCategoryIcons[def['iconKey'] as String]!,
        sortOrder: i,
      );
      await db.insert('categories', category.toMap());
    }
  }

  // --- ACCOUNTS ---

  Future<int> createAccount(Account account) async {
    final db = await instance.database;
    return await db.insert('accounts', account.toMap());
  }

  Future<Account?> getAccount(int id) async {
    final db = await instance.database;
    final maps = await db.query('accounts', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) {
      return Account.fromMap(maps.first);
    }
    return null;
  }

  Future<List<Account>> getAllAccounts() async {
    final db = await instance.database;
    final result = await db.query('accounts', orderBy: 'id ASC');
    return result.map((json) => Account.fromMap(json)).toList();
  }

  Future<int> updateAccount(Account account) async {
    final db = await instance.database;
    return await db.update(
      'accounts',
      account.toMap(),
      where: 'id = ?',
      whereArgs: [account.id],
    );
  }

  Future<int> deleteAccount(int id, {int? reassignToAccountId}) async {
    final db = await instance.database;
    return await db.transaction((txn) async {
      // Check if account has transactions
      final count = Sqflite.firstIntValue(
        await txn.rawQuery(
          'SELECT COUNT(*) FROM transactions WHERE account_id = ? OR to_account_id = ?',
          [id, id],
        ),
      );

      if (count != null && count > 0) {
        if (reassignToAccountId == null) {
          throw Exception(
            'Account has $count transactions. Cannot delete without reassigning.',
          );
        }

        // Reassign transactions to another account
        // Update source account transactions
        await txn.rawUpdate(
          'UPDATE transactions SET account_id = ? WHERE account_id = ?',
          [reassignToAccountId, id],
        );

        // Update destination account transactions (for transfers)
        await txn.rawUpdate(
          'UPDATE transactions SET to_account_id = ? WHERE to_account_id = ?',
          [reassignToAccountId, id],
        );

        // Transfer the balance to the reassignment account
        final accountMaps =
            await txn.query('accounts', where: 'id = ?', whereArgs: [id]);
        if (accountMaps.isNotEmpty) {
          final account = Account.fromMap(accountMaps.first);
          await txn.rawUpdate(
            'UPDATE accounts SET current_balance = current_balance + ? WHERE id = ?',
            [account.currentBalance, reassignToAccountId],
          );
        }
      }

      // Delete the account
      return await txn.delete('accounts', where: 'id = ?', whereArgs: [id]);
    });
  }

  Future<int> countTransactionsForAccount(int accountId) async {
    final db = await instance.database;
    final count = Sqflite.firstIntValue(
      await db.rawQuery(
        'SELECT COUNT(*) FROM transactions WHERE account_id = ? OR to_account_id = ?',
        [accountId, accountId],
      ),
    );
    return count ?? 0;
  }

  // --- CATEGORIES ---

  Future<int> createCategory(Category category) async {
    final db = await instance.database;
    return await db.insert('categories', category.toMap());
  }

  Future<Category?> getCategory(int id) async {
    final db = await instance.database;
    final maps = await db.query('categories', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) {
      return Category.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateCategory(Category category) async {
    final db = await instance.database;
    return await db.update(
      'categories',
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  Future<List<Category>> getAllCategories() async {
    final db = await instance.database;
    final result =
        await db.query('categories', orderBy: 'sort_order ASC, name ASC');
    return result.map((json) => Category.fromMap(json)).toList();
  }

  Future<List<Category>> getCategoriesByType(TransactionType type) async {
    final db = await instance.database;
    final result = await db.query(
      'categories',
      where: 'type = ?',
      whereArgs: [type.index],
      orderBy: 'sort_order ASC, name ASC',
    );
    return result.map((json) => Category.fromMap(json)).toList();
  }

  Future<void> updateCategoryOrder(List<Category> categories) async {
    final db = await instance.database;
    await db.transaction((txn) async {
      for (int i = 0; i < categories.length; i++) {
        await txn.update(
          'categories',
          {'sort_order': i},
          where: 'id = ?',
          whereArgs: [categories[i].id],
        );
      }
    });
  }

  Future<int> deleteCategory(int id, {int? reassignToCategoryId}) async {
    final db = await instance.database;
    return await db.transaction((txn) async {
      // 1. Delete associated budgets
      await txn.delete('budgets', where: 'category_id = ?', whereArgs: [id]);

      // 2. Handle associated transactions
      if (reassignToCategoryId != null) {
        await txn.rawUpdate(
          'UPDATE transactions SET category_id = ? WHERE category_id = ?',
          [reassignToCategoryId, id],
        );
      } else {
        // Mark as uncategorized
        await txn.rawUpdate(
          'UPDATE transactions SET category_id = NULL WHERE category_id = ?',
          [id],
        );
      }

      // 3. Delete the category itself
      return await txn.delete('categories', where: 'id = ?', whereArgs: [id]);
    });
  }

  Future<int> countTransactionsForCategory(int categoryId) async {
    final db = await instance.database;
    final count = Sqflite.firstIntValue(
      await db.rawQuery(
        'SELECT COUNT(*) FROM transactions WHERE category_id = ?',
        [categoryId],
      ),
    );
    return count ?? 0;
  }

  Future<int> getTotalTransactionCount() async {
    final db = await instance.database;
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM transactions'),
    );
    return count ?? 0;
  }

  // --- TRANSACTIONS ---

  Future<int> createTransaction(TransactionItem transaction) async {
    final db = await instance.database;
    return await db.transaction((txn) async {
      final int id = await txn.insert('transactions', transaction.toMap());

      // Update Account Balance
      if (transaction.type == TransactionType.income) {
        await txn.rawUpdate(
          'UPDATE accounts SET current_balance = current_balance + ? WHERE id = ?',
          [transaction.amount, transaction.accountId],
        );
      } else if (transaction.type == TransactionType.expense) {
        await txn.rawUpdate(
          'UPDATE accounts SET current_balance = current_balance - ? WHERE id = ?',
          [transaction.amount, transaction.accountId],
        );
      } else if (transaction.type == TransactionType.transfer) {
        // Deduct from source
        await txn.rawUpdate(
          'UPDATE accounts SET current_balance = current_balance - ? WHERE id = ?',
          [transaction.amount, transaction.accountId],
        );
        // Add to destination
        if (transaction.toAccountId != null) {
          await txn.rawUpdate(
            'UPDATE accounts SET current_balance = current_balance + ? WHERE id = ?',
            [transaction.amount, transaction.toAccountId],
          );
        }
      }
      return id;
    });
  }

  Future<List<TransactionItem>> getTransactions({
    DateTime? startDate,
    DateTime? endDate,
    int? categoryId,
    int? accountId,
    String? searchQuery,
    int limit = 100,
    int offset = 0,
  }) async {
    final db = await instance.database;

    String whereClause = '1=1';
    final List<dynamic> args = [];

    if (startDate != null) {
      whereClause += ' AND date >= ?';
      args.add(startDate.toIso8601String());
    }
    if (endDate != null) {
      whereClause += ' AND date <= ?';
      args.add(endDate.toIso8601String());
    }
    if (categoryId != null) {
      whereClause += ' AND category_id = ?';
      args.add(categoryId);
    }
    if (accountId != null) {
      whereClause += ' AND (account_id = ? OR to_account_id = ?)';
      args.add(accountId);
      args.add(accountId);
    }
    if (searchQuery != null && searchQuery.isNotEmpty) {
      whereClause += ''' AND (
        note LIKE ? OR 
        CAST(amount AS TEXT) LIKE ? OR
        category_id IN (SELECT id FROM categories WHERE name LIKE ?) OR
        account_id IN (SELECT id FROM accounts WHERE name LIKE ?)
      )''';
      final searchPattern = '%$searchQuery%';
      args.addAll([searchPattern, searchPattern, searchPattern, searchPattern]);
    }

    final result = await db.query(
      'transactions',
      where: whereClause,
      whereArgs: args,
      orderBy: 'date DESC, id DESC',
      limit: limit,
      offset: offset,
    );

    return result.map((json) => TransactionItem.fromMap(json)).toList();
  }

  /// Enhanced transaction query with advanced filtering
  Future<List<TransactionItem>> getTransactionsFiltered({
    DateTime? startDate,
    DateTime? endDate,
    double? minAmount,
    double? maxAmount,
    List<int>? categoryIds,
    List<int>? accountIds,
    List<int>? transactionTypes,
    String? searchQuery,
    String orderBy = 'date DESC, id DESC',
    int limit = 100,
    int offset = 0,
  }) async {
    final db = await instance.database;

    String whereClause = '1=1';
    final List<dynamic> args = [];

    // Date range
    if (startDate != null) {
      whereClause += ' AND date >= ?';
      args.add(startDate.toIso8601String());
    }
    if (endDate != null) {
      whereClause += ' AND date <= ?';
      args.add(endDate.toIso8601String());
    }

    // Amount range
    if (minAmount != null) {
      whereClause += ' AND amount >= ?';
      args.add(minAmount);
    }
    if (maxAmount != null) {
      whereClause += ' AND amount <= ?';
      args.add(maxAmount);
    }

    // Multiple categories
    if (categoryIds != null && categoryIds.isNotEmpty) {
      final placeholders = List.filled(categoryIds.length, '?').join(',');
      whereClause += ' AND category_id IN ($placeholders)';
      args.addAll(categoryIds);
    }

    // Multiple accounts
    if (accountIds != null && accountIds.isNotEmpty) {
      final placeholders = List.filled(accountIds.length, '?').join(',');
      whereClause +=
          ' AND (account_id IN ($placeholders) OR to_account_id IN ($placeholders))';
      args.addAll(accountIds);
      args.addAll(accountIds);
    }

    // Transaction types
    if (transactionTypes != null && transactionTypes.isNotEmpty) {
      final placeholders = List.filled(transactionTypes.length, '?').join(',');
      whereClause += ' AND type IN ($placeholders)';
      args.addAll(transactionTypes);
    }

    // Enhanced search
    if (searchQuery != null && searchQuery.isNotEmpty) {
      whereClause += ''' AND (
        note LIKE ? OR 
        CAST(amount AS TEXT) LIKE ? OR
        category_id IN (SELECT id FROM categories WHERE name LIKE ?) OR
        account_id IN (SELECT id FROM accounts WHERE name LIKE ?)
      )''';
      final searchPattern = '%$searchQuery%';
      args.addAll([searchPattern, searchPattern, searchPattern, searchPattern]);
    }

    final result = await db.query(
      'transactions',
      where: whereClause,
      whereArgs: args,
      orderBy: orderBy,
      limit: limit,
      offset: offset,
    );

    return result.map((json) => TransactionItem.fromMap(json)).toList();
  }

  Future<void> deleteTransaction(int id) async {
    final db = await instance.database;
    final tx = await db.query('transactions', where: 'id = ?', whereArgs: [id]);
    if (tx.isEmpty) return;

    final transaction = TransactionItem.fromMap(tx.first);

    await db.transaction((txn) async {
      // Revert Balance
      if (transaction.type == TransactionType.income) {
        await txn.rawUpdate(
          'UPDATE accounts SET current_balance = current_balance - ? WHERE id = ?',
          [transaction.amount, transaction.accountId],
        );
      } else if (transaction.type == TransactionType.expense) {
        await txn.rawUpdate(
          'UPDATE accounts SET current_balance = current_balance + ? WHERE id = ?',
          [transaction.amount, transaction.accountId],
        );
      } else if (transaction.type == TransactionType.transfer) {
        await txn.rawUpdate(
          'UPDATE accounts SET current_balance = current_balance + ? WHERE id = ?',
          [transaction.amount, transaction.accountId],
        );
        if (transaction.toAccountId != null) {
          await txn.rawUpdate(
            'UPDATE accounts SET current_balance = current_balance - ? WHERE id = ?',
            [transaction.amount, transaction.toAccountId],
          );
        }
      }

      await txn.delete('transactions', where: 'id = ?', whereArgs: [id]);
    });
  }

  Future<int> updateTransaction(TransactionItem transaction) async {
    final db = await instance.database;
    return await db.transaction((txn) async {
      final maps = await txn
          .query('transactions', where: 'id = ?', whereArgs: [transaction.id]);
      if (maps.isEmpty) throw Exception('Transaction not found');
      final old = TransactionItem.fromMap(maps.first);

      // Revert old transaction effect on balances
      if (old.type == TransactionType.income) {
        await txn.rawUpdate(
          'UPDATE accounts SET current_balance = current_balance - ? WHERE id = ?',
          [old.amount, old.accountId],
        );
      } else if (old.type == TransactionType.expense) {
        await txn.rawUpdate(
          'UPDATE accounts SET current_balance = current_balance + ? WHERE id = ?',
          [old.amount, old.accountId],
        );
      } else if (old.type == TransactionType.transfer) {
        await txn.rawUpdate(
          'UPDATE accounts SET current_balance = current_balance + ? WHERE id = ?',
          [old.amount, old.accountId],
        );
        if (old.toAccountId != null) {
          await txn.rawUpdate(
            'UPDATE accounts SET current_balance = current_balance - ? WHERE id = ?',
            [old.amount, old.toAccountId],
          );
        }
      }

      // Apply new transaction effect on balances
      if (transaction.type == TransactionType.income) {
        await txn.rawUpdate(
          'UPDATE accounts SET current_balance = current_balance + ? WHERE id = ?',
          [transaction.amount, transaction.accountId],
        );
      } else if (transaction.type == TransactionType.expense) {
        await txn.rawUpdate(
          'UPDATE accounts SET current_balance = current_balance - ? WHERE id = ?',
          [transaction.amount, transaction.accountId],
        );
      } else if (transaction.type == TransactionType.transfer) {
        await txn.rawUpdate(
          'UPDATE accounts SET current_balance = current_balance - ? WHERE id = ?',
          [transaction.amount, transaction.accountId],
        );
        if (transaction.toAccountId != null) {
          await txn.rawUpdate(
            'UPDATE accounts SET current_balance = current_balance + ? WHERE id = ?',
            [transaction.amount, transaction.toAccountId],
          );
        }
      }

      await txn.update(
        'transactions',
        transaction.toMap(),
        where: 'id = ?',
        whereArgs: [transaction.id],
      );
      return transaction.id ?? -1;
    });
  }

  // --- BUDGETS ---

  Future<List<Budget>> getBudgetsForMonth(int month, int year) async {
    final db = await instance.database;
    // Get budgets
    final budgetsResult = await db.query(
      'budgets',
      where: 'month = ? AND year = ?',
      whereArgs: [month, year],
    );
    final List<Budget> budgets =
        budgetsResult.map((e) => Budget.fromMap(e)).toList();

    // Calculate spent amount for each budget
    // This is a naive loop, but okay for typical number of categories (10-20)
    final List<Budget> result = [];
    for (final b in budgets) {
      final sumResult = await db.rawQuery('''
        SELECT SUM(amount) as total 
        FROM transactions 
        WHERE category_id = ? 
        AND type = ? 
        AND strftime('%m', date) = ? 
        AND strftime('%Y', date) = ?
      ''', [
        b.categoryId,
        TransactionType.expense.index,
        month.toString().padLeft(2, '0'),
        year.toString(),
      ]);

      double spent = 0;
      final totalVal = sumResult.first['total'];
      if (totalVal != null) {
        spent = (totalVal as num).toDouble();
      }
      result.add(b.copyWith(spent: spent));
    }
    return result;
  }

  Future<int> setBudget(Budget budget) async {
    final db = await instance.database;
    // Check if exists
    final exists = await db.query(
      'budgets',
      where: 'category_id = ? AND month = ? AND year = ?',
      whereArgs: [budget.categoryId, budget.month, budget.year],
    );

    if (exists.isNotEmpty) {
      final Map<String, dynamic> updated =
          Map<String, dynamic>.from(budget.toMap());
      // Never include the primary key in the SET clause for updates — remove it if present
      updated.remove('id');
      return await db.update(
        'budgets',
        updated,
        where: 'id = ?',
        whereArgs: [exists.first['id']],
      );
    } else {
      return await db.insert('budgets', budget.toMap());
    }
  }

  // --- REPORTS ---

  Future<Map<String, double>> getMonthlySummary(int month, int year) async {
    final db = await instance.database;
    final m = month.toString().padLeft(2, '0');
    final y = year.toString();

    final incomeRes = await db.rawQuery(
      '''
      SELECT SUM(amount) as total FROM transactions 
      WHERE type = ? AND strftime('%m', date) = ? AND strftime('%Y', date) = ?
    ''',
      [TransactionType.income.index, m, y],
    );

    final expenseRes = await db.rawQuery(
      '''
      SELECT SUM(amount) as total FROM transactions 
      WHERE type = ? AND strftime('%m', date) = ? AND strftime('%Y', date) = ?
    ''',
      [TransactionType.expense.index, m, y],
    );

    final incomeVal = incomeRes.first['total'];
    final expenseVal = expenseRes.first['total'];
    return {
      'income': (incomeVal as num?)?.toDouble() ?? 0.0,
      'expense': (expenseVal as num?)?.toDouble() ?? 0.0,
    };
  }

  Future<Map<int, double>> getCategorySpending(int month, int year) async {
    final db = await instance.database;
    final m = month.toString().padLeft(2, '0');
    final y = year.toString();

    final result = await db.rawQuery(
      '''
      SELECT category_id, SUM(amount) as total 
      FROM transactions 
      WHERE type = ? AND strftime('%m', date) = ? AND strftime('%Y', date) = ? AND category_id IS NOT NULL
      GROUP BY category_id
    ''',
      [TransactionType.expense.index, m, y],
    );

    final Map<int, double> spending = {};
    for (final row in result) {
      final totalVal = row['total'];
      spending[row['category_id'] as int] = (totalVal as num).toDouble();
    }
    return spending;
  }

  // New method to get frequent categories
  Future<List<Category>> getFrequentCategories(
    TransactionType type, {
    int limit = 5,
    int daysAgo = 90,
  }) async {
    final db = await instance.database;
    final now = DateTime.now();
    final dateLimit = now.subtract(Duration(days: daysAgo));

    final result = await db.rawQuery(
      '''
      SELECT c.id, c.name, c.type, c.color, c.icon_code_point, c.is_archived, c.monthly_budget_limit, c.sort_order,
             COUNT(t.id) as transaction_count
      FROM categories c
      JOIN transactions t ON c.id = t.category_id
      WHERE t.type = ? AND t.date >= ?
      GROUP BY c.id, c.name, c.type, c.color, c.icon_code_point, c.is_archived, c.monthly_budget_limit, c.sort_order
      ORDER BY transaction_count DESC
      LIMIT ?
    ''',
      [type.index, dateLimit.toIso8601String(), limit],
    );

    return result.map((json) => Category.fromMap(json)).toList();
  }

  // Method to close DB
  Future<void> close() async {
    final db = await instance.database;
    await db.close();
  }

  /// Deletes the entire database file and resets the in-memory handle.
  /// Use with caution — this will remove all user data.
  Future<void> deleteAllData() async {
    // Close current DB connection first
    try {
      if (_database != null) {
        await _database!.close();
      }
    } catch (_) {}
    _database = null;
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, AppConstants.dbName);
    try {
      await deleteDatabase(path);
    } catch (_) {}
  }
}
