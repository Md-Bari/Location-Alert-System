import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart' hide DistanceCalculator;
import '../../../app/theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/location_constants.dart';
import '../../../core/utils/distance_calculator.dart';
import '../../../core/utils/route_progress.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../destination/controllers/destination_notifier.dart';
import '../../destination/screens/destination_search_screen.dart';
import '../../location/controllers/location_notifier.dart';
import '../../location/models/app_location.dart';
import '../models/route_model.dart';
import '../services/routing_service.dart';
import '../widgets/map_overlays.dart';
import '../widgets/trip_bottom_sheet.dart';
import '../widgets/user_location_marker.dart';
import '../../settings/controllers/settings_notifier.dart';
import '../../settings/screens/settings_screen.dart';
import '../../trip/controllers/trip_notifier.dart';
import '../../trip/models/trip_model.dart';
import '../../trip/widgets/alert_dialogs.dart';

final routingServiceProvider = Provider<RoutingService>((ref) {
  return RoutingService();
});

/// How the camera reacts to live location updates (mirrors Google Maps behaviour).
enum CameraMode {
  /// User panned the map; camera stays put.
  free,

  /// Camera stays centered on the user, north-up.
  follow,

  /// Camera is centered on the user and rotated heading-up.
  navigate,
}

/// Interpolated position of the on-screen location marker.
class _UserPose {
  final LatLng position;
  final double? heading;
  final double accuracy;

