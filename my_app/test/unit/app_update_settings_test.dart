import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/core/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('App Update Notification Settings Persistence Tests', () {
    test('Defaults to app update notifications enabled and persists toggle state', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final storageService = StorageService(prefs);

      expect(storageService.getAppUpdateNotificationsEnabled(), isTrue);

      await storageService.setAppUpdateNotificationsEnabled(false);
      expect(storageService.getAppUpdateNotificationsEnabled(), isFalse);

      await storageService.setAppUpdateNotificationsEnabled(true);
      expect(storageService.getAppUpdateNotificationsEnabled(), isTrue);
    });
  });
}
