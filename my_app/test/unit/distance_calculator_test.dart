import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/core/utils/distance_calculator.dart';

void main() {
  group('DistanceCalculator Haversine Tests', () {
    test('Calculates 0 meters for identical coordinates', () {
      final distance = DistanceCalculator.calculateHaversineDistance(
        startLatitude: 23.777176,
        startLongitude: 90.399452,
        destinationLatitude: 23.777176,
        destinationLongitude: 90.399452,
      );

      expect(distance, equals(0.0));
    });

    test('Calculates accurate distance between known Dhaka points (~100m)', () {
      // 0.0009 degrees latitude change is approximately 100m
      const startLat = 23.777176;
      const startLng = 90.399452;
      const destLat = 23.778076;
      const destLng = 90.399452;

      final distance = DistanceCalculator.calculateHaversineDistance(
        startLatitude: startLat,
        startLongitude: startLng,
        destinationLatitude: destLat,
        destinationLongitude: destLng,
      );

      expect(distance, greaterThan(95.0));
      expect(distance, lessThan(105.0));
    });

    test('Formats distances correctly', () {
      expect(DistanceCalculator.formatDistance(0), equals('0 m'));
      expect(DistanceCalculator.formatDistance(99), equals('99 m'));
      expect(DistanceCalculator.formatDistance(100), equals('100 m'));
      expect(DistanceCalculator.formatDistance(500), equals('500 m'));
      expect(DistanceCalculator.formatDistance(1000), equals('1.0 km'));
      expect(DistanceCalculator.formatDistance(2540), equals('2.5 km'));
    });

    test('Formats duration correctly', () {
      expect(DistanceCalculator.formatDuration(0), equals('0 min'));
      expect(DistanceCalculator.formatDuration(45), equals('1 min'));
      expect(DistanceCalculator.formatDuration(300), equals('5 mins'));
      expect(DistanceCalculator.formatDuration(3600), equals('1 hr'));
      expect(DistanceCalculator.formatDuration(4500), equals('1 hr 15 mins'));
    });
  });
}
