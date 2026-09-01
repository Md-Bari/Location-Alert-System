import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';
import '../../features/destination/models/destination_model.dart';

class StorageService {
  final SharedPreferences _prefs;
  static const String keyRecentDestinations = 'recent_destinations';

  StorageService(this._prefs);

  static Future<StorageService> init() async {
    final prefs = await SharedPreferences.getInstance();
    return StorageService(prefs);
  }

  // Warning Distance
  double getWarningDistance() {
    return _prefs.getDouble(AppConstants.keyWarningDistance) ??
        AppConstants.defaultWarningDistanceMeters;
  }

  Future<bool> setWarningDistance(double distance) {
    return _prefs.setDouble(AppConstants.keyWarningDistance, distance);
  }

  // Arrival Distance
  double getArrivalDistance() {
    return _prefs.getDouble(AppConstants.keyArrivalDistance) ??
        AppConstants.defaultArrivalDistanceMeters;
  }

  Future<bool> setArrivalDistance(double distance) {
    return _prefs.setDouble(AppConstants.keyArrivalDistance, distance);
  }

  // Sound Enabled
  bool getSoundEnabled() {
    return _prefs.getBool(AppConstants.keySoundEnabled) ??
        AppConstants.defaultSoundEnabled;
  }

  Future<bool> setSoundEnabled(bool enabled) {
    return _prefs.setBool(AppConstants.keySoundEnabled, enabled);
  }

  // Vibration Enabled
  bool getVibrationEnabled() {
    return _prefs.getBool(AppConstants.keyVibrationEnabled) ??
        AppConstants.defaultVibrationEnabled;
  }

  Future<bool> setVibrationEnabled(bool enabled) {
    return _prefs.setBool(AppConstants.keyVibrationEnabled, enabled);
  }

  // Notifications Enabled
  bool getNotificationsEnabled() {
    return _prefs.getBool(AppConstants.keyNotificationsEnabled) ??
        AppConstants.defaultNotificationsEnabled;
  }

  Future<bool> setNotificationsEnabled(bool enabled) {
    return _prefs.setBool(AppConstants.keyNotificationsEnabled, enabled);
  }

  // Dark Mode
  bool getDarkMode() {
    return _prefs.getBool(AppConstants.keyDarkMode) ?? true;
  }

  Future<bool> setDarkMode(bool enabled) {
    return _prefs.setBool(AppConstants.keyDarkMode, enabled);
  }

  // Recent Destinations (Offline Persistence)
  List<DestinationModel> getRecentDestinations() {
    final rawJson = _prefs.getStringList(keyRecentDestinations) ?? [];
    return rawJson
        .map((str) {
          try {
            return DestinationModel.fromJson(json.decode(str));
          } catch (_) {
            return null;
          }
        })
        .whereType<DestinationModel>()
        .toList();
  }

  Future<bool> saveRecentDestination(DestinationModel destination) async {
    final current = getRecentDestinations();
    // Deduplicate existing entry
    current.removeWhere((d) =>
        d.id == destination.id ||
        (d.latitude == destination.latitude &&
            d.longitude == destination.longitude));

    current.insert(0, destination);
    if (current.length > 10) {
      current.removeLast();
    }

    final rawList = current.map((d) => json.encode(d.toJson())).toList();
    return _prefs.setStringList(keyRecentDestinations, rawList);
  }

  Future<bool> clearRecentDestinations() {
    return _prefs.remove(keyRecentDestinations);
  }
}
