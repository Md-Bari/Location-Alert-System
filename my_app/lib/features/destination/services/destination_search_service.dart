import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/distance_calculator.dart';
import '../models/destination_model.dart';

class DestinationSearchService {
  final http.Client _client;

  DestinationSearchService({http.Client? client})
      : _client = client ?? http.Client();

  /// Searches places prioritizing user's current region, returning Bangla/English place names ranked by distance.
  Future<List<DestinationModel>> searchPlaces(
    String query, {
    double? userLat,
    double? userLng,
  }) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) return [];

    final encodedQuery = Uri.encodeComponent(cleanQuery);
    var urlString =
        'https://nominatim.openstreetmap.org/search?q=$encodedQuery&format=json&addressdetails=1&namedetails=1&limit=15';

    // Add regional viewbox bias if current location is known
    if (userLat != null && userLng != null) {
      final minLng = userLng - 0.75;
      final maxLng = userLng + 0.75;
      final minLat = userLat - 0.75;
      final maxLat = userLat + 0.75;

      urlString += '&viewbox=$minLng,$maxLat,$maxLng,$minLat&bounded=0';
    }

    final url = Uri.parse(urlString);

    try {
      final response = await _client.get(
        url,
        headers: {
          'User-Agent': AppConstants.mapUserAgent,
          'Accept-Language': 'bn,en-US;q=0.9,en;q=0.8',
        },
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final List data = json.decode(response.body);

        final results = data.map<DestinationModel>((element) {
          final item = element as Map<String, dynamic>;
          final displayName = item['display_name'] as String? ?? 'Unknown Location';
          final parts = displayName.split(',');
          var primaryName = parts.isNotEmpty ? parts.first.trim() : displayName;
          final subtitle = parts.length > 1 ? parts.sublist(1).join(',').trim() : '';

          final namedetails = item['namedetails'] as Map<String, dynamic>?;
          final nameBn = namedetails?['name:bn'] as String?;
          final nameEn = namedetails?['name:en'] as String?;

          // Annotate Bangla name if available and not present
          if (nameBn != null &&
              nameBn.isNotEmpty &&
              !primaryName.contains(nameBn)) {
            if (nameEn != null && nameEn.isNotEmpty && nameEn != primaryName) {
              primaryName = '$primaryName / $nameBn';
            } else if (!primaryName.contains('/')) {
              primaryName = '$primaryName ($nameBn)';
            }
          }

          final destLat = (item['lat'] is num)
              ? (item['lat'] as num).toDouble()
              : double.parse(item['lat'].toString());
          final destLng = (item['lon'] is num)
              ? (item['lon'] as num).toDouble()
              : double.parse(item['lon'].toString());

          double? distMeters;
          if (userLat != null && userLng != null) {
            distMeters = DistanceCalculator.calculateHaversineDistance(
              startLatitude: userLat,
              startLongitude: userLng,
              destinationLatitude: destLat,
              destinationLongitude: destLng,
            );
          }

          return DestinationModel(
            id: item['place_id']?.toString() ??
                DateTime.now().millisecondsSinceEpoch.toString(),
            name: primaryName,
            address: subtitle.isNotEmpty ? subtitle : displayName,
            latitude: destLat,
            longitude: destLng,
            distanceFromUserMeters: distMeters,
          );
        }).toList();

        // Sort by distance from user if current location is available
        if (userLat != null && userLng != null) {
          results.sort((a, b) {
            final dA = a.distanceFromUserMeters ?? double.infinity;
            final dB = b.distanceFromUserMeters ?? double.infinity;
            return dA.compareTo(dB);
          });
        }

        return results;
      }
    } catch (_) {
      // Graceful offline/timeout handling
    }

    return [];
  }

  /// Reverse geocodes latitude/longitude coordinates to place name & address.
  Future<DestinationModel> createFromCoordinates(
      double latitude, double longitude) async {
    final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?lat=$latitude&lon=$longitude&format=json&addressdetails=1&namedetails=1');

    try {
      final response = await _client.get(
        url,
        headers: {
          'User-Agent': AppConstants.mapUserAgent,
          'Accept-Language': 'bn,en-US;q=0.9,en;q=0.8',
        },
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final displayName = data['display_name'] as String? ?? '';
        final addressObj = data['address'] as Map?;
        final namedetails = data['namedetails'] as Map?;

        String name = 'Pinned Location';
        if (namedetails != null && namedetails['name:bn'] != null) {
          name = namedetails['name:bn'];
        } else if (addressObj != null) {
          name = addressObj['amenity'] ??
              addressObj['building'] ??
              addressObj['road'] ??
              addressObj['suburb'] ??
              addressObj['city'] ??
              'Pinned Location';
        }

        return DestinationModel(
          id: 'map_pin_${DateTime.now().millisecondsSinceEpoch}',
          name: name,
          address: displayName.isNotEmpty
              ? displayName
              : 'Lat: ${latitude.toStringAsFixed(5)}, Lng: ${longitude.toStringAsFixed(5)}',
          latitude: latitude,
          longitude: longitude,
        );
      }
    } catch (_) {
      // Graceful fallback
    }

    return DestinationModel(
      id: 'map_pin_${DateTime.now().millisecondsSinceEpoch}',
      name: 'Pinned Destination',
      address:
          'Lat: ${latitude.toStringAsFixed(5)}, Lng: ${longitude.toStringAsFixed(5)}',
      latitude: latitude,
      longitude: longitude,
    );
  }
}
