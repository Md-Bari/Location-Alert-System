import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/core/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('Traffic Setting Persistence Tests', () {
    test('Defaults to traffic disabled and persists toggle state', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final storageService = StorageService(prefs);

      expect(storageService.getTrafficEnabled(), isFalse);

      await storageService.setTrafficEnabled(true);
      expect(storageService.getTrafficEnabled(), isTrue);

      await storageService.setTrafficEnabled(false);
      expect(storageService.getTrafficEnabled(), isFalse);
    });
  });
}
