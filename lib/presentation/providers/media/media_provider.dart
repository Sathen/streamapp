import 'package:flutter/cupertino.dart';

import '../../../data/datasources/remote/services/media_service.dart';
import '../../../data/models/models/media_item.dart';
import '../../../data/models/models/tmdb_models.dart';
import '../base/base_provider.dart';

enum DisplayCategory { movies, tv }

class MediaProvider extends BaseProvider {
  final MediaService _mediaService = MediaService(null, null, null);

  // State
  DisplayCategory _selectedCategory = DisplayCategory.movies;

  // Movies
  List<MediaItem> _nowPlayingMovies = [];
  List<MediaItem> _popularMovies = [];
  List<MediaItem> _topRatedMovies = [];
  List<MediaItem> _newestMovies = [];

  // TV Shows
  List<MediaItem> _popularTV = [];
  List<MediaItem> _topRatedTV = [];
  List<MediaItem> _newestTV = [];

  // Details
  TmdbMediaDetails? _selectedMedia;
  List<TVSeasonDetails>? _seasonDetails;

  // Getters
  DisplayCategory get selectedCategory => _selectedCategory;

  List<MediaItem> get nowPlayingMovies => _nowPlayingMovies;

  List<MediaItem> get popularMovies => _popularMovies;

  List<MediaItem> get topRatedMovies => _topRatedMovies;

  List<MediaItem> get newestMovies => _newestMovies;

  List<MediaItem> get popularTV => _popularTV;

  List<MediaItem> get topRatedTV => _topRatedTV;

  List<MediaItem> get newestTV => _newestTV;

  TmdbMediaDetails? get selectedMedia => _selectedMedia;

  List<TVSeasonDetails>? get seasonDetails => _seasonDetails;

  void setSelectedCategory(DisplayCategory category) {
    _selectedCategory = category;
    safeNotifyListeners();
  }

  Future<void> initializeData() async {
    try {
      setLoading(true);
      clearError();

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
      setError('Failed to load data: ${e.toString()}');
    } finally {
      setLoading(false);
    }
  }

  // Movie loading methods
  Future<void> _loadNowPlayingMovies() async {
    try {
      _nowPlayingMovies = await _mediaService.fetchNowPlayingMovies();
    } catch (e) {
      debugPrint('Error loading now playing movies: $e');
    }
  }

  Future<void> _loadPopularMovies() async {
    try {
      _popularMovies = await _mediaService.fetchPopularMovies();
    } catch (e) {
      debugPrint('Error loading popular movies: $e');
    }
  }

  Future<void> _loadTopRatedMovies() async {
    try {
      _topRatedMovies = await _mediaService.fetchTopRatedMovies();
    } catch (e) {
      debugPrint('Error loading top rated movies: $e');
    }
  }

  Future<void> _loadNewestMovies() async {
    try {
      _newestMovies = await _mediaService.fetchNewestMovies();
    } catch (e) {
      debugPrint('Error loading newest movies: $e');
    }
  }

  // TV loading methods
  Future<void> _loadPopularTV() async {
    try {
      _popularTV = await _mediaService.fetchPopularTV();
    } catch (e) {
      debugPrint('Error loading popular TV: $e');
    }
  }

  Future<void> _loadTopRatedTV() async {
    try {
      _topRatedTV = await _mediaService.fetchTopRatedTV();
    } catch (e) {
      debugPrint('Error loading top rated TV: $e');
    }
  }

  Future<void> _loadNewestTV() async {
    try {
      _newestTV = await _mediaService.fetchNewestTV();
    } catch (e) {
      debugPrint('Error loading newest TV: $e');
    }
  }

  // Media details methods
  Future<void> loadMovieDetails(int tmdbId) async {
    try {
      setLoading(true);
      clearError();

      _selectedMedia = await _mediaService.fetchMovieDetails(tmdbId);
      _seasonDetails = null; // Clear TV season details
    } catch (e) {
      setError('Failed to load movie details: ${e.toString()}');
    } finally {
      setLoading(false);
    }
  }

  Future<void> loadTVDetails(int tmdbId) async {
    try {
      setLoading(true);
      clearError();

      final tvDetails = await _mediaService.fetchTVDetails(tmdbId);
      _selectedMedia = tvDetails;

      // Load season details
      _seasonDetails = await Future.wait(
        tvDetails.seasons.map(
          (s) => _mediaService.fetchTVSeasonDetails(tmdbId, s.seasonNumber),
        ),
      );
    } catch (e) {
      setError('Failed to load TV details: ${e.toString()}');
    } finally {
      setLoading(false);
    }
  }

  void clearSelectedMedia() {
    _selectedMedia = null;
    _seasonDetails = null;
    clearError();
    safeNotifyListeners();
  }
}
