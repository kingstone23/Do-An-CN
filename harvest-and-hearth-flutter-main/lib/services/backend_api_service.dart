import 'dart:convert';

import 'package:clerk_flutter/clerk_flutter.dart';
import 'package:http/http.dart' as http;

import '../models/food_item.dart';
import '../models/recipe.dart';

/// REST client for the Harvest & Hearth API (MongoDB behind Node).
/// Requires [attach] with an active [ClerkAuthState] before calls.
class BackendApiService {
  BackendApiService._();
  static final instance = BackendApiService._();

  /// Long enough for Render free-tier cold start + Atlas round-trip.
  static const Duration _kTimeout = Duration(seconds: 45);

  ClerkAuthState? _auth;
  String _base = '';
  /// Reused for connection pooling across API calls (closed on [detach]).
  http.Client? _httpClient;

  http.Client get _http => _httpClient ??= http.Client();

  void configure({required String baseUrl}) {
    _base = baseUrl.replaceAll(RegExp(r'/$'), '');
  }

  bool get isConfigured => _base.isNotEmpty;

  void attach(ClerkAuthState auth) => _auth = auth;

  void detach() {
    _auth = null;
    _httpClient?.close();
    _httpClient = null;
  }

  Future<String> _jwt() async {
    final a = _auth;
    if (a == null) {
      throw StateError('BackendApiService: no Clerk session');
    }
    final t = await a.sessionToken();
    return t.jwt;
  }

  Future<Map<String, String>> _headers() async => {
        'Authorization': 'Bearer ${await _jwt()}',
        'Content-Type': 'application/json',
      };

  Uri _u(String path) => Uri.parse('$_base$path');

  Future<http.Response> _get(Uri url, {Map<String, String>? headers}) =>
      _http.get(url, headers: headers).timeout(_kTimeout);

  Future<http.Response> _delete(Uri url, {Map<String, String>? headers}) =>
      _http.delete(url, headers: headers).timeout(_kTimeout);

  Future<http.Response> _post(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
  }) =>
      _http.post(url, headers: headers, body: body).timeout(_kTimeout);

  Future<http.Response> _put(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
  }) =>
      _http.put(url, headers: headers, body: body).timeout(_kTimeout);

  Future<http.Response> _patch(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
  }) =>
      _http.patch(url, headers: headers, body: body).timeout(_kTimeout);

  void _throwIfBad(http.Response r) {
    if (r.statusCode >= 200 && r.statusCode < 300) return;
    throw BackendApiException(r.statusCode, r.body);
  }

  List<Map<String, dynamic>> _decodeJsonList(String body) {
    final list = jsonDecode(body) as List<dynamic>;
    return List<Map<String, dynamic>>.from(
      list.map((e) => Map<String, dynamic>.from(e as Map)),
    );
  }

  // ── Profile ───────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> getProfile() async {
    final r = await _get(_u('/api/v1/profile'), headers: await _headers());
    _throwIfBad(r);
    return jsonDecode(r.body) as Map<String, dynamic>;
  }

  Future<void> upsertProfile(
    String _, {
    String? name,
    String? email,
  }) async {
    final r = await _put(
      _u('/api/v1/profile'),
      headers: await _headers(),
      body: jsonEncode({
        if (name != null) 'name': name,
        if (email != null) 'email': email,
      }),
    );
    _throwIfBad(r);
  }

  Future<void> updateProfileSettings(
    String _,
    String language,
    bool isDark,
  ) async {
    final r = await _put(
      _u('/api/v1/profile'),
      headers: await _headers(),
      body: jsonEncode({
        'language': language,
        'is_dark': isDark,
      }),
    );
    _throwIfBad(r);
  }

  // ── Food items ─────────────────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getFoodItems(String userId) async {
    final r = await _get(
      _u('/api/v1/food-items'),
      headers: await _headers(),
    );
    _throwIfBad(r);
    return _decodeJsonList(r.body);
  }

  Future<void> insertFoodItem(String userId, FoodItem item) async {
    final r = await _post(
      _u('/api/v1/food-items'),
      headers: await _headers(),
      body: jsonEncode(_foodPayload(item)),
    );
    _throwIfBad(r);
  }

  Future<void> insertFoodItems(String userId, List<FoodItem> items) async {
    final r = await _post(
      _u('/api/v1/food-items'),
      headers: await _headers(),
      body: jsonEncode(items.map(_foodPayload).toList()),
    );
    _throwIfBad(r);
  }

  Map<String, dynamic> _foodPayload(FoodItem item) => {
        'id': item.id,
        'name': item.name,
        'category': item.category.value,
        'storage': item.storage.value,
        'quantity': item.quantity,
        'unit': item.unit,
        'added_date': item.addedDate.toIso8601String(),
        'expiry_date': item.expiryDate?.toIso8601String(),
        'warning_days': item.warningDays,
      };

  Future<void> deleteFoodItem(String itemId) async {
    final r = await _delete(
      _u('/api/v1/food-items/$itemId'),
      headers: await _headers(),
    );
    _throwIfBad(r);
  }

  Future<void> updateFoodItem(FoodItem item) async {
    final r = await _patch(
      _u('/api/v1/food-items/${item.id}'),
      headers: await _headers(),
      body: jsonEncode({
        'name': item.name,
        'category': item.category.value,
        'storage': item.storage.value,
        'quantity': item.quantity,
        'unit': item.unit,
        'added_date': item.addedDate.toIso8601String(),
        'expiry_date': item.expiryDate?.toIso8601String(),
        'warning_days': item.warningDays,
      }),
    );
    _throwIfBad(r);
  }

  // ── Saved recipes ──────────────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getSavedRecipes(String userId) async {
    final r = await _get(
      _u('/api/v1/saved-recipes'),
      headers: await _headers(),
    );
    _throwIfBad(r);
    return _decodeJsonList(r.body);
  }

  Future<void> saveRecipe(String userId, Recipe recipe) async {
    final r = await _post(
      _u('/api/v1/saved-recipes'),
      headers: await _headers(),
      body: jsonEncode({
        'original_id': recipe.id,
        'recipe_data': recipe.toJson(),
      }),
    );
    _throwIfBad(r);
  }

  Future<void> unsaveRecipe(String userId, String originalId) async {
    final enc = Uri.encodeComponent(originalId);
    final r = await _delete(
      _u('/api/v1/saved-recipes/$enc'),
      headers: await _headers(),
    );
    _throwIfBad(r);
  }
}

class BackendApiException implements Exception {
  BackendApiException(this.statusCode, this.body);
  final int statusCode;
  final String body;

  @override
  String toString() => 'BackendApiException($statusCode): $body';
}
