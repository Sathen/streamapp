import 'package:flutter/material.dart';

import '../../../core/di/service_locator.dart';
import '../../../data/datasources/remote/services/jellyfin_service.dart';
import '../../../data/models/models/media_item.dart';
import '../base/base_provider.dart';
import 'jellyfin_auth_provider.dart';

class JellyfinDataProvider extends BaseProvider {
  final JellyfinService _service = get<JellyfinService>();
  final JellyfinAuthProvider _authProvider;

  JellyfinDataProvider(this._authProvider) {
    // Listen to auth changes
    _authProvider.addListener(_onAuthChanged);
  }

  @override
  void dispose() {
    _authProvider.removeListener(_onAuthChanged);
    super.dispose();
  }

  // ===========================
  // DATA STATE MANAGEMENT
  // ===========================

  // Content cache
  List<MediaItem> _continueWatching = [];
  List<MediaItem> _recentlyAdded = [];
  Map<String, List<MediaItem>> _libraries = {};
  List<MediaItem> _favorites = [];
  List<MediaItem> _nextUpEpisodes = [];
  Map<String, dynamic>? _serverStats;

  // Loading states for different sections
  bool _isLoadingContinueWatching = false;
  bool _isLoadingRecentlyAdded = false;
  bool _isLoadingLibraries = false;
  bool _isLoadingFavorites = false;
  bool _isLoadingNextUp = false;

  // Last refresh timestamps
  DateTime? _lastContinueWatchingRefresh;
  DateTime? _lastRecentlyAddedRefresh;
  DateTime? _lastLibrariesRefresh;
  DateTime? _lastFavoritesRefresh;

  // Error states
  String? _continueWatchingError;
  String? _recentlyAddedError;
  String? _librariesError;
  String? _favoritesError;

  // ===========================
  // GETTERS - Read-only access to cached data
  // ===========================

  // Content data
  List<MediaItem> get continueWatching => List.unmodifiable(_continueWatching);

  List<MediaItem> get recentlyAdded => List.unmodifiable(_recentlyAdded);

  Map<String, List<MediaItem>> get libraries => Map.unmodifiable(_libraries);

  List<MediaItem> get favorites => List.unmodifiable(_favorites);

  List<MediaItem> get nextUpEpisodes => List.unmodifiable(_nextUpEpisodes);

  Map<String, dynamic>? get serverStats => _serverStats;

  // Loading states
  bool get isLoadingContinueWatching => _isLoadingContinueWatching;

  bool get isLoadingRecentlyAdded => _isLoadingRecentlyAdded;

  bool get isLoadingLibraries => _isLoadingLibraries;

  bool get isLoadingFavorites => _isLoadingFavorites;

  bool get isLoadingNextUp => _isLoadingNextUp;

  bool get isLoadingAnyContent =>
      _isLoadingContinueWatching ||
      _isLoadingRecentlyAdded ||
      _isLoadingLibraries ||
      _isLoadingFavorites ||
      _isLoadingNextUp;

  // Error states
  String? get continueWatchingError => _continueWatchingError;

  String? get recentlyAddedError => _recentlyAddedError;

  String? get librariesError => _librariesError;

  String? get favoritesError => _favoritesError;

  bool get hasAnyErrors =>
      _continueWatchingError != null ||
      _recentlyAddedError != null ||
      _librariesError != null ||
      _favoritesError != null;

  // Data availability
  bool get hasAnyContent =>
      _continueWatching.isNotEmpty ||
      _recentlyAdded.isNotEmpty ||
      _libraries.isNotEmpty ||
      _favorites.isNotEmpty ||
      _nextUpEpisodes.isNotEmpty;

  bool get canLoadData => _authProvider.isLoggedIn;

  // Refresh timestamps
  DateTime? get lastContinueWatchingRefresh => _lastContinueWatchingRefresh;

  DateTime? get lastRecentlyAddedRefresh => _lastRecentlyAddedRefresh;

  DateTime? get lastLibrariesRefresh => _lastLibrariesRefresh;

