import 'package:latlong2/latlong.dart';

enum LocationPermissionStatus {
  granted,
  denied,
  permanentlyDenied,
  disabled,
  unknown,
}

class AppLocation {
  final double latitude;
  final double longitude;
  final double accuracy;
  final double speed;
  final double heading;
  final DateTime timestamp;

  const AppLocation({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.speed,
    required this.heading,
    required this.timestamp,
  });

  LatLng toLatLng() => LatLng(latitude, longitude);

  /// Speed in km/h, clamped to zero for invalid (negative) readings.
  double get speedKmh => speed > 0 ? speed * 3.6 : 0.0;

  /// Whether [heading] holds a usable direction of travel in degrees.
  bool get hasHeading => heading >= 0 && heading <= 360;

  AppLocation copyWith({
    double? latitude,
    double? longitude,
    double? accuracy,
    double? speed,
    double? heading,
    DateTime? timestamp,
  }) {
    return AppLocation(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      accuracy: accuracy ?? this.accuracy,
      speed: speed ?? this.speed,
      heading: heading ?? this.heading,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  String toString() =>
      'AppLocation(lat: $latitude, lng: $longitude, acc: ${accuracy}m)';
}
