import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/account.dart';
import '../models/category.dart';
import '../models/transaction_item.dart';
import '../models/budget.dart';
import '../models/enums.dart';
import '../utils/constants.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

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
      version: 1,
      onCreate: _createDB,
      onConfigure: _onConfigure,
    );
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
        monthly_budget_limit REAL
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
    final defaultCategories = [
      Category(name: 'Groceries', type: TransactionType.expense, color: 0xFF4CAF50, iconCodePoint: AppConstants.defaultCategoryIcons['Groceries']!),
      Category(name: 'Rent', type: TransactionType.expense, color: 0xFF2196F3, iconCodePoint: AppConstants.defaultCategoryIcons['Rent']!),
      Category(name: 'Utilities', type: TransactionType.expense, color: 0xFFFF9800, iconCodePoint: AppConstants.defaultCategoryIcons['Utilities']!),
      Category(name: 'Dining', type: TransactionType.expense, color: 0xFFE91E63, iconCodePoint: AppConstants.defaultCategoryIcons['Dining']!),
      Category(name: 'Transportation', type: TransactionType.expense, color: 0xFF9C27B0, iconCodePoint: AppConstants.defaultCategoryIcons['Transportation']!),
      Category(name: 'Entertainment', type: TransactionType.expense, color: 0xFF673AB7, iconCodePoint: AppConstants.defaultCategoryIcons['Entertainment']!),
      Category(name: 'Healthcare', type: TransactionType.expense, color: 0xFFF44336, iconCodePoint: AppConstants.defaultCategoryIcons['Healthcare']!),
      Category(name: 'Shopping', type: TransactionType.expense, color: 0xFF00BCD4, iconCodePoint: AppConstants.defaultCategoryIcons['Shopping']!),
      Category(name: 'Salary', type: TransactionType.income, color: 0xFF4CAF50, iconCodePoint: AppConstants.defaultCategoryIcons['Salary']!),
      Category(name: 'Freelance', type: TransactionType.income, color: 0xFF8BC34A, iconCodePoint: AppConstants.defaultCategoryIcons['Freelance']!),
      Category(name: 'Investments', type: TransactionType.income, color: 0xFF009688, iconCodePoint: AppConstants.defaultCategoryIcons['Investments']!),
    ];

    for (var cat in defaultCategories) {
      await db.insert('categories', cat.toMap());
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
    return await db.update('accounts', account.toMap(), where: 'id = ?', whereArgs: [account.id]);
  }

  Future<int> deleteAccount(int id) async {
    final db = await instance.database;
    // Check if account has transactions
    final count = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM transactions WHERE account_id = ? OR to_account_id = ?', [id, id]));
    if (count != null && count > 0) {
      throw Exception('Cannot delete account with existing transactions. Please archive it instead.');
    }
    return await db.delete('accounts', where: 'id = ?', whereArgs: [id]);
  }

  // --- CATEGORIES ---

  Future<int> createCategory(Category category) async {
    final db = await instance.database;
    return await db.insert('categories', category.toMap());
  }

  Future<List<Category>> getAllCategories() async {
    final db = await instance.database;
    final result = await db.query('categories', orderBy: 'name ASC');
    return result.map((json) => Category.fromMap(json)).toList();
  }
  
  Future<List<Category>> getCategoriesByType(TransactionType type) async {
    final db = await instance.database;
    final result = await db.query(
      'categories', 
      where: 'type = ?', 
      whereArgs: [type.index],
      orderBy: 'name ASC'
    );
    return result.map((json) => Category.fromMap(json)).toList();
  }

  // --- TRANSACTIONS ---

  Future<int> createTransaction(TransactionItem transaction) async {
    final db = await instance.database;
    return await db.transaction((txn) async {
      int id = await txn.insert('transactions', transaction.toMap());

      // Update Account Balance
      if (transaction.type == TransactionType.income) {
         await txn.rawUpdate('UPDATE accounts SET current_balance = current_balance + ? WHERE id = ?', [transaction.amount, transaction.accountId]);
      } else if (transaction.type == TransactionType.expense) {
         await txn.rawUpdate('UPDATE accounts SET current_balance = current_balance - ? WHERE id = ?', [transaction.amount, transaction.accountId]);
      } else if (transaction.type == TransactionType.transfer) {
         // Deduct from source
         await txn.rawUpdate('UPDATE accounts SET current_balance = current_balance - ? WHERE id = ?', [transaction.amount, transaction.accountId]);
         // Add to destination
         if (transaction.toAccountId != null) {
           await txn.rawUpdate('UPDATE accounts SET current_balance = current_balance + ? WHERE id = ?', [transaction.amount, transaction.toAccountId]);
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
    List<dynamic> args = [];

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
      whereClause += ' AND (note LIKE ? OR amount LIKE ?)'; // Simple search
      args.add('%$searchQuery%');
      args.add('%$searchQuery%');
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

  Future<void> deleteTransaction(int id) async {
    final db = await instance.database;
    final tx = await db.query('transactions', where: 'id = ?', whereArgs: [id]);
    if (tx.isEmpty) return;
    
    final transaction = TransactionItem.fromMap(tx.first);

    await db.transaction((txn) async {
      // Revert Balance
      if (transaction.type == TransactionType.income) {
         await txn.rawUpdate('UPDATE accounts SET current_balance = current_balance - ? WHERE id = ?', [transaction.amount, transaction.accountId]);
      } else if (transaction.type == TransactionType.expense) {
         await txn.rawUpdate('UPDATE accounts SET current_balance = current_balance + ? WHERE id = ?', [transaction.amount, transaction.accountId]);
      } else if (transaction.type == TransactionType.transfer) {
         await txn.rawUpdate('UPDATE accounts SET current_balance = current_balance + ? WHERE id = ?', [transaction.amount, transaction.accountId]);
         if (transaction.toAccountId != null) {
           await txn.rawUpdate('UPDATE accounts SET current_balance = current_balance - ? WHERE id = ?', [transaction.amount, transaction.toAccountId]);
         }
      }
      
      await txn.delete('transactions', where: 'id = ?', whereArgs: [id]);
    });
  }

  // --- BUDGETS ---
  
  Future<List<Budget>> getBudgetsForMonth(int month, int year) async {
    final db = await instance.database;
    // Get budgets
    final budgetsResult = await db.query('budgets', where: 'month = ? AND year = ?', whereArgs: [month, year]);
    List<Budget> budgets = budgetsResult.map((e) => Budget.fromMap(e)).toList();
    
    // Calculate spent amount for each budget
    // This is a naive loop, but okay for typical number of categories (10-20)
    List<Budget> result = [];
    for (var b in budgets) {
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
        year.toString()
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
    final exists = await db.query('budgets', 
      where: 'category_id = ? AND month = ? AND year = ?', 
      whereArgs: [budget.categoryId, budget.month, budget.year]
    );
    
    if (exists.isNotEmpty) {
      return await db.update('budgets', budget.toMap(), 
        where: 'id = ?', whereArgs: [exists.first['id']]);
    } else {
      return await db.insert('budgets', budget.toMap());
    }
  }

  // --- REPORTS ---
  
  Future<Map<String, double>> getMonthlySummary(int month, int year) async {
    final db = await instance.database;
    final m = month.toString().padLeft(2, '0');
    final y = year.toString();
    
    final incomeRes = await db.rawQuery('''
      SELECT SUM(amount) as total FROM transactions 
      WHERE type = ? AND strftime('%m', date) = ? AND strftime('%Y', date) = ?
    ''', [TransactionType.income.index, m, y]);
    
    final expenseRes = await db.rawQuery('''
      SELECT SUM(amount) as total FROM transactions 
      WHERE type = ? AND strftime('%m', date) = ? AND strftime('%Y', date) = ?
    ''', [TransactionType.expense.index, m, y]);

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

    final result = await db.rawQuery('''
      SELECT category_id, SUM(amount) as total 
      FROM transactions 
      WHERE type = ? AND strftime('%m', date) = ? AND strftime('%Y', date) = ? AND category_id IS NOT NULL
      GROUP BY category_id
    ''', [TransactionType.expense.index, m, y]);

    final Map<int, double> spending = {};
    for (var row in result) {
      final totalVal = row['total'];
      spending[row['category_id'] as int] = (totalVal as num).toDouble();
    }
    return spending;
  }
  
  // Method to close DB
  Future<void> close() async {
    final db = await instance.database;
    await db.close();
  }
}
