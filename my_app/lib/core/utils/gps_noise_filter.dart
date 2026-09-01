import '../constants/location_constants.dart';

/// Class for protecting alert system against GPS accuracy fluctuations and noise spikes.
class GpsNoiseFilter {
  final double maxAcceptableAccuracyMeters;
  final int windowSize;

  final List<double> _distanceHistory = [];

  GpsNoiseFilter({
    this.maxAcceptableAccuracyMeters = LocationConstants.maxAcceptableAccuracyMeters,
    this.windowSize = LocationConstants.noiseFilterBufferSize,
  });

  /// Evaluates whether a raw GPS position reading meets accuracy standards.
  bool isValidPosition({required double accuracyMeters}) {
    if (accuracyMeters < 0) return false;
    // If accuracy is worse than threshold (e.g. > 50m), mark as noisy/invalid
    return accuracyMeters <= maxAcceptableAccuracyMeters;
  }

  /// Adds a distance measurement (in meters) to history and returns the filtered/smoothed distance.
  double addAndFilterDistance(double rawDistanceMeters) {
    _distanceHistory.add(rawDistanceMeters);
    if (_distanceHistory.length > windowSize) {
      _distanceHistory.removeAt(0);
    }

    return getSmoothedDistance();
  }

  /// Calculates median distance from current window to eliminate outlier spikes.
  double getSmoothedDistance() {
    if (_distanceHistory.isEmpty) return 0.0;
    if (_distanceHistory.length == 1) return _distanceHistory.first;

    final sorted = List<double>.from(_distanceHistory)..sort();
    final middle = sorted.length ~/ 2;

    if (sorted.length % 2 == 1) {
      return sorted[middle];
    } else {
      return (sorted[middle - 1] + sorted[middle]) / 2.0;
    }
  }

  /// Evaluates whether a threshold trigger condition (e.g. warning distance <= 100m) is confirmed
  /// by checking that at least [minConsecutive] recent readings consistently satisfy the condition.
  bool isThresholdConfirmed({
    required double thresholdMeters,
    int minConsecutive = LocationConstants.minRequiredReadingsForConfirm,
  }) {
    if (_distanceHistory.length < minConsecutive) {
      // If we don't have enough history yet, fall back to smoothed distance check
      return getSmoothedDistance() <= thresholdMeters;
    }

    final recentReadings = _distanceHistory.sublist(
      _distanceHistory.length - minConsecutive,
    );

    return recentReadings.every((d) => d <= thresholdMeters);
  }

  /// Resets filter history for a new trip.
  void reset() {
    _distanceHistory.clear();
  }

  List<double> get history => List.unmodifiable(_distanceHistory);
}
