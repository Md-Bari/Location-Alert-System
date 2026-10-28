import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme.dart';
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
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  /// Debounces keystrokes so Nominatim (max 1 request/second) is not flooded.
  void _scheduleSearch(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 450), () {
      final location = ref.read(locationNotifierProvider).currentLocation;
      ref.read(destinationNotifierProvider.notifier).searchPlaces(
            query,
            userLat: location?.latitude,
            userLng: location?.longitude,
          );
    });
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
              prefixIcon: Icons.search_rounded,
              autofocus: true,
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () {
                        _debounce?.cancel();
                        _searchController.clear();
                        destinationNotifier.searchPlaces('');
                        setState(() {});
                      },
                    )
                  : null,
              onChanged: (query) {
                setState(() {});
                _scheduleSearch(query);
              },
              onSubmitted: (query) {
                _debounce?.cancel();
                destinationNotifier.searchPlaces(
                  query,
                  userLat: currentLocation?.latitude,
                  userLng: currentLocation?.longitude,
                );
              },
            ),
            const SizedBox(height: 16),

            if (destinationState.isSearching) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: const LinearProgressIndicator(minHeight: 3),
              ),
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
                      Icon(Icons.history_rounded, size: 18, color: AppTheme.primaryColor),
                      SizedBox(width: 6),
                      Text(
                        'RECENT PLACES',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.primaryColor,
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
                              Container(
                                padding: const EdgeInsets.all(22),
                                decoration: BoxDecoration(
                                  gradient: AppTheme.primaryGradient,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.accentColor.withValues(alpha: 0.35),
                                      blurRadius: 24,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.travel_explore_rounded,
                                  size: 44,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 20),
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
      final isSearching = ref.read(destinationNotifierProvider).isSearching;
      return Center(
        child: Text(
          isSearching
              ? 'Searching…'
              : 'No matching places found. Try tapping on the map.',
          style: const TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.separated(
      itemCount: destinations.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
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

        return Card(
          child: ListTile(
            leading: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.place_rounded,
                color: Colors.white,
                size: 22,
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
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      DistanceCalculator.formatDistance(distance),
                      style: const TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  )
                : null,
            onTap: () => onSelect(destination),
          ),
        );
      },
    );
  }
}
