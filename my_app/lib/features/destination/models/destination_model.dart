import 'package:latlong2/latlong.dart';

class DestinationModel {
  final String id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final double? distanceFromUserMeters;

  const DestinationModel({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.distanceFromUserMeters,
  });

  LatLng toLatLng() => LatLng(latitude, longitude);

  DestinationModel copyWith({
    String? id,
    String? name,
    String? address,
    double? latitude,
    double? longitude,
    double? distanceFromUserMeters,
  }) {
    return DestinationModel(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      distanceFromUserMeters:
          distanceFromUserMeters ?? this.distanceFromUserMeters,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'address': address,
        'latitude': latitude,
        'longitude': longitude,
        'distanceFromUserMeters': distanceFromUserMeters,
      };

  factory DestinationModel.fromJson(Map<String, dynamic> json) =>
      DestinationModel(
        id: json['id'] as String,
        name: json['name'] as String,
        address: json['address'] as String? ?? '',
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        distanceFromUserMeters:
            (json['distanceFromUserMeters'] as num?)?.toDouble(),
      );

  @override
  String toString() => 'DestinationModel($name @ $latitude, $longitude)';
}
