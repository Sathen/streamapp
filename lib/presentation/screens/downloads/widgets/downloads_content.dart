import 'package:flutter/material.dart';

import '../../../providers/download/download_provider.dart';
import '../../../widgets/common/misc/empty_state.dart';
import 'active_downloads_section.dart';
import 'downloaded_files_grid.dart';
import 'downloaded_files_list.dart';

class DownloadsContent extends StatelessWidget {
  final DownloadProvider downloadProvider;
  final bool isGridView;

  const DownloadsContent({
    super.key,
    required this.downloadProvider,
    required this.isGridView,
  });

  @override
  Widget build(BuildContext context) {
    if (downloadProvider.isLoading) {
      return _buildLoadingState();
    }

    final activeDownloads = downloadProvider.downloadInfoMap.keys.toList();
    final downloadedFiles = downloadProvider.downloadedEpisodes.toList();

    if (activeDownloads.isEmpty && downloadedFiles.isEmpty) {
      return EmptyState(
        icon: Icons.cloud_download_outlined,
        title: 'No Downloads Yet',
        message:
            'Your downloaded videos will appear here.\nStart downloading to enjoy offline viewing.',
      );
    }

    return RefreshIndicator(
      onRefresh: () => downloadProvider.loadDownloadedFiles(),
      child: CustomScrollView(
        slivers: [
          // Active Downloads Section
          if (activeDownloads.isNotEmpty)
            SliverToBoxAdapter(
              child: ActiveDownloadsSection(
                downloadProvider: downloadProvider,
                activeDownloads: activeDownloads,
              ),
            ),

          // Separator
          if (activeDownloads.isNotEmpty && downloadedFiles.isNotEmpty)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Divider(),
              ),
            ),

          // Downloaded Files Section
          if (downloadedFiles.isNotEmpty)
            isGridView
                ? DownloadedFilesGrid(
                  downloadProvider: downloadProvider,
                  downloadedFiles: downloadedFiles,
                )
                : DownloadedFilesList(
                  downloadProvider: downloadProvider,
                  downloadedFiles: downloadedFiles,
                ),

          // Bottom padding
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Loading downloads...'),
        ],
      ),
    );
  }
}
