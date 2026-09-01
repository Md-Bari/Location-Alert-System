class AppConstants {
  static const String appName = 'Location Alert';
  static const String appVersion = '1.0.0';

  // Default Trip Configuration
  static const double defaultWarningDistanceMeters = 100.0;
  static const double defaultArrivalDistanceMeters = 20.0;
  static const bool defaultSoundEnabled = true;
  static const bool defaultVibrationEnabled = true;
  static const bool defaultNotificationsEnabled = true;
  static const bool defaultAppUpdateNotificationsEnabled = true;
  static const bool defaultTrafficEnabled = false;

  // Limits & Validation
  static const double minWarningDistanceMeters = 30.0;
  static const double maxWarningDistanceMeters = 2000.0;
  static const double minArrivalDistanceMeters = 5.0;
  static const double maxArrivalDistanceMeters = 200.0;

  // Storage Keys
  static const String keyWarningDistance = 'warning_distance';
  static const String keyArrivalDistance = 'arrival_distance';
  static const String keySoundEnabled = 'sound_enabled';
  static const String keyVibrationEnabled = 'vibration_enabled';
  static const String keyNotificationsEnabled = 'notifications_enabled';
  static const String keyAppUpdateNotificationsEnabled =
      'app_update_notifications_enabled';
  static const String keyDarkMode = 'dark_mode';
  static const String keyTrafficEnabled = 'traffic_enabled';

  // OpenStreetMap & Traffic Tile Templates
  static const String osmTileUrlTemplate =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  static const String trafficTileUrlTemplate =
      'https://mt1.google.com/vt/lyrs=traffic&x={x}&y={y}&z={z}';
  static const String mapUserAgent = 'com.locationalert.app';
}
