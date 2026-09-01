import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_location.dart';
import '../services/location_service.dart';

class LocationState {
  final AppLocation? currentLocation;
  final LocationPermissionStatus permissionStatus;
  final bool isLoading;
  final String? errorMessage;

  const LocationState({
    this.currentLocation,
    this.permissionStatus = LocationPermissionStatus.unknown,
    this.isLoading = false,
    this.errorMessage,
  });

  LocationState copyWith({
    AppLocation? currentLocation,
    LocationPermissionStatus? permissionStatus,
    bool? isLoading,
    String? errorMessage,
  }) {
    return LocationState(
      currentLocation: currentLocation ?? this.currentLocation,
      permissionStatus: permissionStatus ?? this.permissionStatus,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class LocationNotifier extends StateNotifier<LocationState> {
  final LocationService _locationService;

  LocationNotifier(this._locationService) : super(const LocationState()) {
    init();
  }

  Future<void> init() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final serviceEnabled = await _locationService.isLocationServiceEnabled();
      if (!serviceEnabled) {
        state = state.copyWith(
          isLoading: false,
          permissionStatus: LocationPermissionStatus.disabled,
          errorMessage: 'Location services are disabled on device.',
        );
        return;
      }

      final perm = await _locationService.checkPermission();
      if (perm == LocationPermissionStatus.granted) {
        await refreshLocation();
      } else {
        state = state.copyWith(
          isLoading: false,
          permissionStatus: perm,
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> requestPermissionAndFetchLocation() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final perm = await _locationService.requestPermission();
      state = state.copyWith(permissionStatus: perm);

      if (perm == LocationPermissionStatus.granted) {
        await refreshLocation();
      } else if (perm == LocationPermissionStatus.permanentlyDenied) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Location permission is permanently denied. Please enable in Settings.',
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Location permission was denied.',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> refreshLocation() async {
    try {
      final location = await _locationService.getCurrentLocation();
      state = state.copyWith(
        currentLocation: location,
        isLoading: false,
        permissionStatus: LocationPermissionStatus.granted,
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  void updateLocationManually(AppLocation location) {
    state = state.copyWith(
      currentLocation: location,
      permissionStatus: LocationPermissionStatus.granted,
    );
  }
}

final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});

final locationNotifierProvider =
    StateNotifierProvider<LocationNotifier, LocationState>((ref) {
  final service = ref.watch(locationServiceProvider);
  return LocationNotifier(service);
});
