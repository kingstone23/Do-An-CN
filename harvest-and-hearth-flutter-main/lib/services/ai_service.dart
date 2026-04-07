import '../models/food_item.dart';
import '../models/recipe.dart';
import 'groq_service.dart';
import 'gemini_service.dart';

/// Facade AI service: thử Groq trước, nếu lỗi tự động fallback sang Gemini.
class AiService {
  AiService._();
  static AiService? _instance;
  static AiService get instance => _instance ??= AiService._();

  Future<List<Recipe>> generateRecipes(
    List<FoodItem> inventory,
    String language,
  ) async {
    try {
      final recipes =
          await GroqService.instance.generateRecipes(inventory, language);
      return recipes;
    } catch (groqError) {
      // Groq thất bại → thử Gemini làm backup
      try {
        return await GeminiService.instance.generateRecipes(inventory, language);
      } catch (geminiError) {
        // Cả hai đều lỗi → ném lỗi gốc từ Groq cho user
        throw groqError;
      }
    }
  }
}
