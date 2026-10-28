import 'dart:math';

import 'package:flutter/material.dart';
import '../../../app/theme.dart';

/// Google Maps-style "blue dot" with a pulsing halo and a direction-of-travel beam.
class UserLocationMarker extends StatefulWidget {
  /// Compass heading in degrees (0 = North), or null when direction is unknown.
  final double? heading;

  /// Whether the GPS fix is live; a stale fix renders greyed out.
  final bool isLive;

  /// Renders a navigation arrow instead of a dot (used while a trip is active).
  final bool navigationStyle;

  const UserLocationMarker({
    super.key,
    this.heading,
    this.isLive = true,
    this.navigationStyle = false,
  });

  static const double size = 96;

  @override
  State<UserLocationMarker> createState() => _UserLocationMarkerState();
}

class _UserLocationMarkerState extends State<UserLocationMarker>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.isLive ? AppTheme.locationBlue : AppTheme.routeTravelledColor;
    final headingRad = widget.heading == null ? null : widget.heading! * pi / 180.0;

    return SizedBox(
      width: UserLocationMarker.size,
      height: UserLocationMarker.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Pulsing halo
          if (widget.isLive)
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, _) {
                final t = Curves.easeOut.transform(_pulseController.value);
                return Container(
                  width: 22 + 52 * t,
                  height: 22 + 52 * t,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withValues(alpha: 0.28 * (1 - t)),
                  ),
                );
              },
            ),

          // Heading beam
          if (headingRad != null && !widget.navigationStyle)
            Transform.rotate(
              angle: headingRad,
              child: CustomPaint(
                size: const Size(UserLocationMarker.size, UserLocationMarker.size),
                painter: _HeadingBeamPainter(color: color),
              ),
            ),

          if (widget.navigationStyle)
            Transform.rotate(
              angle: headingRad ?? 0,
              child: _NavigationArrow(color: color),
            )
          else
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _NavigationArrow extends StatelessWidget {
  final Color color;

  const _NavigationArrow({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: CustomPaint(painter: _ArrowPainter(color: color)),
    );
  }
}

class _ArrowPainter extends CustomPainter {
  final Color color;

  _ArrowPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final path = Path()
      ..moveTo(w * 0.5, h * 0.16)
      ..lineTo(w * 0.78, h * 0.80)
      ..lineTo(w * 0.5, h * 0.64)
      ..lineTo(w * 0.22, h * 0.80)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _ArrowPainter oldDelegate) => oldDelegate.color != color;
}

class _HeadingBeamPainter extends CustomPainter {
  final Color color;

  _HeadingBeamPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const sweep = 70 * pi / 180;

    final rect = Rect.fromCircle(center: center, radius: radius);
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [color.withValues(alpha: 0.55), color.withValues(alpha: 0.0)],
        stops: const [0.15, 1.0],
      ).createShader(rect);

    // Beam points "up" (north) before rotation; canvas angle 0 is east, so start at -90°.
    final path = Path()
      ..moveTo(center.dx, center.dy)
      ..arcTo(rect, -pi / 2 - sweep / 2, sweep, false)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _HeadingBeamPainter oldDelegate) => oldDelegate.color != color;
}
