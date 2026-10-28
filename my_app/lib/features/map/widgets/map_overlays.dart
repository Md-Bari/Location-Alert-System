import 'package:flutter/material.dart';
import '../../../app/theme.dart';

/// Destination pin with a floating name label.
class DestinationPin extends StatelessWidget {
  final String name;

  const DestinationPin({super.key, required this.name});

  static const double width = 180;
  static const double height = 92;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            constraints: const BoxConstraints(maxWidth: width),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              gradient: AppTheme.alertGradient,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.alertColor.withValues(alpha: 0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Text(
              name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 2),
          Stack(
            alignment: Alignment.topCenter,
            children: [
              Icon(
                Icons.location_on,
                size: 52,
                color: Colors.black.withValues(alpha: 0.18),
                shadows: const [Shadow(blurRadius: 6)],
              ),
              const Icon(Icons.location_on, size: 50, color: AppTheme.alertColor),
              Positioned(
                top: 12,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Round floating map control (Google Maps style).
class MapControlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final String tooltip;
  final Color? iconColor;
  final Color? backgroundColor;
  final double size;
  final Widget? child;

  const MapControlButton({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.tooltip,
    this.iconColor,
    this.backgroundColor,
    this.size = 48,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Tooltip(
      message: tooltip,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: backgroundColor ?? theme.colorScheme.surface,
          shape: BoxShape.circle,
          boxShadow: AppTheme.floatingShadow(context),
        ),
        child: Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onPressed,
            child: Center(
              child: child ??
                  Icon(
                    icon,
                    size: size * 0.48,
                    color: iconColor ?? theme.colorScheme.onSurface.withValues(alpha: 0.8),
                  ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Small rounded status/info banner floating over the map.
class MapBanner extends StatelessWidget {
  final IconData icon;
  final String message;
  final Color color;
  final String? actionLabel;
  final VoidCallback? onAction;

  const MapBanner({
    super.key,
    required this.icon,
    required this.message,
    required this.color,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
            ),
          ),
          if (actionLabel != null && onAction != null)
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: color,
                backgroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                minimumSize: const Size(0, 34),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: onAction,
              child: Text(
                actionLabel!,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }
}
