import 'package:flutter/material.dart';
import 'package:stream_flutter/models/media_detail.dart';
import 'package:stream_flutter/models/series_models.dart';

class TechnicalInfoBottomSheet extends StatelessWidget {
  final MediaDetail mediaDetail;
  final SeriesInfo? seriesInfo;

  const TechnicalInfoBottomSheet({
    super.key,
    required this.mediaDetail,
    this.seriesInfo,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Technical Details', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
          if (mediaDetail.mediaType == 'Series' && seriesInfo != null) ...[
            Text('Seasons: ${seriesInfo!.seasons.length}'),
            Text('Episodes: ${seriesInfo!.totalEpisodeCount}'),
            LinearProgressIndicator(
              value: seriesInfo!.watchProgress,
              backgroundColor: Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
            ),
            const SizedBox(height: 4),
            Text('Watch Progress: ${(seriesInfo!.watchProgress * 100).toStringAsFixed(1)}%'),
          ] else ...[
            Text('Runtime: ${mediaDetail.duration ?? 0} minutes'),
          ],
          if (mediaDetail.videoQuality != null) Text('Video Quality: ${mediaDetail.videoQuality}'),
          if (mediaDetail.videoCodec != null) Text('Video Codec: ${mediaDetail.videoCodec}'),
          if (mediaDetail.audioCodec != null) Text('Audio Codec: ${mediaDetail.audioCodec}'),
          if (mediaDetail.container != null) Text('Container: ${mediaDetail.container}'),
          if (mediaDetail.bitrate != null) Text('Bitrate: ${mediaDetail.bitrate} bps'),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ),
        ],
      ),
    );
  }
}
