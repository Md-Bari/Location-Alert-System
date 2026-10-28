import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/location_constants.dart';
import '../../../core/utils/distance_calculator.dart';
import '../models/app_location.dart';
import '../services/location_service.dart';

class LocationState {
  final AppLocation? currentLocation;
  final LocationPermissionStatus permissionStatus;
  final bool isLoading;
  final bool isLive;
  final bool isPreciseLocation;
  final String? errorMessage;

  const LocationState({
    this.currentLocation,
    this.permissionStatus = LocationPermissionStatus.unknown,
    this.isLoading = false,
    this.isLive = false,
    this.isPreciseLocation = true,
    this.errorMessage,
  });

  LocationState copyWith({
    AppLocation? currentLocation,
    LocationPermissionStatus? permissionStatus,
    bool? isLoading,
    bool? isLive,
    bool? isPreciseLocation,
    String? errorMessage,
  }) {
    return LocationState(
      currentLocation: currentLocation ?? this.currentLocation,
      permissionStatus: permissionStatus ?? this.permissionStatus,
      isLoading: isLoading ?? this.isLoading,
      isLive: isLive ?? this.isLive,
      isPreciseLocation: isPreciseLocation ?? this.isPreciseLocation,
      errorMessage: errorMessage,
    );
  }
}

/// Owns the single live GPS stream of the app. Map, route progress and trip
/// alerts all consume [LocationState.currentLocation] from here.
class LocationNotifier extends StateNotifier<LocationState> {
  final LocationService _locationService;

  StreamSubscription<AppLocation>? _positionSubscription;
  StreamSubscription<bool>? _serviceStatusSubscription;
  Timer? _retryTimer;
  bool _backgroundTracking = false;
  double? _lastHeading;

  LocationNotifier(this._locationService) : super(const LocationState()) {
    init();
  }

  Future<void> init() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    _listenToServiceStatus();
    try {
      final serviceEnabled = await _locationService.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _setServiceDisabled();
        return;
      }

