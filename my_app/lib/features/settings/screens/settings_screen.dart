import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../notifications/services/notification_service.dart';
import '../controllers/settings_notifier.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsNotifierProvider);
    final settingsNotifier = ref.read(settingsNotifierProvider.notifier);
    final notificationService = ref.read(notificationServiceProvider);

    final arrivalMax = min(
      AppConstants.maxArrivalDistanceMeters,
      settings.warningDistance - SettingsNotifier.minThresholdGapMeters,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          // Hero header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.accentColor.withValues(alpha: 0.35),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.radar_rounded, color: Colors.white, size: 30),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        AppConstants.appName,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Alert at ${settings.warningDistance.round()} m · Arrive at ${settings.arrivalDistance.round()} m',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Proximity Distances Section
          const _SectionHeader(icon: Icons.radar_rounded, title: 'PROXIMITY THRESHOLDS'),
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ThresholdSlider(
                    title: 'Warning Distance',
                    description: 'Sound, vibration and notification when you get this close.',
                    value: settings.warningDistance,
                    min: AppConstants.minWarningDistanceMeters,
                    max: AppConstants.maxWarningDistanceMeters,
                    step: 10,
                    color: AppTheme.warningColor,
                    onChanged: settingsNotifier.updateWarningDistance,
                  ),
                  const Divider(height: 28),
                  _ThresholdSlider(
                    title: 'Arrival Distance',
                    description: 'Arrival alert fires and the trip completes inside this radius.',
                    value: settings.arrivalDistance.clamp(
                      AppConstants.minArrivalDistanceMeters,
                      arrivalMax,
                    ),
                    min: AppConstants.minArrivalDistanceMeters,
                    max: arrivalMax,
                    step: 5,
                    color: AppTheme.successColor,
                    onChanged: settingsNotifier.updateArrivalDistance,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Alerts & Feedback Section
          const _SectionHeader(icon: Icons.notifications_rounded, title: 'ALERTS & FEEDBACK'),
          Card(
            child: Column(
              children: [
                _SettingsSwitchTile(
                  icon: Icons.volume_up_rounded,
                  color: AppTheme.primaryColor,
                  title: 'Sound Alerts',
                  subtitle: 'Play sound on warning & arrival',
                  value: settings.soundEnabled,
                  onChanged: settingsNotifier.setSoundEnabled,
                ),
                const _TileDivider(),
                _SettingsSwitchTile(
                  icon: Icons.vibration_rounded,
                  color: AppTheme.accentColor,
                  title: 'Vibration Feedback',
                  subtitle: 'Vibrate device when reaching alerts',
                  value: settings.vibrationEnabled,
                  onChanged: settingsNotifier.setVibrationEnabled,
                ),
                const _TileDivider(),
                _SettingsSwitchTile(
                  icon: Icons.notifications_active_rounded,
                  color: AppTheme.warningColor,
                  title: 'System Notifications',
                  subtitle: 'Show foreground & background notifications',
                  value: settings.notificationsEnabled,
                  onChanged: (val) async {
                    if (val) await notificationService.requestPermission();
                    await settingsNotifier.setNotificationsEnabled(val);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Map Section
          const _SectionHeader(icon: Icons.map_rounded, title: 'MAP & APPEARANCE'),
          Card(
            child: Column(
              children: [
                _SettingsSwitchTile(
                  icon: Icons.traffic_rounded,
                  color: AppTheme.successColor,
                  title: 'Live Traffic Flow Layer',
                  subtitle: 'Show real-time road traffic congestion on map',
                  value: settings.isTrafficEnabled,
                  onChanged: settingsNotifier.setTrafficEnabled,
                ),
                const _TileDivider(),
                _SettingsSwitchTile(
                  icon: Icons.dark_mode_rounded,
                  color: const Color(0xFF8B5CF6),
                  title: 'Dark Mode',
                  subtitle: 'Dark app theme and night map style',
                  value: settings.isDarkMode,
                  onChanged: settingsNotifier.toggleDarkMode,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // App Updates Section
          const _SectionHeader(icon: Icons.system_update_rounded, title: 'APPLICATION UPDATES'),
          Card(
            child: Column(
              children: [
                _SettingsSwitchTile(
                  icon: Icons.system_update_rounded,
                  color: AppTheme.primaryColor,
                  title: 'Direct App Update Notifications',
                  subtitle: 'Receive push & direct notifications for new releases',
                  value: settings.isAppUpdateNotificationsEnabled,
                  onChanged: settingsNotifier.setAppUpdateNotificationsEnabled,
                ),
                const _TileDivider(),
                ListTile(
                  leading: const _TileIcon(icon: Icons.update_rounded, color: AppTheme.successColor),
                  title: const Text(
                    'Check for Updates Now',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text('Current Version: v${AppConstants.appVersion}'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () async {
                    if (settings.isAppUpdateNotificationsEnabled) {
                      await notificationService.showAppUpdateNotification(
                        currentVersion: AppConstants.appVersion,
                      );
                    }
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Location Alert v${AppConstants.appVersion} is up to date!',
                          ),
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: Text(
              'Map data ${AppConstants.mapAttribution}',
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;

  const _SectionHeader({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppTheme.primaryColor),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: AppTheme.primaryColor,
              letterSpacing: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}

class _TileIcon extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _TileIcon({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }
}

class _TileDivider extends StatelessWidget {
  const _TileDivider();

  @override
  Widget build(BuildContext context) => const Divider(height: 1, indent: 70);
}

class _SettingsSwitchTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingsSwitchTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      secondary: _TileIcon(icon: icon, color: color),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      value: value,
      onChanged: onChanged,
    );
  }
}

class _ThresholdSlider extends StatelessWidget {
  final String title;
  final String description;
  final double value;
  final double min;
  final double max;
  final double step;
  final Color color;
  final ValueChanged<double> onChanged;

  const _ThresholdSlider({
    required this.title,
    required this.description,
    required this.value,
    required this.min,
    required this.max,
    required this.step,
    required this.color,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final divisions = ((max - min) / step).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${value.round()} meters',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: color,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          description,
          style: TextStyle(
            fontSize: 12,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
          ),
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: color,
            inactiveTrackColor: color.withValues(alpha: 0.15),
            overlayColor: color.withValues(alpha: 0.12),
            valueIndicatorColor: color,
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions > 0 ? divisions : null,
            label: '${value.round()}m',
            onChanged: max > min ? onChanged : null,
          ),
        ),
      ],
    );
  }
}
