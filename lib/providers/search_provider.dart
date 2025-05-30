import 'dart:convert';
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/search_result.dart';

class SearchProvider extends ChangeNotifier {
  SearchResult _results = SearchResult();
  bool _isLoading = false;
  String? _error;

  SearchResult get results => _results;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> search(String query) async {
    if (query.isEmpty) {
      _reset();
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse("http://192.168.1.28:3535/online/search?name=$query"),
      );

      if (response.statusCode == 200) {
        _results = SearchResult.fromJson(json.decode(response.body));
      } else {
        _error = "Server error: ${response.statusCode}";
      }
    } catch (e) {
      _error = e.toString();
      log(e.toString());
    }

    _isLoading = false;
    notifyListeners();
  }

  void _reset() {
    _results = SearchResult();
    _error = null;
    _isLoading = false;
  }
}
