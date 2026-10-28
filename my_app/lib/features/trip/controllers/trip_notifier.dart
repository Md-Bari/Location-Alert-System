import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/distance_calculator.dart';
import '../../../core/utils/gps_noise_filter.dart';
import '../../location/controllers/location_notifier.dart';
import '../../location/models/app_location.dart';
import '../../notifications/services/notification_service.dart';
import '../../settings/controllers/settings_notifier.dart';
import '../../settings/models/settings_model.dart';
import '../models/trip_model.dart';

class TripState {
  final TripModel? activeTrip;
  final bool isWarningAlertVisible;
  final bool isArrivalAlertVisible;
  final String? errorMessage;

  const TripState({
    this.activeTrip,
    this.isWarningAlertVisible = false,
    this.isArrivalAlertVisible = false,
    this.errorMessage,
  });

  TripState copyWith({
    TripModel? activeTrip,
    bool clearTrip = false,
    bool? isWarningAlertVisible,
    bool? isArrivalAlertVisible,
    String? errorMessage,
  }) {
    return TripState(
      activeTrip: clearTrip ? null : (activeTrip ?? this.activeTrip),
      isWarningAlertVisible:
          isWarningAlertVisible ?? this.isWarningAlertVisible,
      isArrivalAlertVisible:
          isArrivalAlertVisible ?? this.isArrivalAlertVisible,
      errorMessage: errorMessage,
    );
  }
}

/// Evaluates live positions from [locationNotifierProvider] against proximity alert thresholds.
class TripNotifier extends StateNotifier<TripState> {
  final NotificationService _notificationService;
  final GpsNoiseFilter _noiseFilter = GpsNoiseFilter();

  /// Called with true while a trip needs uninterrupted (background) GPS updates.
  final void Function(bool active)? onActiveTrackingChanged;
  SettingsModel _settings;

  TripNotifier(
    this._notificationService,
    this._settings, {
    this.onActiveTrackingChanged,
  }) : super(const TripState());

  void updateSettings(SettingsModel newSettings) {
    _settings = newSettings;
  }

  /// Starts continuous tracking for a new trip towards selected destination.
  Future<void> startTrip({
    required AppLocation currentLocation,
    required double destinationLat,
    required double destinationLng,
    required String destinationName,
  }) async {
    _noiseFilter.reset();

    final initialDistance = DistanceCalculator.calculateHaversineDistance(
      startLatitude: currentLocation.latitude,
      startLongitude: currentLocation.longitude,
      destinationLatitude: destinationLat,
      destinationLongitude: destinationLng,
    );

    final trip = TripModel(
      tripId: 'trip_${DateTime.now().millisecondsSinceEpoch}',
      startLatitude: currentLocation.latitude,
      startLongitude: currentLocation.longitude,
      destinationLatitude: destinationLat,
      destinationLongitude: destinationLng,
      destinationName: destinationName,
      warningDistance: _settings.warningDistance,
      arrivalDistance: _settings.arrivalDistance,
      trackingStatus: TrackingStatus.tracking,
      warningTriggered: false,
      arrivalTriggered: false,
      startTime: DateTime.now(),
      currentDistanceMeters: initialDistance,
      currentAccuracyMeters: currentLocation.accuracy,
    );

    _noiseFilter.addAndFilterDistance(initialDistance);

    state = state.copyWith(
      activeTrip: trip,
      isWarningAlertVisible: false,
      isArrivalAlertVisible: false,
      errorMessage: null,
    );

    onActiveTrackingChanged?.call(true);
    _notificationService.requestPermission();
  }

