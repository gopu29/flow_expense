/// A monthly spending budget with optional per-category limits.
class Budget {
  final String id;
  final String profileName;
  final double monthlyLimit;
  final Map<String, double> categoryLimits; // categoryId -> limit
  final String monthYear; // e.g. "2026-10"

  const Budget({
    required this.id,
    this.profileName = 'Personal',
    required this.monthlyLimit,
    this.categoryLimits = const {},
    required this.monthYear,
  });

  factory Budget.fromMap(Map<String, dynamic> map) {
    // categoryLimits will be deserialized by the database helper
    return Budget(
      id: map['id'] as String,
      profileName: map['profileName'] as String? ?? 'Personal',
      monthlyLimit: (map['monthlyLimit'] as num).toDouble(),
      categoryLimits: const {},
      monthYear: map['monthYear'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'profileName': profileName,
      'monthlyLimit': monthlyLimit,
      'categoryLimits': '{}', // Serialized by database helper
      'monthYear': monthYear,
    };
  }

  Budget copyWith({
    String? id,
    String? profileName,
    double? monthlyLimit,
    Map<String, double>? categoryLimits,
    String? monthYear,
  }) {
    return Budget(
      id: id ?? this.id,
      profileName: profileName ?? this.profileName,
      monthlyLimit: monthlyLimit ?? this.monthlyLimit,
      categoryLimits: categoryLimits ?? this.categoryLimits,
      monthYear: monthYear ?? this.monthYear,
    );
  }
}
