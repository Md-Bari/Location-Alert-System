enum TrackingStatus {
  idle,
  destinationSelected,
  tracking,
  approaching,
  arrived,
  completed,
  paused,
}

class TripModel {
  final String tripId;
  final double startLatitude;
  final double startLongitude;
  final double destinationLatitude;
  final double destinationLongitude;
  final String destinationName;
  final double warningDistance;
  final double arrivalDistance;
  final TrackingStatus trackingStatus;
  final bool warningTriggered;
  final bool arrivalTriggered;
  final DateTime startTime;
  final DateTime? endTime;

  // Real-time tracking progress metadata
  final double? currentDistanceMeters;
  final double? currentAccuracyMeters;

  const TripModel({
    required this.tripId,
    required this.startLatitude,
    required this.startLongitude,
    required this.destinationLatitude,
    required this.destinationLongitude,
    required this.destinationName,
    required this.warningDistance,
    required this.arrivalDistance,
    required this.trackingStatus,
    required this.warningTriggered,
    required this.arrivalTriggered,
    required this.startTime,
    this.endTime,
    this.currentDistanceMeters,
    this.currentAccuracyMeters,
  });

  TripModel copyWith({
    String? tripId,
    double? startLatitude,
    double? startLongitude,
    double? destinationLatitude,
    double? destinationLongitude,
    String? destinationName,
    double? warningDistance,
    double? arrivalDistance,
    TrackingStatus? trackingStatus,
    bool? warningTriggered,
    bool? arrivalTriggered,
    DateTime? startTime,
    DateTime? endTime,
    double? currentDistanceMeters,
    double? currentAccuracyMeters,
  }) {
    return TripModel(
      tripId: tripId ?? this.tripId,
      startLatitude: startLatitude ?? this.startLatitude,
      startLongitude: startLongitude ?? this.startLongitude,
      destinationLatitude: destinationLatitude ?? this.destinationLatitude,
      destinationLongitude: destinationLongitude ?? this.destinationLongitude,
      destinationName: destinationName ?? this.destinationName,
      warningDistance: warningDistance ?? this.warningDistance,
      arrivalDistance: arrivalDistance ?? this.arrivalDistance,
      trackingStatus: trackingStatus ?? this.trackingStatus,
      warningTriggered: warningTriggered ?? this.warningTriggered,
      arrivalTriggered: arrivalTriggered ?? this.arrivalTriggered,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      currentDistanceMeters: currentDistanceMeters ?? this.currentDistanceMeters,
      currentAccuracyMeters: currentAccuracyMeters ?? this.currentAccuracyMeters,
    );
  }
}
