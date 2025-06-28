import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../providers/download/download_provider.dart';
import '../../../widgets/common/dialogs/confirmation_dialog.dart';

class DownloadsAppBar extends StatelessWidget {
  final DownloadProvider downloadProvider;
  final bool isGridView;
  final VoidCallback onViewToggle;
  final VoidCallback onBackPressed;

  const DownloadsAppBar({
    super.key,
    required this.downloadProvider,
    required this.isGridView,
    required this.onViewToggle,
    required this.onBackPressed,
  });

  @override
  Widget build(BuildContext context) {
    final activeDownloads = downloadProvider.downloadInfoMap.keys.length;
    final downloadedFiles = downloadProvider.downloadedEpisodes.length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceBlue.withOpacity(0.8),
        border: Border(
          bottom: BorderSide(color: AppTheme.outlineVariant, width: 1),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onBackPressed,
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.surfaceBlue,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.outlineVariant, width: 1),
              ),
              child: Icon(
                Icons.arrow_back_rounded,
                color: AppTheme.highEmphasisText,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Downloads',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppTheme.highEmphasisText,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (activeDownloads > 0 || downloadedFiles > 0)
                  Text(
                    '$downloadedFiles files${activeDownloads > 0 ? ' • $activeDownloads downloading' : ''}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color:
                          activeDownloads > 0
                              ? AppTheme.accentBlue
                              : AppTheme.mediumEmphasisText,
                    ),
                  ),
              ],
            ),
          ),
          if (downloadedFiles > 0 || activeDownloads > 0) ...[
            IconButton(
              onPressed: onViewToggle,
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceBlue,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.outlineVariant, width: 1),
                ),
                child: Icon(
                  isGridView ? Icons.view_list : Icons.grid_view,
                  color: AppTheme.highEmphasisText,
                  size: 20,
                ),
              ),
            ),
            if (downloadedFiles > 0)
              IconButton(
                onPressed: () => _showDeleteAllDialog(context),
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.errorColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.errorColor.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    Icons.delete_sweep,
                    color: AppTheme.errorColor,
                    size: 20,
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  void _showDeleteAllDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => ConfirmationDialog(
            title: 'Delete All Downloads',
            message:
                'Are you sure you want to delete all downloaded files? This action cannot be undone.',
            confirmText: 'Delete All',
            cancelText: 'Cancel',
            isDestructive: true,
            icon: Icons.delete_sweep,
            onConfirm: () => downloadProvider.deleteAllDownloads(),
          ),
    );
  }
}
