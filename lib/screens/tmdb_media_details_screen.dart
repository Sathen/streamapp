import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stream_flutter/screens/play_options_dialog.dart';
import 'package:stream_flutter/screens/production_cast_section.dart';
import 'package:stream_flutter/screens/stream_selector_modal.dart';
import 'package:stream_flutter/screens/medi_list/tmdb_media_seasons_list.dart';
import 'package:stream_flutter/services/media_service.dart';

import '../client/online_server_api.dart';
import '../models/tmdb_models.dart';
import '../providers/download_manager.dart';
import '../util/errors.dart';
import 'media_back_drop_appbar.dart';
import 'media_header_section.dart';
import 'movie_play_button.dart';

class MediaDetailsScreen extends StatefulWidget {
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

class _MediaDetailsScreenState extends State<MediaDetailsScreen> {
  final tmdbService = MediaService(null, null, null);
  final onlineServerApi = OnlineServerApi();
  bool isLoading = true;
  bool _isFetchingStreams = false;
  TVEpisode? _loadingTappedEpisode;

  TmdbMediaDetails? _mediaData;
  List<TVSeasonDetails>? seasonDetails;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);
    _mediaData = null;
    seasonDetails = null;

    if (widget.type == MediaType.movie) {
      _mediaData = await tmdbService.fetchMovieDetails(widget.tmdbId);
    } else if (widget.type == MediaType.tv) {
      final tvSpecificDetails = await tmdbService.fetchTVDetails(widget.tmdbId);
      _mediaData = tvSpecificDetails;
      seasonDetails = await Future.wait(
        tvSpecificDetails.seasons.map(
          (s) =>
              tmdbService.fetchTVSeasonDetails(widget.tmdbId, s.seasonNumber),
        ),
      );
    }

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final backdropPath = _mediaData?.backdropPath;
    final title = _mediaData?.title ?? 'Details';

    return Scaffold(
      extendBodyBehindAppBar: true, // Allow body to extend behind AppBar
      body: CustomScrollView(
        slivers: <Widget>[
          MediaBackdropAppBar( // ✅ без обгортки!
            title: title,
            backdropPath: backdropPath,
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: MediaHeaderSection(media: _mediaData!),
            ),
          ),
          if (widget.type == MediaType.movie)
            SliverToBoxAdapter(
              child: MoviePlayButton(
                episodeKey: generateMovieKey(widget.tmdbId.toString()),
                theme: theme,
                isFetchingStreams: _isFetchingStreams,
                onPlayPressed: () {
                  if (_mediaData != null) {
                    _fetchAndShowStreamsForMovie(
                      _mediaData!.title,
                      _mediaData!.originalTitle,
                    );
                  }
                },
              ),
            ),
          if (widget.type == MediaType.tv && seasonDetails != null)
            SliverToBoxAdapter(
              child: TVSeasonsList(
                seasonDetails: seasonDetails!,
                tmdbId: widget.tmdbId,
                loadingEpisode: _loadingTappedEpisode,
                mediaData: _mediaData,
                onEpisodeTap: _fetchAndShowStreamsForTVEpisode,
              ),
            ),
          if (_mediaData?.productionCompanies != null &&
              _mediaData!.productionCompanies.isNotEmpty)
            SliverToBoxAdapter(
              child: ProductionCastSection(
                theme: theme,
                companies: _mediaData!.productionCompanies,
              ),
            ),
          SliverToBoxAdapter(child: SizedBox(height: 20)), // Bottom padding
        ],
      ),
    );
  }

  Future<void> _fetchAndShowStreamsForMovie(
    String title,
    String? originalTitle,
  ) async {
    if (_mediaData == null) return;
    setState(() {
      _isFetchingStreams = true;
    });
    try {
      final streams = await onlineServerApi.getVideoSteams(
        title,
        originalTitle, // Use original title if available
        0, // Season 0 for movies
        0, // Episode 0 for movies
      );
      if (!mounted) return;
      if (streams.streams.isNotEmpty) {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (context) {
            return StreamSelectorModal(
              itemTitle: title,
              streams: streams,
              onStreamSelected: (url, name) {
                showPlayOptionsDialog(
                  context: context,
                  streamUrl: url,
                  streamName: originalTitle!,
                  contentTitle: title,
                  episodeKey: generateMovieKey(widget.tmdbId.toString()),
                  fileName: 'Movie_${widget.tmdbId}',
                );
              },
            );
          },
        );
      } else {
        showErrorSnackbar(context, 'No streams found for this episode.');
      }
    } catch (e) {
      if (!mounted) return;
      showErrorSnackbar(context, 'Error fetching streams: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isFetchingStreams = false;
        });
      }
    }
  }

  Future<void> _fetchAndShowStreamsForTVEpisode(
    TVSeasonDetails season,
    TVEpisode episode,
    String? seriesTitle,
    String? seriesOriginalTitle,
  ) async {
    if (_mediaData == null) return;
    setState(() {
      _isFetchingStreams = true;
      _loadingTappedEpisode = episode;
    });
    try {
      final streams = await onlineServerApi.getVideoSteams(
        seriesTitle!,
        seriesOriginalTitle, // Use original series title
        season.seasonNumber,
        episode.episodeNumber,
      );
      if (!mounted) return;
      if (streams.streams.isNotEmpty) {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (context) {
            return StreamSelectorModal(
              itemTitle: seriesTitle,
              streams: streams,
              onStreamSelected: (url, name) {
                showPlayOptionsDialog(
                  context: context,
                  streamUrl: url,
                  streamName: name,
                  contentTitle: seriesTitle,
                  episodeKey:
                      generateEpisodeKey(_mediaData!.id.toString(), season.seasonNumber.toString(), episode.episodeNumber.toString()),
                  fileName:
                      '${seriesTitle.replaceAll(" ", "_")}_S${season.seasonNumber}E${episode.episodeNumber}',
                );
              },
            );
          },
        );
      } else {
        showErrorSnackbar(context, 'No streams found for this episode.');
      }
    } catch (e) {
      if (!mounted) return;
      showErrorSnackbar(context, 'Error fetching streams: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isFetchingStreams = false;
          _loadingTappedEpisode = null;
        });
      }
    }
  }
}
