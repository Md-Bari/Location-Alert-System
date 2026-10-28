import 'package:latlong2/latlong.dart';

class RouteModel {
  /// Assumed travel speed for estimates without a real route (36 km/h).
  static const double fallbackSpeedMps = 10.0;

  final List<LatLng> points;
  final double distanceMeters;
  final double durationSeconds;
  final bool isStraightLineFallback;

  const RouteModel({
    required this.points,
    required this.distanceMeters,
    required this.durationSeconds,
    this.isStraightLineFallback = false,
  });

  factory RouteModel.straightLine(LatLng start, LatLng destination, double distanceMeters) {
    return RouteModel(
      points: [start, destination],
      distanceMeters: distanceMeters,
      durationSeconds: distanceMeters / fallbackSpeedMps,
      isStraightLineFallback: true,
    );
  }
}
