import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Service handling local, on-device scheduled reminders (Daily Expense & Weekly Backup)
/// without any remote push servers or external backend dependencies.
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  static const int dailyReminderId = 1001;
  static const int weeklyBackupReminderId = 1002;
  static const int testNotificationId = 9999;

  static const String reminderChannelId = 'flow_expense_reminders';
  static const String reminderChannelName = 'Expense & Backup Reminders';
  static const String reminderChannelDesc =
      'Daily reminders to log transactions and weekly backup reminders';

  /// Initializes timezone data and native notification channels.
  Future<void> initialize() async {
    if (_isInitialized || kIsWeb) return;

    try {
      tz.initializeTimeZones();
    } catch (_) {}

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    try {
      await _notifications.initialize(settings: initSettings);
      _isInitialized = true;
    } catch (e) {
      debugPrint('NotificationService.initialize error: $e');
    }
  }

  /// Requests notification permissions on iOS and Android 13+.
  Future<bool> requestPermissions() async {
    if (kIsWeb) return false;
    await initialize();

    try {
      bool granted = false;

      if (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS) {
        final res = await _notifications
            .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin>()
            ?.requestPermissions(
              alert: true,
              badge: true,
              sound: true,
            );
        granted = res ?? false;
      } else if (defaultTargetPlatform == TargetPlatform.android) {
        final androidImplementation = _notifications
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();
        final res = await androidImplementation?.requestNotificationsPermission();
        granted = res ?? false;
      }

      return granted;
    } catch (e) {
      debugPrint('NotificationService.requestPermissions error: $e');
      return false;
    }
  }

  /// Schedules a recurring daily reminder at [hour]:[minute].
  Future<void> scheduleDailyReminder({
    required int hour,
    required int minute,
  }) async {
    if (kIsWeb) return;
    await initialize();

    try {
      final now = tz.TZDateTime.now(tz.local);
      var scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        hour,
        minute,
      );

      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      const notificationDetails = NotificationDetails(
        android: AndroidNotificationDetails(
          reminderChannelId,
          reminderChannelName,
          channelDescription: reminderChannelDesc,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );

      await _notifications.zonedSchedule(
        id: dailyReminderId,
        title: 'Flow Expense',
        body: "Don't forget to record your spending for today! 💸",
        scheduledDate: scheduledDate,
        notificationDetails: notificationDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e) {
      debugPrint('NotificationService.scheduleDailyReminder error: $e');
    }
  }

  /// Cancels the daily expense reminder.
  Future<void> cancelDailyReminder() async {
    if (kIsWeb) return;
    try {
      await _notifications.cancel(id: dailyReminderId);
    } catch (e) {
      debugPrint('NotificationService.cancelDailyReminder error: $e');
    }
  }

  /// Schedules a recurring weekly reminder (every Sunday at 8:00 PM).
  Future<void> scheduleWeeklyBackupReminder() async {
    if (kIsWeb) return;
    await initialize();

    try {
      final now = tz.TZDateTime.now(tz.local);
      int daysUntilSunday = (DateTime.sunday - now.weekday) % 7;
      var scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        20, // 8:00 PM
        0,
      ).add(Duration(days: daysUntilSunday));

      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 7));
      }

      const notificationDetails = NotificationDetails(
        android: AndroidNotificationDetails(
          reminderChannelId,
          reminderChannelName,
          channelDescription: reminderChannelDesc,
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );

      await _notifications.zonedSchedule(
        id: weeklyBackupReminderId,
        title: 'Flow Expense • Weekly Backup',
        body: 'Time for your weekly check-in! Sync to Google Sheets or backup your data 📊',
        scheduledDate: scheduledDate,
        notificationDetails: notificationDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );
    } catch (e) {
      debugPrint('NotificationService.scheduleWeeklyBackupReminder error: $e');
    }
  }

  /// Cancels the weekly backup reminder.
  Future<void> cancelWeeklyBackupReminder() async {
    if (kIsWeb) return;
    try {
      await _notifications.cancel(id: weeklyBackupReminderId);
    } catch (e) {
      debugPrint('NotificationService.cancelWeeklyBackupReminder error: $e');
    }
  }

  /// Sends an immediate test notification to verify sounds, banners, and lock screen alerts.
  Future<void> showTestNotification() async {
    if (kIsWeb) return;
    await initialize();
    await requestPermissions();

    try {
      const notificationDetails = NotificationDetails(
        android: AndroidNotificationDetails(
          reminderChannelId,
          reminderChannelName,
          channelDescription: reminderChannelDesc,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );

      await _notifications.show(
        id: testNotificationId,
        title: 'Flow Expense • Test Notification',
        body: 'Reminders are working! You will receive daily & weekly expense alerts on time. ✨',
        notificationDetails: notificationDetails,
      );
    } catch (e) {
      debugPrint('NotificationService.showTestNotification error: $e');
    }
  }
}
