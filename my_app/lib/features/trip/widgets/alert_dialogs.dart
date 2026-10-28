import 'package:flutter/material.dart';
import '../../../app/theme.dart';
import '../../../core/utils/distance_calculator.dart';
import '../../../shared/widgets/custom_button.dart';

class WarningAlertDialog extends StatelessWidget {
  final String destinationName;
  final double distanceMeters;
  final VoidCallback onDismiss;

  const WarningAlertDialog({
    super.key,
    required this.destinationName,
    required this.distanceMeters,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return _AlertCard(
      gradient: AppTheme.warningGradient,
      glowColor: AppTheme.warningColor,
      icon: Icons.near_me_rounded,
      title: 'Approaching Destination',
      message: 'You are about ${DistanceCalculator.formatDistance(distanceMeters)} from $destinationName. Get ready!',
      buttonText: 'GOT IT',
      onPressed: onDismiss,
    );
  }
}

class ArrivalAlertDialog extends StatelessWidget {
  final String destinationName;
  final VoidCallback onStopTracking;

  const ArrivalAlertDialog({
    super.key,
    required this.destinationName,
    required this.onStopTracking,
  });

  @override
  Widget build(BuildContext context) {
    return _AlertCard(
      gradient: AppTheme.successGradient,
      glowColor: AppTheme.successColor,
      icon: Icons.where_to_vote_rounded,
      title: 'You Have Arrived',
      message: 'You reached $destinationName.',
      buttonText: 'STOP TRACKING',
      onPressed: onStopTracking,
    );
  }
}

class _AlertCard extends StatelessWidget {
  final LinearGradient gradient;
  final Color glowColor;
  final IconData icon;
  final String title;
  final String message;
  final String buttonText;
  final VoidCallback onPressed;

  const _AlertCard({
    required this.gradient,
    required this.glowColor,
    required this.icon,
    required this.title,
    required this.message,
    required this.buttonText,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      clipBehavior: Clip.antiAlias,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Gradient header with glowing icon
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 28),
            decoration: BoxDecoration(gradient: gradient),
            child: Center(
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.6, end: 1.0),
                duration: const Duration(milliseconds: 500),
                curve: Curves.elasticOut,
                builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Icon(icon, size: 44, color: glowColor),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 22, 24, 24),
            child: Column(
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                CustomButton(
                  text: buttonText,
                  gradient: gradient,
                  onPressed: onPressed,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
