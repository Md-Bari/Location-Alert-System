import 'package:flutter/material.dart';
import '../../features/location/models/app_location.dart';
import '../../features/trip/models/trip_model.dart';

class StatusBadge extends StatelessWidget {
  final LocationPermissionStatus locationPermissionStatus;
  final TrackingStatus? trackingStatus;

  const StatusBadge({
    super.key,
    required this.locationPermissionStatus,
    this.trackingStatus,
  });

  @override
  Widget build(BuildContext context) {
    String label;
    Color color;
    IconData icon;

    if (locationPermissionStatus != LocationPermissionStatus.granted) {
      label = 'GPS Unavailable';
      color = const Color(0xFFEF4444); // Red
      icon = Icons.location_off;
    } else if (trackingStatus == null || trackingStatus == TrackingStatus.idle) {
      label = 'Tracking Inactive';
      color = const Color(0xFF94A3B8); // Slate Grey
      icon = Icons.pause_circle_outline;
    } else if (trackingStatus == TrackingStatus.destinationSelected) {
      label = 'Destination Ready';
      color = const Color(0xFF3B82F6); // Blue
      icon = Icons.pin_drop;
    } else if (trackingStatus == TrackingStatus.tracking) {
      label = 'Tracking Active';
      color = const Color(0xFF10B981); // Green
      icon = Icons.navigation;
    } else if (trackingStatus == TrackingStatus.approaching) {
      label = 'Approaching Target';
      color = const Color(0xFFF59E0B); // Amber Orange
      icon = Icons.warning_amber_rounded;
    } else if (trackingStatus == TrackingStatus.arrived) {
      label = 'Arrived!';
      color = const Color(0xFF10B981); // Bright Green
      icon = Icons.check_circle;
    } else if (trackingStatus == TrackingStatus.paused) {
      label = 'Tracking Paused';
      color = const Color(0xFF64748B); // Muted Grey
      icon = Icons.pause;
    } else {
      label = 'Ready';
      color = const Color(0xFF3B82F6);
      icon = Icons.check;
    }

    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: theme.brightness == Brightness.dark ? 0.4 : 0.1,
            ),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 12, color: color),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
