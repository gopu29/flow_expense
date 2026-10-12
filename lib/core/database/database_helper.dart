import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:path/path.dart';
import 'package:uuid/uuid.dart';

/// Singleton helper that manages the local SQLite database.
///
/// Provides table creation, migrations, and default seed data
/// so the app works out-of-the-box on first launch.
class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;
  static const _dbName = 'flow_expense.db';
  static const _dbVersion = 1;
  static const _uuid = Uuid();

  /// Returns the singleton database instance, creating it on first call.
  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    if (kIsWeb) {
      databaseFactory = databaseFactoryFfiWeb;
      return await databaseFactory.openDatabase(
        _dbName,
        options: OpenDatabaseOptions(
          version: _dbVersion,
          onCreate: _onCreate,
          onUpgrade: _onUpgrade,
        ),
      );
    }

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  // ---------------------------------------------------------------------------
  // Schema
  // ---------------------------------------------------------------------------

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE accounts (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        type INTEGER NOT NULL DEFAULT 0,
        balance REAL NOT NULL DEFAULT 0.0,
        currency TEXT NOT NULL DEFAULT 'INR',
        color INTEGER NOT NULL DEFAULT 0xFF6366F1,
        icon TEXT NOT NULL DEFAULT '🏦',
        isDefault INTEGER NOT NULL DEFAULT 0,
        orderIndex INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE categories (
        id TEXT PRIMARY KEY,
        parentId TEXT,
        name TEXT NOT NULL,
        iconOrEmoji TEXT NOT NULL DEFAULT '📁',
        color INTEGER NOT NULL DEFAULT 0xFF6366F1,
        type INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (parentId) REFERENCES categories (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE transactions (
        id TEXT PRIMARY KEY,
        amount REAL NOT NULL,
        type INTEGER NOT NULL DEFAULT 0,
        categoryId TEXT NOT NULL,
        subCategoryId TEXT,
        accountId TEXT NOT NULL,
        toAccountId TEXT,
        date TEXT NOT NULL,
        note TEXT,
        receiptImagePath TEXT,
        createdAt TEXT NOT NULL,
        FOREIGN KEY (categoryId) REFERENCES categories (id),
        FOREIGN KEY (accountId) REFERENCES accounts (id),
        FOREIGN KEY (toAccountId) REFERENCES accounts (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE budgets (
        id TEXT PRIMARY KEY,
        profileName TEXT NOT NULL DEFAULT 'Personal',
        monthlyLimit REAL NOT NULL DEFAULT 0.0,
        categoryLimits TEXT NOT NULL DEFAULT '{}',
        monthYear TEXT NOT NULL
      )
    ''');

    // Performance indexes
    await db.execute('CREATE INDEX idx_transactions_date ON transactions (date)');
    await db.execute('CREATE INDEX idx_transactions_category ON transactions (categoryId)');
    await db.execute('CREATE INDEX idx_transactions_account ON transactions (accountId)');

    // Seed defaults
    await _seedDefaults(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Future migrations go here
  }

  // ---------------------------------------------------------------------------
  // Seed Data
  // ---------------------------------------------------------------------------

  Future<void> _seedDefaults(Database db) async {
    // Default account
    await db.insert('accounts', {
      'id': _uuid.v4(),
      'name': 'Main Account',
      'type': 0, // bank
      'balance': 0.0,
      'currency': 'INR',
      'color': 0xFF6366F1,
      'icon': '🏦',
      'isDefault': 1,
      'orderIndex': 0,
    });

    // Default expense categories
    final expenseCategories = [
      {'name': 'Food', 'icon': '🍔', 'color': 0xFFF59E0B},
      {'name': 'Transport', 'icon': '🚗', 'color': 0xFF38BDF8},
      {'name': 'Shopping', 'icon': '🛒', 'color': 0xFFA855F7},
      {'name': 'Subscriptions', 'icon': '📱', 'color': 0xFF6366F1},
      {'name': 'Healthcare', 'icon': '💊', 'color': 0xFF10B981},
      {'name': 'Entertainment', 'icon': '🎮', 'color': 0xFFEC4899},
      {'name': 'Bills & Utilities', 'icon': '💡', 'color': 0xFFF97316},
      {'name': 'Education', 'icon': '📚', 'color': 0xFF14B8A6},
      {'name': 'Rent', 'icon': '🏠', 'color': 0xFF8B5CF6},
      {'name': 'Other', 'icon': '📦', 'color': 0xFF64748B},
    ];

    for (final cat in expenseCategories) {
      await db.insert('categories', {
        'id': _uuid.v4(),
        'parentId': null,
        'name': cat['name'],
        'iconOrEmoji': cat['icon'],
        'color': cat['color'],
        'type': 0, // expense
      });
    }

    // Default income categories
    final incomeCategories = [
      {'name': 'Salary', 'icon': '💰', 'color': 0xFF10B981},
      {'name': 'Freelance', 'icon': '💻', 'color': 0xFF38BDF8},
      {'name': 'Investment', 'icon': '📈', 'color': 0xFF6366F1},
    ];

    for (final cat in incomeCategories) {
      await db.insert('categories', {
        'id': _uuid.v4(),
        'parentId': null,
        'name': cat['name'],
        'iconOrEmoji': cat['icon'],
        'color': cat['color'],
        'type': 1, // income
      });
    }

    // Default transfer category
    await db.insert('categories', {
      'id': _uuid.v4(),
      'parentId': null,
      'name': 'Transfer',
      'iconOrEmoji': '🔄',
      'color': 0xFF6366F1,
      'type': 2, // transfer
    });
  }

  // ---------------------------------------------------------------------------
  // Generic CRUD helpers
  // ---------------------------------------------------------------------------

  /// Insert a row and return the generated/provided id.
  Future<void> insert(String table, Map<String, dynamic> row) async {
    final db = await database;
    await db.insert(table, row, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Query all rows from a table.
  Future<List<Map<String, dynamic>>> queryAll(String table) async {
    final db = await database;
    return db.query(table);
  }

  /// Query rows with a WHERE clause.
  Future<List<Map<String, dynamic>>> query(
    String table, {
    String? where,
    List<Object?>? whereArgs,
    String? orderBy,
  }) async {
    final db = await database;
    return db.query(table, where: where, whereArgs: whereArgs, orderBy: orderBy);
  }

  /// Update a row by id.
  Future<int> update(String table, Map<String, dynamic> row, String id) async {
    final db = await database;
    return db.update(table, row, where: 'id = ?', whereArgs: [id]);
  }

  /// Delete a row by id.
  Future<int> delete(String table, String id) async {
    final db = await database;
    return db.delete(table, where: 'id = ?', whereArgs: [id]);
  }

  /// Generate a new UUID v4.
  static String newId() => _uuid.v4();
}
