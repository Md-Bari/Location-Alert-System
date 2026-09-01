import 'dart:async';
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

    return AppLocation(
      latitude: position.latitude,
      longitude: position.longitude,
      accuracy: position.accuracy,
      speed: position.speed,
      heading: position.heading,
      timestamp: position.timestamp,
    );
  }

  /// Returns continuous location update stream with background/foreground service configuration.
  Stream<AppLocation> getPositionStream() {
    late LocationSettings settings;

    // Configure foreground notification for Android persistent tracking
    settings = AndroidSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: LocationConstants.distanceFilterMeters,
      intervalDuration: const Duration(
        milliseconds: LocationConstants.locationUpdateIntervalMs,
      ),
      foregroundNotificationConfig: ForegroundNotificationConfig(
        notificationTitle: "Trip Location Alert Active",
        notificationText: "Monitoring proximity to destination in real time",
        notificationIcon: AndroidResource(name: 'mipmap/ic_launcher'),
        enableWakeLock: true,
      ),
    );

    return Geolocator.getPositionStream(locationSettings: settings).map(
      (position) => AppLocation(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        speed: position.speed,
        heading: position.heading,
        timestamp: position.timestamp,
      ),
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
