/// Whether a category tracks expenses, income, or transfers.
enum CategoryType { expense, income, transfer }

/// Represents a spending/income category (e.g., Food, Salary, Transport).
/// Supports sub-categories via [parentId].
class Category {
  final String id;
  final String? parentId; // null = top-level category
  final String name;
  final String iconOrEmoji;
  final int color;
  final CategoryType type;
  final int sortOrder; // display position among siblings of the same type

  const Category({
    required this.id,
    this.parentId,
    required this.name,
    this.iconOrEmoji = '📁',
    this.color = 0xFF6366F1,
    this.type = CategoryType.expense,
    this.sortOrder = 0,
  });

  /// Orders categories by [sortOrder], then by name.
  static int compareForDisplay(Category a, Category b) {
    final byOrder = a.sortOrder.compareTo(b.sortOrder);
    return byOrder != 0 ? byOrder : a.name.compareTo(b.name);
  }

  /// Whether this is a sub-category.
  bool get isSubCategory => parentId != null;

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'] as String,
      parentId: map['parentId'] as String?,
      name: map['name'] as String,
      iconOrEmoji: map['iconOrEmoji'] as String? ?? '📁',
      color: map['color'] as int? ?? 0xFF6366F1,
      type: CategoryType.values[map['type'] as int? ?? 0],
      sortOrder: map['sortOrder'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'parentId': parentId,
      'name': name,
      'iconOrEmoji': iconOrEmoji,
      'color': color,
      'type': type.index,
      'sortOrder': sortOrder,
    };
  }

  Category copyWith({
    String? id,
    String? parentId,
    String? name,
    String? iconOrEmoji,
    int? color,
    CategoryType? type,
    int? sortOrder,
  }) {
    return Category(
      id: id ?? this.id,
      parentId: parentId ?? this.parentId,
      name: name ?? this.name,
      iconOrEmoji: iconOrEmoji ?? this.iconOrEmoji,
      color: color ?? this.color,
      type: type ?? this.type,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }
}