  /// Evaluates location updates against GPS noise filters and proximity alert thresholds.
  void handleLocationUpdate(AppLocation location) {
    final trip = state.activeTrip;
    if (trip == null ||
        trip.trackingStatus == TrackingStatus.paused ||
        trip.trackingStatus == TrackingStatus.completed ||
        trip.trackingStatus == TrackingStatus.arrived) {
      return;
    }

    // 1. Validate GPS Accuracy
    if (!_noiseFilter.isValidPosition(accuracyMeters: location.accuracy)) {
      // Discard inaccurate reading but record current accuracy for UI feedback
      state = state.copyWith(
        activeTrip: trip.copyWith(currentAccuracyMeters: location.accuracy),
      );
      return;
    }

    // 2. Calculate raw distance to destination
    final rawDistance = DistanceCalculator.calculateHaversineDistance(
      startLatitude: location.latitude,
      startLongitude: location.longitude,
      destinationLatitude: trip.destinationLatitude,
      destinationLongitude: trip.destinationLongitude,
    );

    // 3. Smooth raw distance using noise filter
    final smoothedDistance = _noiseFilter.addAndFilterDistance(rawDistance);

    var updatedTrip = trip.copyWith(
      currentDistanceMeters: smoothedDistance,
      currentAccuracyMeters: location.accuracy,
    );

    // 4. Check Arrival Threshold (e.g. <= 20 meters)
    if (smoothedDistance <= trip.arrivalDistance && !trip.arrivalTriggered) {
      final confirmed = _noiseFilter.isThresholdConfirmed(
        thresholdMeters: trip.arrivalDistance,
      );

      if (confirmed) {
        updatedTrip = updatedTrip.copyWith(
          trackingStatus: TrackingStatus.arrived,
          arrivalTriggered: true,
          endTime: DateTime.now(),
        );

        state = state.copyWith(
          activeTrip: updatedTrip,
          isArrivalAlertVisible: true,
        );

        _notificationService.showArrivalNotification(
          destinationName: trip.destinationName,
          soundEnabled: _settings.soundEnabled,
          vibrationEnabled: _settings.vibrationEnabled,
          notificationsEnabled: _settings.notificationsEnabled,
        );

        stopTrackingStream();
        return;
      }
    }

    // 5. Check Warning Threshold (e.g. <= 100 meters)
    if (smoothedDistance <= trip.warningDistance && !trip.warningTriggered) {
      final confirmed = _noiseFilter.isThresholdConfirmed(
        thresholdMeters: trip.warningDistance,
      );

      if (confirmed) {
        updatedTrip = updatedTrip.copyWith(
          trackingStatus: TrackingStatus.approaching,
          warningTriggered: true,
        );

        state = state.copyWith(
          activeTrip: updatedTrip,
          isWarningAlertVisible: true,
        );

        _notificationService.showWarningNotification(
          destinationName: trip.destinationName,
          distanceMeters: smoothedDistance,
          soundEnabled: _settings.soundEnabled,
          vibrationEnabled: _settings.vibrationEnabled,
          notificationsEnabled: _settings.notificationsEnabled,
        );
      }
    }

    state = state.copyWith(activeTrip: updatedTrip);
  }

  void dismissWarningAlert() {
    state = state.copyWith(isWarningAlertVisible: false);
  }

  void dismissArrivalAlert() {
    state = state.copyWith(isArrivalAlertVisible: false);
  }

  void pauseTrip() {
    final trip = state.activeTrip;
    if (trip == null) return;
    onActiveTrackingChanged?.call(false);
    state = state.copyWith(
      activeTrip: trip.copyWith(trackingStatus: TrackingStatus.paused),
    );
  }

  void resumeTrip() {
    final trip = state.activeTrip;
    if (trip == null) return;
    onActiveTrackingChanged?.call(true);
    state = state.copyWith(
      activeTrip: trip.copyWith(
        trackingStatus: trip.warningTriggered
            ? TrackingStatus.approaching
            : TrackingStatus.tracking,
      ),
    );
  }

  void endTrip() {
    // 1. Immediately reset state synchronously for 0ms UI latency
    state = state.copyWith(
      clearTrip: true,
      isWarningAlertVisible: false,
      isArrivalAlertVisible: false,
      errorMessage: null,
    );

    // 2. Perform platform cleanup asynchronously in background
    stopTrackingStream();
    _notificationService.cancelNotifications();
  }

  /// Leaves background GPS mode; the foreground live stream keeps running for the map.
  Future<void> stopTrackingStream() async {
    onActiveTrackingChanged?.call(false);
  }
}

final tripNotifierProvider =
    StateNotifierProvider<TripNotifier, TripState>((ref) {
  final notificationService = ref.watch(notificationServiceProvider);

  // Read (not watch) settings: watching would rebuild the notifier and wipe an active trip
  // whenever any setting changes, e.g. toggling the traffic layer.
  final notifier = TripNotifier(
    notificationService,
    ref.read(settingsNotifierProvider),
    onActiveTrackingChanged: (active) {
      ref.read(locationNotifierProvider.notifier).setBackgroundTracking(active);
    },
  );
  ref.listen<SettingsModel>(settingsNotifierProvider, (previous, next) {
    notifier.updateSettings(next);
  });

  // Feed every live GPS fix into the alert engine.
  ref.listen<LocationState>(locationNotifierProvider, (previous, next) {
    final location = next.currentLocation;
    if (location != null && !identical(location, previous?.currentLocation)) {
      notifier.handleLocationUpdate(location);
    }
  });

  return notifier;
});
