import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../data/datasources/remote/client/online_server_api.dart';
import '../../../data/models/models/search_result.dart';
import '../base/base_provider.dart';

class SearchProvider extends BaseProvider {
  final OnlineServerApi _serverApi = OnlineServerApi();

  List<String> _recentSearches = [];
  SearchResult _results = SearchResult();
  String _currentQuery = '';

  SearchProvider() {
    _loadRecentSearches();
  }

  // Getters
  List<String> get recentSearches => _recentSearches;

  SearchResult get results => _results;

  String get currentQuery => _currentQuery;

  bool get hasResults => _results.items.isNotEmpty;

  bool get hasRecentSearches => _recentSearches.isNotEmpty;

  Future<void> _loadRecentSearches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final searchesJson = prefs.getString('recent_searches');
      if (searchesJson != null) {
        final List<dynamic> searchesList = json.decode(searchesJson);
        _recentSearches = searchesList.cast<String>();
        safeNotifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading recent searches: $e');
    }
  }

  Future<void> _saveRecentSearches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final searchesJson = json.encode(_recentSearches);
      await prefs.setString('recent_searches', searchesJson);
    } catch (e) {
      debugPrint('Error saving recent searches: $e');
    }
  }

  Future<void> search(String query) async {
    if (query.trim().isEmpty) {
      clearResults();
      return;
    }

    _currentQuery = query.trim();

    try {
      setLoading(true);
      clearError();

      // Add to recent searches
      await _addToRecentSearches(query.trim());

      // Perform search
      _results = await _serverApi.search(query.trim());
    } catch (e) {
      setError('Search failed: ${e.toString()}');
      _results = SearchResult(); // Empty results on error
    } finally {
      setLoading(false);
    }
  }

  Future<void> _addToRecentSearches(String query) async {
    try {
      // Remove if already exists
      _recentSearches.remove(query);

      // Add to beginning
      _recentSearches.insert(0, query);

      // Keep only last 10
      if (_recentSearches.length > 10) {
        _recentSearches = _recentSearches.take(10).toList();
      }

      // Save to storage
      await _saveRecentSearches();
      safeNotifyListeners();
    } catch (e) {
      debugPrint('Error adding to recent searches: $e');
    }
  }

  Future<void> selectRecentSearch(String query) async {
    await search(query);
  }

  Future<void> clearRecentSearches() async {
    try {
      _recentSearches.clear();
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('recent_searches');
      safeNotifyListeners();
    } catch (e) {
      setError('Failed to clear recent searches');
    }
  }

  void clearResults() {
    _results = SearchResult();
    _currentQuery = '';
    clearError();
    safeNotifyListeners();
  }
}
