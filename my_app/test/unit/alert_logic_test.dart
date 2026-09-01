import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/features/trip/models/trip_model.dart';

void main() {
  group('Trip Alert Logic & State Transition Tests', () {
    test('Initial trip state has single-trigger flags set to false', () {
      final trip = TripModel(
        tripId: 'test_1',
        startLatitude: 23.77,
        startLongitude: 90.39,
        destinationLatitude: 23.78,
        destinationLongitude: 90.40,
        destinationName: 'Test Target',
        warningDistance: 100.0,
        arrivalDistance: 20.0,
        trackingStatus: TrackingStatus.tracking,
        warningTriggered: false,
        arrivalTriggered: false,
        startTime: DateTime.now(),
      );

      expect(trip.warningTriggered, isFalse);
      expect(trip.arrivalTriggered, isFalse);
      expect(trip.trackingStatus, equals(TrackingStatus.tracking));
    });

    test('Warning state update sets warningTriggered to true once', () {
      final trip = TripModel(
        tripId: 'test_1',
        startLatitude: 23.77,
        startLongitude: 90.39,
        destinationLatitude: 23.78,
        destinationLongitude: 90.40,
        destinationName: 'Test Target',
        warningDistance: 100.0,
        arrivalDistance: 20.0,
        trackingStatus: TrackingStatus.tracking,
        warningTriggered: false,
        arrivalTriggered: false,
        startTime: DateTime.now(),
      );

      final approachingTrip = trip.copyWith(
        trackingStatus: TrackingStatus.approaching,
        warningTriggered: true,
        currentDistanceMeters: 95.0,
      );

      expect(approachingTrip.warningTriggered, isTrue);
      expect(approachingTrip.trackingStatus, equals(TrackingStatus.approaching));

      // Subsequent update maintains warningTriggered true
      final nextUpdateTrip = approachingTrip.copyWith(
        currentDistanceMeters: 80.0,
      );
      expect(nextUpdateTrip.warningTriggered, isTrue);
    });

    test('Arrival state update sets arrivalTriggered and updates status', () {
      final trip = TripModel(
        tripId: 'test_1',
        startLatitude: 23.77,
        startLongitude: 90.39,
        destinationLatitude: 23.78,
        destinationLongitude: 90.40,
        destinationName: 'Test Target',
        warningDistance: 100.0,
        arrivalDistance: 20.0,
        trackingStatus: TrackingStatus.approaching,
        warningTriggered: true,
        arrivalTriggered: false,
        startTime: DateTime.now(),
      );

      final arrivedTrip = trip.copyWith(
        trackingStatus: TrackingStatus.arrived,
        arrivalTriggered: true,
        currentDistanceMeters: 15.0,
        endTime: DateTime.now(),
      );

      expect(arrivedTrip.arrivalTriggered, isTrue);
      expect(arrivedTrip.trackingStatus, equals(TrackingStatus.arrived));
      expect(arrivedTrip.endTime, isNotNull);
    });
  });
}
