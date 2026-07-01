import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:namaz_vakitleri/core/models/prayer_time_model.dart';
import 'package:namaz_vakitleri/core/services/storage_service.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  static Future<void> init() async {
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Europe/Istanbul'));

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(settings: initSettings);
    _initialized = true;
  }

  static Future<bool> requestPermission() async {
    try {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (android != null) {
        final granted = await android.requestNotificationsPermission();
        // Exact alarm permissions are granted natively via USE_EXACT_ALARM in manifest,
        // calling requestExactAlarmsPermission() opens settings and can cause UI hang.
        return granted ?? false;
      }
    } catch (e) {
      debugPrint('İzin isteme hatası: $e');
    }
    return true;
  }

  /// Safely cancel a notification - catches platform errors
  static Future<void> _safeCancel(int id) async {
    try {
      await _plugin.cancel(id: id);
    } catch (e) {
      debugPrint('Bildirim iptal hatası (görmezden geliniyor): $e');
      // Known issue with flutter_local_notifications - ignore cancel errors
    }
  }

  static Future<void> schedulePrayerNotification(
    PrayerTimeModel prayer, {
    int minutesBefore = 0,
    bool recurring = false,
  }) async {
    // Ensure initialized
    if (!_initialized) await init();

    // Request permissions first
    await requestPermission();

    // Cancel any existing notification for this prayer (safe - won't throw)
    await _safeCancel(prayer.notificationId);

    final actualTime = prayer.time.subtract(Duration(minutes: minutesBefore));
    var scheduledTime = tz.TZDateTime.from(actualTime, tz.local);

    // For recurring alarms, if time already passed today, schedule for tomorrow
    if (scheduledTime.isBefore(tz.TZDateTime.now(tz.local))) {
      if (recurring) {
        scheduledTime = scheduledTime.add(const Duration(days: 1));
      } else {
        // Non-recurring and in the past - still save to storage
        await StorageService.setAlarmDetails(
          prayer.notificationId,
          enabled: true,
          minutesBefore: minutesBefore,
          recurring: recurring,
        );
        return;
      }
    }

    // Build message
    String title;
    String body;
    if (minutesBefore > 0) {
      title = '🕌 Namaz Vaktine $minutesBefore Dakika';
      body =
          '${prayer.turkishName} (${prayer.arabicName}) vaktine $minutesBefore dakika kaldı. Hazırlanın!';
    } else {
      title = '🕌 Namaz Vakti';
      body =
          '${prayer.turkishName} (${prayer.arabicName}) vakti girdi. Hayırlı namazlar!';
    }

    await _plugin.zonedSchedule(
      id: prayer.notificationId,
      title: title,
      body: body,
      scheduledDate: scheduledTime,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          'prayer_channel',
          'Namaz Vakitleri',
          channelDescription: 'Namaz vakti bildirimleri',
          importance: Importance.max,
          priority: Priority.max,
          color: prayer.color,
          playSound: true,
          enableVibration: true,
          fullScreenIntent: true,
          styleInformation: BigTextStyleInformation(body),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: recurring ? DateTimeComponents.time : null,
    );

    await StorageService.setAlarmDetails(
      prayer.notificationId,
      enabled: true,
      minutesBefore: minutesBefore,
      recurring: recurring,
    );

    debugPrint(
        '✅ Alarm kuruldu: ${prayer.turkishName} -> $scheduledTime (${minutesBefore}dk önce, tekrar: $recurring)');
  }

  static Future<void> cancelPrayerNotification(PrayerTimeModel prayer) async {
    await _safeCancel(prayer.notificationId);
    await StorageService.setAlarmDetails(
      prayer.notificationId,
      enabled: false,
      minutesBefore: 0,
      recurring: false,
    );
  }

  static Future<void> cancelAllNotifications() async {
    try {
      await _plugin.cancelAll();
    } catch (e) {
      debugPrint('Tüm bildirimleri iptal hatası: $e');
    }
  }

  static Future<List<PendingNotificationRequest>>
      getPendingNotifications() async {
    try {
      return await _plugin.pendingNotificationRequests();
    } catch (e) {
      debugPrint('Bekleyen bildirim listesi hatası: $e');
      return [];
    }
  }
}
