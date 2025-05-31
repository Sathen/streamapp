import 'dart:io';

import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:stream_flutter/client/online_server_api.dart';
import 'package:stream_flutter/models/video_streams.dart';
import 'package:stream_flutter/models/media_detail.dart';
import 'package:stream_flutter/models/online_media_details_entity.dart';
import 'package:stream_flutter/screens/widgets/actions.dart';
import 'package:stream_flutter/screens/widgets/header.dart';
import 'package:stream_flutter/screens/widgets/title_section.dart';
import 'package:url_launcher/url_launcher.dart';

import 'video_player_screen.dart';

class OnlineMediaDetailScreen extends StatefulWidget {
  final String path;

  const OnlineMediaDetailScreen({super.key, required this.path});

  @override
  State<OnlineMediaDetailScreen> createState() =>
      _OnlineMediaDetailScreenState();
}

class _OnlineMediaDetailScreenState extends State<OnlineMediaDetailScreen> {
  bool _isLoading = true;
  late OnlineMediaDetailsEntity _mediaDetails;
  OnlineServerApi serverApi = OnlineServerApi();
  int _selectedSeasonIndex = 0;

  int? _loadingEpisodeNumber;

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
      body:
      _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(),
    );
  }

  Widget _buildBody() {
    var mediaDetail = MediaDetail.fromOnline(_mediaDetails);
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeaderStack(),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TitleSection(mediaDetail: mediaDetail),
                const SizedBox(height: 16),
                ActionsSection(mediaDetail: mediaDetail),
                const SizedBox(height: 16),
                _buildOverviewSection(),
                const SizedBox(height: 16),
                const SizedBox(height: 16),
                _buildEpisodesList(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderStack() {
    return HeaderImage(
      backdropUrl: _mediaDetails.backdropPath,
      fallbackPosterUrl: _mediaDetails.posterPath,
    );
  }

  Widget _buildOverviewSection() {
    return Text(
      _mediaDetails.description,
      style: Theme
          .of(context)
          .textTheme
          .bodyMedium,
    );
  }

  Future<void> _loadMediaDetail() async {
    final mediaDetail = await serverApi.get(widget.path);
    if (!mounted) return;

    setState(() {
      _mediaDetails = mediaDetail;
      _isLoading = false;
    });
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      actions: [
        IconButton(
          icon: Icon(
            Icons.favorite,
            color: Theme
                .of(context)
                .colorScheme
                .secondary,
          ),
          onPressed:
              () =>
          {
            //TODO: not implemented
          },
        ),
      ],
    );
  }

  Future<void> showStreamSelectorFromModel(BuildContext context,
      String path,
      void Function(String url) onQualitySelected,) async {
    VideoStreams streams = await serverApi.getVideoStreams(path);

    if (!mounted) return;

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
                  // Step 1: Source
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

                  // Step 2: Translators
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
                        onTap:
                            () =>
                            setState(() => selectedTranslator = translator),
                      );
                    }),
                  ],


                  // Step 3: Quality
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
  }

  void _showPlayOptions(String url) {
    if (kIsWeb) {
      launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication, // works on mobile
        webOnlyWindowName: '_blank', // required for web
      );
    }

    if (!Platform.isAndroid) {
      _openInternalPlayer(url);
      return;
    }

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.play_circle_outline),
              title: const Text('Play with Internal Player'),
              onTap: () {
                Navigator.pop(context);
                _openInternalPlayer(url);
              },
            ),
            ListTile(
              leading: const Icon(Icons.open_in_new),
              title: const Text('Play with External Player'),
              onTap: () {
                Navigator.pop(context);
                _launchExternalPlayer(url);
              },
            ),
          ],
        );
      },
    );
  }

  void _openInternalPlayer(String streamUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VideoPlayerScreen(streamUrl: streamUrl),
      ),
    );
  }

  Future<void> _launchExternalPlayer(String url) async {
    final intent = AndroidIntent(
      action: 'action_view',
      data: Uri.encodeFull(url),
      type: 'video/*',
    );
    await intent.launch();
  }

  Widget _buildEpisodesList(BuildContext context) {
    if (_mediaDetails.seasons.isEmpty) {
      return ElevatedButton.icon(
        icon: const Icon(Icons.play_arrow),
        label: const Text('Дивитися фільм'),
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 48),
        ),
        onPressed:
        _loadingEpisodeNumber != null
            ? null
            : () async {
          setState(() {
            _loadingEpisodeNumber =
            -1; // Використовуємо -1 для позначення завантаження фільму
          });
          await showStreamSelectorFromModel(
            context,
            _mediaDetails.embedUrl ?? "",
            _showPlayOptions,
          );
          setState(() {
            _loadingEpisodeNumber = null;
          });
        },
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Селектор сезонів
        SizedBox(
          height: 48,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _mediaDetails.seasons.length,
            itemBuilder: (context, index) {
              final season = _mediaDetails.seasons[index];
              final isSelected = index == _selectedSeasonIndex;

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: ChoiceChip(
                  label: Text('Сезон ${season.seasonNumber}'),
                  selected: isSelected,
                  onSelected:
                  _loadingEpisodeNumber != null
                      ? null
                      : (_) {
                    setState(() => _selectedSeasonIndex = index);
                  },
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),

        // Епізоди для обраного сезону
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount:
          _mediaDetails.seasons[_selectedSeasonIndex].numberOfEpisodes,
          itemBuilder: (context, index) {
            final season = _mediaDetails.seasons[_selectedSeasonIndex];
            final episodeNumber = index + 1;
            final episodeTitle = "Епізод $episodeNumber";
            final embedUrl = season.embedEpisodesUrls[episodeNumber] ?? "";

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 6),
              child: ListTile(
                title: Text(episodeTitle),
                // Відображаємо індикатор завантаження, якщо цей епізод завантажується
                trailing:
                _loadingEpisodeNumber == episodeNumber
                    ? const SizedBox(
                  width: 24, // Розмір спінера
                  height: 24, // Розмір спінера
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : const Icon(Icons.play_arrow),
                onTap:
                _loadingEpisodeNumber !=
                    null // Вимикаємо натискання, якщо будь-який епізод завантажується
                    ? null
                    : () async {
                  // Встановлюємо номер епізоду, який завантажується, і оновлюємо UI
                  setState(() {
                    _loadingEpisodeNumber = episodeNumber;
                  });

                  // Викликаємо функцію для показу селектора стріму
                  await showStreamSelectorFromModel(
                    context,
                    embedUrl,
                    _showPlayOptions,
                  );

                  // Після закриття модального вікна або вибору, скидаємо стан завантаження
                  setState(() {
                    _loadingEpisodeNumber = null;
                  });
                },
              ),
            );
          },
        ),
      ],
    );
  }
}
