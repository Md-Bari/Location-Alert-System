import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/constants/location_constants.dart';
import '../../../core/errors/failure.dart';
import '../models/app_location.dart';

class LocationService {
  /// Checks if device location service (GPS) is enabled.
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Checks current location permission.
  Future<LocationPermissionStatus> checkPermission() async {
    final permission = await Geolocator.checkPermission();
    return _mapPermissionStatus(permission);
  }

  /// Requests location permission.
  Future<LocationPermissionStatus> requestPermission() async {
    final permission = await Geolocator.requestPermission();
    return _mapPermissionStatus(permission);
  }

  /// Gets current high-accuracy GPS position.
  Future<AppLocation> getCurrentLocation() async {
    final serviceEnabled = await isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const LocationServiceDisabledFailure();
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw const LocationPermissionDeniedFailure();
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw const LocationPermissionPermanentlyDeniedFailure();
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 15),
      ),
    );

    return _toAppLocation(position);
  }

  /// Returns last cached OS position (instant, may be stale) or null.
  Future<AppLocation?> getLastKnownLocation() async {
    try {
      final position = await Geolocator.getLastKnownPosition();
      return position == null ? null : _toAppLocation(position);
    } catch (_) {
      return null;
    }
  }

  /// Whether the user granted precise (not approximate) location.
  Future<bool> isPreciseLocationEnabled() async {
    try {
      final status = await Geolocator.getLocationAccuracy();
      return status == LocationAccuracyStatus.precise;
    } catch (_) {
      return true;
    }
  }

  /// Asks for precise location: temporary full accuracy on iOS, app settings on Android.
  Future<void> requestPreciseLocation() async {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      await Geolocator.requestTemporaryFullAccuracy(purposeKey: 'TripTracking');
    } else {
      await Geolocator.openAppSettings();
    }
  }

  Future<bool> openAppSettings() => Geolocator.openAppSettings();

  Future<bool> openLocationSettings() => Geolocator.openLocationSettings();

  /// Emits true/false whenever the device GPS service is switched on or off.
  Stream<bool> getServiceStatusStream() {
    return Geolocator.getServiceStatusStream()
        .map((status) => status == ServiceStatus.enabled);
  }

  /// Returns continuous high-frequency location update stream.
  ///
  /// When [background] is true (active trip), Android runs a foreground service
  /// and iOS keeps updating while the app is backgrounded or the screen is locked.
  Stream<AppLocation> getPositionStream({bool background = false}) {
    final LocationSettings settings;

    if (defaultTargetPlatform == TargetPlatform.android) {
      settings = AndroidSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: LocationConstants.distanceFilterMeters,
        intervalDuration: const Duration(
          milliseconds: LocationConstants.locationUpdateIntervalMs,
        ),
        foregroundNotificationConfig: background
            ? const ForegroundNotificationConfig(
                notificationTitle: 'Trip Location Alert Active',
                notificationText:
                    'Monitoring proximity to destination in real time',
                notificationIcon:
                    AndroidResource(name: 'ic_launcher', defType: 'mipmap'),
                enableWakeLock: true,
                setOngoing: true,
              )
            : null,
      );
    } else if (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      settings = AppleSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        activityType: ActivityType.otherNavigation,
        distanceFilter: LocationConstants.distanceFilterMeters,
        pauseLocationUpdatesAutomatically: false,
        allowBackgroundLocationUpdates: background,
        showBackgroundLocationIndicator: background,
      );
    } else {
      settings = const LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: LocationConstants.distanceFilterMeters,
      );
    }

    return Geolocator.getPositionStream(locationSettings: settings)
        .map(_toAppLocation);
  }

  AppLocation _toAppLocation(Position position) {
    return AppLocation(
      latitude: position.latitude,
      longitude: position.longitude,
      accuracy: position.accuracy,
      speed: position.speed,
      heading: position.heading,
      timestamp: position.timestamp,
    );
  }

  LocationPermissionStatus _mapPermissionStatus(LocationPermission permission) {
    switch (permission) {
      case LocationPermission.always:
      case LocationPermission.whileInUse:
        return LocationPermissionStatus.granted;
      case LocationPermission.denied:
        return LocationPermissionStatus.denied;
      case LocationPermission.deniedForever:
        return LocationPermissionStatus.permanentlyDenied;
      case LocationPermission.unableToDetermine:
        return LocationPermissionStatus.unknown;
    }
  }
}