      final perm = await _locationService.checkPermission();
      if (perm == LocationPermissionStatus.granted) {
        await _onPermissionGranted();
      } else {
        state = state.copyWith(
          isLoading: false,
          permissionStatus: perm,
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> requestPermissionAndFetchLocation() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      if (state.permissionStatus == LocationPermissionStatus.disabled ||
          !await _locationService.isLocationServiceEnabled()) {
        await _locationService.openLocationSettings();
        state = state.copyWith(isLoading: false);
        return;
      }

      if (state.permissionStatus == LocationPermissionStatus.permanentlyDenied) {
        await _locationService.openAppSettings();
        state = state.copyWith(isLoading: false);
        return;
      }

      final perm = await _locationService.requestPermission();
      state = state.copyWith(permissionStatus: perm);

      if (perm == LocationPermissionStatus.granted) {
        await _onPermissionGranted();
      } else if (perm == LocationPermissionStatus.permanentlyDenied) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Location permission is permanently denied. Tap OPEN to enable it in Settings.',
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Location permission was denied.',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Re-validates permission & GPS state, e.g. after returning from system settings.
  Future<void> onAppResumed() async {
    if (_positionSubscription == null) {
      await init();
    } else {
      final precise = await _locationService.isPreciseLocationEnabled();
      state = state.copyWith(isPreciseLocation: precise, errorMessage: state.errorMessage);
    }
  }

  Future<void> requestPreciseLocation() async {
    await _locationService.requestPreciseLocation();
    final precise = await _locationService.isPreciseLocationEnabled();
    state = state.copyWith(isPreciseLocation: precise, errorMessage: state.errorMessage);
  }

  Future<void> refreshLocation() async {
    try {
      final location = await _locationService.getCurrentLocation();
      _emitLocation(location);
      state = state.copyWith(
        isLoading: false,
        permissionStatus: LocationPermissionStatus.granted,
        errorMessage: null,
      );
      if (_positionSubscription == null) _startPositionStream();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Switches the live stream into (or out of) background mode for an active trip.
  Future<void> setBackgroundTracking(bool enabled) async {
    if (_backgroundTracking == enabled && _positionSubscription != null) return;
    _backgroundTracking = enabled;
    if (state.permissionStatus == LocationPermissionStatus.granted) {
      await _startPositionStream();
    }
  }

  void updateLocationManually(AppLocation location) {
    _emitLocation(location);
    state = state.copyWith(permissionStatus: LocationPermissionStatus.granted);
  }

  Future<void> _onPermissionGranted() async {
    state = state.copyWith(
      permissionStatus: LocationPermissionStatus.granted,
      errorMessage: null,
    );

    // Show the cached fix instantly so the map does not wait for a cold GPS start.
    if (state.currentLocation == null) {
      final lastKnown = await _locationService.getLastKnownLocation();
      if (lastKnown != null && state.currentLocation == null) {
        _emitLocation(lastKnown);
      }
    }

    final precise = await _locationService.isPreciseLocationEnabled();
    state = state.copyWith(isPreciseLocation: precise);

    await _startPositionStream();
  }

  Future<void> _startPositionStream() async {
    _retryTimer?.cancel();
    await _positionSubscription?.cancel();
    _positionSubscription = _locationService
        .getPositionStream(background: _backgroundTracking)
        .listen(
      (location) {
        _emitLocation(location);
        if (state.isLoading || !state.isLive || state.errorMessage != null) {
          state = state.copyWith(isLoading: false, isLive: true, errorMessage: null);
        }
      },
      onError: (Object err) async {
        await _positionSubscription?.cancel();
        _positionSubscription = null;

        final serviceEnabled = await _locationService.isLocationServiceEnabled();
        if (!serviceEnabled) {
          _setServiceDisabled();
          return;
        }

        final perm = await _locationService.checkPermission();
        if (perm != LocationPermissionStatus.granted) {
          state = state.copyWith(isLive: false, isLoading: false, permissionStatus: perm);
          return;
        }

        state = state.copyWith(
          isLive: false,
          isLoading: false,
          errorMessage: 'GPS signal lost. Reconnecting…',
        );
        _retryTimer = Timer(const Duration(seconds: 3), _startPositionStream);
      },
      cancelOnError: true,
    );
  }

  void _listenToServiceStatus() {
    if (_serviceStatusSubscription != null) return;
    try {
      _serviceStatusSubscription =
          _locationService.getServiceStatusStream().listen((enabled) {
        if (!enabled) {
          _positionSubscription?.cancel();
          _positionSubscription = null;
          _setServiceDisabled();
        } else if (_positionSubscription == null) {
          init();
        }
      }, onError: (_) {});
    } catch (_) {
      // Service status stream unsupported on this platform.
    }
  }

  void _setServiceDisabled() {
    state = state.copyWith(
      isLoading: false,
      isLive: false,
      permissionStatus: LocationPermissionStatus.disabled,
      errorMessage: 'Location services are turned off. Turn on GPS to see your live position.',
    );
  }

  /// Publishes a fix, deriving a stable direction of travel when the GPS course is unreliable.
  void _emitLocation(AppLocation location) {
    final previous = state.currentLocation;
    double? heading;

    if (location.hasHeading &&
        location.speed >= LocationConstants.minSpeedForGpsHeadingMps) {
      heading = location.heading;
    } else if (previous != null) {
      final moved = DistanceCalculator.calculateHaversineDistance(
        startLatitude: previous.latitude,
        startLongitude: previous.longitude,
        destinationLatitude: location.latitude,
        destinationLongitude: location.longitude,
      );
      if (moved >= LocationConstants.minMoveForBearingMeters &&
          moved > location.accuracy * 0.5) {
        heading = DistanceCalculator.calculateBearing(
          startLatitude: previous.latitude,
          startLongitude: previous.longitude,
          destinationLatitude: location.latitude,
          destinationLongitude: location.longitude,
        );
      }
    }

    heading ??= _lastHeading;
    _lastHeading = heading;

    state = state.copyWith(
      currentLocation: location.copyWith(heading: heading ?? -1),
      errorMessage: state.errorMessage,
    );
  }

  @override
  void dispose() {
    _retryTimer?.cancel();
    _positionSubscription?.cancel();
    _serviceStatusSubscription?.cancel();
    super.dispose();
  }
}

final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});

final locationNotifierProvider =
    StateNotifierProvider<LocationNotifier, LocationState>((ref) {
  final service = ref.watch(locationServiceProvider);
  return LocationNotifier(service);
});
