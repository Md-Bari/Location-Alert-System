import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/services/storage_service.dart';
import '../models/settings_model.dart';

class SettingsNotifier extends StateNotifier<SettingsModel> {
  final StorageService _storageService;

  SettingsNotifier(this._storageService)
    : super(
        SettingsModel(
          warningDistance: _storageService.getWarningDistance(),
          arrivalDistance: _storageService.getArrivalDistance(),
          soundEnabled: _storageService.getSoundEnabled(),
          vibrationEnabled: _storageService.getVibrationEnabled(),
          notificationsEnabled: _storageService.getNotificationsEnabled(),
          isAppUpdateNotificationsEnabled:
              _storageService.getAppUpdateNotificationsEnabled(),
          isDarkMode: _storageService.getDarkMode(),
          isTrafficEnabled: _storageService.getTrafficEnabled(),
        ),
      );

  Future<void> updateWarningDistance(double distance) async {
    final validDistance = distance.clamp(
      AppConstants.minWarningDistanceMeters,
      AppConstants.maxWarningDistanceMeters,
    );
    await _storageService.setWarningDistance(validDistance);
    state = state.copyWith(warningDistance: validDistance);
  }

  Future<void> updateArrivalDistance(double distance) async {
    final validDistance = distance.clamp(
      AppConstants.minArrivalDistanceMeters,
      AppConstants.maxArrivalDistanceMeters,
    );
    await _storageService.setArrivalDistance(validDistance);
    state = state.copyWith(arrivalDistance: validDistance);
  }

  Future<void> setSoundEnabled(bool enabled) async {
    await _storageService.setSoundEnabled(enabled);
    state = state.copyWith(soundEnabled: enabled);
  }

  Future<void> setVibrationEnabled(bool enabled) async {
    await _storageService.setVibrationEnabled(enabled);
    state = state.copyWith(vibrationEnabled: enabled);
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    await _storageService.setNotificationsEnabled(enabled);
    state = state.copyWith(notificationsEnabled: enabled);
  }

  Future<void> setAppUpdateNotificationsEnabled(bool enabled) async {
    await _storageService.setAppUpdateNotificationsEnabled(enabled);
    state = state.copyWith(isAppUpdateNotificationsEnabled: enabled);
  }

  Future<void> toggleDarkMode(bool enabled) async {
    await _storageService.setDarkMode(enabled);
    state = state.copyWith(isDarkMode: enabled);
  }

  Future<void> setTrafficEnabled(bool enabled) async {
    await _storageService.setTrafficEnabled(enabled);
    state = state.copyWith(isTrafficEnabled: enabled);
  }
}

final storageServiceProvider = Provider<StorageService>((ref) {
  throw UnimplementedError(
    'storageServiceProvider must be initialized in ProviderScope overrides',
  );
});

final settingsNotifierProvider =
    StateNotifierProvider<SettingsNotifier, SettingsModel>((ref) {
      final storageService = ref.watch(storageServiceProvider);
      return SettingsNotifier(storageService);
    });
