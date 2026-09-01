import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/core/utils/gps_noise_filter.dart';

void main() {
  group('GpsNoiseFilter Tests', () {
    late GpsNoiseFilter filter;

    setUp(() {
      filter = GpsNoiseFilter(maxAcceptableAccuracyMeters: 50.0, windowSize: 5);
    });

    test('Discards inaccurate position readings (>50m accuracy)', () {
      expect(filter.isValidPosition(accuracyMeters: 10.0), isTrue);
      expect(filter.isValidPosition(accuracyMeters: 49.9), isTrue);
      expect(filter.isValidPosition(accuracyMeters: 50.0), isTrue);
      expect(filter.isValidPosition(accuracyMeters: 50.1), isFalse);
      expect(filter.isValidPosition(accuracyMeters: 150.0), isFalse);
    });

    test('Median filter smooths out erratic distance spikes', () {
      // Sequence with noise spike: 150m, 85m, 160m, 90m, 170m
      filter.addAndFilterDistance(150.0);
      filter.addAndFilterDistance(85.0);
      filter.addAndFilterDistance(160.0);
      filter.addAndFilterDistance(90.0);
      final smoothed = filter.addAndFilterDistance(170.0);

      // Sorted window: [85, 90, 150, 160, 170] -> Median is 150.0 (prevents false 85m trigger)
      expect(smoothed, equals(150.0));
    });

    test('Requires consecutive readings to confirm threshold', () {
      filter.addAndFilterDistance(120.0);
      filter.addAndFilterDistance(95.0); // 1st reading below 100m

      // Min consecutive = 2
      expect(
        filter.isThresholdConfirmed(thresholdMeters: 100.0, minConsecutive: 2),
        isFalse,
      );

      filter.addAndFilterDistance(92.0); // 2nd consecutive reading below 100m
      expect(
        filter.isThresholdConfirmed(thresholdMeters: 100.0, minConsecutive: 2),
        isTrue,
      );
    });

    test('Resets filter history properly', () {
      filter.addAndFilterDistance(100.0);
      filter.reset();
      expect(filter.history, isEmpty);
    });
  });
}
