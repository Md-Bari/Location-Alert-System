abstract class Failure {
  final String message;
  final dynamic details;

  const Failure(this.message, [this.details]);

  @override
  String toString() => message;
}

class LocationServiceDisabledFailure extends Failure {
  const LocationServiceDisabledFailure([super.message = 'Location services are disabled on your device.']);
}

class LocationPermissionDeniedFailure extends Failure {
  const LocationPermissionDeniedFailure([super.message = 'Location permission was denied.']);
}

class LocationPermissionPermanentlyDeniedFailure extends Failure {
  const LocationPermissionPermanentlyDeniedFailure(
      [super.message = 'Location permission is permanently denied. Please enable it in system settings.']);
}

class RoutingFailure extends Failure {
  const RoutingFailure([super.message = 'Failed to calculate route to destination.', super.details]);
}

class NotificationPermissionFailure extends Failure {
  const NotificationPermissionFailure([super.message = 'Notification permission was not granted.']);
}
