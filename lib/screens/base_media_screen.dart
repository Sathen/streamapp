// lib/screens/base_media_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:stream_flutter/screens/play_options_dialog.dart';
import 'package:stream_flutter/screens/stream_selector_modal.dart';
import 'package:stream_flutter/util/errors.dart';

import '../data/datasources/remote/client/online_server_api.dart';
import '../data/models/models/tmdb_models.dart';
import '../data/models/models/video_streams.dart';

// Abstract base class for media details
abstract class BaseMediaDetailScreen extends StatefulWidget {
  const BaseMediaDetailScreen({super.key});
}

abstract class BaseMediaDetailScreenState<T extends BaseMediaDetailScreen>
    extends State<T> {
  // Common properties
  bool isLoading = true;
  bool isFetchingStreams = false;
  String? errorMessage;
  final OnlineServerApi serverApi = OnlineServerApi();

  // Abstract methods that must be implemented by subclasses
  Future<void> loadData();

  Widget buildContent();

  PreferredSizeWidget? buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
    );
  }

  @override
  void initState() {
    super.initState();
    loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: buildAppBar(),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : errorMessage != null
              ? _buildErrorWidget()
              : buildContent(),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              errorMessage!,
              style: const TextStyle(color: Colors.red, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  errorMessage = null;
                });
                loadData();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  // Common method for showing stream selector with different data sources
  Future<void> showStreamSelectorFromStreams({
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

  // Common method for showing stream selector with embed URL
  Future<void> showStreamSelectorFromEmbedUrl({
    required BuildContext context,
    required String embedUrl,
    required String contentTitle,
    required String episodeKey,
    required String fileName,
    String? streamName,
  }) async {
    try {
      setState(() {
        isFetchingStreams = true;
      });

      final streams = await serverApi.getVideoStreamsByPath(embedUrl);

      if (!mounted) return;

      setState(() {
        isFetchingStreams = false;
      });

      await showStreamSelectorFromStreams(
        context: context,
        streams: streams,
        contentTitle: contentTitle,
        episodeKey: episodeKey,
        fileName: fileName,
        streamName: streamName,
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isFetchingStreams = false;
      });

      showErrorSnackbar(context, 'Failed to load streams. Please try again.');
      debugPrint('Error fetching video streams: $e');
    }
  }

  // Common method for showing stream selector with API parameters
  Future<void> showStreamSelectorFromApi({
    required BuildContext context,
    required String title,
    String? originalTitle,
    TVSeasonDetails? season,
    TVEpisode? episode,
    MovieDetails? movieDetails,
    required String contentTitle,
    required String episodeKey,
    required String fileName,
  }) async {
    try {
      setState(() {
        isFetchingStreams = true;
      });

      var year = movieDetails?.releaseDate != null ? DateTime.parse(movieDetails!.releaseDate).year : null;

      final streams = await serverApi.getVideoSteams(
        title: title,
        originalTitle: originalTitle,
        year: season?.airDate != null ? DateTime.parse(season!.airDate).year : year,
        seasonNumber: season?.seasonNumber,
        episodeNumber: episode?.episodeNumber,
        mediaType: season != null ? 'tv' : 'movie',
        totalEpisodes: season?.numberOfEpisodes
      );

      if (!mounted) return;

      setState(() {
        isFetchingStreams = false;
      });

      await showStreamSelectorFromStreams(
        context: context,
        streams: streams,
        contentTitle: contentTitle,
        episodeKey: episodeKey,
        fileName: fileName,
        streamName: originalTitle,
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isFetchingStreams = false;
      });

      showErrorSnackbar(context, 'Error fetching streams: $e');
      debugPrint('Error fetching video streams: $e');
    }
  }

  // Helper method to handle common error scenarios
  void handleError(dynamic error, String defaultMessage) {
    if (!mounted) return;

    setState(() {
      isLoading = false;
      errorMessage = defaultMessage;
    });

    debugPrint('Error: $error');
  }

  // Helper method to show loading state
  void setLoadingState(bool loading) {
    if (!mounted) return;

    setState(() {
      isLoading = loading;
    });
  }
}
