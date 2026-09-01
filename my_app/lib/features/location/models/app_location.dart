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

  @override
  String toString() =>
      'AppLocation(lat: $latitude, lng: $longitude, acc: ${accuracy}m)';
}
