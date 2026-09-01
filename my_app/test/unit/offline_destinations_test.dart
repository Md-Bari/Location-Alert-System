import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/core/services/storage_service.dart';
import 'package:my_app/features/destination/models/destination_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('Offline Recent Destinations Persistence Tests', () {
    test('Saves and retrieves recent destinations offline', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final storageService = StorageService(prefs);

      expect(storageService.getRecentDestinations(), isEmpty);

      const dest1 = DestinationModel(
        id: 'dest_1',
        name: 'Dhanmondi Lake',
        address: 'Dhanmondi, Dhaka',
        latitude: 23.7460,
        longitude: 90.3750,
      );

      const dest2 = DestinationModel(
        id: 'dest_2',
        name: 'Gulshan 2',
        address: 'Gulshan, Dhaka',
        latitude: 23.7925,
        longitude: 90.4167,
      );

      await storageService.saveRecentDestination(dest1);
      await storageService.saveRecentDestination(dest2);

      final recents = storageService.getRecentDestinations();
      expect(recents.length, equals(2));
      // Latest saved destination (dest2) appears first
      expect(recents.first.name, equals('Gulshan 2'));
      expect(recents.last.name, equals('Dhanmondi Lake'));
    });

    test('Deduplicates duplicate destinations when re-selected', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final storageService = StorageService(prefs);

      const dest = DestinationModel(
        id: 'dest_1',
        name: 'Uttara Sector 3',
        address: 'Uttara, Dhaka',
        latitude: 23.8700,
        longitude: 90.3900,
      );

      await storageService.saveRecentDestination(dest);
      await storageService.saveRecentDestination(dest);

      final recents = storageService.getRecentDestinations();
      expect(recents.length, equals(1));
    });
  });
}
