import 'package:flutter_test/flutter_test.dart';
import 'package:flow_expense/core/services/notification_service.dart';
import 'package:flow_expense/core/providers/app_settings_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NotificationService', () {
    test('singleton instance exists and constants are properly defined', () {
      final service1 = NotificationService();
      final service2 = NotificationService();

      expect(identical(service1, service2), isTrue);
      expect(NotificationService.dailyReminderId, 1001);
      expect(NotificationService.weeklyBackupReminderId, 1002);
      expect(NotificationService.testNotificationId, 9999);
      expect(NotificationService.reminderChannelId, 'flow_expense_reminders');
    });

    test('schedule and cancel methods fail gracefully when platform bindings absent', () async {
      final service = NotificationService();

      // Should complete without throwing unhandled exceptions in headless test environment
      await service.scheduleDailyReminder(hour: 21, minute: 30);
      await service.cancelDailyReminder();
      await service.scheduleWeeklyBackupReminder();
      await service.cancelWeeklyBackupReminder();
      await service.showTestNotification();
    });

    test('AppSettings incorporates reminder flags and default schedule', () {
      final settings = AppSettings();
      expect(settings.dailyReminderEnabled, isFalse);
      expect(settings.dailyReminderHour, 20);
      expect(settings.dailyReminderMinute, 0);
      expect(settings.backupReminderEnabled, isFalse);

      final updated = settings.copyWith(
        dailyReminderEnabled: true,
        dailyReminderHour: 21,
        dailyReminderMinute: 15,
        backupReminderEnabled: true,
      );

      expect(updated.dailyReminderEnabled, isTrue);
      expect(updated.dailyReminderHour, 21);
      expect(updated.dailyReminderMinute, 15);
      expect(updated.backupReminderEnabled, isTrue);
    });
  });
}
