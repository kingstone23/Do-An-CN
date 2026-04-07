import 'package:flutter/material.dart';
import '../models/food_item.dart';

class CategoryInfo {
  final FoodCategory category;
  final IconData icon;
  final Color color;
  final String translationKey;

  const CategoryInfo({
    required this.category,
    required this.icon,
    required this.color,
    required this.translationKey,
  });
}

class AppCategories {
  AppCategories._();

  static const List<CategoryInfo> all = [
    CategoryInfo(
      category: FoodCategory.vegetables,
      icon: Icons.eco_rounded,
      color: Color(0xFF4CAF50),
      translationKey: 'cat_vegetables',
    ),
    CategoryInfo(
      category: FoodCategory.fruits,
      icon: Icons.apple_rounded,
      color: Color(0xFFFF5722),
      translationKey: 'cat_fruits',
    ),
    CategoryInfo(
      category: FoodCategory.meat,
      icon: Icons.set_meal_rounded,
      color: Color(0xFFF44336),
      translationKey: 'cat_meat',
    ),
    CategoryInfo(
      category: FoodCategory.dairy,
      icon: Icons.local_drink_rounded,
      color: Color(0xFF2196F3),
      translationKey: 'cat_dairy',
    ),
    CategoryInfo(
      category: FoodCategory.seafood,
      icon: Icons.water_rounded,
      color: Color(0xFF00BCD4),
      translationKey: 'cat_seafood',
    ),
    CategoryInfo(
      category: FoodCategory.drinks,
      icon: Icons.local_cafe_rounded,
      color: Color(0xFF9C27B0),
      translationKey: 'cat_drinks',
    ),
    CategoryInfo(
      category: FoodCategory.snacks,
      icon: Icons.cookie_rounded,
      color: Color(0xFFFF9800),
      translationKey: 'cat_snacks',
    ),
    CategoryInfo(
      category: FoodCategory.other,
      icon: Icons.category_rounded,
      color: Color(0xFF607D8B),
      translationKey: 'cat_other',
    ),
  ];

  static CategoryInfo forCategory(FoodCategory category) {
    return all.firstWhere(
      (c) => c.category == category,
      orElse: () => all.last,
    );
  }
}
