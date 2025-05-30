import 'package:flutter/material.dart';
import 'package:stream_flutter/models/media_detail.dart';
import 'package:stream_flutter/models/series_models.dart';
import 'package:stream_flutter/screens/widgets/technical_info.dart';

class QualitySection extends StatelessWidget {
  final int selectedBitrate;
  final MediaDetail mediaDetail;
  final SeriesInfo? seriesInfo;
  final List<int> bitrates;
  final ValueChanged<int> onBitrateChanged;

  const QualitySection({super.key, required this.selectedBitrate, required this.mediaDetail, this.seriesInfo, required this.bitrates, required this.onBitrateChanged});


  @override
  Widget build(BuildContext context) {
    return  Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        // Bitrate Button
        GestureDetector(
          onTap: () => _showBitrateSelection(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(
                color: Theme.of(context).colorScheme.secondary,
              ),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.high_quality,
                  color: Theme.of(context).colorScheme.secondary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Bitrate: ${selectedBitrate != 0 ? '${(selectedBitrate / 1000000).toStringAsFixed(1)} Mbps' : 'Auto'}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16), // Space between buttons
        // Technical Info Button
        GestureDetector(
          onTap: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              builder:
                  (BuildContext context) => TechnicalInfoBottomSheet(
                mediaDetail: mediaDetail,
                seriesInfo: seriesInfo,
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(
                color: Theme.of(context).colorScheme.secondary,
              ),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.info_outline,
                  color: Theme.of(context).colorScheme.secondary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Technical Info',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showBitrateSelection(BuildContext context) {
    final availableBitrates =
    bitrates.isNotEmpty
        ? bitrates
        : [500000, 1000000, 2000000];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select Bitrate',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              ...availableBitrates.map((bitrate) {
                return ListTile(
                  title: Text('${(bitrate / 1000000).toStringAsFixed(1)} Mbps'),
                  onTap: () {
                      onBitrateChanged(bitrate);
                    Navigator.pop(context);
                  },
                );
              }),
              ListTile(
                title: const Text('Auto (Max Quality)'),
                onTap: () {
                  onBitrateChanged(0);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

}