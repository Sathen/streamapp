import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stream_flutter/client/online_server_api.dart';
import 'dart:convert';

import '../models/search_result.dart';

class SearchProvider with ChangeNotifier {
  List<String> _recentSearches = [];
  SearchResult _results = SearchResult();
  bool _isLoading = false;
  String? _error;
  OnlineServerApi serverApi = OnlineServerApi();

  List<String> get recentSearches => _recentSearches;
  SearchResult get results => _results;
  bool get isLoading => _isLoading;
  String? get error => _error;

  SearchProvider() {
    _loadRecentSearches();
  }

  // Load recent searches from SharedPreferences
  Future<void> _loadRecentSearches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final searchesJson = prefs.getString('recent_searches');
      if (searchesJson != null) {
        final List<dynamic> searchesList = json.decode(searchesJson);
        _recentSearches = searchesList.cast<String>();
        notifyListeners();
      }
    } catch (e) {
      print('Error loading recent searches: $e');
    }
  }

  // Save recent searches to SharedPreferences
  Future<void> _saveRecentSearches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final searchesJson = json.encode(_recentSearches);
      await prefs.setString('recent_searches', searchesJson);
    } catch (e) {
      print('Error saving recent searches: $e');
    }
  }

  Future<void> search(String query) async {
    if (query.trim().isEmpty) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Add to recent searches (avoid duplicates and limit to 10)
      _recentSearches.remove(query); // Remove if already exists
      _recentSearches.insert(0, query); // Add to beginning
      if (_recentSearches.length > 10) {
        _recentSearches = _recentSearches.take(10).toList();
      }

      // Save to persistent storage
      await _saveRecentSearches();

      // Perform your actual search logic here
      _results = await serverApi.search(query);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearRecentSearches() async {
    _recentSearches.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('recent_searches');
    notifyListeners();
  }
}