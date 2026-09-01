import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_app/core/services/storage_service.dart';
import 'package:my_app/features/location/models/app_location.dart';
import 'package:my_app/features/settings/controllers/settings_notifier.dart';
import 'package:my_app/features/settings/screens/settings_screen.dart';
import 'package:my_app/features/trip/models/trip_model.dart';
import 'package:my_app/shared/widgets/status_badge.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('Widget Tests', () {
    testWidgets('StatusBadge renders tracking status correctly',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatusBadge(
              locationPermissionStatus: LocationPermissionStatus.granted,
              trackingStatus: TrackingStatus.tracking,
            ),
          ),
        ),
      );

      expect(find.text('Tracking Active'), findsOneWidget);
    });

    testWidgets('SettingsScreen mounts and renders sliders correctly',
        (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final storageService = StorageService(prefs);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            storageServiceProvider.overrideWithValue(storageService),
          ],
          child: const MaterialApp(
            home: SettingsScreen(),
          ),
        ),
      );

      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Warning Distance'), findsOneWidget);
      expect(find.text('Arrival Distance'), findsOneWidget);
      expect(find.text('Sound Alerts'), findsOneWidget);
    });
  });
}
