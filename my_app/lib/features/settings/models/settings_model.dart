class SettingsModel {
  final double warningDistance;
  final double arrivalDistance;
  final bool soundEnabled;
  final bool vibrationEnabled;
  final bool notificationsEnabled;
  final bool isAppUpdateNotificationsEnabled;
  final bool isDarkMode;
  final bool isTrafficEnabled;

  const SettingsModel({
    required this.warningDistance,
    required this.arrivalDistance,
    required this.soundEnabled,
    required this.vibrationEnabled,
    required this.notificationsEnabled,
    required this.isAppUpdateNotificationsEnabled,
    required this.isDarkMode,
    required this.isTrafficEnabled,
  });

  SettingsModel copyWith({
    double? warningDistance,
    double? arrivalDistance,
    bool? soundEnabled,
    bool? vibrationEnabled,
    bool? notificationsEnabled,
    bool? isAppUpdateNotificationsEnabled,
    bool? isDarkMode,
    bool? isTrafficEnabled,
  }) {
    return SettingsModel(
      warningDistance: warningDistance ?? this.warningDistance,
      arrivalDistance: arrivalDistance ?? this.arrivalDistance,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      isAppUpdateNotificationsEnabled: isAppUpdateNotificationsEnabled ??
          this.isAppUpdateNotificationsEnabled,
      isDarkMode: isDarkMode ?? this.isDarkMode,
      isTrafficEnabled: isTrafficEnabled ?? this.isTrafficEnabled,
    );
  }
}
