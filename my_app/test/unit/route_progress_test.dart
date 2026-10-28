import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart' hide DistanceCalculator;
import 'package:my_app/core/utils/distance_calculator.dart';
import 'package:my_app/core/utils/route_progress.dart';

void main() {
  group('DistanceCalculator.calculateBearing', () {
    test('returns ~0 degrees when heading due north', () {
      final bearing = DistanceCalculator.calculateBearing(
        startLatitude: 23.0,
        startLongitude: 90.0,
        destinationLatitude: 23.01,
        destinationLongitude: 90.0,
      );
      expect(bearing, closeTo(0, 0.5));
    });

    test('returns ~90 degrees when heading due east', () {
      final bearing = DistanceCalculator.calculateBearing(
        startLatitude: 0.0,
        startLongitude: 90.0,
        destinationLatitude: 0.0,
        destinationLongitude: 90.01,
      );
      expect(bearing, closeTo(90, 0.5));
    });

    test('returns ~270 degrees when heading due west', () {
      final bearing = DistanceCalculator.calculateBearing(
        startLatitude: 0.0,
        startLongitude: 90.0,
        destinationLatitude: 0.0,
        destinationLongitude: 89.99,
      );
      expect(bearing, closeTo(270, 0.5));
    });
  });

  group('RouteProgress.compute', () {
    // Straight east-west route along the equator, ~1113 m per 0.01 degree.
    const route = [
      LatLng(0.0, 90.00),
      LatLng(0.0, 90.01),
      LatLng(0.0, 90.02),
    ];

    test('returns null for an empty route', () {
      expect(RouteProgress.compute(const [], const LatLng(0, 0)), isNull);
    });

    test('snaps a position on the route and computes remaining distance', () {
      final progress = RouteProgress.compute(route, const LatLng(0.0, 90.005))!;

      expect(progress.segmentIndex, 0);
      expect(progress.distanceFromRouteMeters, closeTo(0, 0.5));
      expect(progress.snappedPoint.longitude, closeTo(90.005, 1e-9));
      // 1.5 segments remain.
      expect(progress.remainingDistanceMeters, closeTo(1667.9, 1));
      expect(progress.remainingPoints.first, progress.snappedPoint);
      expect(progress.remainingPoints.last, route.last);
      expect(progress.travelledPoints.first, route.first);
    });

    test('measures perpendicular distance when user is off the route', () {
      // ~111 m north of the second segment.
      final progress = RouteProgress.compute(route, const LatLng(0.001, 90.015))!;

      expect(progress.segmentIndex, 1);
      expect(progress.distanceFromRouteMeters, closeTo(111.2, 1));
      expect(progress.remainingDistanceMeters, closeTo(556.0, 1));
    });

    test('clamps to route end when user has passed the destination', () {
      final progress = RouteProgress.compute(route, const LatLng(0.0, 90.03))!;

      expect(progress.remainingDistanceMeters, closeTo(0, 0.5));
      expect(progress.snappedPoint.longitude, closeTo(90.02, 1e-9));
    });
  });
}
