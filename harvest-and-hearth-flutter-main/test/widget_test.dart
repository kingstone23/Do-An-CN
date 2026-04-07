import 'package:flutter_test/flutter_test.dart';

import 'package:harvest_and_hearth/constants/translations.dart';

void main() {
  test('Translations VIE returns expected recipe title', () {
    expect(Translations.get('recipes_title', 'VIE'), 'Công thức nấu ăn');
  });

  test('Translations ENG returns expected recipe title', () {
    expect(Translations.get('recipes_title', 'ENG'), 'Recipes');
  });

  test('Difficulty keys differ by language', () {
    expect(Translations.get('recipes_difficulty_easy', 'VIE'), 'Dễ');
    expect(Translations.get('recipes_difficulty_easy', 'ENG'), 'Easy');
  });

  test('Barcode scanner screen title keys exist', () {
    expect(Translations.get('food_scan_title', 'VIE'), contains('QR'));
    expect(Translations.get('food_scan_hint', 'ENG'), isNotEmpty);
  });
}
