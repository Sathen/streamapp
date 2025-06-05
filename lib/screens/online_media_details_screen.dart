// lib/screens/online_media_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:stream_flutter/client/online_server_api.dart';
import 'package:stream_flutter/models/online_media_details_entity.dart';
import 'package:stream_flutter/models/video_streams.dart';
import 'package:stream_flutter/screens/play_options_dialog.dart';
import 'package:stream_flutter/screens/widgets/header.dart';

import '../providers/download_manager.dart';
import 'medi_list/online_media_seasons_list.dart';
import 'media_header_section.dart';

class OnlineMediaDetailScreen extends StatefulWidget {
  final String path;

  const OnlineMediaDetailScreen({super.key, required this.path});

  @override
  State<OnlineMediaDetailScreen> createState() =>
      _OnlineMediaDetailScreenState();
}

class _OnlineMediaDetailScreenState extends State<OnlineMediaDetailScreen> {
  bool _isLoading = true;
  OnlineMediaDetailsEntity? _mediaDetails;
  final OnlineServerApi serverApi = OnlineServerApi();
  OnlineMediaDetailsEpisode? _loadingEpisode;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadMediaDetail();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            _errorMessage!,
            style: const TextStyle(color: Colors.red, fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ),
      )
          : _mediaDetails == null
          ? const Center(child: Text('No media details found.'))
          : _buildBody(),
    );
  }

  Widget _buildBody() {
    final mediaDetails = _mediaDetails!;
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: _buildHeaderStack(mediaDetails),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(16.0),
          sliver: SliverToBoxAdapter(
            child: MediaHeaderSection(mediaDetail: mediaDetails),
          ),
        ),
        OnlineMediaSeasonsList(
          mediaDetails: mediaDetails,
          loadingEpisode: _loadingEpisode,
          onEpisodeTap: (season, episode, embedUrl, contentTitle) async {
            setState(() {
              _loadingEpisode = episode;
            });

            try {
              await showStreamSelectorFromModel(
                context,
                embedUrl!,
                    (url) => showPlayOptionsDialog(
                  context: context,
                  streamUrl: url,
                  streamName: '',
                  contentTitle: contentTitle ?? mediaDetails.title,
                  episodeKey: generateEpisodeKey(mediaDetails.title, season.seasonNumber.toString(), episode.episodeNumber.toString()),
                  fileName: '${mediaDetails.title.replaceAll(" ", "_")}_S${season.seasonNumber}.E${episode.episodeNumber}',
                ),
              );
            } catch (e) {
              debugPrint('Error showing stream selector: $e');
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Failed to load streams. Please try again.')),
                );
              }
            } finally {
              setState(() {
                _loadingEpisode = null;
              });
            }
          },
        ),
      ],
    );
  }

  Widget _buildHeaderStack(OnlineMediaDetailsEntity mediaDetails) {
    return HeaderImage(
      backdropUrl: mediaDetails.backdropPath,
      fallbackPosterUrl: mediaDetails.posterPath,
    );
  }

  Future<void> _loadMediaDetail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final mediaDetail = await serverApi.get(widget.path);
      if (!mounted) return;

      setState(() {
        _mediaDetails = mediaDetail;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load media details. Please try again.';
      });
      debugPrint('Error loading media detail: $e');
    }
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      actions: [
        IconButton(
          icon: Icon(
            Icons.favorite,
            color: Theme.of(context).colorScheme.secondary,
          ),
          onPressed: () {
            // TODO: Implement favorite toggle
          },
        ),
      ],
    );
  }

  Future<void> showStreamSelectorFromModel(
      BuildContext context,
      String path,
      void Function(String url) onQualitySelected,
      ) async {
    try {
      VideoStreams streams = await serverApi.getVideoStreams(path);

      if (!mounted) return;

      if (streams.streams.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No streams available for this episode.')),
          );
        }
        return;
      }

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (context) {
          String? selectedSource;
          VideoStream? selectedTranslator;

          return StatefulBuilder(
            builder: (context, setState) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (selectedSource == null) ...[
                      const SizedBox(height: 16),
                      const Text(
                        "📡 Оберіть джерело",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      ...streams.streams.keys.map((source) {
                        return ListTile(
                          title: Text(source),
                          onTap: () => setState(() => selectedSource = source),
                        );
                      }),
                    ],
                    if (selectedSource != null && selectedTranslator == null) ...[
                      const SizedBox(height: 16),
                      const Text(
                        "🗣 Перекладач",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      ...streams.streams[selectedSource]!.map((translator) {
                        return ListTile(
                          title: Text(translator.name),
                          onTap: () => setState(() => selectedTranslator = translator),
                        );
                      }),
                    ],
                    if (selectedTranslator != null) ...[
                      const SizedBox(height: 16),
                      const Text(
                        "🎞 Якість",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      ...selectedTranslator!.links.map((link) {
                        return ListTile(
                          title: Text(link.quality),
                          onTap: () {
                            Navigator.of(context).pop();
                            onQualitySelected(link.url);
                          },
                        );
                      }),
                    ],
                  ],
                ),
              );
            },
          );
        },
      );
    } catch (e) {
      debugPrint('Error fetching video streams: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to fetch video streams. Please try again.')),
        );
      }
    }
  }
}