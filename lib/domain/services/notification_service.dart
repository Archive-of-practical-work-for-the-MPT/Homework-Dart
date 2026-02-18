abstract class NotificationService {
  Future<void> init();

  Future<void> scheduleDailyReviewReminder({
    required int hour,
    required int minute,
  });

  Future<void> cancelAll();
}

