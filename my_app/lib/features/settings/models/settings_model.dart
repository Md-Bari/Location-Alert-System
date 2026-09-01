class SettingsModel {
  final double warningDistance;
  final double arrivalDistance;
  final bool soundEnabled;
  final bool vibrationEnabled;
  final bool notificationsEnabled;
  final bool isDarkMode;

  const SettingsModel({
    required this.warningDistance,
    required this.arrivalDistance,
    required this.soundEnabled,
    required this.vibrationEnabled,
    required this.notificationsEnabled,
    required this.isDarkMode,
  });

  SettingsModel copyWith({
    double? warningDistance,
    double? arrivalDistance,
    bool? soundEnabled,
    bool? vibrationEnabled,
    bool? notificationsEnabled,
    bool? isDarkMode,
  }) {
    return SettingsModel(
      warningDistance: warningDistance ?? this.warningDistance,
      arrivalDistance: arrivalDistance ?? this.arrivalDistance,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      isDarkMode: isDarkMode ?? this.isDarkMode,
    );
  }
}
