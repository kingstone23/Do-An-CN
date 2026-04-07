import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

import '../models/food_item.dart';
import '../models/recipe.dart';

const _uuid = Uuid();
const _groqEndpoint = 'https://api.groq.com/openai/v1/chat/completions';
const _model = 'llama-3.3-70b-versatile';

class GroqService {
  GroqService._();
  static GroqService? _instance;
  static GroqService get instance => _instance ??= GroqService._();

  String get _apiKey => dotenv.maybeGet('GROQ_API_KEY') ?? '';

  Future<List<Recipe>> generateRecipes(
    List<FoodItem> inventory,
    String language,
  ) async {
    final ingredientList = inventory.map((item) {
      final expiry = item.daysUntilExpiry;
      final expiryNote = expiry != null
          ? (language == 'VIE'
              ? ' (còn ${expiry < 0 ? 'đã hết hạn' : '$expiry ngày'})'
              : ' (${expiry < 0 ? 'expired' : '$expiry days left'})')
          : '';
      return '- ${item.name} (${item.quantity} ${item.unit})$expiryNote';
    }).join('\n');

    final prompt = language == 'VIE'
        ? '''Bạn là một đầu bếp AI chuyên về ẩm thực Việt Nam. Dựa trên các nguyên liệu sau trong tủ lạnh:

$ingredientList

Hãy gợi ý 3 món ăn Việt Nam phù hợp. Ưu tiên sử dụng nguyên liệu sắp hết hạn trước.

Trả về CHÍNH XÁC JSON sau (không có text khác, không có markdown):
{
  "recipes": [
    {
      "name": "Tên món",
      "description": "Mô tả ngắn",
      "difficulty": "easy",
      "prepTime": 15,
      "cookTime": 30,
      "servings": 4,
      "calories": 350,
      "ingredientsNeeded": ["100g thịt bò", "2 củ cà rốt"],
      "instructions": ["Bước 1: ...", "Bước 2: ..."],
      "sourceName": "AI Chef",
      "sourceUrl": "",
      "imageKeyword": "vietnamese beef stir fry"
    }
  ]
}'''
        : '''You are an AI chef. Based on the following fridge ingredients:

$ingredientList

Suggest 3 suitable recipes. Prioritize ingredients expiring soon.

Return EXACTLY this JSON (no other text, no markdown):
{
  "recipes": [
    {
      "name": "Recipe name",
      "description": "Short description",
      "difficulty": "easy",
      "prepTime": 15,
      "cookTime": 30,
      "servings": 4,
      "calories": 350,
      "ingredientsNeeded": ["100g beef", "2 carrots"],
      "instructions": ["Step 1: ...", "Step 2: ..."],
      "sourceName": "AI Chef",
      "sourceUrl": "",
      "imageKeyword": "beef stir fry"
    }
  ]
}''';

    final response = await http.post(
      Uri.parse(_groqEndpoint),
      headers: {
        'Authorization': 'Bearer $_apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': _model,
        'messages': [
          {'role': 'user', 'content': prompt},
        ],
        'temperature': 0.7,
        'response_format': {'type': 'json_object'},
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Groq API error ${response.statusCode}: ${response.body}');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final content =
        (body['choices'] as List)[0]['message']['content'] as String;

    final parsed = jsonDecode(content) as Map<String, dynamic>;
    final recipeList = parsed['recipes'] as List;

    return recipeList.map((r) {
      final map = r as Map<String, dynamic>;
      return Recipe.fromJson({...map, 'id': _uuid.v4()});
    }).toList();
  }
}
