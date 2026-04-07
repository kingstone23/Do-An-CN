import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../constants/translations.dart';
import '../models/food_item.dart';

/// Daily summary at 09:00 local time when there are expired / expiring-soon items.
class ExpiryReminderService {
  ExpiryReminderService._();
  static final ExpiryReminderService instance = ExpiryReminderService._();

  static const prefsKeyEnabled = 'expiry_reminders_enabled';
  static const _channelId = 'harvest_expiry';
  /// High-importance channel for immediate / heads-up notifications (Android 8+).
  static const _channelIdImmediate = 'harvest_expiry_immediate';
  static const _notificationIdSummary = 10001;
  static const _notificationIdSimulatorTest = 10002;

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    tzdata.initializeTimeZones();
    try {
      final tzName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(tzName));
    } catch (e, st) {
      debugPrint('ExpiryReminderService timezone: $e\n$st');
      tz.setLocalLocation(tz.getLocation('UTC'));
    }

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    await _plugin.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
    );

    if (Platform.isAndroid) {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await android?.createNotificationChannel(
        const AndroidNotificationChannel(
          _channelId,
          'Nhắc hạn thực phẩm',
          description: 'Thông báo khi có mặt hàng sắp hết hạn hoặc đã hết hạn',
          importance: Importance.defaultImportance,
        ),
      );
      await android?.createNotificationChannel(
        const AndroidNotificationChannel(
          _channelIdImmediate,
          'Harvest & Hearth — Thông báo ngay',
          description: 'Thông báo thử và cảnh báo hiển thị ngay',
          importance: Importance.high,
        ),
      );
    }
    _initialized = true;
  }

  Future<bool> remindersEnabled() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(prefsKeyEnabled) ?? true;
  }

  Future<void> setRemindersEnabled(bool value) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(prefsKeyEnabled, value);
    if (!value) {
      await cancelAll();
    }
  }

  Future<void> requestPostNotificationsPermissionIfNeeded() async {
    if (!Platform.isAndroid) return;
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.requestNotificationsPermission();
  }

  Future<void> syncInventory(
    List<FoodItem> items, {
    required String language,
  }) async {
    if (!_initialized) await init();
    final enabled = await remindersEnabled();
    if (!enabled) {
      await _plugin.cancel(_notificationIdSummary);
      return;
    }

    final expiring = items.where((e) => e.isExpiringSoon && !e.isExpired).length;
    final expired = items.where((e) => e.isExpired).length;
    if (expiring == 0 && expired == 0) {
      await _plugin.cancel(_notificationIdSummary);
      return;
    }

    final lang = language == 'ENG' ? 'ENG' : 'VIE';
    final title = Translations.get('expiry_notif_title', lang);
    final body = Translations.get('expiry_notif_body', lang)
        .replaceAll('{expired}', '$expired')
        .replaceAll('{expiring}', '$expiring');

    final android = AndroidNotificationDetails(
      _channelId,
      'Nhắc hạn thực phẩm',
      channelDescription: 'Tóm tắt mỗi ngày lúc 9:00',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );
    const ios = DarwinNotificationDetails();
    final details = NotificationDetails(android: android, iOS: ios);

    await _plugin.cancel(_notificationIdSummary);

    final scheduled = _nextNineAm();
    try {
      await _plugin.zonedSchedule(
        _notificationIdSummary,
        title,
        body,
        scheduled,
        details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e, st) {
      debugPrint('ExpiryReminderService zonedSchedule: $e\n$st');
    }
  }

  tz.TZDateTime _nextNineAm() {
    final now = tz.TZDateTime.now(tz.local);
    var t = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      9,
      0,
    );
    if (!t.isAfter(now)) {
      t = t.add(const Duration(days: 1));
    }
    return t;
  }

  Future<void> cancelAll() async {
    if (!_initialized) await init();
    await _plugin.cancel(_notificationIdSummary);
    await _plugin.cancel(_notificationIdSimulatorTest);
  }

  /// Immediate notification with the same copy as the daily summary (QA / time simulator).
  /// Returns `false` if the user denied notification permission (Android 13+ / iOS).
  Future<bool> showImmediateTestSummary({
    required int expiring,
    required int expired,
    required String language,
  }) async {
    if (!_initialized) await init();

    if (Platform.isAndroid) {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final granted = await android?.requestNotificationsPermission();
      if (granted == false) {
        debugPrint('ExpiryReminderService: POST_NOTIFICATIONS denied');
        return false;
      }
    } else if (Platform.isIOS) {
      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      final ok = await ios?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      if (ok == false) {
        debugPrint('ExpiryReminderService: iOS notification permission denied');
        return false;
      }
    }

    final lang = language == 'ENG' ? 'ENG' : 'VIE';
    final title = Translations.get('expiry_notif_title', lang);
    final body = Translations.get('expiry_notif_body', lang)
        .replaceAll('{expired}', '$expired')
        .replaceAll('{expiring}', '$expiring');

    final android = AndroidNotificationDetails(
      _channelIdImmediate,
      'Harvest & Hearth — Thông báo ngay',
      channelDescription: 'Thông báo thử và cảnh báo hiển thị ngay',
      importance: Importance.high,
      priority: Priority.high,
      visibility: NotificationVisibility.public,
      showWhen: true,
      enableVibration: true,
      playSound: true,
    );
    const ios = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    final details = NotificationDetails(android: android, iOS: ios);

    try {
      await _plugin.show(
        _notificationIdSimulatorTest,
        title,
        body,
        details,
      );
      return true;
    } catch (e, st) {
      debugPrint('ExpiryReminderService showImmediateTestSummary: $e\n$st');
      return false;
    }
  }
}
