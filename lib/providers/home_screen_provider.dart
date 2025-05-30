import 'package:flutter/material.dart';
import '../models/media_item.dart';
import '../services/media_service.dart';

class HomeScreenProvider extends ChangeNotifier {
  final MediaService mediaService;

  HomeScreenProvider({required this.mediaService});

  List<MediaItem> continueWatching = [];
  List<MediaItem> recentlyAdded = [];
  Map<String, List<MediaItem>> libraries = {};
  bool isLoading = true;

  Future<void> initializeData() async {
    try {
      isLoading = true;
      notifyListeners();

      await Future.wait([
        _loadContinueWatching(),
        _loadRecentlyAdded(),
        _loadLibraries(),
      ]);
    } catch (e) {
      debugPrint('Error initializing data: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadContinueWatching() async {
    continueWatching = await mediaService.fetchContinueWatching();
  }

  Future<void> _loadRecentlyAdded() async {
    recentlyAdded = await mediaService.fetchRecentlyAdded();
  }

  Future<void> _loadLibraries() async {
    libraries = await mediaService.fetchLibraries();
  }
}
