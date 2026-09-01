import 'dart:async';
import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:vibration/vibration.dart';
import '../../../core/constants/location_constants.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  /// Initializes the local notification plugin and configures channels for Android & iOS.
  Future<void> init() async {
    if (_isInitialized) return;

    const androidInitSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const darwinInitSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidInitSettings,
      iOS: darwinInitSettings,
    );

    await _flutterLocalNotificationsPlugin.initialize(initSettings);

    // Create high-importance Android Notification Channel for location alerts
    if (Platform.isAndroid) {
      final androidImplementation = _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidImplementation != null) {
        await androidImplementation.createNotificationChannel(
          const AndroidNotificationChannel(
            LocationConstants.notificationChannelId,
            LocationConstants.notificationChannelName,
            description: LocationConstants.notificationChannelDescription,
            importance: Importance.max,
            playSound: true,
            enableVibration: true,
          ),
        );
      }
    }

    _isInitialized = true;
  }

  /// Requests system notification permissions.
  Future<bool> requestPermission() async {
    await init();
    if (Platform.isAndroid) {
      final androidImplementation = _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      final granted =
          await androidImplementation?.requestNotificationsPermission();
      return granted ?? false;
    } else if (Platform.isIOS) {
      final iosImplementation = _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>();
      final granted = await iosImplementation?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }
    return true;
  }

  /// Triggers 100-meter warning notification and alert feedback.
  Future<void> showWarningNotification({
    required String destinationName,
    required double distanceMeters,
    required bool soundEnabled,
    required bool vibrationEnabled,
    required bool notificationsEnabled,
  }) async {
    if (vibrationEnabled) {
      _triggerVibrationPattern(isArrival: false);
    }

    if (!notificationsEnabled) return;
    await init();

    final androidDetails = AndroidNotificationDetails(
      LocationConstants.notificationChannelId,
      LocationConstants.notificationChannelName,
      channelDescription: LocationConstants.notificationChannelDescription,
      importance: Importance.max,
      priority: Priority.high,
      playSound: soundEnabled,
      enableVibration: vibrationEnabled,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentSound: true,
      presentBadge: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _flutterLocalNotificationsPlugin.show(
      LocationConstants.warningNotificationId,
      '⚠️ Approaching Destination!',
      'You are ${distanceMeters.round()}m away from $destinationName.',
      details,
    );
  }

  /// Triggers destination arrival notification and alert feedback.
  Future<void> showArrivalNotification({
    required String destinationName,
    required bool soundEnabled,
    required bool vibrationEnabled,
    required bool notificationsEnabled,
  }) async {
    if (vibrationEnabled) {
      _triggerVibrationPattern(isArrival: true);
    }

    if (!notificationsEnabled) return;
    await init();

    final androidDetails = AndroidNotificationDetails(
      LocationConstants.notificationChannelId,
      LocationConstants.notificationChannelName,
      channelDescription: LocationConstants.notificationChannelDescription,
      importance: Importance.max,
      priority: Priority.max,
      playSound: soundEnabled,
      enableVibration: vibrationEnabled,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentSound: true,
      presentBadge: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _flutterLocalNotificationsPlugin.show(
      LocationConstants.arrivalNotificationId,
      '🔔 Destination Reached!',
      'You have arrived at $destinationName.',
      details,
    );
  }

  /// Cancels active notifications.
  Future<void> cancelNotifications() async {
    await _flutterLocalNotificationsPlugin
        .cancel(LocationConstants.warningNotificationId);
    await _flutterLocalNotificationsPlugin
        .cancel(LocationConstants.arrivalNotificationId);
  }

  void _triggerVibrationPattern({required bool isArrival}) async {
    try {
      final hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator == true) {
        if (isArrival) {
          // Intense multi-burst pattern for arrival
          Vibration.vibrate(pattern: [0, 500, 200, 500, 200, 800]);
        } else {
          // Warning pattern
          Vibration.vibrate(pattern: [0, 400, 200, 400]);
        }
      }
    } catch (_) {
      // Platform vibration unsupported or suppressed
    }
  }
}
