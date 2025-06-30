import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/di/service_locator.dart';
import '../../../core/enums/display_category.dart';
import '../../../core/utils/result.dart';
import '../../../data/datasources/remote/client/tmdb_client.dart';
import '../../../data/models/models/media_item.dart';
import '../../../data/models/models/tmdb_models.dart';
import '../base/enhanced_base_provider.dart';

class MediaProvider extends EnhancedBaseProvider {
  TmdbClient get _mediaService => get<TmdbClient>();


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

  List<MediaItem> get nowPlayingMovies => List.unmodifiable(_nowPlayingMovies);

  List<MediaItem> get popularMovies => List.unmodifiable(_popularMovies);

  List<MediaItem> get topRatedMovies => List.unmodifiable(_topRatedMovies);

  List<MediaItem> get newestMovies => List.unmodifiable(_newestMovies);

  List<MediaItem> get popularTV => List.unmodifiable(_popularTV);

  List<MediaItem> get topRatedTV => List.unmodifiable(_topRatedTV);

  List<MediaItem> get newestTV => List.unmodifiable(_newestTV);

  TmdbMediaDetails? get selectedMedia => _selectedMedia;

  List<TVSeasonDetails>? get seasonDetails => _seasonDetails;

  void setSelectedCategory(DisplayCategory category) {
    _selectedCategory = category;
    safeNotifyListeners();
  }

  /// Initialize all data with proper error handling
  Future<Result<void>> initializeData() async {
    return executeOperation(() async {
      final results = await executeOperations([
        () => _mediaService.fetchNowPlayingMovies(),
        () => _mediaService.fetchPopularMovies(),
        () => _mediaService.fetchTopRatedMovies(),
        () => _mediaService.fetchNewestMovies(),
        () => _mediaService.fetchPopularTV(),
        () => _mediaService.fetchTopRatedTV(),
        () => _mediaService.fetchNewestTV(),
      ], errorPrefix: 'Failed to initialize data');

      if (results.isSuccess) {
        final data = results.data!;
        _nowPlayingMovies = data[0] as List<MediaItem>;
        _popularMovies = data[1] as List<MediaItem>;
        _topRatedMovies = data[2] as List<MediaItem>;
        _newestMovies = data[3] as List<MediaItem>;
        _popularTV = data[4] as List<MediaItem>;
        _topRatedTV = data[5] as List<MediaItem>;
        _newestTV = data[6] as List<MediaItem>;
        safeNotifyListeners();
      }
    }, errorPrefix: 'Failed to load media data');
  }

  /// Load movie details with proper error handling
  Future<Result<TmdbMovieDetails>> loadMovieDetails(int tmdbId) async {
    return executeOperation(() async {
      final details = await _mediaService.fetchMovieDetails(tmdbId);
      _selectedMedia = details;
      _seasonDetails = null; // Clear TV season details
      safeNotifyListeners();
      return details;
    }, errorPrefix: 'Failed to load movie details');
  }

  /// Load TV details with proper error handling
  Future<Result<TVDetails>> loadTVDetails(int tmdbId) async {
    return executeOperation(() async {
      final tvDetails = await _mediaService.fetchTVDetails(tmdbId);
      _selectedMedia = tvDetails;

      // Load season details
      final seasonFutures =
          tvDetails.seasons
              .map(
                (s) =>
                    _mediaService.fetchTVSeasonDetails(tmdbId, s.seasonNumber),
              )
              .toList();

      _seasonDetails = await Future.wait(seasonFutures);
      safeNotifyListeners();
      return tvDetails;
    }, errorPrefix: 'Failed to load TV details');
  }

  /// Refresh specific category data
  Future<Result<List<MediaItem>>> refreshCategory(
    DisplayCategory category,
  ) async {
    switch (category) {
      case DisplayCategory.movies:
        return executeOperation(() async {
          _popularMovies = await _mediaService.fetchPopularMovies();
          safeNotifyListeners();
          return _popularMovies;
        }, errorPrefix: 'Failed to refresh movies');
      case DisplayCategory.tv:
        return executeOperation(() async {
          _popularTV = await _mediaService.fetchPopularTV();
          safeNotifyListeners();
          return _popularTV;
        }, errorPrefix: 'Failed to refresh TV shows');
    }
  }

  void clearSelectedMedia() {
    _selectedMedia = null;
    _seasonDetails = null;
    clearError();
    safeNotifyListeners();
  }
}

// Example usage in a widget
class ExampleUsage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<MediaProvider>(
      builder: (context, provider, child) {
        return RefreshIndicator(
          onRefresh: () async {
            final result = await provider.initializeData();

            // Handle the result
            result.fold(
              (data) {
                // Success - data is automatically handled by provider
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Data refreshed successfully')),
                );
              },
              (error, exception) {
                // Error - show user-friendly message
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(error)));
              },
            );
          },
          child:
              provider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : provider.hasError
                  ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(provider.error!),
                        ElevatedButton(
                          onPressed: () => provider.initializeData(),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                  : ListView.builder(
                    itemCount: provider.popularMovies.length,
                    itemBuilder: (context, index) {
                      final movie = provider.popularMovies[index];
                      return ListTile(
                        title: Text(movie.name),
                        onTap: () async {
                          final result = await provider.loadMovieDetails(
                            int.parse(movie.id),
                          );

                          result.fold(
                            (movieDetails) {
                              // Navigate to details screen
                              Navigator.pushNamed(
                                context,
                                '/movie-details',
                                arguments: movieDetails,
                              );
                            },
                            (error, exception) {
                              ScaffoldMessenger.of(
                                context,
                              ).showSnackBar(SnackBar(content: Text(error)));
                            },
                          );
                        },
                      );
                    },
                  ),
        );
      },
    );
  }
}
