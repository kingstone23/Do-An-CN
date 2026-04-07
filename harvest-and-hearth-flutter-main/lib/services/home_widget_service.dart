import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';

import '../constants/translations.dart';
import '../models/food_item.dart';

/// Android home screen widget (see `HarvestWidgetProvider`).
class HomeWidgetService {
  HomeWidgetService._();
  static final HomeWidgetService instance = HomeWidgetService._();

  Future<void> update(List<FoodItem> items, String language) async {
    if (!Platform.isAndroid) return;
    final lang = language == 'ENG' ? 'ENG' : 'VIE';

    final expiring =
        items.where((e) => e.isExpiringSoon && !e.isExpired).toList();
    final expired = items.where((e) => e.isExpired).toList();

    final line1 = Translations.get('widget_line1', lang)
        .replaceAll('{expiring}', '${expiring.length}')
        .replaceAll('{expired}', '${expired.length}');

    final names = <String>[
      ...expired.map((e) => e.name),
      ...expiring.map((e) => e.name),
    ];
    final line2 = names.take(4).join(', ');
    final line2Short =
        line2.isEmpty ? Translations.get('widget_all_ok', lang) : line2;

    try {
      await HomeWidget.saveWidgetData<String>('line1', line1);
      await HomeWidget.saveWidgetData<String>('expiring_count', '${expiring.length}');
      await HomeWidget.saveWidgetData<String>('expired_count', '${expired.length}');
      await HomeWidget.saveWidgetData<String>(
        'label_expiring',
        Translations.get('widget_label_expiring', lang),
      );
      await HomeWidget.saveWidgetData<String>(
        'label_expired',
        Translations.get('widget_label_expired', lang),
      );
      await HomeWidget.saveWidgetData<String>(
        'subtitle',
        Translations.get('widget_subtitle', lang),
      );
      await HomeWidget.saveWidgetData<String>('line2', line2Short);
      await HomeWidget.updateWidget(
        androidName: 'HarvestWidgetProvider',
        qualifiedAndroidName:
            'com.harvestandhearth.app.HarvestWidgetProvider',
      );
    } catch (e, st) {
      debugPrint('HomeWidgetService.update: $e\n$st');
    }
  }

  Future<void> clear() async {
    if (!Platform.isAndroid) return;
    try {
      await HomeWidget.saveWidgetData<String>('line1', '');
      await HomeWidget.saveWidgetData<String>('expiring_count', '0');
      await HomeWidget.saveWidgetData<String>('expired_count', '0');
      await HomeWidget.saveWidgetData<String>('label_expiring', '');
      await HomeWidget.saveWidgetData<String>('label_expired', '');
      await HomeWidget.saveWidgetData<String>('subtitle', '');
      await HomeWidget.saveWidgetData<String>('line2', '');
      await HomeWidget.updateWidget(
        androidName: 'HarvestWidgetProvider',
        qualifiedAndroidName:
            'com.harvestandhearth.app.HarvestWidgetProvider',
      );
    } catch (e, st) {
      debugPrint('HomeWidgetService.clear: $e\n$st');
    }
  }
}
