import 'dart:developer';

import '../../domain/services/notification_service.dart';

class DummyNotificationService implements NotificationService {
  DateTime? _scheduledTime;

  @override
  Future<void> init() async {
    // Здесь позже можно инициализировать реальные уведомления
    log('DummyNotificationService init');
  }

  @override
  Future<void> scheduleDailyReviewReminder({
    required int hour,
    required int minute,
  }) async {
    final now = DateTime.now();
    _scheduledTime = DateTime(now.year, now.month, now.day, hour, minute);
    log('Запланировано ежедневное напоминание о повторении слов на $_scheduledTime');
  }

  @override
  Future<void> cancelAll() async {
    _scheduledTime = null;
    log('Все запланированные напоминания отменены');
  }
}

