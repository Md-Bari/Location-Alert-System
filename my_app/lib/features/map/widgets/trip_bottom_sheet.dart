import 'package:flutter/material.dart';
import '../../../app/theme.dart';
import '../../../core/utils/distance_calculator.dart';
import '../../destination/models/destination_model.dart';
import '../../location/models/app_location.dart';
import '../../trip/models/trip_model.dart';
import '../../../shared/widgets/custom_button.dart';

class TripBottomSheet extends StatelessWidget {
  final AppLocation? currentLocation;
  final bool isLocationLive;
  final DestinationModel? selectedDestination;
  final TripModel? activeTrip;
  final double? remainingDistanceMeters;
  final double? routeDurationSeconds;
  final double? tripProgress;
  final bool isRouteEstimated;
  final VoidCallback onSelectDestinationPressed;
  final VoidCallback onStartTripPressed;
  final VoidCallback onPauseTripPressed;
  final VoidCallback onResumeTripPressed;
  final VoidCallback onEndTripPressed;
  final VoidCallback onChangeDestinationPressed;

  const TripBottomSheet({
    super.key,
    required this.currentLocation,
    this.isLocationLive = false,
    required this.selectedDestination,
    required this.activeTrip,
    this.remainingDistanceMeters,
    this.routeDurationSeconds,
    this.tripProgress,
    this.isRouteEstimated = false,
    required this.onSelectDestinationPressed,
    required this.onStartTripPressed,
    required this.onPauseTripPressed,
    required this.onResumeTripPressed,
    required this.onEndTripPressed,
    required this.onChangeDestinationPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isTrackingActive = activeTrip != null &&
        (activeTrip!.trackingStatus == TrackingStatus.tracking ||
            activeTrip!.trackingStatus == TrackingStatus.approaching ||
            activeTrip!.trackingStatus == TrackingStatus.paused);
    final isPaused = activeTrip?.trackingStatus == TrackingStatus.paused;
    final isApproaching = activeTrip?.trackingStatus == TrackingStatus.approaching;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.14),
            blurRadius: 24,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Destination header with live GPS status
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    gradient: isApproaching
                        ? AppTheme.warningGradient
                        : selectedDestination != null
                            ? AppTheme.alertGradient
                            : AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(
                    isTrackingActive
                        ? Icons.navigation_rounded
                        : selectedDestination != null
                            ? Icons.flag_rounded
                            : Icons.explore_rounded,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isTrackingActive
                            ? (isPaused ? 'TRIP PAUSED' : 'ON THE WAY TO')
                            : selectedDestination != null
                                ? 'DESTINATION'
                                : 'READY TO GO',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        selectedDestination?.name ?? 'Where are you heading?',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _LiveGpsChip(location: currentLocation, isLive: isLocationLive),
              ],
            ),

            if (selectedDestination == null && currentLocation != null) ...[
              const SizedBox(height: 10),
              Text(
                'Search a place or tap anywhere on the map to drop a destination pin.',
                style: TextStyle(
                  fontSize: 13,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
            const SizedBox(height: 16),

            // Distance, time & arrival display if active or destination selected
            if (remainingDistanceMeters != null && selectedDestination != null) ...[
              Row(
                children: [
                  Expanded(
                    child: _StatTile(
                      label: 'Distance',
                      value: DistanceCalculator.formatDistance(remainingDistanceMeters!),
                      icon: Icons.straighten_rounded,
                      color: AppTheme.locationBlue,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StatTile(
                      label: isRouteEstimated ? 'Time (est.)' : 'Time',
                      value: routeDurationSeconds != null
                          ? DistanceCalculator.formatDuration(routeDurationSeconds!)
                          : '--',
                      icon: Icons.schedule_rounded,
                      color: AppTheme.accentColor,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: isTrackingActive
                        ? _StatTile(
                            label: 'Speed',
                            value: '${(currentLocation?.speedKmh ?? 0).round()} km/h',
                            icon: Icons.speed_rounded,
                            color: AppTheme.successColor,
                          )
                        : _StatTile(
                            label: 'Arrive',
                            value: routeDurationSeconds != null
                                ? TimeOfDay.fromDateTime(
                                    DateTime.now().add(
                                      Duration(seconds: routeDurationSeconds!.round()),
                                    ),
                                  ).format(context)
                                : '--',
                            icon: Icons.flag_circle_rounded,
                            color: AppTheme.successColor,
                          ),
                  ),
                ],
              ),
              if (isTrackingActive && activeTrip?.currentDistanceMeters != null) ...[
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: tripProgress ?? 0,
                          minHeight: 8,
                          backgroundColor: AppTheme.locationBlue.withValues(alpha: 0.12),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isApproaching ? AppTheme.warningColor : AppTheme.locationBlue,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '${DistanceCalculator.formatDistance(activeTrip!.currentDistanceMeters!)} direct',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 16),
            ],

            // Action Buttons based on state
            if (!isTrackingActive) ...[
              if (selectedDestination == null) ...[
                CustomButton(
                  text: 'Select Destination',
                  icon: Icons.search_rounded,
                  gradient: AppTheme.primaryGradient,
                  onPressed: onSelectDestinationPressed,
                ),
              ] else ...[
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: CustomButton(
                        text: currentLocation == null ? 'Waiting for GPS…' : 'START TRIP',
                        icon: Icons.navigation_rounded,
                        gradient: AppTheme.successGradient,
                        isLoading: currentLocation == null,
                        onPressed: onStartTripPressed,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 1,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 54),
                        ),
                        onPressed: onChangeDestinationPressed,
                        child: const Text('Change'),
                      ),
                    ),
                  ],
                ),
              ],
            ] else ...[
              Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      text: isPaused ? 'Resume' : 'Pause',
                      icon: isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                      gradient: isPaused ? AppTheme.successGradient : AppTheme.warningGradient,
                      onPressed: isPaused ? onResumeTripPressed : onPauseTripPressed,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomButton(
                      text: 'End Trip',
                      icon: Icons.stop_rounded,
                      gradient: AppTheme.alertGradient,
                      onPressed: onEndTripPressed,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: theme.brightness == Brightness.dark ? 0.16 : 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.3,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LiveGpsChip extends StatelessWidget {
  final AppLocation? location;
  final bool isLive;

  const _LiveGpsChip({required this.location, required this.isLive});

  @override
  Widget build(BuildContext context) {
    final hasFix = location != null;
    final accuracy = location?.accuracy ?? 0;
    final color = !hasFix || !isLive
        ? AppTheme.textMuted
        : accuracy <= 15
            ? AppTheme.successColor
            : accuracy <= 50
                ? AppTheme.warningColor
                : AppTheme.alertColor;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            !hasFix
                ? 'No GPS'
                : isLive
                    ? 'LIVE ±${accuracy.round()}m'
                    : '±${accuracy.round()}m',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
