import 'package:flutter/foundation.dart';

import '../../../data/datasources/remote/client/online_server_api.dart';
import '../../../data/datasources/remote/services/media_service.dart';
import '../../../data/models/models/online_media_details_entity.dart';
import '../../../data/models/models/search_result.dart';
import '../../../data/models/models/tmdb_models.dart';
import '../base/base_provider.dart';

class MediaDetailsProvider extends BaseProvider {
  final MediaService _mediaService = MediaService(null, null, null);
  final OnlineServerApi _onlineApi = OnlineServerApi();

  // TMDB Data
  TmdbMediaDetails? _mediaData;
  List<TVSeasonDetails>? _seasonDetails;

  // Online Data
  OnlineMediaDetailsEntity? _onlineMediaData;

  // Loading states
  TVEpisode? _loadingEpisode;
  bool _isFetchingStreams = false;

  // Getters
  TmdbMediaDetails? get mediaData => _mediaData;

  List<TVSeasonDetails>? get seasonDetails => _seasonDetails;

  OnlineMediaDetailsEntity? get onlineMediaData => _onlineMediaData;

  TVEpisode? get loadingEpisode => _loadingEpisode;

  bool get isFetchingStreams => _isFetchingStreams;

  // Load TMDB media details
  Future<void> loadTmdbMediaDetails(int tmdbId, MediaType type) async {
    try {
      setLoading(true);
      clearError();

      _mediaData = null;
      _seasonDetails = null;

      if (type == MediaType.movie) {
        _mediaData = await _mediaService.fetchMovieDetails(tmdbId);
      } else if (type == MediaType.tv) {
        final tvDetails = await _mediaService.fetchTVDetails(tmdbId);
        _mediaData = tvDetails;
        _seasonDetails = await Future.wait(
          tvDetails.seasons.map(
            (s) => _mediaService.fetchTVSeasonDetails(tmdbId, s.seasonNumber),
          ),
        );
      }

      safeNotifyListeners();
    } catch (e) {
      setError('Failed to load media details: ${e.toString()}');
      debugPrint('Error loading TMDB media: $e');
    } finally {
      setLoading(false);
    }
  }

  // Load online media details
  Future<void> loadOnlineMediaDetails(SearchItem searchItem) async {
    try {
      setLoading(true);
      clearError();

      _onlineMediaData = null;
      _onlineMediaData = await _onlineApi.get(searchItem);

      safeNotifyListeners();
    } catch (e) {
      setError('Failed to load online media details: ${e.toString()}');
      debugPrint('Error loading online media: $e');
    } finally {
      setLoading(false);
    }
  }

  // Set episode loading state
  void setEpisodeLoading(TVEpisode? episode) {
    _loadingEpisode = episode;
    safeNotifyListeners();
  }

  // Set stream fetching state
  void setFetchingStreams(bool fetching) {
    _isFetchingStreams = fetching;
    safeNotifyListeners();
  }

  // Clear all data
  void clearData() {
    _mediaData = null;
    _seasonDetails = null;
    _onlineMediaData = null;
    _loadingEpisode = null;
    _isFetchingStreams = false;
    clearError();
    safeNotifyListeners();
  }
}
