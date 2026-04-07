import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/recipe.dart';

// ── Value objects ──────────────────────────────────────────────────────────

/// Lightweight TheMealDB entry (list view only).
/// Call [RecipeSearchService.getMealById] to get full [Recipe] details.
class MealSummary {
  final String mealDbId;
  final String name;
  final String thumbnailUrl;

  const MealSummary({
    required this.mealDbId,
    required this.name,
    required this.thumbnailUrl,
  });
}

/// Single result from DuckDuckGo Instant Answer API.
class DdgResult {
  final String title;
  final String snippet;
  final String url;

  const DdgResult({
    required this.title,
    required this.snippet,
    required this.url,
  });
}

// ── Service ────────────────────────────────────────────────────────────────

class RecipeSearchService {
  RecipeSearchService._();
  static final instance = RecipeSearchService._();

  static const _mealDbBase = 'https://www.themealdb.com/api/json/v1/1';
  static const _ddgBase = 'https://api.duckduckgo.com/';
  static const _timeout = Duration(seconds: 15);

  // ── TheMealDB ─────────────────────────────────────────────────────────────

  /// Returns lightweight list of Vietnamese dishes (name + thumbnail only).
  Future<List<MealSummary>> getVietnameseDishes() async {
    final res = await http
        .get(Uri.parse('$_mealDbBase/filter.php?a=Vietnamese'))
        .timeout(_timeout);
    if (res.statusCode != 200) throw Exception('TheMealDB ${res.statusCode}');
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final meals = (data['meals'] as List? ?? []);
    return meals
        .map((m) => MealSummary(
              mealDbId: m['idMeal'] as String,
              name: m['strMeal'] as String,
              thumbnailUrl: m['strMealThumb'] as String,
            ))
        .toList();
  }

  /// Full-text search on TheMealDB — returns complete [Recipe] objects.
  Future<List<Recipe>> searchMealDB(String query) async {
    final uri =
        Uri.parse('$_mealDbBase/search.php?s=${Uri.encodeComponent(query)}');
    final res = await http.get(uri).timeout(_timeout);
    if (res.statusCode != 200) throw Exception('TheMealDB ${res.statusCode}');
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final meals = (data['meals'] as List? ?? []);
    return meals.map((m) => _mealToRecipe(m as Map<String, dynamic>)).toList();
  }

  /// Fetch full meal details by TheMealDB id.
  Future<Recipe?> getMealById(String mealId) async {
    final uri = Uri.parse('$_mealDbBase/lookup.php?i=$mealId');
    final res = await http.get(uri).timeout(_timeout);
    if (res.statusCode != 200) return null;
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final meals = data['meals'] as List?;
    if (meals == null || meals.isEmpty) return null;
    return _mealToRecipe(meals.first as Map<String, dynamic>);
  }

  Recipe _mealToRecipe(Map<String, dynamic> m) {
    // Collect non-empty ingredients with their measures
    final ingredients = <String>[];
    for (var i = 1; i <= 20; i++) {
      final ing = (m['strIngredient$i'] as String? ?? '').trim();
      final measure = (m['strMeasure$i'] as String? ?? '').trim();
      if (ing.isNotEmpty) {
        ingredients.add(measure.isEmpty ? ing : '$measure $ing');
      }
    }

    // Split raw instructions into step list
    final raw = m['strInstructions'] as String? ?? '';
    final steps = raw
        .split(RegExp(r'\r?\n'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    final area = m['strArea'] as String? ?? '';
    final category = m['strCategory'] as String? ?? '';
    final descParts = [if (area.isNotEmpty) area, if (category.isNotEmpty) category];

    return Recipe(
      id: 'mealdb_${m['idMeal']}',
      name: m['strMeal'] as String,
      description: descParts.join(' · '),
      difficulty: RecipeDifficulty.medium,
      prepTime: 15,
      cookTime: 30,
      servings: 4,
      calories: 0,
      ingredientsNeeded: ingredients,
      instructions: steps,
      sourceName: 'TheMealDB',
      sourceUrl: 'https://www.themealdb.com/meal/${m['idMeal']}',
      imageKeyword: m['strMealThumb'] as String? ?? '',
    );
  }

  // ── DuckDuckGo ────────────────────────────────────────────────────────────

  /// Queries DuckDuckGo Instant Answer API.
  /// Returns abstract + related topics as [DdgResult] list.
  Future<List<DdgResult>> searchDuckDuckGo(String query) async {
    final uri = Uri.parse(_ddgBase).replace(queryParameters: {
      'q': '$query recipe',
      'format': 'json',
      'no_redirect': '1',
      'no_html': '1',
      'skip_disambig': '1',
    });

    try {
      final res = await http
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return [];

      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final results = <DdgResult>[];

      // Top abstract
      final abstractText = (data['AbstractText'] as String? ?? '').trim();
      final abstractUrl = (data['AbstractURL'] as String? ?? '').trim();
      final heading = (data['Heading'] as String? ?? '').trim();
      if (abstractText.isNotEmpty && abstractUrl.isNotEmpty) {
        results.add(DdgResult(
          title: heading.isEmpty ? query : heading,
          snippet: abstractText,
          url: abstractUrl,
        ));
      }

      // Related topics (up to 6)
      final topics = data['RelatedTopics'] as List? ?? [];
      for (final t in topics.take(6)) {
        if (t is Map<String, dynamic>) {
          final text = (t['Text'] as String? ?? '').trim();
          final url = (t['FirstURL'] as String? ?? '').trim();
          if (text.isNotEmpty && url.isNotEmpty) {
            results.add(DdgResult(
              title: text.length > 70 ? '${text.substring(0, 70)}…' : text,
              snippet: text,
              url: url,
            ));
          }
        }
      }

      return results;
    } catch (_) {
      return [];
    }
  }
}
