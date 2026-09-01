import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:my_app/features/destination/services/destination_search_service.dart';

void main() {
  group('DestinationSearchService Regional & Multilingual Tests', () {
    test('Constructs regional viewbox parameters when user position is provided',
        () async {
      late String requestedUrl;

      final mockClient = MockClient((request) async {
        requestedUrl = request.url.toString();
        return http.Response('[]', 200);
      });

      final service = DestinationSearchService(client: mockClient);
      await service.searchPlaces(
        'Dhanmondi',
        userLat: 23.777176,
        userLng: 90.399452,
      );

      expect(requestedUrl, contains('viewbox=89.649452,24.527176,91.149452,23.027176'));
      expect(requestedUrl, contains('bounded=0'));
    });

    test('Parses Bangla & English place annotations and ranks by distance', () async {
      final mockJsonResponse = '''
      [
        {
          "place_id": 101,
          "display_name": "Uttara Sector 3, Dhaka",
          "lat": "23.8700",
          "lon": "90.3900",
          "namedetails": {"name:bn": "উত্তরা সেক্টর ৩", "name:en": "Uttara Sector 3"}
        },
        {
          "place_id": 102,
          "display_name": "Dhanmondi Lake, Dhaka",
          "lat": "23.7460",
          "lon": "90.3750",
          "namedetails": {"name:bn": "ধানমন্ডি লেক", "name:en": "Dhanmondi Lake"}
        }
      ]
      ''';

      final mockClient = MockClient((request) async {
        return http.Response(
          mockJsonResponse,
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final service = DestinationSearchService(client: mockClient);
      // User is at Dhanmondi (23.7500, 90.3800) -> Dhanmondi Lake should rank closer than Uttara!
      final results = await service.searchPlaces(
        'Lake',
        userLat: 23.7500,
        userLng: 90.3800,
      );

      expect(results.length, equals(2));
      expect(results.first.name, contains('Dhanmondi Lake'));
      expect(results.first.name, contains('ধানমন্ডি লেক'));
      expect(results.first.distanceFromUserMeters, lessThan(results.last.distanceFromUserMeters!));
    });
  });
}
