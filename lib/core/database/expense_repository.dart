import '../../models/account.dart';
import '../../models/category.dart';
import '../../models/transaction.dart';
import '../../models/budget.dart';
import 'database_helper.dart';

/// Repository managing high-level CRUD and domain logic across SQLite tables.
class ExpenseRepository {
  final DatabaseHelper _dbHelper;

  ExpenseRepository({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper();

  // ---------------------------------------------------------------------------
  // Accounts
  // ---------------------------------------------------------------------------

  Future<List<Account>> getAccounts() async {
    final rows = await _dbHelper.query(
      'accounts',
      orderBy: 'orderIndex ASC, name ASC',
    );
    return rows.map((r) => Account.fromMap(r)).toList();
  }

  Future<void> saveAccount(Account account) async {
    await _dbHelper.insert('accounts', account.toMap());
  }

  Future<void> updateAccount(Account account) async {
    await _dbHelper.update('accounts', account.toMap(), account.id);
  }

  Future<void> deleteAccount(String id) async {
    await _dbHelper.delete('accounts', id);
  }

  // ---------------------------------------------------------------------------
  // Categories
  // ---------------------------------------------------------------------------

  Future<List<Category>> getCategories({CategoryType? type}) async {
    final rows = await _dbHelper.query(
      'categories',
      where: type != null ? 'type = ?' : null,
      whereArgs: type != null ? [type.index] : null,
      orderBy: 'name ASC',
    );
    return rows.map((r) => Category.fromMap(r)).toList();
  }

  Future<void> saveCategory(Category category) async {
    await _dbHelper.insert('categories', category.toMap());
  }

  // ---------------------------------------------------------------------------
  // Transactions
  // ---------------------------------------------------------------------------

  Future<List<Transaction>> getTransactions({
    DateTime? startDate,
    DateTime? endDate,
    String? accountId,
    String? categoryId,
  }) async {
    final conditions = <String>[];
    final args = <Object?>[];

    if (startDate != null) {
      conditions.add('date >= ?');
      args.add(startDate.toIso8601String());
    }
    if (endDate != null) {
      conditions.add('date <= ?');
      args.add(endDate.toIso8601String());
    }
    if (accountId != null) {
      conditions.add('(accountId = ? OR toAccountId = ?)');
      args.add(accountId);
      args.add(accountId);
    }
    if (categoryId != null) {
      conditions.add('categoryId = ?');
      args.add(categoryId);
    }

    final where = conditions.isNotEmpty ? conditions.join(' AND ') : null;
    final rows = await _dbHelper.query(
      'transactions',
      where: where,
      whereArgs: args.isNotEmpty ? args : null,
      orderBy: 'date DESC, createdAt DESC',
    );

    return rows.map((r) => Transaction.fromMap(r)).toList();
  }

  /// Adds a transaction and updates the corresponding account balances.
  Future<void> addTransaction(Transaction tx) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      await txn.insert('transactions', tx.toMap());

      // Update account balance
      if (tx.type == TransactionType.expense) {
        await txn.rawUpdate(
          'UPDATE accounts SET balance = balance - ? WHERE id = ?',
          [tx.amount, tx.accountId],
        );
      } else if (tx.type == TransactionType.income) {
        await txn.rawUpdate(
          'UPDATE accounts SET balance = balance + ? WHERE id = ?',
          [tx.amount, tx.accountId],
        );
      } else if (tx.type == TransactionType.transfer && tx.toAccountId != null) {
        await txn.rawUpdate(
          'UPDATE accounts SET balance = balance - ? WHERE id = ?',
          [tx.amount, tx.accountId],
        );
        await txn.rawUpdate(
          'UPDATE accounts SET balance = balance + ? WHERE id = ?',
          [tx.amount, tx.toAccountId],
        );
      }
    });
  }

  /// Deletes a transaction and restores account balances.
  Future<void> deleteTransaction(Transaction tx) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      await txn.delete('transactions', where: 'id = ?', whereArgs: [tx.id]);

      // Revert account balance
      if (tx.type == TransactionType.expense) {
        await txn.rawUpdate(
          'UPDATE accounts SET balance = balance + ? WHERE id = ?',
          [tx.amount, tx.accountId],
        );
      } else if (tx.type == TransactionType.income) {
        await txn.rawUpdate(
          'UPDATE accounts SET balance = balance - ? WHERE id = ?',
          [tx.amount, tx.accountId],
        );
      } else if (tx.type == TransactionType.transfer && tx.toAccountId != null) {
        await txn.rawUpdate(
          'UPDATE accounts SET balance = balance + ? WHERE id = ?',
          [tx.amount, tx.accountId],
        );
        await txn.rawUpdate(
          'UPDATE accounts SET balance = balance - ? WHERE id = ?',
          [tx.amount, tx.toAccountId],
        );
      }
    });
  }

  // ---------------------------------------------------------------------------
  // Budgets
  // ---------------------------------------------------------------------------

  Future<Budget?> getBudgetForMonth(String monthYear) async {
    final rows = await _dbHelper.query(
      'budgets',
      where: 'monthYear = ?',
      whereArgs: [monthYear],
      orderBy: 'profileName ASC',
    );
    if (rows.isEmpty) return null;
    return Budget.fromMap(rows.first);
  }

  Future<void> saveBudget(Budget budget) async {
    await _dbHelper.insert('budgets', budget.toMap());
  }

  // ---------------------------------------------------------------------------
  // Aggregated Stats
  // ---------------------------------------------------------------------------

  /// Calculates total net balance across all accounts.
  Future<double> getTotalNetWorth() async {
    final accounts = await getAccounts();
    return accounts.fold<double>(0.0, (sum, a) => sum + a.balance);
  }

  /// Calculates total expense spend for a given month.
  Future<double> getMonthlyExpenseTotal(int year, int month) async {
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 0, 23, 59, 59);

    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      '''
      SELECT COALESCE(SUM(amount), 0.0) as total
      FROM transactions
      WHERE type = 0 AND date >= ? AND date <= ?
      ''',
      [start.toIso8601String(), end.toIso8601String()],
    );
    return (result.first['total'] as num).toDouble();
  }

  /// Calculates total income for a given month.
  Future<double> getMonthlyIncomeTotal(int year, int month) async {
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 0, 23, 59, 59);

    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      '''
      SELECT COALESCE(SUM(amount), 0.0) as total
      FROM transactions
      WHERE type = 1 AND date >= ? AND date <= ?
      ''',
      [start.toIso8601String(), end.toIso8601String()],
    );
    return (result.first['total'] as num).toDouble();
  }
}
