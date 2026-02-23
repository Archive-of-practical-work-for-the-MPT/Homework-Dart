import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

import '../../domain/services/notification_service.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Обработка фоновых сообщений
}

class FirebaseNotificationService implements NotificationService {
  static const _reminderChannelId = 'daily_review_reminder';
  static const _reminderNotificationId = 1;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  @override
  Future<void> init() async {
    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Europe/Moscow'));

    final androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    final initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    const androidChannel = AndroidNotificationChannel(
      _reminderChannelId,
      'Напоминания о повторении',
      description: 'Уведомления о времени повторения карточек',
      importance: Importance.high,
    );
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);

    if (Platform.isAndroid) {
      final androidPlugin = _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.requestNotificationsPermission();
      await androidPlugin?.requestExactAlarmsPermission();
    }

    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    await rescheduleFromFirestore();
  }

  void _onNotificationTapped(NotificationResponse response) {
    // Можно открыть экран тренировки
  }

  Future<void> _saveReminderToFirestore(int hour, int minute) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    await _firestore.collection('users').doc(uid).set({
      'reminder': {
        'hour': hour,
        'minute': minute,
      },
    }, SetOptions(merge: true));
  }

  Future<({int hour, int minute})?> _loadReminderFromFirestore() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;

    final doc = await _firestore.collection('users').doc(uid).get();
    final reminder = doc.data()?['reminder'] as Map<String, dynamic>?;
    if (reminder == null) return null;

    final hour = (reminder['hour'] as num?)?.toInt();
    final minute = (reminder['minute'] as num?)?.toInt();
    if (hour == null || minute == null) return null;

    return (hour: hour, minute: minute);
  }

  @override
  Future<void> scheduleDailyReviewReminder({
    required int hour,
    required int minute,
  }) async {
    if (Platform.isAndroid) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    }

    await _saveReminderToFirestore(hour, minute);

    await _localNotifications.cancel(_reminderNotificationId);

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

    const androidDetails = AndroidNotificationDetails(
      _reminderChannelId,
      'Напоминания о повторении',
      channelDescription: 'Уведомления о времени повторения карточек',
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.zonedSchedule(
      _reminderNotificationId,
      'Пора повторить слова!',
      'Откройте приложение и потренируйте карточки.',
      scheduledDate,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  @override
  Future<void> cancelAll() async {
    final uid = _auth.currentUser?.uid;
    if (uid != null) {
      await _firestore.collection('users').doc(uid).update({
        'reminder': FieldValue.delete(),
      });
    }
    await _localNotifications.cancelAll();
  }

  Future<void> rescheduleFromFirestore() async {
    final reminder = await _loadReminderFromFirestore();
    if (reminder != null) {
      await scheduleDailyReviewReminder(
        hour: reminder.hour,
        minute: reminder.minute,
      );
    }
  }
}