  DateTime? get lastFavoritesRefresh => _lastFavoritesRefresh;

  // ===========================
  // DATA LOADING - Individual sections
  // ===========================

  /// Load continue watching content
  Future<void> loadContinueWatching({bool force = false}) async {
    if (!canLoadData) return;
    if (_isLoadingContinueWatching && !force) return;

    _isLoadingContinueWatching = true;
    _continueWatchingError = null;
    safeNotifyListeners();

    try {
      _continueWatching = await _service.fetchContinueWatching();
      _lastContinueWatchingRefresh = DateTime.now();
    } catch (e) {
      _continueWatchingError =
          'Failed to load continue watching: ${e.toString()}';
    } finally {
      _isLoadingContinueWatching = false;
      safeNotifyListeners();
    }
  }

  /// Load recently added content
  Future<void> loadRecentlyAdded({bool force = false}) async {
    if (!canLoadData) return;
    if (_isLoadingRecentlyAdded && !force) return;

    _isLoadingRecentlyAdded = true;
    _recentlyAddedError = null;
    safeNotifyListeners();

    try {
      _recentlyAdded = await _service.fetchRecentlyAdded();
      _lastRecentlyAddedRefresh = DateTime.now();
    } catch (e) {
      _recentlyAddedError = 'Failed to load recently added: ${e.toString()}';
    } finally {
      _isLoadingRecentlyAdded = false;
      safeNotifyListeners();
    }
  }

  /// Load all libraries
  Future<void> loadLibraries({bool force = false}) async {
    if (!canLoadData) return;
    if (_isLoadingLibraries && !force) return;

    _isLoadingLibraries = true;
    _librariesError = null;
    safeNotifyListeners();

    try {
      _libraries = await _service.fetchLibraries();
      _lastLibrariesRefresh = DateTime.now();
    } catch (e) {
      _librariesError = 'Failed to load libraries: ${e.toString()}';
    } finally {
      _isLoadingLibraries = false;
      safeNotifyListeners();
    }
  }

  /// Load favorites
  Future<void> loadFavorites({bool force = false}) async {
    if (!canLoadData) return;
    if (_isLoadingFavorites && !force) return;

    _isLoadingFavorites = true;
    _favoritesError = null;
    safeNotifyListeners();

    try {
      _favorites = await _service.getFavorites();
      _lastFavoritesRefresh = DateTime.now();
    } catch (e) {
      _favoritesError = 'Failed to load favorites: ${e.toString()}';
    } finally {
      _isLoadingFavorites = false;
      safeNotifyListeners();
    }
  }

  /// Load next up episodes
  Future<void> loadNextUpEpisodes({bool force = false}) async {
    if (!canLoadData) return;
    if (_isLoadingNextUp && !force) return;

    _isLoadingNextUp = true;
    safeNotifyListeners();

    try {
      _nextUpEpisodes = await _service.getNextUpEpisodes();
    } catch (e) {
      // Next up is optional, don't show error
      debugPrint('Failed to load next up episodes: $e');
    } finally {
      _isLoadingNextUp = false;
      safeNotifyListeners();
    }
  }

  /// Load server statistics
  Future<void> loadServerStats() async {
    if (!canLoadData) return;

    try {
      _serverStats = await _service.getServerStats();
      safeNotifyListeners();
    } catch (e) {
      debugPrint('Failed to load server stats: $e');
    }
  }

  // ===========================
  // BULK OPERATIONS
  // ===========================

  /// Load all essential content
  Future<void> loadAllContent({bool force = false}) async {
    if (!canLoadData) return;

    await Future.wait([
      loadContinueWatching(force: force),
      loadRecentlyAdded(force: force),
      loadLibraries(force: force),
      loadFavorites(force: force),
      loadNextUpEpisodes(force: force),
    ]);

    // Load stats separately (non-critical)
    loadServerStats();
  }

  /// Refresh all content
  Future<void> refreshAll() async {
    await loadAllContent(force: true);
  }

