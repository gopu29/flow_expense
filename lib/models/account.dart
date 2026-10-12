/// Supported account types.
enum AccountType { bank, cash, creditCard, savings, investment }

/// Represents a financial account (e.g., Main Bank, Cash, Credit Card).
class Account {
  final String id;
  final String name;
  final AccountType type;
  final double balance;
  final String currency;
  final int color;
  final String icon;
  final bool isDefault;
  final int orderIndex;

  const Account({
    required this.id,
    required this.name,
    required this.type,
    this.balance = 0.0,
    this.currency = 'INR',
    this.color = 0xFF6366F1,
    this.icon = '🏦',
    this.isDefault = false,
    this.orderIndex = 0,
  });

  /// Create from SQLite row map.
  factory Account.fromMap(Map<String, dynamic> map) {
    return Account(
      id: map['id'] as String,
      name: map['name'] as String,
      type: AccountType.values[map['type'] as int],
      balance: (map['balance'] as num).toDouble(),
      currency: map['currency'] as String? ?? 'INR',
      color: map['color'] as int? ?? 0xFF6366F1,
      icon: map['icon'] as String? ?? '🏦',
      isDefault: (map['isDefault'] as int? ?? 0) == 1,
      orderIndex: map['orderIndex'] as int? ?? 0,
    );
  }

  /// Convert to SQLite row map.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type.index,
      'balance': balance,
      'currency': currency,
      'color': color,
      'icon': icon,
      'isDefault': isDefault ? 1 : 0,
      'orderIndex': orderIndex,
    };
  }

  /// Create a copy with updated fields.
  Account copyWith({
    String? id,
    String? name,
    AccountType? type,
    double? balance,
    String? currency,
    int? color,
    String? icon,
    bool? isDefault,
    int? orderIndex,
  }) {
    return Account(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      balance: balance ?? this.balance,
      currency: currency ?? this.currency,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      isDefault: isDefault ?? this.isDefault,
      orderIndex: orderIndex ?? this.orderIndex,
    );
  }
}