  const _UserPose(this.position, this.heading, this.accuracy);
}

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  static const LatLng _fallbackCenter = LatLng(23.777176, 90.399452);

  final MapController _mapController = MapController();
  final ValueNotifier<_UserPose?> _pose = ValueNotifier(null);
  final ValueNotifier<double> _mapRotation = ValueNotifier(0);

  late final AnimationController _markerController;
  AnimationController? _cameraController;
  bool _isCameraAnimating = false;
  bool _mapReady = false;

  LatLng? _fromPosition;
  LatLng? _toPosition;
  double? _fromHeading;
  double? _toHeading;
  double _accuracy = 0;

  CameraMode _cameraMode = CameraMode.follow;

  RouteModel? _routeModel;
  RouteProgress? _routeProgress;
  bool _isCalculatingRoute = false;
  DateTime? _lastRouteRequest;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _markerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: LocationConstants.markerAnimationMs),
    )..addListener(_onMarkerTick);

    // LocationNotifier starts the live stream itself; render any fix it already has.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final location = ref.read(locationNotifierProvider).currentLocation;
      if (location != null) _onNewFix(location);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _markerController.dispose();
    _cameraController?.dispose();
    _pose.dispose();
    _mapRotation.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(locationNotifierProvider.notifier).onAppResumed();
    }
  }

  // ---------------------------------------------------------------------------
  // Live location animation & camera
  // ---------------------------------------------------------------------------

  void _onNewFix(AppLocation location) {
    final target = location.toLatLng();
    final heading = location.hasHeading ? location.heading : null;
    final current = _pose.value;
    _accuracy = location.accuracy;

    final jump = current == null
        ? double.infinity
        : DistanceCalculator.calculateHaversineDistance(
            startLatitude: current.position.latitude,
            startLongitude: current.position.longitude,
            destinationLatitude: target.latitude,
            destinationLongitude: target.longitude,
          );

    if (current == null || jump > 500) {
      // First fix or teleport: snap instead of gliding across the map.
      _markerController.stop();
      _fromPosition = target;
      _toPosition = target;
      _fromHeading = heading;
      _toHeading = heading;
      _pose.value = _UserPose(target, heading, _accuracy);
      if (current == null && _mapReady && _cameraMode != CameraMode.free) {
        _animateCamera(target, LocationConstants.followZoom);
      } else {
        _followCamera(target, heading);
      }
    } else {
      _fromPosition = current.position;
      _toPosition = target;
      _fromHeading = current.heading ?? heading;
      _toHeading = heading ?? current.heading;
      _markerController.forward(from: 0);
    }

    _updateRouteProgress(target, location.accuracy);
  }

  void _onMarkerTick() {
    final from = _fromPosition;
    final to = _toPosition;
    if (from == null || to == null) return;

    final t = _markerController.value;
    final position = LatLng(
      from.latitude + (to.latitude - from.latitude) * t,
      from.longitude + (to.longitude - from.longitude) * t,
    );
    final heading = _lerpAngle(_fromHeading, _toHeading, t);

    _pose.value = _UserPose(position, heading, _accuracy);
    _followCamera(position, heading);
  }

  void _followCamera(LatLng position, double? heading) {
    if (!_mapReady || _isCameraAnimating) return;
    final camera = _mapController.camera;

    switch (_cameraMode) {
      case CameraMode.free:
        return;
      case CameraMode.follow:
        _mapController.move(position, camera.zoom);
      case CameraMode.navigate:
        _mapController.moveAndRotate(
          position,
          camera.zoom,
          heading != null ? -heading : camera.rotation,
        );
    }
  }

  /// Smoothly flies the camera to [destination] like Google Maps' recenter animation.
  void _animateCamera(
    LatLng destination,
    double zoom, {
    double rotation = 0,
  }) {
    if (!_mapReady) return;
    _cameraController?.dispose();

    final camera = _mapController.camera;
    final startCenter = camera.center;
    final startZoom = camera.zoom;
    final startRotation = camera.rotation;
    final rotationDelta = _shortestAngleDelta(startRotation, rotation);

    final controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    );
    final curve = CurvedAnimation(parent: controller, curve: Curves.easeInOutCubic);

    controller.addListener(() {
      final t = curve.value;
      _mapController.moveAndRotate(
        LatLng(
          startCenter.latitude + (destination.latitude - startCenter.latitude) * t,
          startCenter.longitude + (destination.longitude - startCenter.longitude) * t,
        ),
        startZoom + (zoom - startZoom) * t,
        startRotation + rotationDelta * t,
      );
    });
    controller.addStatusListener((status) {
      if (status == AnimationStatus.completed || status == AnimationStatus.dismissed) {
        _isCameraAnimating = false;
      }
    });

    _cameraController = controller;
    _isCameraAnimating = true;
    controller.forward();
  }

  void _onMapEvent(MapEvent event) {
    if (_mapRotation.value != event.camera.rotation) {
      _mapRotation.value = event.camera.rotation;
    }

    final isUserGesture = event.source == MapEventSource.dragStart ||
        event.source == MapEventSource.onDrag ||
        event.source == MapEventSource.multiFingerGestureStart ||
        event.source == MapEventSource.onMultiFinger;

    if (isUserGesture) {
      _cameraController?.stop();
      _isCameraAnimating = false;
      if (_cameraMode != CameraMode.free) {
        setState(() => _cameraMode = CameraMode.free);
      }
    }
  }

  void _onLocateMePressed() {
    final pose = _pose.value;
    if (pose == null) {
      ref.read(locationNotifierProvider.notifier).refreshLocation();
      return;
    }

    final isTripActive = _isTripActive(ref.read(tripNotifierProvider).activeTrip);
    _setCameraMode(switch (_cameraMode) {
      CameraMode.free => isTripActive ? CameraMode.navigate : CameraMode.follow,
      CameraMode.follow => CameraMode.navigate,
      CameraMode.navigate => CameraMode.follow,
    });
  }

  void _setCameraMode(CameraMode mode) {
    final pose = _pose.value;
    setState(() => _cameraMode = mode);
    if (pose == null || !_mapReady) return;

    final zoom = max(
      _mapController.camera.zoom,
      mode == CameraMode.navigate
          ? LocationConstants.navigationZoom
          : LocationConstants.followZoom,
    );
    _animateCamera(
      pose.position,
      zoom,
      rotation: mode == CameraMode.navigate && pose.heading != null ? -pose.heading! : 0,
    );
  }

  void _resetNorth() {
    if (!_mapReady) return;
    if (_cameraMode == CameraMode.navigate) {
      _setCameraMode(CameraMode.follow);
    } else {
      final camera = _mapController.camera;
      _animateCamera(camera.center, camera.zoom);
    }
  }

  void _showRouteOverview() {
    final destination = ref.read(destinationNotifierProvider).selectedDestination;
    if (!_mapReady || destination == null) return;

    final points = <LatLng>[
      ...?_routeModel?.points,
      destination.toLatLng(),
      if (_pose.value != null) _pose.value!.position,
    ];
    if (points.length < 2) {
      _animateCamera(destination.toLatLng(), LocationConstants.followZoom);
    } else {
      _mapController.rotate(0);
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: LatLngBounds.fromPoints(points),
          padding: const EdgeInsets.fromLTRB(56, 190, 56, 360),
          maxZoom: 17,
        ),
      );
    }
    setState(() => _cameraMode = CameraMode.free);
  }

  // ---------------------------------------------------------------------------
  // Routing
  // ---------------------------------------------------------------------------

  Future<void> _updateRoute({bool fitToRoute = false}) async {
    final locationState = ref.read(locationNotifierProvider);
    final destinationState = ref.read(destinationNotifierProvider);

    if (locationState.currentLocation == null ||
        destinationState.selectedDestination == null) {
      if (mounted) {
        setState(() {
          _routeModel = null;
          _routeProgress = null;
        });
      }
      return;
    }

    final start = locationState.currentLocation!.toLatLng();
    final destination = destinationState.selectedDestination!;
    final dest = destination.toLatLng();

    _lastRouteRequest = DateTime.now();
    setState(() {
      _isCalculatingRoute = true;
    });

    try {
      final route = await ref.read(routingServiceProvider).calculateRoute(
            start: start,
            destination: dest,
          );

      // Ignore the result if the destination changed while the request was in flight.
      if (!mounted ||
          ref.read(destinationNotifierProvider).selectedDestination?.id != destination.id) {
        return;
      }

      setState(() {
        _routeModel = route;
        _routeProgress = RouteProgress.compute(route.points, start);
        _isCalculatingRoute = false;
      });
      if (fitToRoute) _showRouteOverview();
    } catch (_) {
      if (mounted) {
        setState(() {
          _isCalculatingRoute = false;
        });
      }
    }
  }

  void _updateRouteProgress(LatLng position, double accuracy) {
    final route = _routeModel;
    final destination = ref.read(destinationNotifierProvider).selectedDestination;
    if (route == null || destination == null) return;

    if (route.isStraightLineFallback) {
      // Keep the guide line attached to the user and retry real routing periodically.
      final distance = DistanceCalculator.calculateHaversineDistance(
        startLatitude: position.latitude,
        startLongitude: position.longitude,
        destinationLatitude: destination.latitude,
        destinationLongitude: destination.longitude,
      );
      setState(() {
        _routeModel = RouteModel.straightLine(position, destination.toLatLng(), distance);
        _routeProgress = RouteProgress.compute(_routeModel!.points, position);
      });
      if (_canReroute()) _updateRoute();
      return;
    }

    final progress = RouteProgress.compute(route.points, position);
    setState(() => _routeProgress = progress);

    final offRouteLimit = LocationConstants.offRouteThresholdMeters + accuracy;
    if (progress != null &&
        progress.distanceFromRouteMeters > offRouteLimit &&
        _canReroute()) {
      _updateRoute();
    }
  }

  bool _canReroute() {
    if (_isCalculatingRoute) return false;
    final last = _lastRouteRequest;
    return last == null ||
        DateTime.now().difference(last).inSeconds >= LocationConstants.rerouteCooldownSeconds;
  }

  // ---------------------------------------------------------------------------
  // Dialogs
  // ---------------------------------------------------------------------------

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
          ref.read(destinationNotifierProvider.notifier).clearDestination();
          Navigator.of(ctx).pop();
          _setCameraMode(CameraMode.follow);
        },
      ),
    );
  }

  void _openSearch() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const DestinationSearchScreen()),
    );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final locationState = ref.watch(locationNotifierProvider);
    final destinationState = ref.watch(destinationNotifierProvider);
    final tripState = ref.watch(tripNotifierProvider);
    final tripNotifier = ref.read(tripNotifierProvider.notifier);
    final settings = ref.watch(settingsNotifierProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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

    // Recalculate route whenever the destination changes
    ref.listen(destinationNotifierProvider, (previous, next) {
      if (previous?.selectedDestination?.id != next.selectedDestination?.id) {
        _updateRoute(fitToRoute: next.selectedDestination != null);
      }
    });

    // Animate every live GPS fix onto the map
    ref.listen<LocationState>(locationNotifierProvider, (previous, next) {
      final location = next.currentLocation;
      if (location == null || identical(location, previous?.currentLocation)) return;
      final isFirstFix = previous?.currentLocation == null;
      _onNewFix(location);
      if (isFirstFix && _routeModel == null) _updateRoute();
    });

    final currentLocation = locationState.currentLocation;
    final selectedDestination = destinationState.selectedDestination;
    final activeTrip = tripState.activeTrip;
    final isTripActive = _isTripActive(activeTrip);

    final initialCenter = currentLocation?.toLatLng() ??
        (selectedDestination?.toLatLng() ?? _fallbackCenter);

    final progress = _routeProgress;
    final route = _routeModel;
    final remainingRouteMeters = progress?.remainingDistanceMeters ?? route?.distanceMeters;

    double? etaSeconds;
    if (route != null && remainingRouteMeters != null) {
      if (!route.isStraightLineFallback && route.distanceMeters > 0) {
        etaSeconds = route.durationSeconds * (remainingRouteMeters / route.distanceMeters);
      } else if ((currentLocation?.speed ?? 0) > 2) {
        etaSeconds = remainingRouteMeters / currentLocation!.speed;
      } else {
        etaSeconds = remainingRouteMeters / RouteModel.fallbackSpeedMps;
      }
    }

    double? tripProgress;
    if (isTripActive && route != null && route.distanceMeters > 0 && remainingRouteMeters != null) {
      tripProgress = (1 - remainingRouteMeters / route.distanceMeters).clamp(0.0, 1.0);
    }

    return Scaffold(
      body: Stack(
        children: [
          // 1. FlutterMap Layer
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: initialCenter,
              initialZoom: currentLocation != null ? LocationConstants.followZoom : 13.0,
              minZoom: 3,
              maxZoom: 20,
              backgroundColor: isDark ? const Color(0xFF1B1F2A) : const Color(0xFFE8ECF2),
              onMapReady: () {
                _mapReady = true;
                final pose = _pose.value;
                if (pose != null) _followCamera(pose.position, pose.heading);
              },
              onMapEvent: _onMapEvent,
              onTap: (tapPosition, point) {
                if (activeTrip == null) {
                  ref
                      .read(destinationNotifierProvider.notifier)
                      .selectFromCoordinates(point.latitude, point.longitude);
                }
              },
            ),
            children: [
              TileLayer(
                key: ValueKey(isDark),
                urlTemplate: isDark
                    ? AppConstants.darkTileUrlTemplate
                    : AppConstants.lightTileUrlTemplate,
                subdomains: AppConstants.cartoSubdomains,
                userAgentPackageName: AppConstants.mapUserAgent,
                retinaMode: RetinaMode.isHighDensity(context),
                maxNativeZoom: 20,
              ),

              if (settings.isTrafficEnabled)
                TileLayer(
                  urlTemplate: AppConstants.trafficTileUrlTemplate,
                  userAgentPackageName: AppConstants.mapUserAgent,
                ),

              // Route Polyline Layer: travelled part greyed out, remaining part highlighted
              if (route != null && route.points.length > 1)
                PolylineLayer(
                  polylines: [
                    if (progress != null && progress.travelledPoints.length > 1)
                      Polyline(
                        points: progress.travelledPoints,
                        strokeWidth: 6,
                        color: AppTheme.routeTravelledColor.withValues(alpha: 0.8),
                        strokeCap: StrokeCap.round,
                        strokeJoin: StrokeJoin.round,
                      ),
                    Polyline(
                      points: progress?.remainingPoints ?? route.points,
                      strokeWidth: 6,
                      color: route.isStraightLineFallback
                          ? AppTheme.routeColor.withValues(alpha: 0.6)
                          : AppTheme.routeColor,
                      borderStrokeWidth: 2.5,
                      borderColor: AppTheme.routeBorderColor,
                      strokeCap: StrokeCap.round,
                      strokeJoin: StrokeJoin.round,
                    ),
                  ],
                ),

              // Arrival / warning radius rings around the destination
              if (selectedDestination != null)
                CircleLayer(
                  circles: [
                    CircleMarker(
                      point: selectedDestination.toLatLng(),
                      radius: activeTrip?.warningDistance ?? settings.warningDistance,
                      useRadiusInMeter: true,
                      color: AppTheme.warningColor.withValues(alpha: 0.08),
                      borderColor: AppTheme.warningColor.withValues(alpha: 0.5),
                      borderStrokeWidth: 1.5,
                    ),
                    CircleMarker(
                      point: selectedDestination.toLatLng(),
                      radius: activeTrip?.arrivalDistance ?? settings.arrivalDistance,
                      useRadiusInMeter: true,
                      color: AppTheme.successColor.withValues(alpha: 0.15),
                      borderColor: AppTheme.successColor.withValues(alpha: 0.7),
                      borderStrokeWidth: 1.5,
                    ),
                  ],
                ),

              // Destination Marker
              if (selectedDestination != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: selectedDestination.toLatLng(),
                      width: DestinationPin.width,
                      height: DestinationPin.height,
                      alignment: Alignment.topCenter,
                      rotate: true,
                      child: DestinationPin(name: selectedDestination.name),
                    ),
                  ],
                ),

              // Live user location: GPS accuracy circle
              ValueListenableBuilder<_UserPose?>(
                valueListenable: _pose,
                builder: (context, pose, _) {
                  if (pose == null) return const SizedBox.shrink();
                  return CircleLayer(
                    circles: [
                      CircleMarker(
                        point: pose.position,
                        radius: pose.accuracy,
                        useRadiusInMeter: true,
                        color: AppTheme.locationBlue.withValues(alpha: 0.12),
                        borderColor: AppTheme.locationBlue.withValues(alpha: 0.35),
                        borderStrokeWidth: 1,
                      ),
                    ],
                  );
                },
              ),

              // Live user location: animated marker (rebuilt per frame without rebuilding the map)
              ValueListenableBuilder<_UserPose?>(
                valueListenable: _pose,
                builder: (context, pose, _) {
                  if (pose == null) return const SizedBox.shrink();
                  return MarkerLayer(
                    markers: [
                      Marker(
                        point: pose.position,
                        width: UserLocationMarker.size,
                        height: UserLocationMarker.size,
                        child: UserLocationMarker(
                          heading: pose.heading,
                          isLive: locationState.isLive,
                          navigationStyle: isTripActive,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),

          // 2. Top floating search bar, status & banners
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _SearchPill(
                          destinationName: selectedDestination?.name,
                          isTripActive: isTripActive,
                          onTap: isTripActive ? null : _openSearch,
                          onClear: selectedDestination != null && activeTrip == null
                              ? () => ref
                                  .read(destinationNotifierProvider.notifier)
                                  .clearDestination()
                              : null,
                        ),
                      ),
                      const SizedBox(width: 10),
                      MapControlButton(
                        icon: Icons.tune_rounded,
                        tooltip: 'Settings',
                        size: 54,
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const SettingsScreen()),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      StatusBadge(
                        locationPermissionStatus: locationState.permissionStatus,
                        trackingStatus: activeTrip?.trackingStatus ??
                            (selectedDestination != null
                                ? TrackingStatus.destinationSelected
                                : TrackingStatus.idle),
                      ),
                      if (_isCalculatingRoute) ...[
                        const SizedBox(width: 8),
                        const _RoutingChip(),
                      ],
                    ],
                  ),

                  // Permission / Error Notice Banner
                  if (locationState.permissionStatus != LocationPermissionStatus.granted) ...[
                    const SizedBox(height: 10),
                    MapBanner(
                      icon: locationState.permissionStatus == LocationPermissionStatus.disabled
                          ? Icons.location_disabled_rounded
                          : Icons.location_off_rounded,
                      color: AppTheme.alertColor,
                      message: locationState.errorMessage ??
                          'Location access is required for real-time tracking and alerts.',
                      actionLabel: switch (locationState.permissionStatus) {
                        LocationPermissionStatus.disabled => 'TURN ON',
                        LocationPermissionStatus.permanentlyDenied => 'OPEN',
                        _ => 'GRANT',
                      },
                      onAction: () {
                        ref
                            .read(locationNotifierProvider.notifier)
                            .requestPermissionAndFetchLocation();
                      },
                    ),
                  ] else if (!locationState.isPreciseLocation) ...[
                    const SizedBox(height: 10),
                    MapBanner(
                      icon: Icons.gps_not_fixed_rounded,
                      color: AppTheme.warningColor,
                      message: 'Precise location is off. Your position may be off by hundreds of meters.',
                      actionLabel: 'FIX',
                      onAction: () {
                        ref.read(locationNotifierProvider.notifier).requestPreciseLocation();
                      },
                    ),
                  ] else if (locationState.errorMessage != null) ...[
                    const SizedBox(height: 10),
                    MapBanner(
                      icon: Icons.satellite_alt_rounded,
                      color: AppTheme.textMuted,
                      message: locationState.errorMessage!,
                    ),
                  ],
                ],
              ),
            ),
          ),

          // 3. Floating map controls + bottom sheet panel
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 16, 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Text(
                          AppConstants.mapAttribution,
                          style: TextStyle(
                            fontSize: 9,
                            color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ValueListenableBuilder<double>(
                            valueListenable: _mapRotation,
                            builder: (context, rotation, _) {
                              if (rotation.abs() % 360 < 1) return const SizedBox.shrink();
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: MapControlButton(
                                  icon: Icons.navigation_rounded,
                                  tooltip: 'Reset to north',
                                  size: 42,
                                  onPressed: _resetNorth,
                                  child: Transform.rotate(
                                    angle: rotation * pi / 180,
                                    child: const Icon(
                                      Icons.navigation_rounded,
                                      color: AppTheme.alertColor,
                                      size: 22,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          MapControlButton(
                            icon: Icons.traffic_rounded,
                            tooltip: 'Toggle live traffic',
                            backgroundColor: settings.isTrafficEnabled
                                ? AppTheme.successColor
                                : null,
                            iconColor: settings.isTrafficEnabled ? Colors.white : null,
                            onPressed: () {
                              ref
                                  .read(settingsNotifierProvider.notifier)
                                  .setTrafficEnabled(!settings.isTrafficEnabled);
                            },
                          ),
                          if (selectedDestination != null) ...[
                            const SizedBox(height: 10),
                            MapControlButton(
                              icon: Icons.alt_route_rounded,
                              tooltip: 'Route overview',
                              iconColor: AppTheme.alertColor,
                              onPressed: _showRouteOverview,
                            ),
                          ],
                          const SizedBox(height: 10),
                          MapControlButton(
                            icon: switch (_cameraMode) {
                              CameraMode.free => Icons.location_searching_rounded,
                              CameraMode.follow => Icons.my_location_rounded,
                              CameraMode.navigate => Icons.navigation_rounded,
                            },
                            tooltip: switch (_cameraMode) {
                              CameraMode.free => 'Show my location',
                              CameraMode.follow => 'Heading-up navigation',
                              CameraMode.navigate => 'North-up view',
                            },
                            size: 56,
                            iconColor: _cameraMode == CameraMode.free
                                ? null
                                : AppTheme.locationBlue,
                            onPressed: _onLocateMePressed,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                TripBottomSheet(
                  currentLocation: currentLocation,
                  isLocationLive: locationState.isLive,
                  selectedDestination: selectedDestination,
                  activeTrip: activeTrip,
                  remainingDistanceMeters: remainingRouteMeters ??
                      activeTrip?.currentDistanceMeters,
                  routeDurationSeconds: etaSeconds,
                  tripProgress: tripProgress,
                  isRouteEstimated: route?.isStraightLineFallback ?? false,
                  onSelectDestinationPressed: _openSearch,
                  onStartTripPressed: () {
                    if (currentLocation != null && selectedDestination != null) {
                      tripNotifier.startTrip(
                        currentLocation: currentLocation,
                        destinationLat: selectedDestination.latitude,
                        destinationLng: selectedDestination.longitude,
                        destinationName: selectedDestination.name,
                      );
                      _setCameraMode(CameraMode.navigate);
                    }
                  },
                  onPauseTripPressed: () => tripNotifier.pauseTrip(),
                  onResumeTripPressed: () => tripNotifier.resumeTrip(),
                  onEndTripPressed: () {
                    tripNotifier.endTrip();
                    ref.read(destinationNotifierProvider.notifier).clearDestination();
                    _setCameraMode(CameraMode.follow);
                  },
                  onChangeDestinationPressed: _openSearch,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static bool _isTripActive(TripModel? trip) {
    return trip != null &&
        (trip.trackingStatus == TrackingStatus.tracking ||
            trip.trackingStatus == TrackingStatus.approaching ||
            trip.trackingStatus == TrackingStatus.paused);
  }

  static double? _lerpAngle(double? from, double? to, double t) {
    if (from == null) return to;
    if (to == null) return from;
    return (from + _shortestAngleDelta(from, to) * t + 360) % 360;
  }

  static double _shortestAngleDelta(double from, double to) {
    return ((to - from + 540) % 360) - 180;
  }
}

class _SearchPill extends StatelessWidget {
  final String? destinationName;
  final bool isTripActive;
  final VoidCallback? onTap;
  final VoidCallback? onClear;

  const _SearchPill({
    required this.destinationName,
    required this.isTripActive,
    required this.onTap,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasDestination = destinationName != null;

    return Container(
      height: 54,
      decoration: AppTheme.floatingSurface(context, radius: 28),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(28),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.only(left: 8, right: 6),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    gradient: hasDestination ? AppTheme.alertGradient : AppTheme.primaryGradient,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isTripActive
                        ? Icons.navigation_rounded
                        : hasDestination
                            ? Icons.place_rounded
                            : Icons.search_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (hasDestination)
                        Text(
                          isTripActive ? 'NAVIGATING TO' : 'DESTINATION',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                      Text(
                        destinationName ?? 'Where to?',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: hasDestination ? 15 : 16,
                          fontWeight: hasDestination ? FontWeight.w800 : FontWeight.w600,
                          color: hasDestination
                              ? theme.colorScheme.onSurface
                              : theme.colorScheme.onSurface.withValues(alpha: 0.55),
                        ),
                      ),
                    ],
                  ),
                ),
                if (onClear != null)
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    tooltip: 'Clear destination',
                    onPressed: onClear,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoutingChip extends StatelessWidget {
  const _RoutingChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: AppTheme.floatingSurface(context, radius: 20),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 8),
          Text(
            'Finding route…',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
