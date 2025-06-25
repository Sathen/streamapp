import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stream_flutter/data/models/models/generic_media_details.dart';

import '../../../core/di/service_locator.dart';
import '../../../data/datasources/remote/client/online_server_api.dart';
import '../../../data/datasources/remote/services/media_service.dart';
import '../../../data/models/models/online_media_details_entity.dart';
import '../../../data/models/models/search_result.dart';
import '../../../data/models/models/tmdb_models.dart';
import '../../../data/models/models/video_streams.dart';
import '../base/base_provider.dart';
import '../watch_history/watch_history_provider.dart';

class MediaDetailsProvider extends BaseProvider {
  final MediaService _mediaService = get<MediaService>();
  final OnlineServerApi _onlineApi = get<OnlineServerApi>();

  TmdbMediaDetails? _mediaData;
  List<TVSeasonDetails>? _seasonDetails;

  // Online Data
  OnlineMediaDetailsEntity? _onlineMediaData;

  // Loading states
  GenericEpisode? _loadingEpisode;
  bool _isFetchingStreams = false;

  // Getters
  TmdbMediaDetails? get tmdbMediaData => _mediaData;

  List<TVSeasonDetails>? get seasonDetails => _seasonDetails;

  OnlineMediaDetailsEntity? get onlineMediaData => _onlineMediaData;

  GenericEpisode? get loadingEpisode => _loadingEpisode;

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
                (s) =>
                _mediaService.fetchTVSeasonDetails(tmdbId, s.seasonNumber),
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

  String? getTmdbId(bool isOnline) {
    if (isOnline && onlineMediaData != null) {
      // For online media, parse the tmdbId string to int
      return onlineMediaData?.tmdbId;
    } else if (!isOnline && tmdbMediaData != null) {
      // For TMDB media, use the tmdbId getter
      return tmdbMediaData?.tmdbId;
    }
    return null;
  }

  bool hasSeasons(bool isOnline) {
    if (isOnline &&
        (onlineMediaData?.seasons == null ||
            onlineMediaData!.seasons.isEmpty)) {
      return false;
    }

    if (!isOnline && (seasonDetails == null || seasonDetails!.isEmpty)) {
      return false;
    }

    return true;
  }

  // Set episode loading state
  void setEpisodeLoading(GenericEpisode? episode) {
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

  bool hasWatchedEpisode(BuildContext context,
      String tmdbId,
      int seasonNumber,
      int episodeNumber,) {
    try {
      final historyProvider = Provider.of<WatchHistoryProvider>(
        context,
        listen: false,
      );
      return historyProvider.hasWatchedEpisode(
        tmdbId,
        seasonNumber,
        episodeNumber,
      );
    } catch (e) {
      return false;
    }
  }

  /// Get watched episodes for a TV show (for UI indicators)
  Map<int, Set<int>>? getWatchedEpisodes(BuildContext context, String tmdbId) {
    try {
      final historyProvider = Provider.of<WatchHistoryProvider>(
        context,
        listen: false,
      );
      return historyProvider.getWatchedEpisodes(tmdbId);
    } catch (e) {
      return null;
    }
  }

  GenericMediaData? getMediaDetails(bool isOnlineMedia) {
    return isOnlineMedia ? onlineMediaData : tmdbMediaData;
  }

  Future<VideoStreams> getVideoSteamsByPath({required String embedUrl}) async {
    return _onlineApi.getVideoStreamsByPath(embedUrl);
  }

  Future<VideoStreams> getVideoSteams(
      {required String title, String? originalTitle, int? year, required seasonNumber, required episodeNumber, required String mediaType}) async {
    return _onlineApi.getVideoSteams(title: title,
        originalTitle: originalTitle,
        year: year,
        seasonNumber: seasonNumber,
        episodeNumber: episodeNumber,
        mediaType: mediaType);
  }
}
