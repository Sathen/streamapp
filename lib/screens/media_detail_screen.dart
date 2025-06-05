import 'dart:convert';

import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:stream_flutter/client/jellyfin_serials_api.dart';
import 'package:stream_flutter/models/series_models.dart';
import 'package:stream_flutter/screens/widgets/cast_sections.dart';
import 'package:stream_flutter/screens/widgets/episodes.dart';
import 'package:stream_flutter/screens/widgets/header.dart';
import 'package:stream_flutter/screens/widgets/quality_section.dart';
import 'package:stream_flutter/screens/widgets/title_section.dart';

import '../models/media_detail.dart';
import '../providers/auth_provider.dart';
import 'video_player_screen.dart';

class JellyfinMediaDetailScreen extends StatefulWidget {
  final String mediaId;

  const JellyfinMediaDetailScreen({
    super.key,
    required this.mediaId,
  });

  @override
  State<JellyfinMediaDetailScreen> createState() => _JellyfinMediaDetailScreenState();
}

class _JellyfinMediaDetailScreenState extends State<JellyfinMediaDetailScreen> {
  MediaDetail? _mediaDetail;
  SeriesInfo? _seriesInfo;
  bool _isLoading = true;
  int _selectedSeasonIndex = 0;
  int _selectedBitrate = 0;
  final List<int> _bitrates = [];

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

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      actions: [
        IconButton(
          icon: Icon(
            _mediaDetail?.isFavorite ?? false
                ? Icons.favorite
                : Icons.favorite_border,
            color: Theme.of(context).colorScheme.secondary,
          ),
          onPressed:
              () => {
                //TODO: not implemented
              },
        ),
      ],
    );
  }

  Widget _buildBody() {
    if (_mediaDetail == null) return const SizedBox.shrink();

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
                TitleSection(mediaDetail: _mediaDetail!),
                const SizedBox(height: 16),
                _buildOverviewSection(),
                const SizedBox(height: 16),
                QualitySection(
                  selectedBitrate: _selectedBitrate,
                  mediaDetail: _mediaDetail!,
                  seriesInfo: _seriesInfo,
                  bitrates: _bitrates,
                  onBitrateChanged: (int value) {
                    _selectedBitrate = value;
                  },
                ),
                const SizedBox(height: 16),
                if (_mediaDetail?.mediaType == 'Series')
                  Episodes(
                    seriesInfo: _seriesInfo!,
                    selectedSeasonIndex: _selectedSeasonIndex,
                    onSeasonChanged: (value) => _selectedSeasonIndex = value,
                    onPlayEpisode: _playEpisode,
                  )
                else
                  _buildPlayButton(),
                const SizedBox(height: 16),
                _buildCastSection(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderStack() {
    return HeaderImage(
      backdropUrl: _mediaDetail?.backdropPath,
      fallbackPosterUrl: _mediaDetail?.posterPath,
    );
  }

  Widget _buildOverviewSection() {
    return Text(
      _mediaDetail?.overview ?? '',
      style: Theme.of(context).textTheme.bodyMedium,
    );
  }

  void _playEpisode(Episode episode) {
    _playMedia(episode.id);
  }

  Widget _buildPlayButton() {
    final duration = _mediaDetail?.duration;
    final durationText =
        duration != null ? '${duration ~/ 60}h ${duration % 60}m' : '';

    return ElevatedButton.icon(
      icon: const Icon(Icons.play_arrow),
      label: Text('Play $durationText'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 48),
      ),
      onPressed: () => _playMedia(_mediaDetail!.id),
    );
  }

  Widget _buildCastSection() {
    final cast = _mediaDetail?.cast ?? [];
    if (cast.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Cast & Crew', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        CastChipList(cast: cast),
      ],
    );
  }


  Future<void> _loadMediaDetail() async {
    try {
      var authProvider = Provider.of<AuthProvider>(context, listen: false);
      final mediaDetail = await _fetchMediaDetail(authProvider.serverUrl!, authProvider.authHeaders!);
      final seriesInfo =
      mediaDetail.mediaType == 'Series' ? await _fetchSeriesInfo(authProvider.serverUrl!, authProvider.authHeaders!) : null;
      if (!mounted) return;

      setState(() {
        _mediaDetail = mediaDetail;
        _seriesInfo = seriesInfo;
        _isLoading = false;
      });

    } catch (e) {
      if (mounted) _showErrorSnackBar(e.toString());
    }
  }

  Future<MediaDetail> _fetchMediaDetail(String serverUrl, Map<String, String> headers) async {
    final response = await http.get(
      Uri.parse('$serverUrl/Items/${widget.mediaId}'),
      headers: headers,
    );
    if (response.statusCode != 200) throw Exception('Failed to fetch media');
    return MediaDetail.fromJson(serverUrl, json.decode(response.body));
  }

  Future<SeriesInfo> _fetchSeriesInfo(String serverUrl, Map<String, String> headers) async {
    final service = JellyfinSeriesService(baseUrl: serverUrl, headers: headers);
    return service.getCompleteSeriesInfo(widget.mediaId);
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Error: $message')));
  }

  Future<void> _playMedia(String id) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final serverUrl = authProvider.serverUrl;
    final headers = authProvider.authHeaders;

    final response = await http.get(
      Uri.parse('$serverUrl/Items/$id/PlaybackInfo'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final mediaSourceId = data['MediaSources'][0]['Id'];

      // Get direct play URL
      final streamUrl =
          '$serverUrl/Videos/$id/stream'
          '?static=true'
          '&MediaSourceId=$mediaSourceId';

      if (!mounted) return;

      if (Theme.of(context).platform == TargetPlatform.android) {
        _showPlayOptions(streamUrl, headers!);
      } else {
        // Non-Android devices use internal player directly
        _openInternalPlayer(streamUrl, headers!);
      }
    }
  }

  void _showPlayOptions(String url, Map<String, String> headers) {
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
                _openInternalPlayer(url, headers);
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

  void _openInternalPlayer(String streamUrl, Map<String, String> headers) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => VideoPlayerScreen(streamUrl: streamUrl),
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
}