  /// Smart refresh - only refresh stale data
  Future<void> smartRefresh({
    Duration staleDuration = const Duration(minutes: 5),
  }) async {
    if (!canLoadData) return;

    final now = DateTime.now();

    await Future.wait([
      if (_shouldRefresh(_lastContinueWatchingRefresh, now, staleDuration))
        loadContinueWatching(force: true),
      if (_shouldRefresh(_lastRecentlyAddedRefresh, now, staleDuration))
        loadRecentlyAdded(force: true),
      if (_shouldRefresh(_lastLibrariesRefresh, now, staleDuration))
        loadLibraries(force: true),
      if (_shouldRefresh(_lastFavoritesRefresh, now, staleDuration))
        loadFavorites(force: true),
    ]);
  }

  // ===========================
  // CONTENT OPERATIONS WITH UI UPDATES
  // ===========================

  /// Toggle favorite with optimistic UI update
  Future<void> toggleFavorite(MediaItem item) async {
    if (!canLoadData) return;

    final wasOriginallyFavorite = isFavorite(item.id);

    // Optimistic update
    if (wasOriginallyFavorite) {
      _favorites.removeWhere((fav) => fav.id == item.id);
    } else {
      _favorites.add(item);
    }
    safeNotifyListeners();

    try {
      await _service.toggleFavorite(item.id, !wasOriginallyFavorite);
    } catch (e) {
      // Revert on failure
      if (wasOriginallyFavorite) {
        _favorites.add(item);
      } else {
        _favorites.removeWhere((fav) => fav.id == item.id);
      }
      safeNotifyListeners();
      rethrow;
    }
  }

  /// Mark as played and update relevant sections
  Future<void> markAsPlayed(String itemId) async {
    if (!canLoadData) return;

    try {
      await _service.markAsPlayed(itemId);

      // Remove from continue watching cache
      _continueWatching.removeWhere((item) => item.id == itemId);
      safeNotifyListeners();

      // Refresh continue watching to get updated data
      loadContinueWatching(force: true);
    } catch (e) {
      throw Exception('Failed to mark as played: ${e.toString()}');
    }
  }

  /// Mark as unplayed and refresh continue watching
  Future<void> markAsUnplayed(String itemId) async {
    if (!canLoadData) return;

    try {
      await _service.markAsUnplayed(itemId);

      // Refresh continue watching to show item again
      await loadContinueWatching(force: true);
    } catch (e) {
      throw Exception('Failed to mark as unplayed: ${e.toString()}');
    }
  }

  /// Update playback progress (silent operation)
  Future<void> updatePlaybackProgress({
    required String itemId,
    required int positionTicks,
    bool isPaused = false,
  }) async {
    if (!canLoadData) return;

    try {
      await _service.updatePlaybackProgress(
        itemId: itemId,
        positionTicks: positionTicks,
        isPaused: isPaused,
      );

      // Silently refresh continue watching if significant progress
      if (!isPaused && positionTicks > 0) {
        loadContinueWatching();
      }
    } catch (e) {
      // Don't throw for progress updates - they're not critical
      debugPrint('Failed to update playback progress: $e');
    }
  }

  // ===========================
  // SEARCH & LIBRARY OPERATIONS
  // ===========================

  /// Get direct access to service for operations not cached
  JellyfinService get service => _service;

  /// Search content (not cached)
  Future<List<MediaItem>> searchContent(String query, {int limit = 50}) async {
    if (!canLoadData) return [];
    return await _service.searchContent(query, limit: limit);
  }

  /// Get library content with pagination (not cached)
  Future<List<MediaItem>> getLibraryContent(
    String libraryId, {
    int startIndex = 0,
    int limit = 50,
    String? sortBy,
    String? sortOrder,
    String? searchTerm,
  }) async {
    if (!canLoadData) return [];
    return await _service.fetchLibraryContent(
      libraryId,
      startIndex: startIndex,
      limit: limit,
      sortBy: sortBy,
      sortOrder: sortOrder,
      searchTerm: searchTerm,
    );
  }

