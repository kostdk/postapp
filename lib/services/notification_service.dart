import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;
  bool _timezoneInitialized = false;

  /* ===================== TIMEZONE ===================== */

  void _ensureTimezoneInitialized() {
    if (_timezoneInitialized) return;

    tz.initializeTimeZones();

    try {
      tz.setLocalLocation(tz.getLocation('Europe/Amsterdam'));
      print('✅ Local TZ set: Europe/Amsterdam');
    } catch (e) {
      tz.setLocalLocation(tz.UTC);
      print('⚠️ Fallback to UTC');
    }

    _timezoneInitialized = true;
  }

  /* ===================== INIT ===================== */

  Future<void> initialize() async {
    if (_isInitialized) return;

    _ensureTimezoneInitialized();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        print('📱 Уведомление нажато: ${response.payload}');
      },
    );

    final AndroidFlutterLocalNotificationsPlugin? android = _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    if (android != null) {
      final notificationPermission = await android.requestNotificationsPermission();
      print('🔔 Разрешение на уведомления: $notificationPermission');
      
      // Пытаемся запросить разрешение на точные будильники
      try {
        final exactAlarmPermission = await android.requestExactAlarmsPermission();
        print('⏰ Разрешение на точные будильники: $exactAlarmPermission');
      } catch (e) {
        print('⚠️ Не удалось запросить разрешение на точные будильники: $e');
        print('💡 ВАЖНО: Включите вручную в Настройках → Приложения → postapp → Будильники и напоминания');
      }
      
      await android.createNotificationChannel(
        const AndroidNotificationChannel(
          'notes_channel',
          'Напоминания о заметках',
          description: 'Уведомления для напоминаний',
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
          enableLights: true,
        ),
      );
    }

    _isInitialized = true;
    print('✅ NotificationService инициализирован');
  }

  /* ===================== SCHEDULE ===================== */

  Future<bool> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    try {
      if (!_isInitialized) {
        await initialize();
      }

      _ensureTimezoneInitialized();

      final now = DateTime.now();
      
      print('🕐 Текущее время: $now');
      print('🕐 Время напоминания: $scheduledDate');
      
      if (scheduledDate.isBefore(now) || scheduledDate.isAtSameMomentAs(now)) {
        print('❌ Время напоминания должно быть в будущем!');
        return false;
      }

      final tzDate = tz.TZDateTime.from(scheduledDate, tz.local);
      final nowTz = tz.TZDateTime.now(tz.local);
      
      print('🌍 TZ Now: $nowTz');
      print('🌍 TZ Scheduled: $tzDate');
      print('⏱️  Разница: ${tzDate.difference(nowTz)}');

      if (!tzDate.isAfter(nowTz)) {
        print('❌ Запланированное время не в будущем (после конвертации в TZ)');
        return false;
      }

      await _notifications.zonedSchedule(
        id,
        title,
        body,
        tzDate,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'notes_channel',
            'Напоминания о заметках',
            channelDescription: 'Уведомления для напоминаний',
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
            enableLights: true,
            showWhen: true,
            icon: '@mipmap/ic_launcher',
            largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentSound: true,
            presentBadge: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );

      print('✅ Уведомление запланировано на $tzDate (ID: $id)');
      
      final pending = await _notifications.pendingNotificationRequests();
      print('📋 Всего запланированных уведомлений: ${pending.length}');
      for (var notification in pending) {
        print('   - ID: ${notification.id}, Заголовок: ${notification.title}');
      }
      
      return true;
      
    } catch (e) {
      print('❌ Ошибка планирования уведомления: $e');
      
      // Если ошибка связана с разрешениями
      if (e.toString().contains('exact_alarms_not_permitted')) {
        print('');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        print('⚠️  ТРЕБУЕТСЯ РАЗРЕШЕНИЕ');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        print('Пожалуйста, включите разрешение вручную:');
        print('');
        print('1. Откройте Настройки');
        print('2. Приложения → postapp');
        print('3. Будильники и напоминания → Включить');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        print('');
      }
      
      return false;
    }
  }

  /* ===================== CANCEL ===================== */

  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
    print('🗑️ Уведомление $id отменено');
  }

  Future<void> cancelAll() async {
    await _notifications.cancelAll();
    print('🗑️ Все уведомления отменены');
  }

  /* ===================== DEBUG ===================== */

  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }
}
