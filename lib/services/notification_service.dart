import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  Timer? _taskCheckTimer;

  Future<void> initNotifications() async {
    await AwesomeNotifications().initialize(
      null,
      [
        NotificationChannel(
          channelKey: 'task_reminder_channel',
          channelName: 'Task Reminders',
          channelDescription: 'Reminders for tasks',
          importance: NotificationImportance.Max,
          defaultColor: Colors.blue,
          ledColor: Colors.blue,
          playSound: true,
          enableVibration: true,
        )
      ],
      debug: true,
    );

    bool isAllowed = await AwesomeNotifications().isNotificationAllowed();
    if (!isAllowed) {
      await AwesomeNotifications().requestPermissionToSendNotifications();
    }

    _scheduleDailyReminderCheck();
  }

  Future<void> showNotification(String title, String body) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        channelKey: 'task_reminder_channel',
        title: title,
        body: body,
        notificationLayout: NotificationLayout.Default,
        wakeUpScreen: true,
        fullScreenIntent: true,
      ),
    );
  }

  void _scheduleDailyReminderCheck() {
    _taskCheckTimer?.cancel();

    final now = DateTime.now();
    final next9am = DateTime(now.year, now.month, now.day, 9);
    final delay = now.isAfter(next9am)
        ? next9am.add(Duration(days: 1)).difference(now)
        : next9am.difference(now);

    Timer(delay, () async {
      await _checkTasksForReminders();
      _startCheckingTasksPeriodically();
    });
  }

  void _startCheckingTasksPeriodically() {
    _taskCheckTimer?.cancel();
    _taskCheckTimer = Timer.periodic(Duration(days: 1), (_) async {
      await _checkTasksForReminders();
    });
  }

  Future<void> _checkTasksForReminders() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final check = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('tasks')
        .where('dueDate', isGreaterThan: Timestamp.now())
        .get();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    for (var dc in check.docs) {
      final data = dc.data();
      if (data['dueDate'] == null) continue;

      final dueDate = (data['dueDate'] as Timestamp).toDate();
      final dueOnly = DateTime(dueDate.year, dueDate.month, dueDate.day);
      final daysLeft = dueOnly.difference(today).inDays;

      final title = data['title'];

      if (daysLeft == 1) {
        await showNotification(
          '⏰ Task Reminder!',
          'Only one day left: $title',
        );
      }
    }
  }

  Future<void> onTaskAdded(
      String taskId, String title, DateTime dueDate) async {
    await showNotification(
      'A new task has been added!',
      '$title has been added and End at ${dueDate.day}/${dueDate.month}',
    );
  }

  Future<void> onTaskEdited(
      String taskId, String title, DateTime dueDate) async {
    await showNotification(
      'A Task has been modified! ✏️',
      '$title Has been modified and DueDate is: ${dueDate.day}/${dueDate.month}',
    );
  }

  void dispose() {
    _taskCheckTimer?.cancel();
  }
}
