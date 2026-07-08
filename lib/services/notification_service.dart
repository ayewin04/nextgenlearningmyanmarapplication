// lib/services/notification_service.dart
import 'package:flutter/material.dart';

class NotificationService extends ChangeNotifier {
  bool _isEnabled = true;
  bool get isEnabled => _isEnabled;

  NotificationService() {
    _loadPreferences();
  }

  Future<void> initNotifications() async {
    // Disabled for now
    debugPrint('Notifications disabled due to compatibility issues');
  }

  Future<void> _loadPreferences() async {
    // Placeholder
  }

  Future<void> toggleNotifications(bool enabled) async {
    _isEnabled = enabled;
    notifyListeners();
  }

  Future<void> scheduleDailyReminder({
    required String exam,
    int hour = 10,
    int minute = 0,
  }) async {
    // Disabled
  }

  Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    // Disabled
    debugPrint('Notification: $title - $body');
  }

  Future<void> cancelAll() async {
    // Disabled
  }

  Future<void> cancelNotification(int id) async {
    // Disabled
  }

  Future<void> scheduleStreakReminder(int streak) async {
    // Disabled
  }

  Future<void> showAchievement(String achievement) async {
    // Disabled
  }
}