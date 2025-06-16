// lib/presentation/providers/watch_history/watch_history_provider.dart

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/di/service_locator.dart';
import '../../../core/utils/logger.dart';
import '../../../core/utils/result.dart';
import '../../../data/models/models/watch_history.dart';
import '../base/enhanced_base_provider.dart';

class WatchHistoryProvider extends EnhancedBaseProvider {
  late final SharedPreferences _prefs;
  late final AppLogger _logger;

  static const String _historyKey = 'watch_history';
  static const int _maxHistoryItems = 20;

  List<WatchHistoryItem> _history = [];
  String _sortBy = 'lastWatched'; // lastWatched, title, watchCount
  bool _sortAscending = false;

  WatchHistoryProvider() {
    _prefs = get<SharedPreferences>();
    _logger = get<AppLogger>();
    _loadHistory();
  }

  // Getters
  List<WatchHistoryItem> get history => List.unmodifiable(_sortedHistory);

  List<WatchHistoryItem> get movies =>
      _history.where((item) => item.type == WatchHistoryType.movie).toList();

  List<WatchHistoryItem> get tvShows =>
      _history.where((item) => item.type == WatchHistoryType.tv).toList();

  bool get hasHistory => _history.isNotEmpty;

  int get totalItems => _history.length;

  int get totalMovies => movies.length;

  int get totalTVShows => tvShows.length;

  String get sortBy => _sortBy;

  bool get sortAscending => _sortAscending;

  List<WatchHistoryItem> get _sortedHistory {
    final sortedList = List<WatchHistoryItem>.from(_history);

    switch (_sortBy) {
      case 'title':
        sortedList.sort((a, b) => a.title.compareTo(b.title));
        break;
      case 'watchCount':
        sortedList.sort((a, b) => a.watchCount.compareTo(b.watchCount));
        break;
      case 'lastWatched':
      default:
        sortedList.sort((a, b) => a.lastWatched.compareTo(b.lastWatched));
        break;
    }

    if (!_sortAscending) {
      return sortedList.reversed.toList();
    }

    return sortedList;
  }

  /// Load watch history from storage
  Future<Result<List<WatchHistoryItem>>> _loadHistory() async {
    return executeOperation(() async {
      final historyJson = _prefs.getString(_historyKey);
      if (historyJson != null) {
        final List<dynamic> historyList = json.decode(historyJson);
        _history =
            historyList.map((item) => WatchHistoryItem.fromJson(item)).toList();
        _logger.info('Loaded ${_history.length} watch history items');
        safeNotifyListeners();
        return _history;
      }
      return <WatchHistoryItem>[];
    }, errorPrefix: 'Failed to load watch history');
  }

  /// Save watch history to storage
  Future<Result<void>> _saveHistory() async {
    return executeOperation(() async {
      final historyJson = json.encode(
        _history.map((item) => item.toJson()).toList(),
      );
      await _prefs.setString(_historyKey, historyJson);
      _logger.debug('Saved ${_history.length} watch history items');
    }, errorPrefix: 'Failed to save watch history');
  }

  /// Add movie to watch history
  Future<Result<void>> addMovieToHistory({
    required String tmdbId,
    required String title,
    required String originalTitle,
    String? posterPath,
    String? backdropPath,
    double? rating,
  }) async {
    return executeOperation(() async {
      final existingIndex = _history.indexWhere(
        (item) => item.id == tmdbId && item.type == WatchHistoryType.movie,
      );

      if (existingIndex != -1) {
        // Update existing entry
        final existing = _history[existingIndex];
        _history[existingIndex] = existing.copyWith(
          lastWatched: DateTime.now(),
          watchCount: existing.watchCount + 1,
          isCompleted: true,
        );
        _logger.debug('Updated movie in history: $title');
      } else {
        // Add new entry
        final newItem = WatchHistoryItem(
          id: tmdbId,
          title: title,
          originalTitle: originalTitle,
          type: WatchHistoryType.movie,
          posterPath: posterPath,
          backdropPath: backdropPath,
          rating: rating,
          lastWatched: DateTime.now(),
          watchCount: 1,
          isCompleted: true,
        );

        _history.insert(0, newItem);
        _logger.info('Added movie to history: $title');
      }

      // Keep only the latest items
      if (_history.length > _maxHistoryItems) {
        _history = _history.take(_maxHistoryItems).toList();
      }

      await _saveHistory();
      safeNotifyListeners();
    }, errorPrefix: 'Failed to add movie to history');
  }

