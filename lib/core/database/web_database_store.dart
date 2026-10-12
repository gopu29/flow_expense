import 'package:uuid/uuid.dart';
import '../../models/account.dart';
import '../../models/category.dart';
import '../../models/transaction.dart';
import '../../models/budget.dart';

/// Pure Dart in-memory / local storage driver for Flutter Web.
///
/// Bypasses browser WebAssembly MIME errors while preserving full
/// SQLite functionality on mobile/desktop platforms.
class WebDatabaseStore {
  static final WebDatabaseStore _instance = WebDatabaseStore._internal();
  factory WebDatabaseStore() => _instance;

  WebDatabaseStore._internal() {
    _initSeedData();
  }

  static const _uuid = Uuid();

  final List<Account> _accounts = [];
  final List<Category> _categories = [];
  final List<Transaction> _transactions = [];
  final List<Budget> _budgets = [];

  void _initSeedData() {
    if (_accounts.isNotEmpty) return;

    // Accounts
    final mainBank = Account(
      id: 'acc_main',
      name: 'Main Bank',
      type: AccountType.bank,
      balance: 45200.0,
      icon: '🏦',
      isDefault: true,
      orderIndex: 0,
      color: 0xFF6366F1,
    );

    final cash = Account(
      id: 'acc_cash',
      name: 'Cash Wallet',
      type: AccountType.cash,
      balance: 3500.0,
      icon: '💵',
      isDefault: false,
      orderIndex: 1,
      color: 0xFF10B981,
    );

    final creditCard = Account(
      id: 'acc_cc',
      name: 'Credit Card',
      type: AccountType.creditCard,
      balance: -8450.0,
      icon: '💳',
      isDefault: false,
      orderIndex: 2,
      color: 0xFFEC4899,
    );

    _accounts.addAll([mainBank, cash, creditCard]);

    // Categories
    final catFood = Category(id: 'cat_food', name: 'Food', iconOrEmoji: '🍔', color: 0xFFF59E0B);
    final subFoodGroceries = Category(id: 'cat_food_groceries', parentId: 'cat_food', name: 'Groceries', iconOrEmoji: '🛒', color: 0xFF10B981);
    final subFoodDining = Category(id: 'cat_food_dining', parentId: 'cat_food', name: 'Dining Out', iconOrEmoji: '🍕', color: 0xFFF97316);
    final subFoodCoffee = Category(id: 'cat_food_coffee', parentId: 'cat_food', name: 'Coffee & Snacks', iconOrEmoji: '☕', color: 0xFFD97706);
    final catTransport = Category(id: 'cat_transport', name: 'Transport', iconOrEmoji: '🚗', color: 0xFF38BDF8);
    final catShopping = Category(id: 'cat_shopping', name: 'Shopping', iconOrEmoji: '🛒', color: 0xFFA855F7);
    final catSub = Category(id: 'cat_sub', name: 'Subscriptions', iconOrEmoji: '📱', color: 0xFF6366F1);
    final catHealth = Category(id: 'cat_health', name: 'Healthcare', iconOrEmoji: '💊', color: 0xFF10B981);
    final catEnt = Category(id: 'cat_ent', name: 'Entertainment', iconOrEmoji: '🎮', color: 0xFFEC4899);
    final catBills = Category(id: 'cat_bills', name: 'Bills & Utilities', iconOrEmoji: '💡', color: 0xFFF97316);
    final catOther = Category(id: 'cat_other', name: 'Other', iconOrEmoji: '📦', color: 0xFF64748B);
    final catSalary = Category(id: 'cat_salary', name: 'Salary', iconOrEmoji: '💰', color: 0xFF10B981, type: CategoryType.income);
    final catFreelance = Category(id: 'cat_freelance', name: 'Freelance', iconOrEmoji: '💻', color: 0xFF38BDF8, type: CategoryType.income);
    final catTransfer = Category(id: 'cat_transfer', name: 'Transfer', iconOrEmoji: '🔄', color: 0xFF6366F1, type: CategoryType.transfer);

    _categories.addAll([
      catFood,
      subFoodGroceries,
      subFoodDining,
      subFoodCoffee,
      catTransport,
      catShopping,
      catSub,
      catHealth,
      catEnt,
      catBills,
      catOther,
      catSalary,
      catFreelance,
      catTransfer,
    ]);

    // Sample Transactions for current month
    final now = DateTime.now();

    _transactions.addAll([
      Transaction(
        id: _uuid.v4(),
        amount: 380.0,
        type: TransactionType.expense,
        categoryId: catFood.id,
        accountId: mainBank.id,
        date: now.subtract(const Duration(hours: 2)),
        note: 'Starbucks Coffee',
        createdAt: now.subtract(const Duration(hours: 2)),
      ),
      Transaction(
        id: _uuid.v4(),
        amount: 1450.0,
        type: TransactionType.expense,
        categoryId: catTransport.id,
        accountId: mainBank.id,
        date: now.subtract(const Duration(hours: 5)),
        note: 'Shell Petrol Pump',
        createdAt: now.subtract(const Duration(hours: 5)),
      ),
      Transaction(
        id: _uuid.v4(),
        amount: 2240.0,
        type: TransactionType.expense,
        categoryId: catShopping.id,
        accountId: creditCard.id,
        date: now.subtract(const Duration(days: 1)),
        note: 'Grocery at Nature Basket',
        createdAt: now.subtract(const Duration(days: 1)),
      ),
      Transaction(
        id: _uuid.v4(),
        amount: 799.0,
        type: TransactionType.expense,
        categoryId: catSub.id,
        accountId: mainBank.id,
        date: now.subtract(const Duration(days: 3)),
        note: 'Netflix & Spotify',
        createdAt: now.subtract(const Duration(days: 3)),
      ),
      Transaction(
        id: _uuid.v4(),
        amount: 1850.0,
        type: TransactionType.expense,
        categoryId: catFood.id,
        accountId: mainBank.id,
        date: now.subtract(const Duration(days: 4)),
        note: 'Dinner at Olive Bistro',
        createdAt: now.subtract(const Duration(days: 4)),
      ),
      Transaction(
        id: _uuid.v4(),
        amount: 55000.0,
        type: TransactionType.income,
        categoryId: catSalary.id,
        accountId: mainBank.id,
        date: DateTime(now.year, now.month, 1),
        note: 'Monthly Salary Credit',
        createdAt: DateTime(now.year, now.month, 1),
      ),
    ]);

    // Default Budget for this month
    final monthKey = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    _budgets.add(
      Budget(
        id: 'budget_default',
        profileName: 'Personal',
        monthlyLimit: 10000.0,
        categoryLimits: {
          catFood.id: 3000.0,
          catTransport.id: 2000.0,
          catShopping.id: 3000.0,
          catSub.id: 1000.0,
        },
        monthYear: monthKey,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Accounts
  // ---------------------------------------------------------------------------

  List<Account> getAccounts() {
    return List.unmodifiable(_accounts);
  }

  void saveAccount(Account account) {
    final idx = _accounts.indexWhere((a) => a.id == account.id);
    if (idx >= 0) {
      _accounts[idx] = account;
    } else {
      _accounts.add(account);
    }
  }

  void updateAccount(Account account) {
    final idx = _accounts.indexWhere((a) => a.id == account.id);
    if (idx >= 0) {
      _accounts[idx] = account;
    }
  }

  void deleteAccount(String id) {
    _accounts.removeWhere((a) => a.id == id);
  }

  // ---------------------------------------------------------------------------
  // Categories
  // ---------------------------------------------------------------------------

  List<Category> getCategories({CategoryType? type}) {
    if (type == null) return List.unmodifiable(_categories);
    return _categories.where((c) => c.type == type).toList();
  }

  void saveCategory(Category category) {
    final idx = _categories.indexWhere((c) => c.id == category.id);
    if (idx >= 0) {
      _categories[idx] = category;
    } else {
      _categories.add(category);
    }
  }

  void updateCategory(Category category) {
    final idx = _categories.indexWhere((c) => c.id == category.id);
    if (idx >= 0) {
      _categories[idx] = category;
    }
  }

  void deleteCategory(String id) {
    _categories.removeWhere((c) => c.id == id || c.parentId == id);
  }

  // ---------------------------------------------------------------------------
  // Transactions
  // ---------------------------------------------------------------------------

  List<Transaction> getTransactions({
    DateTime? startDate,
    DateTime? endDate,
    String? accountId,
    String? categoryId,
  }) {
    return _transactions.where((tx) {
      if (startDate != null && tx.date.isBefore(startDate)) return false;
      if (endDate != null && tx.date.isAfter(endDate)) return false;
      if (accountId != null &&
          tx.accountId != accountId &&
          tx.toAccountId != accountId) {
        return false;
      }
      if (categoryId != null && tx.categoryId != categoryId) return false;
      return true;
    }).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  void addTransaction(Transaction tx) {
    _transactions.insert(0, tx);

    // Update account balances
    final accIdx = _accounts.indexWhere((a) => a.id == tx.accountId);
    if (accIdx >= 0) {
      final acc = _accounts[accIdx];
      if (tx.type == TransactionType.expense) {
        _accounts[accIdx] = acc.copyWith(balance: acc.balance - tx.amount);
      } else if (tx.type == TransactionType.income) {
        _accounts[accIdx] = acc.copyWith(balance: acc.balance + tx.amount);
      } else if (tx.type == TransactionType.transfer) {
        _accounts[accIdx] = acc.copyWith(balance: acc.balance - tx.amount);
      }
    }

    if (tx.type == TransactionType.transfer && tx.toAccountId != null) {
      final toIdx = _accounts.indexWhere((a) => a.id == tx.toAccountId);
      if (toIdx >= 0) {
        final toAcc = _accounts[toIdx];
        _accounts[toIdx] = toAcc.copyWith(balance: toAcc.balance + tx.amount);
      }
    }
  }

  void deleteTransaction(Transaction tx) {
    _transactions.removeWhere((t) => t.id == tx.id);

    // Revert account balances
    final accIdx = _accounts.indexWhere((a) => a.id == tx.accountId);
    if (accIdx >= 0) {
      final acc = _accounts[accIdx];
      if (tx.type == TransactionType.expense) {
        _accounts[accIdx] = acc.copyWith(balance: acc.balance + tx.amount);
      } else if (tx.type == TransactionType.income) {
        _accounts[accIdx] = acc.copyWith(balance: acc.balance - tx.amount);
      } else if (tx.type == TransactionType.transfer) {
        _accounts[accIdx] = acc.copyWith(balance: acc.balance + tx.amount);
      }
    }

    if (tx.type == TransactionType.transfer && tx.toAccountId != null) {
      final toIdx = _accounts.indexWhere((a) => a.id == tx.toAccountId);
      if (toIdx >= 0) {
        final toAcc = _accounts[toIdx];
        _accounts[toIdx] = toAcc.copyWith(balance: toAcc.balance - tx.amount);
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Budgets
  // ---------------------------------------------------------------------------

  List<Budget> getBudgetsForMonth(String monthYear) {
    var list = _budgets.where((b) => b.monthYear == monthYear).toList();
    if (list.isEmpty) {
      final defaultBudget = Budget(
        id: 'budget_personal_$monthYear',
        profileName: 'Personal',
        monthlyLimit: 10000.0,
        categoryLimits: {},
        monthYear: monthYear,
      );
      _budgets.add(defaultBudget);
      list = [defaultBudget];
    }
    return List.unmodifiable(list);
  }

  Budget? getBudgetForMonth(String monthYear) {
    final list = getBudgetsForMonth(monthYear);
    return list.isNotEmpty ? list.first : null;
  }

  void saveBudget(Budget budget) {
    final idx = _budgets.indexWhere((b) =>
        b.id == budget.id ||
        (b.monthYear == budget.monthYear &&
            b.profileName.toLowerCase() == budget.profileName.toLowerCase()));
    if (idx >= 0) {
      _budgets[idx] = budget;
    } else {
      _budgets.add(budget);
    }
  }

  void deleteBudget(String id) {
    _budgets.removeWhere((b) => b.id == id);
  }
}
