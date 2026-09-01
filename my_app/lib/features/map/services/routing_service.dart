import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart' hide DistanceCalculator;
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/distance_calculator.dart';
import '../models/route_model.dart';

class RoutingService {
  final http.Client _client;

  RoutingService({http.Client? client}) : _client = client ?? http.Client();

  /// Calculates route between start and destination coordinates using OSRM API with straight-line fallback.
  Future<RouteModel> calculateRoute({
    required LatLng start,
    required LatLng destination,
  }) async {
    final straightLineDistance = DistanceCalculator.calculateHaversineDistance(
      startLatitude: start.latitude,
      startLongitude: start.longitude,
      destinationLatitude: destination.latitude,
      destinationLongitude: destination.longitude,
    );

    final url = Uri.parse(
      'https://router.project-osrm.org/route/v1/driving/${start.longitude},${start.latitude};${destination.longitude},${destination.latitude}?overview=full&geometries=geojson',
    );

    try {
      final response = await _client.get(
        url,
        headers: {'User-Agent': AppConstants.mapUserAgent},
      ).timeout(const Duration(seconds: 7));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final routes = data['routes'] as List?;
        if (routes != null && routes.isNotEmpty) {
          final firstRoute = routes.first;
          final distanceMeters = (firstRoute['distance'] as num).toDouble();
          final durationSeconds = (firstRoute['duration'] as num).toDouble();
          final geometry = firstRoute['geometry'] as Map<String, dynamic>?;

          if (geometry != null && geometry['coordinates'] != null) {
            final coords = geometry['coordinates'] as List;
            final points = coords.map<LatLng>((c) {
              return LatLng(
                (c[1] as num).toDouble(),
                (c[0] as num).toDouble(),
              );
            }).toList();

            return RouteModel(
              points: points,
              distanceMeters: distanceMeters,
              durationSeconds: durationSeconds,
              isStraightLineFallback: false,
            );
          }
        }
      }
    } catch (_) {
      // API call failed, timeout, or no internet -> Graceful Fallback
    }

    return RouteModel.straightLine(start, destination, straightLineDistance);
  }
}
