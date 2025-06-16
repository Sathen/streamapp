import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/di/service_locator.dart';
import '../../../core/utils/logger.dart';
import '../../../core/utils/result.dart';
import '../../../data/datasources/remote/client/online_server_api.dart';
import '../../../data/models/models/search_result.dart';
import '../base/enhanced_base_provider.dart';

class SearchProvider extends EnhancedBaseProvider {
  late final OnlineServerApi _serverApi;
  late final SharedPreferences _prefs;
  late final AppLogger _logger;

  List<String> _recentSearches = [];
  SearchResult _results = SearchResult();
  String _currentQuery = '';

  SearchProvider() {
    _serverApi = get<OnlineServerApi>();
    _prefs = get<SharedPreferences>();
    _logger = get<AppLogger>();

    _logger.info('SearchProvider initialized');
    _loadRecentSearches();
  }

  // Getters
  List<String> get recentSearches => List.unmodifiable(_recentSearches);

  SearchResult get results => _results;

  String get currentQuery => _currentQuery;

  bool get hasResults => _results.items.isNotEmpty;

  bool get hasRecentSearches => _recentSearches.isNotEmpty;

  /// Load recent searches from storage
  Future<Result<List<String>>> _loadRecentSearches() async {
    return executeOperation(() async {
      final searchesJson = _prefs.getString('recent_searches');
      if (searchesJson != null) {
        final List<dynamic> searchesList = json.decode(searchesJson);
        _recentSearches = searchesList.cast<String>();
        safeNotifyListeners();
        return _recentSearches;
      }
      return <String>[];
    }, errorPrefix: 'Failed to load recent searches');
  }

  /// Save recent searches to storage
  Future<Result<void>> _saveRecentSearches() async {
    return executeOperation(() async {
      final searchesJson = json.encode(_recentSearches);
      await _prefs.setString('recent_searches', searchesJson);
    }, errorPrefix: 'Failed to save recent searches');
  }

  /// Perform search with proper error handling
  Future<Result<SearchResult>> search(String query) async {
    if (query.trim().isEmpty) {
      clearResults();
      return success(SearchResult());
    }

    _currentQuery = query.trim();
    _logger.info('Searching for: $_currentQuery');

    return executeOperation(
          () async {
        // Add to recent searches (non-blocking)
        await _addToRecentSearches(_currentQuery);

        // Perform search
        final result = await _serverApi.search(_currentQuery);
        _results = result;

        _logger.info('Search completed: ${result.items.length} results found');
        safeNotifyListeners();
        return result;
      },
      errorPrefix: 'Search failed',
    );
  }

  /// Add query to recent searches
  Future<Result<void>> _addToRecentSearches(String query) async {
    return executeOperation(() async {
      // Remove if already exists
      _recentSearches.remove(query);

      // Add to beginning
      _recentSearches.insert(0, query);

      // Keep only last 10
      if (_recentSearches.length > 10) {
        _recentSearches = _recentSearches.take(10).toList();
      }

      // Save to storage
      final saveResult = await _saveRecentSearches();
      if (saveResult.isSuccess) {
        _logger.debug('Added to recent searches: $query');
        safeNotifyListeners();
      }
    }, errorPrefix: 'Failed to add to recent searches');
  }

  /// Select and search from recent searches
  Future<Result<SearchResult>> selectRecentSearch(String query) async {
    return search(query);
  }

  /// Clear all recent searches
  Future<Result<void>> clearRecentSearches() async {
    return executeOperation(() async {
      _recentSearches.clear();
      await _prefs.remove('recent_searches');
      safeNotifyListeners();
    }, errorPrefix: 'Failed to clear recent searches');
  }

  /// Clear current search results
  void clearResults() {
    _results = SearchResult();
    _currentQuery = '';
    clearError();
    safeNotifyListeners();
  }

  /// Get search suggestions based on query
  List<String> getSearchSuggestions(String query) {
    if (query.trim().isEmpty) return _recentSearches.take(5).toList();

    return _recentSearches
        .where((search) => search.toLowerCase().contains(query.toLowerCase()))
        .take(5)
        .toList();
  }

  /// Check if a query exists in recent searches
  bool isRecentSearch(String query) {
    return _recentSearches.contains(query);
  }

  /// Remove specific search from recent searches
  Future<Result<void>> removeRecentSearch(String query) async {
    return executeOperation(() async {
      _recentSearches.remove(query);
      final saveResult = await _saveRecentSearches();
      if (saveResult.isSuccess) {
        safeNotifyListeners();
      }
    }, errorPrefix: 'Failed to remove recent search');
  }
}
