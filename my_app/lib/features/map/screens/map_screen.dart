import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../destination/controllers/destination_notifier.dart';
import '../../destination/screens/destination_search_screen.dart';
import '../../location/controllers/location_notifier.dart';
import '../../location/models/app_location.dart';
import '../models/route_model.dart';
import '../services/routing_service.dart';
import '../widgets/trip_bottom_sheet.dart';
import '../../settings/controllers/settings_notifier.dart';
import '../../settings/screens/settings_screen.dart';
import '../../trip/controllers/trip_notifier.dart';
import '../../trip/models/trip_model.dart';
import '../../trip/widgets/alert_dialogs.dart';

final routingServiceProvider = Provider<RoutingService>((ref) {
  return RoutingService();
});

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  final MapController _mapController = MapController();
  RouteModel? _routeModel;
  bool _isCalculatingRoute = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(locationNotifierProvider.notifier).init();
    });
  }

  Future<void> _updateRoute() async {
    final locationState = ref.read(locationNotifierProvider);
    final destinationState = ref.read(destinationNotifierProvider);

    if (locationState.currentLocation == null ||
        destinationState.selectedDestination == null) {
      if (mounted) {
        setState(() {
          _routeModel = null;
        });
      }
      return;
    }

    final start = locationState.currentLocation!.toLatLng();
    final dest = destinationState.selectedDestination!.toLatLng();

    setState(() {
      _isCalculatingRoute = true;
    });

    try {
      final route = await ref.read(routingServiceProvider).calculateRoute(
            start: start,
            destination: dest,
          );
      if (mounted) {
        setState(() {
          _routeModel = route;
          _isCalculatingRoute = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isCalculatingRoute = false;
        });
      }
    }
  }

  void _centerMapOn(LatLng position, {double zoom = 15.0}) {
    _mapController.move(position, zoom);
  }

  void _showWarningDialog(TripNotifier tripNotifier, String destName, double distance) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => WarningAlertDialog(
        destinationName: destName,
        distanceMeters: distance,
        onDismiss: () {
          tripNotifier.dismissWarningAlert();
          Navigator.of(ctx).pop();
        },
      ),
    );
  }

  void _showArrivalDialog(TripNotifier tripNotifier, String destName) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => ArrivalAlertDialog(
        destinationName: destName,
        onStopTracking: () {
          tripNotifier.dismissArrivalAlert();
          tripNotifier.endTrip();
          Navigator.of(ctx).pop();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final locationState = ref.watch(locationNotifierProvider);
    final destinationState = ref.watch(destinationNotifierProvider);
    final tripState = ref.watch(tripNotifierProvider);
    final tripNotifier = ref.read(tripNotifierProvider.notifier);

    // Listen for alert triggers to pop dialogs once
    ref.listen<TripState>(tripNotifierProvider, (previous, next) {
      if (next.isWarningAlertVisible &&
          (previous == null || !previous.isWarningAlertVisible)) {
        final destName = next.activeTrip?.destinationName ?? 'Destination';
        final distance = next.activeTrip?.currentDistanceMeters ?? 100.0;
        _showWarningDialog(tripNotifier, destName, distance);
      }

      if (next.isArrivalAlertVisible &&
          (previous == null || !previous.isArrivalAlertVisible)) {
        final destName = next.activeTrip?.destinationName ?? 'Destination';
        _showArrivalDialog(tripNotifier, destName);
      }
    });

    // Listen for destination changes to calculate route
    ref.listen(destinationNotifierProvider, (previous, next) {
      _updateRoute();
    });

    // Listen for location updates when route is not yet calculated
    ref.listen(locationNotifierProvider, (previous, next) {
      if (previous?.currentLocation == null && next.currentLocation != null) {
        _centerMapOn(next.currentLocation!.toLatLng());
        _updateRoute();
      }
    });

    final currentLocation = locationState.currentLocation;
    final selectedDestination = destinationState.selectedDestination;
    final activeTrip = tripState.activeTrip;
    final settings = ref.watch(settingsNotifierProvider);

    final initialCenter = currentLocation?.toLatLng() ??
        (selectedDestination?.toLatLng() ?? const LatLng(23.777176, 90.399452));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Location Alert'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: StatusBadge(
              locationPermissionStatus: locationState.permissionStatus,
              trackingStatus: activeTrip?.trackingStatus ??
                  (selectedDestination != null
                      ? TrackingStatus.destinationSelected
                      : TrackingStatus.idle),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // 0. Route Calculation Progress Indicator
          if (_isCalculatingRoute)
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: LinearProgressIndicator(minHeight: 3),
            ),

          // 1. FlutterMap Layer
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: initialCenter,
              initialZoom: 14.0,
              onTap: (tapPosition, point) {
                if (activeTrip == null ||
                    activeTrip.trackingStatus == TrackingStatus.idle ||
                    activeTrip.trackingStatus == TrackingStatus.destinationSelected) {
                  ref
                      .read(destinationNotifierProvider.notifier)
                      .selectFromCoordinates(point.latitude, point.longitude);
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: AppConstants.osmTileUrlTemplate,
                userAgentPackageName: AppConstants.mapUserAgent,
              ),

              if (settings.isTrafficEnabled)
                TileLayer(
                  urlTemplate: AppConstants.trafficTileUrlTemplate,
                  userAgentPackageName: AppConstants.mapUserAgent,
                ),

              // Route Polyline Layer
              if (_routeModel != null && _routeModel!.points.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _routeModel!.points,
                      strokeWidth: 4.5,
                      color: const Color(0xFF3B82F6),
                    ),
                  ],
                ),

              // Markers Layer
              MarkerLayer(
                markers: [
                  // User Location Marker & Accuracy Circle
                  if (currentLocation != null) ...[
                    Marker(
                      point: currentLocation.toLatLng(),
                      width: 50,
                      height: 50,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: const Color(0xFF3B82F6).withValues(alpha: 0.25),
                              shape: BoxShape.circle,
                            ),
                          ),
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: const Color(0xFF3B82F6),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Destination Marker
                  if (selectedDestination != null) ...[
                    Marker(
                      point: selectedDestination.toLatLng(),
                      width: 60,
                      height: 60,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.red[700],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              selectedDestination.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Icon(
                            Icons.location_on,
                            color: Colors.red[700],
                            size: 36,
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),

          // 2. Permission / Error Notice Banner
          if (locationState.permissionStatus != LocationPermissionStatus.granted)
            Positioned(
              top: 12,
              left: 16,
              right: 16,
              child: Card(
                color: const Color(0xFFEF4444),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: Colors.white),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          locationState.errorMessage ??
                              'Location access is required for real-time alerts.',
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                        ),
                      ),
                      TextButton(
                        style: TextButton.styleFrom(foregroundColor: Colors.white),
                        onPressed: () {
                          ref
                              .read(locationNotifierProvider.notifier)
                              .requestPermissionAndFetchLocation();
                        },
                        child: const Text('GRANT'),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // 3. Floating Map Controls (Traffic Toggle, My Location & Destination Focus)
          Positioned(
            right: 16,
            bottom: 220,
            child: Column(
              children: [
                FloatingActionButton.small(
                  heroTag: 'fab_traffic',
                  backgroundColor: settings.isTrafficEnabled
                      ? const Color(0xFF10B981)
                      : Theme.of(context).cardColor,
                  foregroundColor: settings.isTrafficEnabled
                      ? Colors.white
                      : Colors.grey[700],
                  tooltip: 'Toggle Live Traffic Flow',
                  child: const Icon(Icons.traffic_rounded),
                  onPressed: () {
                    ref
                        .read(settingsNotifierProvider.notifier)
                        .setTrafficEnabled(!settings.isTrafficEnabled);
                  },
                ),
                const SizedBox(height: 8),
                if (selectedDestination != null) ...[
                  FloatingActionButton.small(
                    heroTag: 'fab_dest',
                    backgroundColor: Theme.of(context).cardColor,
                    foregroundColor: Colors.red[700],
                    child: const Icon(Icons.pin_drop),
                    onPressed: () {
                      _centerMapOn(selectedDestination.toLatLng());
                    },
                  ),
                  const SizedBox(height: 8),
                ],
                FloatingActionButton.small(
                  heroTag: 'fab_user',
                  backgroundColor: Theme.of(context).cardColor,
                  foregroundColor: const Color(0xFF3B82F6),
                  child: const Icon(Icons.my_location),
                  onPressed: () {
                    if (currentLocation != null) {
                      _centerMapOn(currentLocation.toLatLng());
                    } else {
                      ref
                          .read(locationNotifierProvider.notifier)
                          .refreshLocation();
                    }
                  },
                ),
              ],
            ),
          ),

          // 4. Bottom Sheet Panel
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: TripBottomSheet(
              currentLocation: currentLocation,
              selectedDestination: selectedDestination,
              activeTrip: activeTrip,
              remainingDistanceMeters: activeTrip?.currentDistanceMeters ??
                  _routeModel?.distanceMeters,
              routeDurationSeconds: _routeModel?.durationSeconds,
              onSelectDestinationPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const DestinationSearchScreen(),
                  ),
                );
              },
              onStartTripPressed: () {
                if (currentLocation != null && selectedDestination != null) {
                  tripNotifier.startTrip(
                    currentLocation: currentLocation,
                    destinationLat: selectedDestination.latitude,
                    destinationLng: selectedDestination.longitude,
                    destinationName: selectedDestination.name,
                  );
                }
              },
              onPauseTripPressed: () => tripNotifier.pauseTrip(),
              onResumeTripPressed: () => tripNotifier.resumeTrip(),
              onEndTripPressed: () {
                tripNotifier.endTrip();
                ref.read(destinationNotifierProvider.notifier).clearDestination();
              },
              onChangeDestinationPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const DestinationSearchScreen(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
