// lib/screens/online_media_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:stream_flutter/models/online_media_details_entity.dart';
import 'package:stream_flutter/screens/movie_play_button.dart';
import 'package:stream_flutter/screens/widgets/header.dart';
import 'package:stream_flutter/providers/download_manager.dart';

import '../models/search_result.dart';
import '../util/errors.dart';
import 'base_media_screen.dart';
import 'medi_list/online_media_seasons_list.dart';
import 'media_header_section.dart';

class OnlineMediaDetailScreen extends BaseMediaDetailScreen {
  final SearchItem searchItem;

  const OnlineMediaDetailScreen({super.key, required this.searchItem});

  @override
  State<OnlineMediaDetailScreen> createState() =>
      _OnlineMediaDetailScreenState();
}

class _OnlineMediaDetailScreenState
    extends BaseMediaDetailScreenState<OnlineMediaDetailScreen> {

  OnlineMediaDetailsEntity? _mediaDetails;
  OnlineMediaDetailsEpisode? _loadingEpisode;

  @override
  Future<void> loadData() async {
    setLoadingState(true);

    try {
      final mediaDetail = await serverApi.get(widget.searchItem);

      if (!mounted) return;

      setState(() {
        _mediaDetails = mediaDetail;
        isLoading = false;
        errorMessage = null;
      });
    } catch (e) {
      handleError(e, 'Failed to load media details. Please try again.');
    }
  }

  @override
  Widget buildContent() {
    if (_mediaDetails == null) {
      return const Center(child: Text('No media details found.'));
    }

    final mediaDetails = _mediaDetails;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: HeaderImage(
            backdropUrl: mediaDetails?.backdropPath,
            fallbackPosterUrl: mediaDetails!.posterPath,
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(16.0),
          sliver: SliverToBoxAdapter(
            child: MediaHeaderSection(mediaDetail: mediaDetails),
          ),
        ),

        if (mediaDetails.seasons.isEmpty)
          SliverToBoxAdapter(
            child: MoviePlayButton(
              onPlayPressed: () => _handleMoviePlay(mediaDetails),
              episodeKey: generateMovieKey(mediaDetails.title),
              theme: Theme.of(context),
              isFetchingStreams: isFetchingStreams,
            ),
          ),

        if (mediaDetails.seasons.isNotEmpty)
          OnlineMediaSeasonsList(
            mediaDetails: mediaDetails,
            loadingEpisode: _loadingEpisode,
            onEpisodeTap: _handleEpisodeTap,
          ),
      ],
    );
  }

  Future<void> _handleMoviePlay(OnlineMediaDetailsEntity mediaDetails) async {
    if (mediaDetails.embedUrl == null) {
      showErrorSnackbar(context, 'No embed URL available for this movie.');
      return;
    }

    await showStreamSelectorFromEmbedUrl(
      context: context,
      embedUrl: mediaDetails.embedUrl!,
      contentTitle: mediaDetails.title,
      episodeKey: generateMovieKey(mediaDetails.title),
      fileName: mediaDetails.title.replaceAll(" ", "_"),
    );
  }

  Future<void> _handleEpisodeTap(
      season,
      OnlineMediaDetailsEpisode episode,
      String? embedUrl,
      String? contentTitle,
      ) async {
    if (_mediaDetails == null || embedUrl == null) return;

    setState(() {
      _loadingEpisode = episode;
    });

    try {
      await showStreamSelectorFromEmbedUrl(
        context: context,
        embedUrl: embedUrl,
        contentTitle: contentTitle ?? _mediaDetails!.title,
        episodeKey: generateEpisodeKey(
          _mediaDetails!.title,
          season.seasonNumber.toString(),
          episode.episodeNumber.toString(),
        ),
        fileName: '${_mediaDetails!.title.replaceAll(" ", "_")}_S${season.seasonNumber}.E${episode.episodeNumber}',
      );
    } catch (e) {
      debugPrint('Error showing stream selector: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to load streams. Please try again.'),
          ),
        );
      }
    } finally {
      setState(() {
        _loadingEpisode = null;
      });
    }
  }
}