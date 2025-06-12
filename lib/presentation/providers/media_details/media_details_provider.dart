import 'package:flutter/material.dart';
import 'package:stream_flutter/data/models/models/generic_media_details.dart';

import '../../../data/datasources/remote/client/online_server_api.dart';
import '../../../data/datasources/remote/services/media_service.dart';
import '../../../data/models/models/online_media_details_entity.dart';
import '../../../data/models/models/search_result.dart';
import '../../../data/models/models/tmdb_models.dart';
import '../../../data/models/models/video_streams.dart';
import '../../../screens/play_options_dialog.dart';
import '../../../screens/stream_selector_modal.dart';
import '../../../util/errors.dart';
import '../base/base_provider.dart';
import '../download/download_provider.dart';

class MediaDetailsProvider extends BaseProvider {
  final MediaService _mediaService = MediaService(null, null, null);
  final OnlineServerApi _onlineApi = OnlineServerApi();

  TmdbMediaDetails? _mediaData;
  List<TVSeasonDetails>? _seasonDetails;

  // Online Data
  OnlineMediaDetailsEntity? _onlineMediaData;

  // Loading states
  GenericEpisode? _loadingEpisode;
  bool _isFetchingStreams = false;

  // Getters
  TmdbMediaDetails? get mediaData => _mediaData;

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

  String? getTmdbId(bool isOnline) {
    if (isOnline && onlineMediaData != null) {
      // For online media, parse the tmdbId string to int
      return onlineMediaData?.tmdbId;
    } else if (!isOnline && mediaData != null) {
      // For TMDB media, use the tmdbId getter
      return mediaData?.tmdbId;
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

  // Handle episode tap with stream selection
  Future<void> handleEpisodeTap({
    required BuildContext context,
    required dynamic season,
    required dynamic episode,
    required int tmdbId,
    String? embedUrl,
    String? contentTitle,
  }) async {
    // Set episode as loading
    setEpisodeLoading(episode);

    try {
      // Get series title from provider or contentTitle
      final seriesTitle = _mediaData?.title ?? contentTitle ?? 'Unknown Series';
      final seriesOriginalTitle =
          _mediaData?.originalTitle ?? _mediaData?.title;

      // Generate episode key for caching/tracking
      final episodeKey = generateEpisodeKey(
        tmdbId.toString(),
        season.seasonNumber.toString(),
        episode.episodeNumber.toString(),
      );

      // Generate filename for downloads
      final fileName =
          '${seriesTitle.replaceAll(" ", "_")}_S${season.seasonNumber}E${episode.episodeNumber}';

      // Show stream selector using the provider's stream handling
      await _showStreamSelectorFromApi(
        context: context,
        title: seriesTitle,
        originalTitle: seriesOriginalTitle,
        season: season,
        episode: episode,
        contentTitle: seriesTitle,
        episodeKey: episodeKey,
        fileName: fileName,
      );
    } catch (e) {
      // Show error using your existing error handling
      if (context.mounted) {
        showErrorSnackbar(context, 'Error fetching streams: $e');
      }
      debugPrint('Error in episode tap: $e');
    } finally {
      // Clear loading state
      setEpisodeLoading(null);
    }
  }

  // Internal method for showing stream selector with API parameters
  Future<void> _showStreamSelectorFromApi({
    required BuildContext context,
    required String title,
    String? originalTitle,
    dynamic season,
    dynamic episode,
    MovieDetails? movieDetails,
    required String contentTitle,
    required String episodeKey,
    required String fileName,
  }) async {
    try {
      setFetchingStreams(true);

      var year =
          movieDetails?.releaseDate != null
              ? DateTime.parse(movieDetails!.releaseDate).year
              : null;

      final streams = await _onlineApi.getVideoSteams(
        title: title,
        originalTitle: originalTitle,
        year: year,
        seasonNumber: season?.seasonNumber,
        episodeNumber: episode?.episodeNumber,
        mediaType: season != null ? 'tv' : 'movie',
      );

      if (!context.mounted) return;

      setFetchingStreams(false);

      await _showStreamSelectorFromStreams(
        context: context,
        streams: streams,
        contentTitle: contentTitle,
        episodeKey: episodeKey,
        fileName: fileName,
      );
    } catch (e) {
      if (!context.mounted) return;

      setFetchingStreams(false);
      showErrorSnackbar(context, 'Failed to load streams. Please try again.');
      debugPrint('Error fetching video streams: $e');
    }
  }

  // Internal method for showing stream selector with streams data
  Future<void> _showStreamSelectorFromStreams({
    required BuildContext context,
    required VideoStreams streams,
    required String contentTitle,
    required String episodeKey,
    required String fileName,
    String? streamName,
  }) async {
    if (streams.data.isEmpty) {
      showErrorSnackbar(context, 'No streams available for this content.');
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StreamSelectorModal(
          itemTitle: contentTitle,
          streams: streams,
          onStreamSelected: (url, name) {
            showPlayOptionsDialog(
              context: context,
              streamUrl: url,
              streamName: streamName ?? name,
              contentTitle: contentTitle,
              episodeKey: episodeKey,
              fileName: fileName,
            );
          },
        );
      },
    );
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
