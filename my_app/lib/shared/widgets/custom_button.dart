import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color? backgroundColor;
  final Gradient? gradient;
  final Color? textColor;
  final bool isLoading;
  final bool isFullWidth;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.backgroundColor,
    this.gradient,
    this.textColor,
    this.isLoading = false,
    this.isFullWidth = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = backgroundColor ?? theme.colorScheme.primary;
    final fg = textColor ?? Colors.white;
    final isEnabled = !isLoading && onPressed != null;
    final shadowColor = gradient?.colors.last ?? bg;

    Widget child = Row(
      mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading) ...[
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(fg),
            ),
          ),
          const SizedBox(width: 10),
        ] else if (icon != null) ...[
          Icon(icon, size: 20, color: fg),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.2,
              color: fg,
            ),
          ),
        ),
      ],
    );

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: isEnabled ? 1 : 0.7,
      child: Container(
        width: isFullWidth ? double.infinity : null,
        height: 54,
        decoration: BoxDecoration(
          color: gradient == null ? bg : null,
          gradient: gradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isEnabled
              ? [
                  BoxShadow(
                    color: shadowColor.withValues(alpha: 0.35),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: isEnabled ? onPressed : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
