import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/account.dart';
import '../../models/category.dart';
import '../../models/transaction.dart';
import '../../models/budget.dart';
import '../database/expense_repository.dart';

/// Singleton Repository Provider
final repositoryProvider = Provider<ExpenseRepository>((ref) {
  return ExpenseRepository();
});

/// Currently selected viewing date
class SelectedDateNotifier extends Notifier<DateTime> {
  @override
  DateTime build() => DateTime.now();

  void updateDate(DateTime newDate) => state = newDate;
}

final selectedDateProvider =
    NotifierProvider<SelectedDateNotifier, DateTime>(SelectedDateNotifier.new);

/// Active navigation bar index (0: Activity, 1: Summary, 2: Budget, 3: Analytics, 4: Accounts)
class ActiveNavIndexNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void setIndex(int index) => state = index;
}

final activeNavIndexProvider =
    NotifierProvider<ActiveNavIndexNotifier, int>(ActiveNavIndexNotifier.new);

/// Accounts AsyncNotifier
class AccountsNotifier extends AsyncNotifier<List<Account>> {
  @override
  Future<List<Account>> build() async {
    final repo = ref.watch(repositoryProvider);
    return repo.getAccounts();
  }

  Future<void> addAccount(Account account) async {
    final repo = ref.read(repositoryProvider);
    await repo.saveAccount(account);
    ref.invalidateSelf();
  }

  Future<void> updateAccount(Account account) async {
    final repo = ref.read(repositoryProvider);
    await repo.updateAccount(account);
    ref.invalidateSelf();
  }

  Future<void> deleteAccount(String id) async {
    final repo = ref.read(repositoryProvider);
    await repo.deleteAccount(id);
    ref.invalidateSelf();
  }

  Future<void> reorderAccounts(int oldIndex, int newIndex) async {
    final current = state.value ?? [];
    if (current.isEmpty) return;
    final list = List<Account>.from(current);
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);
    state = AsyncData(list);

    final repo = ref.read(repositoryProvider);
    for (int i = 0; i < list.length; i++) {
      await repo.updateAccount(list[i]);
    }
  }
}

final accountsProvider =
    AsyncNotifierProvider<AccountsNotifier, List<Account>>(AccountsNotifier.new);

/// Categories AsyncNotifier
class CategoriesNotifier extends AsyncNotifier<List<Category>> {
  @override
  Future<List<Category>> build() async {
    final repo = ref.watch(repositoryProvider);
    return repo.getCategories();
  }

  Future<void> addCategory(Category category) async {
    final repo = ref.read(repositoryProvider);
    await repo.saveCategory(category);
    ref.invalidateSelf();
  }

  Future<void> updateCategory(Category category) async {
    final repo = ref.read(repositoryProvider);
    await repo.updateCategory(category);
    ref.invalidateSelf();
  }

  Future<void> deleteCategory(String id) async {
    final repo = ref.read(repositoryProvider);
    await repo.deleteCategory(id);
    ref.invalidateSelf();
  }
}

final categoriesProvider =
    AsyncNotifierProvider<CategoriesNotifier, List<Category>>(CategoriesNotifier.new);

/// Transactions AsyncNotifier
class TransactionsNotifier extends AsyncNotifier<List<Transaction>> {
  @override
  Future<List<Transaction>> build() async {
    final repo = ref.watch(repositoryProvider);
    return repo.getTransactions();
  }

  Future<void> addTransaction(Transaction tx) async {
    final repo = ref.read(repositoryProvider);
    await repo.addTransaction(tx);
    // Invalidate transactions and accounts so balances update reactively
    ref.invalidateSelf();
    ref.invalidate(accountsProvider);
  }

  Future<void> deleteTransaction(Transaction tx) async {
    final repo = ref.read(repositoryProvider);
    await repo.deleteTransaction(tx);
    ref.invalidateSelf();
    ref.invalidate(accountsProvider);
  }
}

final transactionsProvider =
    AsyncNotifierProvider<TransactionsNotifier, List<Transaction>>(
        TransactionsNotifier.new);

/// Active Budget Profile Name (e.g. 'Personal', 'Business')
class ActiveBudgetProfileNotifier extends Notifier<String> {
  @override
  String build() => 'Personal';

  void setProfile(String name) => state = name;
}

final activeBudgetProfileProvider =
    NotifierProvider<ActiveBudgetProfileNotifier, String>(
        ActiveBudgetProfileNotifier.new);

/// All budgets for the currently selected month
final monthlyBudgetsProvider = FutureProvider<List<Budget>>((ref) async {
  final repo = ref.watch(repositoryProvider);
  final selectedDate = ref.watch(selectedDateProvider);
  final monthKey =
      '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}';
  return repo.getBudgetsForMonth(monthKey);
});

/// Active budget provider for the currently selected month and profile
final budgetProvider = FutureProvider<Budget?>((ref) async {
  final budgets = await ref.watch(monthlyBudgetsProvider.future);
  final activeProfile = ref.watch(activeBudgetProfileProvider);

  if (budgets.isEmpty) return null;
  return budgets.firstWhere(
    (b) => b.profileName.toLowerCase() == activeProfile.toLowerCase(),
    orElse: () => budgets.first,
  );
});

/// Total Expense for the selected month
final monthlyExpenseTotalProvider = Provider<double>((ref) {
  final transactionsAsync = ref.watch(transactionsProvider);
  final selectedDate = ref.watch(selectedDateProvider);

  return transactionsAsync.maybeWhen(
    data: (txs) {
      return txs
          .where((tx) =>
              tx.type == TransactionType.expense &&
              tx.date.year == selectedDate.year &&
              tx.date.month == selectedDate.month)
          .fold<double>(0.0, (sum, tx) => sum + tx.amount);
    },
    orElse: () => 0.0,
  );
});

/// Total Income for the selected month
final monthlyIncomeTotalProvider = Provider<double>((ref) {
  final transactionsAsync = ref.watch(transactionsProvider);
  final selectedDate = ref.watch(selectedDateProvider);

  return transactionsAsync.maybeWhen(
    data: (txs) {
      return txs
          .where((tx) =>
              tx.type == TransactionType.income &&
              tx.date.year == selectedDate.year &&
              tx.date.month == selectedDate.month)
          .fold<double>(0.0, (sum, tx) => sum + tx.amount);
    },
    orElse: () => 0.0,
  );
});

/// Total Net Balance across all accounts
final totalNetWorthProvider = Provider<double>((ref) {
  final accountsAsync = ref.watch(accountsProvider);
  return accountsAsync.maybeWhen(
    data: (accounts) =>
        accounts.fold<double>(0.0, (sum, a) => sum + a.balance),
    orElse: () => 0.0,
  );
});
