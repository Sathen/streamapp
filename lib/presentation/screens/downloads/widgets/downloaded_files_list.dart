import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';

import '../../../../core/theme/app_theme.dart';
import '../../video_player/video_player_screen.dart';
import '../../../../core/utils/errors.dart';
import '../../../providers/download/download_provider.dart';
import '../../../widgets/common/dialogs/confirmation_dialog.dart';

class DownloadedFilesList extends StatelessWidget {
  final DownloadProvider downloadProvider;
  final List<String> downloadedFiles;

  const DownloadedFilesList({
    super.key,
    required this.downloadProvider,
    required this.downloadedFiles,
  });

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final episodeKey = downloadedFiles[index];
          return _buildFileCard(context, episodeKey);
        }, childCount: downloadedFiles.length),
      ),
    );
  }

  Widget _buildFileCard(BuildContext context, String episodeKey) {
    final filePath = downloadProvider.getDownloadedFilePath(episodeKey);
    final fileName = episodeKey.replaceAll('_', ' ');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.surfaceBlue,
            AppTheme.surfaceVariant.withOpacity(0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.primaryBlue.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlue.withOpacity(0.1),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _playVideo(context, filePath!),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Thumbnail with play icon
                Container(
                  width: 80,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primaryBlue.withOpacity(0.2),
                        AppTheme.accentBlue.withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: Icon(
                          Icons.play_circle_filled,
                          color: AppTheme.primaryBlue,
                          size: 32,
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryBlue,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.download_done,
                            color: Colors.white,
                            size: 12,
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
                        ).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.highEmphasisText,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryBlue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.download_done,
                              size: 14,
                              color: AppTheme.primaryBlue,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Downloaded',
                              style: Theme.of(
                                context,
                              ).textTheme.labelSmall?.copyWith(
                                color: AppTheme.primaryBlue,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // More options button
                IconButton(
                  icon: Icon(
                    Icons.more_vert,
                    color: AppTheme.mediumEmphasisText,
                  ),
                  onPressed:
                      () => _showFileOptions(context, episodeKey, fileName),
                  style: IconButton.styleFrom(
                    backgroundColor: AppTheme.surfaceVariant.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _playVideo(BuildContext context, String filePath) async {
    try {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VideoPlayerScreen(streamUrl: filePath),
        ),
      );
    } catch (e) {
      final result = await OpenFile.open(filePath);
      if (result.type != ResultType.done) {
        showErrorSnackbar(context, 'Could not open file: ${result.message}');
      }
    }
  }

  void _showFileOptions(
    BuildContext context,
    String episodeKey,
    String fileName,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceBlue,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag handle
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),

                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.play_circle, color: AppTheme.primaryBlue),
                  ),
                  title: const Text('Play Video'),
                  subtitle: const Text('Open in video player'),
                  onTap: () {
                    Navigator.pop(context);
                    final filePath = downloadProvider.getDownloadedFilePath(
                      episodeKey,
                    );
                    if (filePath != null) _playVideo(context, filePath);
                  },
                ),

                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.errorColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.delete, color: AppTheme.errorColor),
                  ),
                  title: Text(
                    'Delete File',
                    style: TextStyle(color: AppTheme.errorColor),
                  ),
                  subtitle: const Text('Remove from device'),
                  onTap: () {
                    Navigator.pop(context);
                    _showDeleteConfirmation(context, episodeKey, fileName);
                  },
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
    );
  }

  void _showDeleteConfirmation(
    BuildContext context,
    String episodeKey,
    String fileName,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => ConfirmationDialog(
            title: 'Delete File',
            message:
                'Are you sure you want to delete "$fileName"?\n\nThis action cannot be undone.',
            confirmText: 'Delete',
            cancelText: 'Cancel',
            isDestructive: true,
            icon: Icons.delete,
            onConfirm: () async {
              final success = await downloadProvider.deleteDownloadedEpisode(
                episodeKey,
              );
              if (context.mounted) {
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('File deleted successfully'),
                      backgroundColor: AppTheme.primaryBlue,
                    ),
                  );
                } else {
                  showErrorSnackbar(context, 'Failed to delete file');
                }
              }
            },
          ),
    );
  }
}
