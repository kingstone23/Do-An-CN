import 'dart:convert';
import 'package:http/http.dart' as http;

/// Unofficial Google Translate endpoint (gtx client).
/// Suitable for short texts such as recipe names and descriptions.
/// Rate-limited — do not call in a tight loop.
class TranslateService {
  TranslateService._();
  static final instance = TranslateService._();

  /// Translates [text] into the app language code [appLang] ('VIE' | 'ENG').
  /// Returns the original text on any error (fail-safe).
  Future<String> translate(String text, String appLang) async {
    if (text.trim().isEmpty) return text;
    final tl = appLang == 'ENG' ? 'en' : 'vi';

    final uri = Uri.https(
      'translate.googleapis.com',
      '/translate_a/single',
      {'client': 'gtx', 'sl': 'auto', 'tl': tl, 'dt': 't', 'q': text},
    );

    try {
      final res = await http.get(uri).timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return text;

      final data = jsonDecode(res.body) as List;
      final parts = data[0] as List;
      return parts
          .where((p) => p is List && p.isNotEmpty && p[0] is String)
          .map((p) => (p as List)[0] as String)
          .join();
    } catch (_) {
      return text; // graceful fallback
    }
  }
}
