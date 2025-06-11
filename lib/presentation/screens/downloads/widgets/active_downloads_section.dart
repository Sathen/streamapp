import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../providers/download/download_provider.dart';

class ActiveDownloadsSection extends StatelessWidget {
  final DownloadProvider downloadProvider;
  final List<String> activeDownloads;

  const ActiveDownloadsSection({
    super.key,
    required this.downloadProvider,
    required this.activeDownloads,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryBlue.withOpacity(0.1),
            AppTheme.accentBlue.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.primaryBlue.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.download,
                    color: AppTheme.primaryBlue,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Active Downloads (${activeDownloads.length})',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.primaryBlue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          ...activeDownloads.map(
            (episodeKey) => _buildDownloadItem(context, episodeKey),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildDownloadItem(BuildContext context, String episodeKey) {
    final downloadInfo = downloadProvider.getDownloadInfo(episodeKey);
    final fileName = episodeKey.replaceAll('_', ' ');

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceBlue,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.outlineVariant.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Progress indicator
          SizedBox(
            width: 40,
            height: 40,
            child: Stack(
              children: [
                CircularProgressIndicator(
                  value: downloadInfo.progress,
                  strokeWidth: 3,
                  backgroundColor: AppTheme.outlineVariant,
                  color: AppTheme.primaryBlue,
                ),
                Center(
                  child: Text(
                    '${(downloadInfo.progress * 100).toInt()}%',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryBlue,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),

          // File info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fileName,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      downloadInfo.formattedSpeed,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.primaryBlue,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (downloadInfo.totalSize != null) ...[
                      Text(
                        ' • ${downloadInfo.totalSize}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.mediumEmphasisText,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // Cancel button
          IconButton(
            onPressed: () => downloadProvider.cancelDownload(episodeKey),
            icon: Icon(Icons.close, color: AppTheme.errorColor, size: 20),
            style: IconButton.styleFrom(
              backgroundColor: AppTheme.errorColor.withOpacity(0.1),
              minimumSize: const Size(32, 32),
            ),
          ),
        ],
      ),
    );
  }
}
