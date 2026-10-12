import 'package:uuid/uuid.dart';
import '../../../models/transaction.dart';
import '../../../models/category.dart';
import '../../../models/account.dart';

/// Parsed transaction proposal extracted from spoken text.
class ParsedTransactionProposal {
  final String id;
  double amount;
  TransactionType type;
  Category category;
  Account account;
  String note;
  DateTime date;

  ParsedTransactionProposal({
    required this.id,
    required this.amount,
    required this.type,
    required this.category,
    required this.account,
    required this.note,
    required this.date,
  });

  Transaction toTransaction() {
    return Transaction(
      id: id,
      amount: amount,
      type: type,
      categoryId: category.id,
      accountId: account.id,
      date: date,
      note: note.isNotEmpty ? note : null,
      createdAt: DateTime.now(),
    );
  }
}

/// Intelligent Natural Language Parser for multi-transaction voice speech.
///
/// Handles natural sentences such as:
/// - "Spent 250 on lunch at subway"
/// - "Bought groceries for 1200 and coffee for 60"
/// - "Received salary of 50000"
/// - "Paid 800 for fuel and 150 for parking"
class VoiceTransactionParser {
  VoiceTransactionParser._();

  static List<ParsedTransactionProposal> parse({
    required String speechText,
    required List<Category> availableCategories,
    required List<Account> availableAccounts,
  }) {
    if (speechText.trim().isEmpty) return [];

    final defaultAccount = availableAccounts.isNotEmpty
        ? availableAccounts.firstWhere((a) => a.isDefault, orElse: () => availableAccounts.first)
        : const Account(id: 'default', name: 'Main Account', type: AccountType.bank);

    final defaultCategory = availableCategories.isNotEmpty
        ? availableCategories.first
        : const Category(id: 'default', name: 'Other', iconOrEmoji: '📦');

    final results = <ParsedTransactionProposal>[];

    // Split speech into potential sub-clauses on "and", "then", commas, or periods
    final clauses = speechText
        .split(RegExp(r'\band\b|\bthen\b|,|\.', caseSensitive: false))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    for (final clause in clauses) {
      // Find numbers (amount)
      final amountRegex = RegExp(r'(?:₹|\$|rs\.?|inr)?\s*([0-9]+(?:\.[0-9]{1,2})?)', caseSensitive: false);
      final match = amountRegex.firstMatch(clause);

      if (match != null) {
        final amountVal = double.tryParse(match.group(1) ?? '0') ?? 0.0;
        if (amountVal <= 0) continue;

        // Determine transaction type
        TransactionType type = TransactionType.expense;
        final lower = clause.toLowerCase();
        if (lower.contains('salary') ||
            lower.contains('received') ||
            lower.contains('got') ||
            lower.contains('earned') ||
            lower.contains('credited') ||
            lower.contains('income')) {
          type = TransactionType.income;
        } else if (lower.contains('transfer') || lower.contains('moved')) {
          type = TransactionType.transfer;
        }

        // Match category by keyword
        Category matchedCat = defaultCategory;
        for (final cat in availableCategories) {
          final catName = cat.name.toLowerCase();
          if (lower.contains(catName)) {
            matchedCat = cat;
            break;
          }
        }

        // Secondary category keyword heuristic
        if (matchedCat == defaultCategory) {
          if (lower.contains('coffee') || lower.contains('food') || lower.contains('lunch') || lower.contains('dinner') || lower.contains('breakfast') || lower.contains('burger') || lower.contains('pizza') || lower.contains('restaurant')) {
            matchedCat = _findCategoryByName(availableCategories, 'Food') ?? defaultCategory;
          } else if (lower.contains('cab') || lower.contains('uber') || lower.contains('ola') || lower.contains('fuel') || lower.contains('petrol') || lower.contains('metro') || lower.contains('transport') || lower.contains('parking')) {
            matchedCat = _findCategoryByName(availableCategories, 'Transport') ?? defaultCategory;
          } else if (lower.contains('grocery') || lower.contains('groceries') || lower.contains('shopping') || lower.contains('clothes')) {
            matchedCat = _findCategoryByName(availableCategories, 'Shopping') ?? defaultCategory;
          } else if (lower.contains('netflix') || lower.contains('spotify') || lower.contains('subscription') || lower.contains('wifi') || lower.contains('recharge')) {
            matchedCat = _findCategoryByName(availableCategories, 'Subscriptions') ?? defaultCategory;
          } else if (lower.contains('rent') || lower.contains('flat') || lower.contains('house')) {
            matchedCat = _findCategoryByName(availableCategories, 'Rent') ?? defaultCategory;
          } else if (lower.contains('salary') || lower.contains('paycheck')) {
            matchedCat = _findCategoryByName(availableCategories, 'Salary') ?? defaultCategory;
          }
        }

        results.add(
          ParsedTransactionProposal(
            id: const Uuid().v4(),
            amount: amountVal,
            type: type,
            category: matchedCat,
            account: defaultAccount,
            note: clause,
            date: DateTime.now(),
          ),
        );
      }
    }

    return results;
  }

  static Category? _findCategoryByName(List<Category> list, String name) {
    for (final c in list) {
      if (c.name.toLowerCase() == name.toLowerCase()) return c;
    }
    return null;
  }
}
