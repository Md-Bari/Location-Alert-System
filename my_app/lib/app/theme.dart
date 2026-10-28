import 'package:flutter/material.dart';

class AppTheme {
  // Vibrant palette
  static const Color primaryColor = Color(0xFF2563EB); // Royal Blue
  static const Color primaryDark = Color(0xFF1D4ED8);
  static const Color accentColor = Color(0xFF6366F1); // Indigo
  static const Color successColor = Color(0xFF10B981); // Emerald Green
  static const Color warningColor = Color(0xFFF59E0B); // Amber Warning
  static const Color alertColor = Color(0xFFEF4444); // Crimson Alert

  // Live location marker & route (Google Maps-like navigation blue)
  static const Color locationBlue = Color(0xFF1A73E8);
  static const Color routeColor = Color(0xFF1A73E8);
  static const Color routeBorderColor = Color(0xFF0B57D0);
  static const Color routeTravelledColor = Color(0xFF94A3B8);

  static const Color darkBackground = Color(0xFF0B1220);
  static const Color darkSurface = Color(0xFF111A2E);
  static const Color darkCard = Color(0xFF1A2540);

  static const Color lightBackground = Color(0xFFF4F6FB);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFFFFFFF);

  static const Color textMuted = Color(0xFF64748B);

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF3B82F6), Color(0xFF6366F1)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF059669)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient warningGradient = LinearGradient(
    colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient alertGradient = LinearGradient(
    colors: [Color(0xFFF87171), Color(0xFFDC2626)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Soft elevated shadow used by floating map controls and panels.
  static List<BoxShadow> floatingShadow(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return [
      BoxShadow(
        color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.12),
        blurRadius: 18,
        offset: const Offset(0, 6),
      ),
    ];
  }

  /// Rounded floating surface used across map overlays.
  static BoxDecoration floatingSurface(BuildContext context, {double radius = 20}) {
    final theme = Theme.of(context);
    return BoxDecoration(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(radius),
      boxShadow: floatingShadow(context),
      border: Border.all(
        color: theme.brightness == Brightness.dark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.black.withValues(alpha: 0.04),
      ),
    );
  }

  static ThemeData lightTheme = _buildTheme(Brightness.light);

  static ThemeData darkTheme = _buildTheme(Brightness.dark);

  static ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final background = isDark ? darkBackground : lightBackground;
    final surface = isDark ? darkSurface : lightSurface;
    final card = isDark ? darkCard : lightCard;
    final onSurface = isDark ? Colors.white : const Color(0xFF0F172A);

    final colorScheme = (isDark ? const ColorScheme.dark() : const ColorScheme.light())
        .copyWith(
      primary: primaryColor,
      onPrimary: Colors.white,
      secondary: accentColor,
      surface: surface,
      onSurface: onSurface,
      surfaceContainerHighest: isDark ? const Color(0xFF223052) : const Color(0xFFEFF2F8),
      error: alertColor,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      cardColor: card,
      dividerColor: onSurface.withValues(alpha: 0.08),
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        backgroundColor: background,
        foregroundColor: onSurface,
        iconTheme: IconThemeData(color: onSurface),
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.2,
          color: onSurface,
        ),
      ),
      cardTheme: CardThemeData(
        color: card,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.05),
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: onSurface,
          side: BorderSide(color: onSurface.withValues(alpha: 0.15), width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
      sliderTheme: SliderThemeData(
        trackHeight: 6,
        activeTrackColor: primaryColor,
        inactiveTrackColor: primaryColor.withValues(alpha: 0.15),
        thumbColor: Colors.white,
        overlayColor: primaryColor.withValues(alpha: 0.12),
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 11, elevation: 3),
        valueIndicatorColor: primaryColor,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? Colors.white : null,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? primaryColor : null,
        ),
        trackOutlineColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? Colors.transparent : null,
        ),
      ),
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark ? const Color(0xFF223052) : const Color(0xFF0F172A),
        contentTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: primaryColor),
    );
  }
}
