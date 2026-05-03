import '../core/simulated_clock.dart';

enum StorageType { fridge, freezer, pantry }

enum FoodCategory {
  vegetables,
  fruits,
  meat,
  dairy,
  seafood,
  drinks,
  snacks,
  other,
}

extension StorageTypeX on StorageType {
  String get value => name;
  static StorageType fromString(String v) => StorageType.values
      .firstWhere((e) => e.name == v, orElse: () => StorageType.fridge);
}

extension FoodCategoryX on FoodCategory {
  String get value => name;
  static FoodCategory fromString(String v) => FoodCategory.values
      .firstWhere((e) => e.name == v, orElse: () => FoodCategory.other);
}

class FoodItem {
  final String id;
  final String name;
  final FoodCategory category;
  final StorageType storage;
  final double quantity;
  final String unit;
  final DateTime addedDate;
  final DateTime? expiryDate;
  final int? warningDays;
  final String? imagePath;

  const FoodItem({
    required this.id,
    required this.name,
    required this.category,
    required this.storage,
    required this.quantity,
    required this.unit,
    required this.addedDate,
    this.expiryDate,
    this.warningDays,
    this.imagePath,
  });

  FoodItem copyWith({
    String? id,
    String? name,
    FoodCategory? category,
    StorageType? storage,
    double? quantity,
    String? unit,
    DateTime? addedDate,
    DateTime? expiryDate,
    int? warningDays,
    String? imagePath,
  }) {
    return FoodItem(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      storage: storage ?? this.storage,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      addedDate: addedDate ?? this.addedDate,
      expiryDate: expiryDate ?? this.expiryDate,
      warningDays: warningDays ?? this.warningDays,
      imagePath: imagePath ?? this.imagePath,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'category': category.value,
        'storage': storage.value,
        'quantity': quantity,
        'unit': unit,
        'addedDate': addedDate.toIso8601String(),
        'expiryDate': expiryDate?.toIso8601String(),
        'warningDays': warningDays,
        'imagePath': imagePath,
      };

  /// Reads a row from the REST API (snake_case column names).
  factory FoodItem.fromApiRow(Map<String, dynamic> row) => FoodItem(
        id: row['id'] as String,
        name: row['name'] as String,
        category: FoodCategoryX.fromString(row['category'] as String),
        storage: StorageTypeX.fromString(row['storage'] as String),
        quantity: (row['quantity'] as num).toDouble(),
        unit: row['unit'] as String,
        addedDate: DateTime.parse(row['added_date'] as String),
        expiryDate: row['expiry_date'] != null
            ? DateTime.parse(row['expiry_date'] as String)
            : null,
        warningDays: row['warning_days'] as int?,
        imagePath: row['image_path'] as String?,
      );

  factory FoodItem.fromJson(Map<String, dynamic> json) => FoodItem(
        id: json['id'] as String,
        name: json['name'] as String,
        category: FoodCategoryX.fromString(json['category'] as String),
        storage: StorageTypeX.fromString(json['storage'] as String),
        quantity: (json['quantity'] as num).toDouble(),
        unit: json['unit'] as String,
        addedDate: DateTime.parse(json['addedDate'] as String),
        expiryDate: json['expiryDate'] != null
            ? DateTime.parse(json['expiryDate'] as String)
            : null,
        warningDays: json['warningDays'] as int?,
        imagePath: json['imagePath'] as String?,
      );

  /// Returns days until expiry. Negative = already expired. Null = no expiry set.
  int? get daysUntilExpiry {
    if (expiryDate == null) return null;
    final now = SimulatedClock.now;
    final today = DateTime(now.year, now.month, now.day);
    final expiry =
        DateTime(expiryDate!.year, expiryDate!.month, expiryDate!.day);
    return expiry.difference(today).inDays;
  }

  bool get isExpired {
    final d = daysUntilExpiry;
    return d != null && d < 0;
  }

  bool get isExpiringSoon {
    final d = daysUntilExpiry;
    if (d == null) return false;
    final threshold = warningDays ?? 3;
    return d >= 0 && d <= threshold;
  }
}
