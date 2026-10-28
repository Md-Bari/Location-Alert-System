import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/storage_service.dart';
import '../../settings/controllers/settings_notifier.dart';
import '../models/destination_model.dart';
import '../services/destination_search_service.dart';

class DestinationState {
  final DestinationModel? selectedDestination;
  final List<DestinationModel> searchResults;
  final List<DestinationModel> recentDestinations;
  final bool isSearching;
  final String? errorMessage;

  const DestinationState({
    this.selectedDestination,
    this.searchResults = const [],
    this.recentDestinations = const [],
    this.isSearching = false,
    this.errorMessage,
  });

  DestinationState copyWith({
    DestinationModel? selectedDestination,
    bool clearDestination = false,
    List<DestinationModel>? searchResults,
    List<DestinationModel>? recentDestinations,
    bool? isSearching,
    String? errorMessage,
  }) {
    return DestinationState(
      selectedDestination: clearDestination
          ? null
          : (selectedDestination ?? this.selectedDestination),
      searchResults: searchResults ?? this.searchResults,
      recentDestinations: recentDestinations ?? this.recentDestinations,
      isSearching: isSearching ?? this.isSearching,
      errorMessage: errorMessage,
    );
  }
}

class DestinationNotifier extends StateNotifier<DestinationState> {
  final DestinationSearchService _searchService;
  final StorageService? _storageService;
  int _searchRequestId = 0;

  DestinationNotifier(this._searchService, [this._storageService])
      : super(DestinationState(
          recentDestinations: _storageService?.getRecentDestinations() ?? [],
        ));

  void selectDestination(DestinationModel destination) {
    _storageService?.saveRecentDestination(destination);
    final updatedRecents = _storageService?.getRecentDestinations() ?? state.recentDestinations;

    state = state.copyWith(
      selectedDestination: destination,
      searchResults: [],
      recentDestinations: updatedRecents,
      isSearching: false,
      errorMessage: null,
    );
  }

  void clearDestination() {
    state = state.copyWith(
      clearDestination: true,
      searchResults: [],
      isSearching: false,
    );
  }

  Future<void> searchPlaces(
    String query, {
    double? userLat,
    double? userLng,
  }) async {
    final requestId = ++_searchRequestId;
    if (query.trim().isEmpty) {
      state = state.copyWith(searchResults: [], isSearching: false);
      return;
    }

    state = state.copyWith(isSearching: true, errorMessage: null);
    try {
      final results = await _searchService.searchPlaces(
        query,
        userLat: userLat,
        userLng: userLng,
      );
      // Drop responses for queries the user has already typed past.
      if (requestId != _searchRequestId) return;
      state = state.copyWith(searchResults: results, isSearching: false);
    } catch (e) {
      if (requestId != _searchRequestId) return;
      state = state.copyWith(
        isSearching: false,
        errorMessage: 'Failed to search places. Check internet connection.',
      );
    }
  }

  Future<void> selectFromCoordinates(double lat, double lng) async {
    state = state.copyWith(isSearching: true, errorMessage: null);
    try {
      final dest = await _searchService.createFromCoordinates(lat, lng);
      selectDestination(dest);
    } catch (e) {
      final dest = DestinationModel(
        id: 'pin_${DateTime.now().millisecondsSinceEpoch}',
        name: 'Selected Point',
        address: 'Lat: ${lat.toStringAsFixed(4)}, Lng: ${lng.toStringAsFixed(4)}',
        latitude: lat,
        longitude: lng,
      );
      selectDestination(dest);
    }
  }
}

final destinationSearchServiceProvider = Provider<DestinationSearchService>((ref) {
  return DestinationSearchService();
});

final destinationNotifierProvider =
    StateNotifierProvider<DestinationNotifier, DestinationState>((ref) {
  final searchService = ref.watch(destinationSearchServiceProvider);
  StorageService? storageService;
  try {
    storageService = ref.watch(storageServiceProvider);
  } catch (_) {}
  return DestinationNotifier(searchService, storageService);
});
