import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/distance_calculator.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../../location/controllers/location_notifier.dart';
import '../controllers/destination_notifier.dart';
import '../models/destination_model.dart';

class DestinationSearchScreen extends ConsumerStatefulWidget {
  const DestinationSearchScreen({super.key});

  @override
  ConsumerState<DestinationSearchScreen> createState() =>
      _DestinationSearchScreenState();
}

class _DestinationSearchScreenState
    extends ConsumerState<DestinationSearchScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final destinationState = ref.watch(destinationNotifierProvider);
    final destinationNotifier = ref.read(destinationNotifierProvider.notifier);
    final locationState = ref.watch(locationNotifierProvider);
    final currentLocation = locationState.currentLocation;

    final isSearchQueryEmpty = _searchController.text.trim().isEmpty;
    final hasRecentDestinations = destinationState.recentDestinations.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Destination'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomTextField(
              controller: _searchController,
              hintText: 'Search place (e.g. Dhanmondi, ধানমন্ডি, Gulshan)',
              prefixIcon: Icons.search,
              autofocus: false,
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        destinationNotifier.searchPlaces(
                          '',
                          userLat: currentLocation?.latitude,
                          userLng: currentLocation?.longitude,
                        );
                        setState(() {});
                      },
                    )
                  : null,
              onChanged: (query) {
                setState(() {});
                destinationNotifier.searchPlaces(
                  query,
                  userLat: currentLocation?.latitude,
                  userLng: currentLocation?.longitude,
                );
              },
            ),
            const SizedBox(height: 16),

            if (destinationState.isSearching) ...[
              const LinearProgressIndicator(),
              const SizedBox(height: 12),
            ],

            if (destinationState.errorMessage != null) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  destinationState.errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ],

            // Section Header for Offline Recent Places
            if (isSearchQueryEmpty && hasRecentDestinations) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.history_rounded, size: 18, color: Colors.blue),
                      SizedBox(width: 6),
                      Text(
                        'SAVED & RECENT PLACES (OFFLINE)',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: Colors.blue,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      '⚡ Offline Ready',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],

            Expanded(
              child: isSearchQueryEmpty
                  ? (hasRecentDestinations
                      ? _buildDestinationList(
                          destinations: destinationState.recentDestinations,
                          currentLat: currentLocation?.latitude,
                          currentLng: currentLocation?.longitude,
                          onSelect: (dest) {
                            destinationNotifier.selectDestination(dest);
                            Navigator.of(context).pop();
                          },
                        )
                      : Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.map_outlined,
                                size: 64,
                                color: Colors.grey.withValues(alpha: 0.5),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Search for a location above or\ntap directly on the map to set a pin.',
                                textAlign: TextAlign.center,
                                style:
                                    TextStyle(color: Colors.grey, fontSize: 15),
                              ),
                            ],
                          ),
                        ))
                  : _buildDestinationList(
                      destinations: destinationState.searchResults,
                      currentLat: currentLocation?.latitude,
                      currentLng: currentLocation?.longitude,
                      onSelect: (dest) {
                        destinationNotifier.selectDestination(dest);
                        Navigator.of(context).pop();
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDestinationList({
    required List<DestinationModel> destinations,
    required double? currentLat,
    required double? currentLng,
    required ValueChanged<DestinationModel> onSelect,
  }) {
    if (destinations.isEmpty) {
      return const Center(
        child: Text(
          'No matching places found. Try tapping on the map.',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.separated(
      itemCount: destinations.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final destination = destinations[index];

        double? distance = destination.distanceFromUserMeters;
        if (distance == null && currentLat != null && currentLng != null) {
          distance = DistanceCalculator.calculateHaversineDistance(
            startLatitude: currentLat,
            startLongitude: currentLng,
            destinationLatitude: destination.latitude,
            destinationLongitude: destination.longitude,
          );
        }

        return ListTile(
          leading: const CircleAvatar(
            backgroundColor: Color(0xFF3B82F6),
            child: Icon(
              Icons.location_on,
              color: Colors.white,
              size: 20,
            ),
          ),
          title: Text(
            destination.name,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
          subtitle: Text(
            destination.address,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12),
          ),
          trailing: distance != null
              ? Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    DistanceCalculator.formatDistance(distance),
                    style: const TextStyle(
                      color: Color(0xFF3B82F6),
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                )
              : null,
          onTap: () => onSelect(destination),
        );
      },
    );
  }
}
