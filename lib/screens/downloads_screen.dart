import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:stream_flutter/screens/video_player_screen.dart';
import 'package:stream_flutter/util/errors.dart';
import 'package:url_launcher/url_launcher.dart';

import '../providers/download_manager.dart';

class _DownloadedFileInfo {
  final FileSystemEntity file;
  final FileStat stat;
  final String? episodeKey;

  _DownloadedFileInfo({
    required this.file,
    required this.stat,
    this.episodeKey,
  });
}

class DownloadsScreen extends StatefulWidget {
  const DownloadsScreen({super.key});

  @override
  State<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends State<DownloadsScreen> {
  List<_DownloadedFileInfo> _downloadedFiles = [];
  bool _isLoading = true;
  bool _isGridView = false;

  @override
  void initState() {
    super.initState();
    _loadDownloadedFiles();
  }

  Future<void> _loadDownloadedFiles() async {
    setState(() => _isLoading = true);

    try {
      final downloadManager = context.read<DownloadManager>();
      final directory = await getApplicationDocumentsDirectory();
      final dir = Directory(directory.path);

      final files = await dir
          .list()
          .where((file) =>
      file.path.endsWith('.mp4') ||
          file.path.endsWith('.ts') ||
          file.path.endsWith('.m3u8'))
          .toList();

      files.sort((a, b) =>
          File(b.path).lastModifiedSync().compareTo(File(a.path).lastModifiedSync()));

      final List<_DownloadedFileInfo> fileInfoList = [];

      for (final file in files) {
        final stat = file.statSync();
        String? matchingEpisodeKey;

        for (final episodeKey in downloadManager.downloadedEpisodes) {
          final filePath = downloadManager.getDownloadedFilePath(episodeKey);
          if (filePath == file.path) {
            matchingEpisodeKey = episodeKey;
            break;
          }
        }

        fileInfoList.add(_DownloadedFileInfo(
          file: file,
          stat: stat,
          episodeKey: matchingEpisodeKey,
        ));
      }

      setState(() {
        _downloadedFiles = fileInfoList;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        showErrorSnackbar(context, 'Error loading downloads: $e');
      }
    }
  }

  List<String> _getActiveDownloads(DownloadManager downloadManager) {
    return downloadManager.downloadInfoMap.keys.toList();
  }

  Future<void> _deleteFile(_DownloadedFileInfo fileInfo) async {
    try {
      final downloadManager = context.read<DownloadManager>();

      if (fileInfo.episodeKey != null) {
        await downloadManager.deleteDownloadedEpisode(fileInfo.episodeKey!);
      } else {
        await fileInfo.file.delete();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File deleted successfully')),
        );
      }
      _loadDownloadedFiles();
    } catch (e) {
      if (mounted) {
        showErrorSnackbar(context, 'Error deleting file: $e');
      }
    }
  }

  Future<void> _deleteAllFiles() async {
    try {
      final downloadManager = context.read<DownloadManager>();

      for (var fileInfo in _downloadedFiles) {
        if (fileInfo.episodeKey != null) {
          await downloadManager.deleteDownloadedEpisode(fileInfo.episodeKey!);
        } else {
          await fileInfo.file.delete();
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All downloads deleted successfully')),
        );
      }
      _loadDownloadedFiles();
    } catch (e) {
      if (mounted) {
        showErrorSnackbar(context, 'Error deleting files: $e');
      }
    }
  }

  Future<void> _playVideo(String path) async {
    try {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VideoPlayerScreen(streamUrl: path),
        ),
      );
    } catch (e) {
      final result = await OpenFile.open(path);
      if (result.type != ResultType.done) {
        showErrorSnackbar(context, 'Could not open file: ${result.message}');
      }
    }
  }

  Future<void> _shareFile(String path) async {
    final uri = Uri.file(path);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        showErrorSnackbar(context, 'Could not find an application to open the file.');
      }
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    var i = (log(bytes) / log(1024)).floor();
    return '${(bytes / pow(1024, i)).toStringAsFixed(1)} ${suffixes[i]}';
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final fileDate = DateTime(date.year, date.month, date.day);

    if (fileDate == today) {
      return 'Today';
    } else if (fileDate == yesterday) {
      return 'Yesterday';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DownloadManager>(
      builder: (context, downloadManager, child) {
        final activeDownloads = _getActiveDownloads(downloadManager);

        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Downloads'),
                if (activeDownloads.isNotEmpty)
                  Text(
                    '${activeDownloads.length} downloading',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
              ],
            ),
            actions: [
              if (_downloadedFiles.isNotEmpty || activeDownloads.isNotEmpty) ...[
                IconButton(
                  onPressed: () {
                    setState(() {
                      _isGridView = !_isGridView;
                    });
                  },
                  icon: Icon(_isGridView ? Icons.view_list : Icons.grid_view),
                ),
                if (_downloadedFiles.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.delete_sweep),
                    onPressed: _showDeleteAllConfirmation,
                  ),
              ],
            ],
          ),
          body: _buildBody(downloadManager),
        );
      },
    );
  }

  Widget _buildBody(DownloadManager downloadManager) {
    final activeDownloads = _getActiveDownloads(downloadManager);

    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_downloadedFiles.isEmpty && activeDownloads.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: [
        // Active downloads section
        if (activeDownloads.isNotEmpty) _buildActiveDownloadsSection(downloadManager, activeDownloads),

        // Downloaded files section
        if (_downloadedFiles.isNotEmpty) ...[
          if (activeDownloads.isNotEmpty)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width * 0.04),
              child: Divider(color: Theme.of(context).colorScheme.outline.withOpacity(0.3)),
            ),
          Expanded(
            child: _isGridView ? _buildGridView() : _buildListView(),
          ),
        ] else if (activeDownloads.isNotEmpty)
          const Expanded(child: SizedBox()),
      ],
    );
  }

  Widget _buildEmptyState() {
    final screenSize = MediaQuery.of(context).size;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(screenSize.width * 0.08),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_download_outlined,
              size: screenSize.width * 0.2,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
            SizedBox(height: screenSize.height * 0.02),
            Text(
              'No Downloads Yet',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: screenSize.width * 0.055,
              ),
            ),
            SizedBox(height: screenSize.height * 0.01),
            Text(
              'Your downloaded videos will appear here.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                fontSize: screenSize.width * 0.035,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveDownloadsSection(DownloadManager downloadManager, List<String> activeDownloads) {
    final screenSize = MediaQuery.of(context).size;

    return Container(
      margin: EdgeInsets.all(screenSize.width * 0.04),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(screenSize.width * 0.04),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(screenSize.width * 0.04),
            child: Row(
              children: [
                Icon(
                  Icons.download,
                  color: Theme.of(context).colorScheme.primary,
                  size: screenSize.width * 0.05,
                ),
                SizedBox(width: screenSize.width * 0.02),
                Text(
                  'Downloading (${activeDownloads.length})',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: screenSize.width * 0.04,
                  ),
                ),
              ],
            ),
          ),
          ...activeDownloads.map((episodeKey) => _buildDownloadingItem(downloadManager, episodeKey, screenSize)),
          SizedBox(height: screenSize.width * 0.02),
        ],
      ),
    );
  }

  Widget _buildDownloadingItem(DownloadManager downloadManager, String episodeKey, Size screenSize) {
    final downloadInfo = downloadManager.getDownloadInfo(episodeKey);
    final fileName = episodeKey.replaceAll('_', ' '); // Simple filename from episode key

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: screenSize.width * 0.04,
        vertical: screenSize.width * 0.01,
      ),
      padding: EdgeInsets.all(screenSize.width * 0.03),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(screenSize.width * 0.03),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Progress indicator
          SizedBox(
            width: screenSize.width * 0.1,
            height: screenSize.width * 0.1,
            child: Stack(
              children: [
                CircularProgressIndicator(
                  value: downloadInfo.progress,
                  strokeWidth: screenSize.width * 0.008,
                  backgroundColor: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                  color: Theme.of(context).colorScheme.primary,
                ),
                Center(
                  child: Text(
                    '${(downloadInfo.progress * 100).toInt()}%',
                    style: TextStyle(
                      fontSize: screenSize.width * 0.025,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: screenSize.width * 0.03),

          // File info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fileName,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: screenSize.width * 0.035,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: screenSize.height * 0.003),
                Row(
                  children: [
                    Text(
                      downloadInfo.formattedSpeed,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w500,
                        fontSize: screenSize.width * 0.03,
                      ),
                    ),
                    if (downloadInfo.totalSize != null) ...[
                      Text(
                        ' • ${downloadInfo.totalSize}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                          fontSize: screenSize.width * 0.03,
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
            onPressed: () {
              downloadManager.cancelDownload(episodeKey);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Download cancelled')),
              );
            },
            icon: Icon(
              Icons.close,
              color: Theme.of(context).colorScheme.error,
              size: screenSize.width * 0.05,
            ),
            style: IconButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error.withOpacity(0.1),
              minimumSize: Size(screenSize.width * 0.08, screenSize.width * 0.08),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListView() {
    final screenSize = MediaQuery.of(context).size;

    return ListView.builder(
      padding: EdgeInsets.all(screenSize.width * 0.04),
      itemCount: _downloadedFiles.length,
      itemBuilder: (context, index) {
        final fileInfo = _downloadedFiles[index];
        return _buildFileCard(fileInfo, screenSize);
      },
    );
  }

  Widget _buildGridView() {
    final screenSize = MediaQuery.of(context).size;
    final crossAxisCount = screenSize.width > 600 ? 3 : 2;
    final aspectRatio = screenSize.width > 600 ? 1.0 : 0.9;

    return GridView.builder(
      padding: EdgeInsets.all(screenSize.width * 0.04),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: aspectRatio,
        crossAxisSpacing: screenSize.width * 0.03,
        mainAxisSpacing: screenSize.width * 0.03,
      ),
      itemCount: _downloadedFiles.length,
      itemBuilder: (context, index) {
        final fileInfo = _downloadedFiles[index];
        return _buildGridCard(fileInfo, screenSize);
      },
    );
  }

  Widget _buildFileCard(_DownloadedFileInfo fileInfo, Size screenSize) {
    final fileName = fileInfo.file.path.split('/').last;
    final fileSize = _formatFileSize(fileInfo.stat.size);
    final lastModified = _formatDate(fileInfo.stat.modified);
    final isTrackedDownload = fileInfo.episodeKey != null;

    return Container(
      margin: EdgeInsets.only(bottom: screenSize.width * 0.03),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(screenSize.width * 0.04),
        border: Border.all(
          color: isTrackedDownload
              ? Theme.of(context).colorScheme.primary.withOpacity(0.3)
              : Theme.of(context).colorScheme.outline.withOpacity(0.2),
          width: isTrackedDownload ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _playVideo(fileInfo.file.path),
        borderRadius: BorderRadius.circular(screenSize.width * 0.04),
        child: Padding(
          padding: EdgeInsets.all(screenSize.width * 0.04),
          child: Row(
            children: [
              // Thumbnail
              Container(
                width: screenSize.width * 0.2,
                height: screenSize.width * 0.15,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(screenSize.width * 0.03),
                  color: isTrackedDownload
                      ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                      : Theme.of(context).colorScheme.surfaceVariant,
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Icon(
                        Icons.play_circle_filled,
                        color: isTrackedDownload
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                        size: screenSize.width * 0.08,
                      ),
                    ),
                    if (isTrackedDownload)
                      Positioned(
                        top: screenSize.width * 0.01,
                        right: screenSize.width * 0.01,
                        child: Container(
                          padding: EdgeInsets.all(screenSize.width * 0.01),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.download_done,
                            color: Colors.white,
                            size: screenSize.width * 0.03,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              SizedBox(width: screenSize.width * 0.04),

              // File info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fileName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: screenSize.width * 0.04,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: screenSize.height * 0.005),
                    Row(
                      children: [
                        Icon(
                          Icons.storage,
                          size: screenSize.width * 0.035,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                        SizedBox(width: screenSize.width * 0.01),
                        Text(
                          fileSize,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontSize: screenSize.width * 0.03,
                          ),
                        ),
                        SizedBox(width: screenSize.width * 0.03),
                        Icon(
                          Icons.schedule,
                          size: screenSize.width * 0.035,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                        SizedBox(width: screenSize.width * 0.01),
                        Flexible(
                          child: Text(
                            lastModified,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontSize: screenSize.width * 0.03,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (isTrackedDownload) ...[
                      SizedBox(height: screenSize.height * 0.005),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: screenSize.width * 0.02,
                          vertical: screenSize.height * 0.003,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(screenSize.width * 0.02),
                        ),
                        child: Text(
                          'Episode',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: screenSize.width * 0.025,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // More options button
              IconButton(
                icon: Icon(
                  Icons.more_vert,
                  size: screenSize.width * 0.05,
                ),
                onPressed: () => _showFileOptions(fileInfo),
                style: IconButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGridCard(_DownloadedFileInfo fileInfo, Size screenSize) {
    final fileName = fileInfo.file.path.split('/').last;
    final fileSize = _formatFileSize(fileInfo.stat.size);
    final isTrackedDownload = fileInfo.episodeKey != null;

    return Card(
      child: InkWell(
        onTap: () => _playVideo(fileInfo.file.path),
        borderRadius: BorderRadius.circular(screenSize.width * 0.03),
        child: Column(
          children: [
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: isTrackedDownload
                      ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                      : Theme.of(context).colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(screenSize.width * 0.03)),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Icon(
                        Icons.play_circle_filled,
                        size: screenSize.width * 0.12,
                        color: isTrackedDownload
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (isTrackedDownload)
                      Positioned(
                        top: screenSize.width * 0.02,
                        right: screenSize.width * 0.02,
                        child: Container(
                          padding: EdgeInsets.all(screenSize.width * 0.01),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.download_done,
                            color: Colors.white,
                            size: screenSize.width * 0.04,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: EdgeInsets.all(screenSize.width * 0.02),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        fileName,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: screenSize.width * 0.032,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(height: screenSize.height * 0.005),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            fileSize,
                            style: TextStyle(fontSize: screenSize.width * 0.028),
                          ),
                        ),
                        SizedBox(
                          width: screenSize.width * 0.06,
                          height: screenSize.width * 0.06,
                          child: IconButton(
                            icon: Icon(
                              Icons.more_vert,
                              size: screenSize.width * 0.035,
                            ),
                            onPressed: () => _showFileOptions(fileInfo),
                            padding: EdgeInsets.zero,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFileOptions(_DownloadedFileInfo fileInfo) {
    final screenSize = MediaQuery.of(context).size;

    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: screenSize.height * 0.02),
          ListTile(
            leading: const Icon(Icons.play_circle),
            title: const Text('Play Video'),
            onTap: () {
              Navigator.pop(context);
              _playVideo(fileInfo.file.path);
            },
          ),
          ListTile(
            leading: const Icon(Icons.share),
            title: const Text('Share File'),
            onTap: () {
              Navigator.pop(context);
              _shareFile(fileInfo.file.path);
            },
          ),
          ListTile(
            leading: Icon(Icons.delete, color: Theme.of(context).colorScheme.error),
            title: Text('Delete File', style: TextStyle(color: Theme.of(context).colorScheme.error)),
            onTap: () {
              Navigator.pop(context);
              _showDeleteConfirmation(fileInfo);
            },
          ),
          SizedBox(height: screenSize.height * 0.02),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(_DownloadedFileInfo fileInfo) {
    final fileName = fileInfo.file.path.split('/').last;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete File'),
        content: Text('Are you sure you want to delete "$fileName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteFile(fileInfo);
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAllConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete All Downloads'),
        content: Text('Are you sure you want to delete all ${_downloadedFiles.length} files?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteAllFiles();
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );
  }
}