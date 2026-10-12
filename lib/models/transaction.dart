/// Transaction direction: spending, earning, or moving between accounts.
enum TransactionType { expense, income, transfer }

/// A single financial transaction entry.
class Transaction {
  final String id;
  final double amount;
  final TransactionType type;
  final String categoryId;
  final String? subCategoryId;
  final String accountId;
  final String? toAccountId; // only for transfers
  final DateTime date;
  final String? note;
  final String? receiptImagePath;
  final DateTime createdAt;

  const Transaction({
    required this.id,
    required this.amount,
    required this.type,
    required this.categoryId,
    this.subCategoryId,
    required this.accountId,
    this.toAccountId,
    required this.date,
    this.note,
    this.receiptImagePath,
    required this.createdAt,
  });

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'] as String,
      amount: (map['amount'] as num).toDouble(),
      type: TransactionType.values[map['type'] as int],
      categoryId: map['categoryId'] as String,
      subCategoryId: map['subCategoryId'] as String?,
      accountId: map['accountId'] as String,
      toAccountId: map['toAccountId'] as String?,
      date: DateTime.parse(map['date'] as String),
      note: map['note'] as String?,
      receiptImagePath: map['receiptImagePath'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'type': type.index,
      'categoryId': categoryId,
      'subCategoryId': subCategoryId,
      'accountId': accountId,
      'toAccountId': toAccountId,
      'date': date.toIso8601String(),
      'note': note,
      'receiptImagePath': receiptImagePath,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  Transaction copyWith({
    String? id,
    double? amount,
    TransactionType? type,
    String? categoryId,
    String? subCategoryId,
    String? accountId,
    String? toAccountId,
    DateTime? date,
    String? note,
    String? receiptImagePath,
    DateTime? createdAt,
  }) {
    return Transaction(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      categoryId: categoryId ?? this.categoryId,
      subCategoryId: subCategoryId ?? this.subCategoryId,
      accountId: accountId ?? this.accountId,
      toAccountId: toAccountId ?? this.toAccountId,
      date: date ?? this.date,
      note: note ?? this.note,
      receiptImagePath: receiptImagePath ?? this.receiptImagePath,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
