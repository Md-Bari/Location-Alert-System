class LocationConstants {
  // GPS & Filtering Settings
  static const double maxAcceptableAccuracyMeters = 50.0;
  static const int noiseFilterBufferSize = 5;
  static const int minRequiredReadingsForConfirm = 2;
  static const int locationUpdateIntervalMs = 1000; // 1 second interval
  static const int distanceFilterMeters = 1; // Minimum movement of 1m

  // Live Map Tracking
  static const double minSpeedForGpsHeadingMps = 0.8; // ~3 km/h
  static const double minMoveForBearingMeters = 4.0;
  static const int markerAnimationMs = 900;
  static const double followZoom = 17.0;
  static const double navigationZoom = 18.0;

  // Route Re-calculation
  static const double offRouteThresholdMeters = 40.0;
  static const int rerouteCooldownSeconds = 20;

  // Notification Channel Constants
  static const String notificationChannelId = 'location_alert_channel';
  static const String notificationChannelName = 'Location Alerts';
  static const String notificationChannelDescription =
      'Proximity notifications for destination approach and arrival.';
  static const int warningNotificationId = 1001;
  static const int arrivalNotificationId = 1002;
  static const int foregroundServiceNotificationId = 888;
}
