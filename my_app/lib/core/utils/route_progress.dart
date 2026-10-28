import 'dart:math';

import 'package:latlong2/latlong.dart' hide DistanceCalculator;

import 'distance_calculator.dart';

/// Result of snapping the user's live position onto a route polyline.
class RouteProgress {
  /// Index of the route segment (points[segmentIndex] -> points[segmentIndex + 1]) the user is on.
  final int segmentIndex;

  /// Closest point on the route to the user's position.
  final LatLng snappedPoint;

  /// Perpendicular distance in meters between the user and the route.
  final double distanceFromRouteMeters;

  /// Distance in meters left to travel along the route.
  final double remainingDistanceMeters;

  /// Route points still ahead of the user, starting at [snappedPoint].
  final List<LatLng> remainingPoints;

  /// Route points already travelled, ending at [snappedPoint].
  final List<LatLng> travelledPoints;

  const RouteProgress({
    required this.segmentIndex,
    required this.snappedPoint,
    required this.distanceFromRouteMeters,
    required this.remainingDistanceMeters,
    required this.remainingPoints,
    required this.travelledPoints,
  });

  /// Snaps [position] onto [points] and returns progress, or null when the route has no points.
  static RouteProgress? compute(List<LatLng> points, LatLng position) {
    if (points.isEmpty) return null;
    if (points.length == 1) {
      final d = _distance(position, points.first);
      return RouteProgress(
        segmentIndex: 0,
        snappedPoint: points.first,
        distanceFromRouteMeters: d,
        remainingDistanceMeters: d,
        remainingPoints: [points.first],
        travelledPoints: [points.first],
      );
    }

    var bestIndex = 0;
    var bestT = 0.0;
    var bestDistance = double.infinity;

    // Local equirectangular projection around the user (accurate for route-scale distances).
    final cosLat = cos(position.latitude * pi / 180.0);
    Point<double> project(LatLng p) => Point(
          (p.longitude - position.longitude) * cosLat,
          p.latitude - position.latitude,
        );

    for (var i = 0; i < points.length - 1; i++) {
      final a = project(points[i]);
      final b = project(points[i + 1]);
      final abX = b.x - a.x;
      final abY = b.y - a.y;
      final lengthSq = abX * abX + abY * abY;

      // User is at the origin of the projection, so AP = -A.
      var t = lengthSq == 0 ? 0.0 : (-a.x * abX + -a.y * abY) / lengthSq;
      t = t.clamp(0.0, 1.0);

      final px = a.x + abX * t;
      final py = a.y + abY * t;
      final distSq = px * px + py * py;

      if (distSq < bestDistance) {
        bestDistance = distSq;
        bestIndex = i;
        bestT = t;
      }
    }

    final a = points[bestIndex];
    final b = points[bestIndex + 1];
    final snapped = LatLng(
      a.latitude + (b.latitude - a.latitude) * bestT,
      a.longitude + (b.longitude - a.longitude) * bestT,
    );

    var remaining = _distance(snapped, b);
    for (var i = bestIndex + 1; i < points.length - 1; i++) {
      remaining += _distance(points[i], points[i + 1]);
    }

    return RouteProgress(
      segmentIndex: bestIndex,
      snappedPoint: snapped,
      distanceFromRouteMeters: _distance(position, snapped),
      remainingDistanceMeters: remaining,
      remainingPoints: [snapped, ...points.sublist(bestIndex + 1)],
      travelledPoints: [...points.sublist(0, bestIndex + 1), snapped],
    );
  }

  static double _distance(LatLng a, LatLng b) {
    return DistanceCalculator.calculateHaversineDistance(
      startLatitude: a.latitude,
      startLongitude: a.longitude,
      destinationLatitude: b.latitude,
      destinationLongitude: b.longitude,
    );
  }
}
