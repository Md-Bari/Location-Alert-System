import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../controllers/settings_notifier.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsNotifierProvider);
    final settingsNotifier = ref.read(settingsNotifierProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Proximity Distances Section
          const Text(
            'PROXIMITY THRESHOLDS',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.blue,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 12),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Warning Distance',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                      Text(
                        '${settings.warningDistance.round()} meters',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFF59E0B),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Triggers warning sound, vibration, and notification when approaching target radius.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  Slider(
                    value: settings.warningDistance,
                    min: AppConstants.minWarningDistanceMeters,
                    max: AppConstants.maxWarningDistanceMeters,
                    divisions: 39,
                    label: '${settings.warningDistance.round()}m',
                    onChanged: (val) =>
                        settingsNotifier.updateWarningDistance(val),
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Arrival Distance',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                      Text(
                        '${settings.arrivalDistance.round()} meters',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF10B981),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Triggers arrival alert and stops active trip tracking.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  Slider(
                    value: settings.arrivalDistance,
                    min: AppConstants.minArrivalDistanceMeters,
                    max: AppConstants.maxArrivalDistanceMeters,
                    divisions: 39,
                    label: '${settings.arrivalDistance.round()}m',
                    onChanged: (val) =>
                        settingsNotifier.updateArrivalDistance(val),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Alerts & Feedback Section
          const Text(
            'ALERTS & FEEDBACK',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.blue,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 12),

          Card(
            child: Column(
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.volume_up_rounded),
                  title: const Text('Sound Alerts'),
                  subtitle: const Text('Play sound on warning & arrival'),
                  value: settings.soundEnabled,
                  onChanged: (val) => settingsNotifier.setSoundEnabled(val),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  secondary: const Icon(Icons.vibration_rounded),
                  title: const Text('Vibration Feedback'),
                  subtitle: const Text('Vibrate device when reaching alerts'),
                  value: settings.vibrationEnabled,
                  onChanged: (val) =>
                      settingsNotifier.setVibrationEnabled(val),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  secondary: const Icon(Icons.notifications_active_rounded),
                  title: const Text('System Notifications'),
                  subtitle:
                      const Text('Show foreground & background notifications'),
                  value: settings.notificationsEnabled,
                  onChanged: (val) =>
                      settingsNotifier.setNotificationsEnabled(val),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  secondary: const Icon(Icons.dark_mode_rounded),
                  title: const Text('Dark Mode'),
                  subtitle: const Text('Toggle app dark theme'),
                  value: settings.isDarkMode,
                  onChanged: (val) => settingsNotifier.toggleDarkMode(val),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
