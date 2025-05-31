import 'package:flutter/material.dart';
import '../models/media_item.dart';
import '../services/media_service.dart';

class HomeScreenProvider extends ChangeNotifier {
  final MediaService mediaService;

  HomeScreenProvider({required this.mediaService});

  bool isLoading = true;

  // Movies
  List<MediaItem> nowPlayingMovies = [];
  List<MediaItem> popularMovies = [];
  List<MediaItem> topRatedMovies = [];
  List<MediaItem> newestMovies = [];

  // TV Shows
  List<MediaItem> popularTV = [];
  List<MediaItem> topRatedTV = [];
  List<MediaItem> newestTV = [];

  Future<void> initializeData() async {
    try {
      // If initializeData is called again (e.g. pull-to-refresh) and isLoading was false,
      // set it to true. If it's the first call, isLoading is already true by default.
      if (!isLoading) {
        isLoading = true;
        // Notify listeners after a microtask to avoid issues during build phase.
        Future.microtask(notifyListeners);
      } else {
        // Ensure isLoading is true if it wasn't already (e.g. if default was false)
        // and notify after microtask. This handles the initial call during provider creation.
        isLoading = true;
        Future.microtask(notifyListeners);
      }

      await Future.wait([
        _loadNowPlayingMovies(),
        _loadPopularMovies(),
        _loadTopRatedMovies(),
        _loadNewestMovies(),

        _loadPopularTV(),
        _loadTopRatedTV(),
        _loadNewestTV(),
      ]);
    } catch (e) {
      debugPrint('Error initializing data: $e');
    } finally {
      isLoading = false;
      notifyListeners(); // This notification is fine as it's after awaits or in finally.
    }
  }

  // Movie Loaders
  Future<void> _loadNowPlayingMovies() async {
    nowPlayingMovies = await mediaService.fetchNowPlayingMovies();
  }

  Future<void> _loadPopularMovies() async {
    popularMovies = await mediaService.fetchPopularMovies();
  }

  Future<void> _loadTopRatedMovies() async {
    topRatedMovies = await mediaService.fetchTopRatedMovies();
  }

  Future<void> _loadNewestMovies() async {
    newestMovies = await mediaService.fetchNewestMovies();
  }

  // TV Loaders
  Future<void> _loadPopularTV() async {
    popularTV = await mediaService.fetchPopularTV();
  }

  Future<void> _loadTopRatedTV() async {
    topRatedTV = await mediaService.fetchTopRatedTV();
  }

  Future<void> _loadNewestTV() async {
    newestTV = await mediaService.fetchNewestTV();
  }
}
