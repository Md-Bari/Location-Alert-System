import 'dart:math';

/// Utility class for distance calculation between geographical coordinates.
class DistanceCalculator {
  /// Radius of Earth in meters
  static const double earthRadiusMeters = 6371000.0;

  /// Calculates geodesic straight-line distance in meters between two lat/lng points using Haversine formula.
  static double calculateHaversineDistance({
    required double startLatitude,
    required double startLongitude,
    required double destinationLatitude,
    required double destinationLongitude,
  }) {
    final dLat = _toRadians(destinationLatitude - startLatitude);
    final dLng = _toRadians(destinationLongitude - startLongitude);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(startLatitude)) *
            cos(_toRadians(destinationLatitude)) *
            sin(dLng / 2) *
            sin(dLng / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadiusMeters * c;
  }

  static double _toRadians(double degree) {
    return degree * (pi / 180.0);
  }

  /// Formats distance in meters into human-readable string (e.g., "97 m", "1.2 km").
  static String formatDistance(double distanceInMeters) {
    if (distanceInMeters < 0) return '0 m';
    if (distanceInMeters >= 1000) {
      final km = distanceInMeters / 1000;
      return '${km.toStringAsFixed(1)} km';
    } else {
      return '${distanceInMeters.round()} m';
    }
  }

  /// Formats estimated duration in seconds into human-readable string (e.g., "5 mins", "1 hr 12 mins").
  static String formatDuration(double durationInSeconds) {
    if (durationInSeconds <= 0) return '0 min';
    final minutes = (durationInSeconds / 60).round();
    if (minutes < 60) {
      return '$minutes min${minutes == 1 ? '' : 's'}';
    } else {
      final hours = minutes ~/ 60;
      final remMinutes = minutes % 60;
      if (remMinutes == 0) {
        return '$hours hr${hours == 1 ? '' : 's'}';
      }
      return '$hours hr $remMinutes min${remMinutes == 1 ? '' : 's'}';
    }
  }
}
