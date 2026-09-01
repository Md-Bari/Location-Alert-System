import 'package:flutter/material.dart';
import '../../../core/utils/distance_calculator.dart';
import '../../destination/models/destination_model.dart';
import '../../location/models/app_location.dart';
import '../../trip/models/trip_model.dart';
import '../../../shared/widgets/custom_button.dart';

class TripBottomSheet extends StatelessWidget {
  final AppLocation? currentLocation;
  final DestinationModel? selectedDestination;
  final TripModel? activeTrip;
  final double? remainingDistanceMeters;
  final double? routeDurationSeconds;
  final VoidCallback onSelectDestinationPressed;
  final VoidCallback onStartTripPressed;
  final VoidCallback onPauseTripPressed;
  final VoidCallback onResumeTripPressed;
  final VoidCallback onEndTripPressed;
  final VoidCallback onChangeDestinationPressed;

  const TripBottomSheet({
    super.key,
    required this.currentLocation,
    required this.selectedDestination,
    required this.activeTrip,
    this.remainingDistanceMeters,
    this.routeDurationSeconds,
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
    final isTrackingActive = activeTrip != null &&
        (activeTrip!.trackingStatus == TrackingStatus.tracking ||
            activeTrip!.trackingStatus == TrackingStatus.approaching ||
            activeTrip!.trackingStatus == TrackingStatus.paused);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, -4),
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
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Live GPS & Distance Status Bar
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Destination',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        selectedDestination?.name ?? 'Not selected',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (currentLocation != null) ...[
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.gps_fixed, size: 12, color: Colors.blue),
                        const SizedBox(width: 4),
                        Text(
                          '±${currentLocation!.accuracy.round()}m GPS',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),

            // Distance & Duration display if active or destination selected
            if (remainingDistanceMeters != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        const Text(
                          'Distance',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DistanceCalculator.formatDistance(
                              remainingDistanceMeters!),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF3B82F6),
                          ),
                        ),
                      ],
                    ),
                    Container(
                      width: 1,
                      height: 30,
                      color: Colors.grey.withValues(alpha: 0.3),
                    ),
                    Column(
                      children: [
                        const Text(
                          'Est. Time',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          routeDurationSeconds != null
                              ? DistanceCalculator.formatDuration(
                                  routeDurationSeconds!)
                              : '--',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Action Buttons based on state
            if (!isTrackingActive) ...[
              if (selectedDestination == null) ...[
                CustomButton(
                  text: 'Select Destination',
                  icon: Icons.search,
                  onPressed: onSelectDestinationPressed,
                ),
              ] else ...[
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: CustomButton(
                        text: 'START TRIP',
                        icon: Icons.play_arrow_rounded,
                        backgroundColor: const Color(0xFF10B981),
                        onPressed: onStartTripPressed,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 1,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 52),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
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
                      text: activeTrip?.trackingStatus == TrackingStatus.paused
                          ? 'Resume'
                          : 'Pause',
                      icon: activeTrip?.trackingStatus == TrackingStatus.paused
                          ? Icons.play_arrow
                          : Icons.pause,
                      backgroundColor: Colors.amber[700],
                      onPressed:
                          activeTrip?.trackingStatus == TrackingStatus.paused
                              ? onResumeTripPressed
                              : onPauseTripPressed,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomButton(
                      text: 'End Trip',
                      icon: Icons.stop_rounded,
                      backgroundColor: const Color(0xFFEF4444),
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