  /// Get item details (not cached)
  Future<MediaItem?> getItemDetails(String itemId) async {
    if (!canLoadData) return null;
    return await _service.getItemDetails(itemId);
  }

  // ===========================
  // UTILITY METHODS
  // ===========================

  /// Check if item is in favorites cache
  bool isFavorite(String itemId) {
    return _favorites.any((item) => item.id == itemId);
  }

  /// Get library by name from cache
  List<MediaItem>? getLibraryByName(String libraryName) {
    return _libraries[libraryName];
  }

  /// Get all library names from cache
  List<String> getLibraryNames() {
    return _libraries.keys.toList();
  }

  /// Get content counts
  Map<String, int> getContentCounts() {
    return {
      'Continue Watching': _continueWatching.length,
      'Recently Added': _recentlyAdded.length,
      'Favorites': _favorites.length,
      'Next Up Episodes': _nextUpEpisodes.length,
      'Libraries': _libraries.length,
      'Total Library Items': _libraries.values.fold(
        0,
        (sum, items) => sum + items.length,
      ),
    };
  }

  /// Get combined recent activity for dashboard
  List<MediaItem> getRecentActivity({int limit = 20}) {
    final combined = <String, MediaItem>{};

    // Priority: Continue watching first
    for (final item in _continueWatching) {
      combined[item.id] = item;
    }

    // Then recently added (if not already in continue watching)
    for (final item in _recentlyAdded) {
      combined.putIfAbsent(item.id, () => item);
    }

    return combined.values.take(limit).toList();
  }

  /// Get items by type from all content
  List<MediaItem> getItemsByType(String type) {
    final allItems = <MediaItem>[];
    allItems.addAll(_continueWatching);
    allItems.addAll(_recentlyAdded);
    allItems.addAll(_favorites);
    allItems.addAll(_nextUpEpisodes);

    for (final libraryItems in _libraries.values) {
      allItems.addAll(libraryItems);
    }

    return allItems
        .where((item) => item.type.toString().toLowerCase() == type.toLowerCase())
        .toList();
  }

  /// Check if data needs refresh
  bool needsRefresh(Duration maxAge) {
    final now = DateTime.now();
    return _shouldRefresh(_lastContinueWatchingRefresh, now, maxAge) ||
        _shouldRefresh(_lastRecentlyAddedRefresh, now, maxAge) ||
        _shouldRefresh(_lastLibrariesRefresh, now, maxAge) ||
        _shouldRefresh(_lastFavoritesRefresh, now, maxAge);
  }

  /// Clear all error states
  void clearErrors() {
    _continueWatchingError = null;
    _recentlyAddedError = null;
    _librariesError = null;
    _favoritesError = null;
    safeNotifyListeners();
  }

  // ===========================
  // PRIVATE METHODS
  // ===========================

  void _onAuthChanged() {
    if (!_authProvider.isLoggedIn) {
      // Clear all data when logged out
      _clearAllData();
      _clearAllErrors();
      safeNotifyListeners();
    } else {
      // Load data when logged in
      loadAllContent();
    }
  }

  void _clearAllData() {
    _continueWatching.clear();
    _recentlyAdded.clear();
    _libraries.clear();
    _favorites.clear();
    _nextUpEpisodes.clear();
    _serverStats = null;

    _lastContinueWatchingRefresh = null;
    _lastRecentlyAddedRefresh = null;
    _lastLibrariesRefresh = null;
    _lastFavoritesRefresh = null;
  }

  void _clearAllErrors() {
    _continueWatchingError = null;
    _recentlyAddedError = null;
    _librariesError = null;
    _favoritesError = null;
  }

  bool _shouldRefresh(DateTime? lastRefresh, DateTime now, Duration maxAge) {
    if (lastRefresh == null) return true;
    return now.difference(lastRefresh) > maxAge;
  }

  String getImageUrl(itemId, type) {

  }
}
