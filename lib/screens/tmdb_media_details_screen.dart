// lib/screens/media_details_screen.dart
import 'package:flutter/material.dart';
import 'package:stream_flutter/screens/production_cast_section.dart';
import 'package:stream_flutter/screens/medi_list/tmdb_media_seasons_list.dart';
import 'package:stream_flutter/services/media_service.dart';
import 'package:stream_flutter/providers/download_manager.dart';

import '../models/tmdb_models.dart';
import '../util/errors.dart';
import 'base_media_screen.dart';
import 'media_back_drop_appbar.dart';
import 'media_header_section.dart';
import 'movie_play_button.dart';

class MediaDetailsScreen extends BaseMediaDetailScreen {
  final int tmdbId;
  final MediaType type;

  const MediaDetailsScreen({
    super.key,
    required this.tmdbId,
    required this.type,
  });

  @override
  State<MediaDetailsScreen> createState() => _MediaDetailsScreenState();
}

class _MediaDetailsScreenState
    extends BaseMediaDetailScreenState<MediaDetailsScreen> {
  final tmdbService = MediaService(null, null, null);
  TmdbMediaDetails? _mediaData;
  List<TVSeasonDetails>? _seasonDetails;
  TVEpisode? _loadingTappedEpisode;

  @override
  Future<void> loadData() async {
    setLoadingState(true);

    try {
      _mediaData = null;
      _seasonDetails = null;

      if (widget.type == MediaType.movie) {
        _mediaData = await tmdbService.fetchMovieDetails(widget.tmdbId);
      } else if (widget.type == MediaType.tv) {
        final tvSpecificDetails = await tmdbService.fetchTVDetails(
          widget.tmdbId,
        );
        _mediaData = tvSpecificDetails;
        _seasonDetails = await Future.wait(
          tvSpecificDetails.seasons.map(
            (s) =>
                tmdbService.fetchTVSeasonDetails(widget.tmdbId, s.seasonNumber),
          ),
        );
      }

      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage = null;
      });
    } catch (e) {
      handleError(e, 'Failed to load media details. Please try again.');
    }
  }


  @override
  Null buildAppBar() {
    return null;//
  }

  @override
  Widget buildContent() {
    if (_mediaData == null) {
      return const Center(child: Text('No media details found.'));
    }

    final theme = Theme.of(context);
    final backdropPath = _mediaData?.backdropPath;
    final title = _mediaData?.title ?? 'Details';

    return CustomScrollView(
      slivers: <Widget>[
        MediaBackdropAppBar(title: title, backdropPath: backdropPath),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: MediaHeaderSection(media: _mediaData!),
          ),
        ),

        // Movie play button
        if (widget.type == MediaType.movie)
          SliverToBoxAdapter(
            child: MoviePlayButton(
              episodeKey: generateMovieKey(widget.tmdbId.toString()),
              theme: theme,
              isFetchingStreams: isFetchingStreams,
              onPlayPressed: () => _handleMoviePlay(),
            ),
          ),

        // TV seasons list
        if (widget.type == MediaType.tv && _seasonDetails != null)
          SliverToBoxAdapter(
            child: TVSeasonsList(
              seasonDetails: _seasonDetails!,
              tmdbId: widget.tmdbId,
              loadingEpisode: _loadingTappedEpisode,
              mediaData: _mediaData,
              onEpisodeTap: _handleTVEpisodeTap,
            ),
          ),

        // Production companies section
        if (_mediaData?.productionCompanies != null &&
            _mediaData!.productionCompanies.isNotEmpty)
          SliverToBoxAdapter(
            child: ProductionCastSection(
              theme: theme,
              companies: _mediaData!.productionCompanies,
            ),
          ),

        const SliverToBoxAdapter(
          child: SizedBox(height: 20), // Bottom padding
        ),
      ],
    );
  }

  Future<void> _handleMoviePlay() async {
    if (_mediaData == null) return;

    await showStreamSelectorFromApi(
      context: context,
      title: _mediaData!.title,
      originalTitle: _mediaData!.originalTitle,
      movieDetails: _mediaData as MovieDetails,
      contentTitle: _mediaData!.title,
      episodeKey: generateMovieKey(widget.tmdbId.toString()),
      fileName: 'Movie_${widget.tmdbId}',
    );
  }

  Future<void> _handleTVEpisodeTap(
    TVSeasonDetails season,
    TVEpisode episode,
    String? seriesTitle,
    String? seriesOriginalTitle,
  ) async {
    if (_mediaData == null) return;

    setState(() {
      _loadingTappedEpisode = episode;
    });
    try {
      await showStreamSelectorFromApi(
        context: context,
        title: seriesTitle!,
        originalTitle: seriesOriginalTitle,
        season: season,
        episode: episode,
        contentTitle: seriesTitle,
        episodeKey: generateEpisodeKey(
          _mediaData!.id.toString(),
          season.seasonNumber.toString(),
          episode.episodeNumber.toString(),
        ),
        fileName:
            '${seriesTitle.replaceAll(" ", "_")}_S${season.seasonNumber}E${episode.episodeNumber}',
      );
    } catch (e) {
      showErrorSnackbar(context, 'Error fetching streams: $e');
    } finally {
      if (mounted) {
        setState(() {
          _loadingTappedEpisode = null;
        });
      }
    }
  }
}