  /// Add TV episode to watch history
  Future<Result<void>> addEpisodeToHistory({
    required String tmdbId,
    required String title,
    required String originalTitle,
    required int seasonNumber,
    required int episodeNumber,
    String? posterPath,
    String? backdropPath,
    double? rating,
  }) async {
    return executeOperation(() async {
      final existingIndex = _history.indexWhere(
        (item) => item.id == tmdbId && item.type == WatchHistoryType.tv,
      );

      if (existingIndex != -1) {
        // Update existing TV show entry
        final existing = _history[existingIndex];
        final updatedEpisodes = Map<int, Set<int>>.from(
          existing.watchedEpisodes ?? {},
        );

        if (!updatedEpisodes.containsKey(seasonNumber)) {
          updatedEpisodes[seasonNumber] = <int>{};
        }
        updatedEpisodes[seasonNumber]!.add(episodeNumber);

        _history[existingIndex] = existing.copyWith(
          lastWatched: DateTime.now(),
          watchCount: existing.watchCount + 1,
          watchedEpisodes: updatedEpisodes,
        );

        _logger.debug(
          'Updated TV show in history: $title S${seasonNumber}E${episodeNumber}',
        );
      } else {
        // Add new TV show entry
        final watchedEpisodes = <int, Set<int>>{
          seasonNumber: {episodeNumber},
        };

        final newItem = WatchHistoryItem(
          id: tmdbId,
          title: title,
          originalTitle: originalTitle,
          type: WatchHistoryType.tv,
          posterPath: posterPath,
          backdropPath: backdropPath,
          rating: rating,
          lastWatched: DateTime.now(),
          watchCount: 1,
          watchedEpisodes: watchedEpisodes,
        );

        _history.insert(0, newItem);
        _logger.info(
          'Added TV show to history: $title S${seasonNumber}E$episodeNumber',
        );
      }

      // Keep only the latest items
      if (_history.length > _maxHistoryItems) {
        _history = _history.take(_maxHistoryItems).toList();
      }

      await _saveHistory();
      safeNotifyListeners();
    }, errorPrefix: 'Failed to add episode to history');
  }

  /// Check if an episode has been watched
  bool hasWatchedEpisode(String tmdbId, int seasonNumber, int episodeNumber) {
    final item = _history.firstWhere(
      (item) => item.id == tmdbId && item.type == WatchHistoryType.tv,
      orElse:
          () => WatchHistoryItem(
            id: '',
            title: '',
            originalTitle: '',
            type: WatchHistoryType.tv,
            lastWatched: DateTime.now(),
          ),
    );

    if (item.id.isEmpty) return false;
    return item.hasWatchedEpisode(seasonNumber, episodeNumber);
  }

  /// Get watched episodes for a TV show
  Map<int, Set<int>>? getWatchedEpisodes(String tmdbId) {
    final item = _history.firstWhere(
      (item) => item.id == tmdbId && item.type == WatchHistoryType.tv,
      orElse:
          () => WatchHistoryItem(
            id: '',
            title: '',
            originalTitle: '',
            type: WatchHistoryType.tv,
            lastWatched: DateTime.now(),
          ),
    );

    return item.id.isNotEmpty ? item.watchedEpisodes : null;
  }

  /// Remove item from history
  Future<Result<void>> removeFromHistory(
    String itemId,
    WatchHistoryType type,
  ) async {
    return executeOperation(() async {
      _history.removeWhere((item) => item.id == itemId && item.type == type);
      await _saveHistory();
      safeNotifyListeners();
      _logger.info('Removed item from history: $itemId');
    }, errorPrefix: 'Failed to remove item from history');
  }

  /// Clear all watch history
  Future<Result<void>> clearHistory() async {
    return executeOperation(() async {
      _history.clear();
      await _prefs.remove(_historyKey);
      safeNotifyListeners();
      _logger.info('Cleared all watch history');
    }, errorPrefix: 'Failed to clear history');
  }

  /// Filter history by type
  List<WatchHistoryItem> getHistoryByType(WatchHistoryType? type) {
    if (type == null) return _sortedHistory;
    return _sortedHistory.where((item) => item.type == type).toList();
  }

  /// Search in history
  List<WatchHistoryItem> searchHistory(String query) {
    if (query.trim().isEmpty) return _sortedHistory;

    final lowercaseQuery = query.toLowerCase();
    return _sortedHistory.where((item) {
      return item.title.toLowerCase().contains(lowercaseQuery) ||
          item.originalTitle.toLowerCase().contains(lowercaseQuery);
    }).toList();
  }

  /// Set sorting options
  void setSorting(String sortBy, {bool? ascending}) {
    _sortBy = sortBy;
    if (ascending != null) {
      _sortAscending = ascending;
    }
    safeNotifyListeners();
  }

  /// Get recently watched items (last 7 days)
  List<WatchHistoryItem> getRecentlyWatched() {
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
    return _sortedHistory
        .where((item) => item.lastWatched.isAfter(sevenDaysAgo))
        .toList();
  }

  /// Get most watched items
  List<WatchHistoryItem> getMostWatched({int limit = 10}) {
    final sortedByWatchCount = List<WatchHistoryItem>.from(_history);
    sortedByWatchCount.sort((a, b) => b.watchCount.compareTo(a.watchCount));
    return sortedByWatchCount.take(limit).toList();
  }
}
