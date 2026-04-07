import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:uuid/uuid.dart';

import '../models/food_item.dart';
import '../models/recipe.dart';

const _uuid = Uuid();

class GeminiService {
  GeminiService._();
  static GeminiService? _instance;
  static GeminiService get instance => _instance ??= GeminiService._();

  GenerativeModel? _model;

  GenerativeModel _getModel() {
    if (_model != null) return _model!;
    final apiKey = dotenv.maybeGet('GEMINI_API_KEY') ?? '';
    _model = GenerativeModel(model: 'gemini-2.0-flash', apiKey: apiKey);
    return _model!;
  }

  Future<List<Recipe>> generateRecipes(
    List<FoodItem> inventory,
    String language,
  ) async {
    final model = _getModel();
    final prompt = _buildPrompt(inventory, language);
    final response = await model.generateContent([Content.text(prompt)]);
    final rawText = response.text ?? '';
    return _parseRecipes(rawText);
  }

  String _buildPrompt(List<FoodItem> inventory, String language) {
    final ingredientList = _formatIngredients(inventory, language);
    if (language == 'VIE') {
      return '''Bạn là đầu bếp AI chuyên ẩm thực Việt Nam. Nguyên liệu trong tủ:

$ingredientList

Gợi ý 3 món Việt Nam, ưu tiên nguyên liệu sắp hết hạn.
Trả về CHÍNH XÁC JSON (không markdown):
{"recipes":[{"name":"","description":"","difficulty":"easy","prepTime":15,"cookTime":30,"servings":4,"calories":350,"ingredientsNeeded":[],"instructions":[],"sourceName":"AI Chef","sourceUrl":"","imageKeyword":""}]}''';
    }
    return '''You are an AI chef. Fridge ingredients:

$ingredientList

Suggest 3 recipes, prioritizing expiring items.
Return EXACTLY this JSON (no markdown):
{"recipes":[{"name":"","description":"","difficulty":"easy","prepTime":15,"cookTime":30,"servings":4,"calories":350,"ingredientsNeeded":[],"instructions":[],"sourceName":"AI Chef","sourceUrl":"","imageKeyword":""}]}''';
  }

  static String _formatIngredients(List<FoodItem> inventory, String language) {
    return inventory.map((item) {
      final expiry = item.daysUntilExpiry;
      final note = expiry == null
          ? ''
          : language == 'VIE'
              ? ' (${expiry < 0 ? 'đã hết hạn' : '$expiry ngày còn'})'
              : ' (${expiry < 0 ? 'expired' : '$expiry days left'})';
      return '- ${item.name} (${item.quantity} ${item.unit})$note';
    }).join('\n');
  }

  static List<Recipe> _parseRecipes(String rawText) {
    final start = rawText.indexOf('{');
    final end = rawText.lastIndexOf('}');
    if (start == -1 || end == -1) throw Exception('Invalid JSON from Gemini');
    final parsed = jsonDecode(rawText.substring(start, end + 1)) as Map<String, dynamic>;
    return (parsed['recipes'] as List)
        .map((r) => Recipe.fromJson({...(r as Map<String, dynamic>), 'id': _uuid.v4()}))
        .toList();
  }
}
