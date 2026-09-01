class LocationConstants {
  // GPS & Filtering Settings
  static const double maxAcceptableAccuracyMeters = 50.0;
  static const int noiseFilterBufferSize = 5;
  static const int minRequiredReadingsForConfirm = 2;
  static const int locationUpdateIntervalMs = 2000; // 2 seconds interval
  static const int distanceFilterMeters = 3; // Minimum movement of 3m

  // Notification Channel Constants
  static const String notificationChannelId = 'location_alert_channel';
  static const String notificationChannelName = 'Location Alerts';
  static const String notificationChannelDescription =
      'Proximity notifications for destination approach and arrival.';
  static const int warningNotificationId = 1001;
  static const int arrivalNotificationId = 1002;
  static const int foregroundServiceNotificationId = 888;
}
