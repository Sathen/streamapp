import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:stream_flutter/screens/video_player_screen.dart';
import 'package:stream_flutter/util/errors.dart';
import 'package:url_launcher/url_launcher.dart';

class DownloadsScreen extends StatefulWidget {
  const DownloadsScreen({super.key});

  @override
  State<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends State<DownloadsScreen> {
  List<FileSystemEntity> _downloadedFiles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDownloadedFiles();
  }

  Future<void> _loadDownloadedFiles() async {
    setState(() => _isLoading = true);
    try {
      final directory = await getApplicationDocumentsDirectory();
      final dir = Directory(directory.path);
      final files = await dir
          .list()
          .where((file) =>
      file.path.endsWith('.mp4') ||
          file.path.endsWith('.ts') ||
          file.path.endsWith('.m3u8'))
          .toList();

      // Sort by last modified date (newest first)
      files.sort((a, b) =>
          File(b.path).lastModifiedSync()
              .compareTo(File(a.path).lastModifiedSync()));

      setState(() {
        _downloadedFiles = files;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading downloads: $e')),
        );
      }
    }
  }

  Future<void> _deleteFile(FileSystemEntity file) async {
    try {
      await file.delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File deleted')),
        );
      }
      _loadDownloadedFiles(); // Refresh the list
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting file: $e')),
        );
      }
    }
  }

  void _showFileOptions(FileSystemEntity file) {
    showModalBottomSheet(
      context: context,
      builder: (context) =>
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.play_arrow),
                title: const Text('Play'),
                onTap: () {
                  Navigator.pop(context);
                  _playVideo(file.path);
                },
              ),
              ListTile(
                leading: const Icon(Icons.share),
                title: const Text('Share'),
                onTap: () {
                  Navigator.pop(context);
                  _shareFile(file.path);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text(
                    'Delete', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteConfirmation(file);
                },
              ),
            ],
          ),
    );
  }

  void _showDeleteConfirmation(FileSystemEntity file) {
    showDialog(
      context: context,
      builder: (context) =>
          AlertDialog(
            title: const Text('Delete File'),
            content: Text('Delete ${file.path
                .split('/')
                .last}?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _deleteFile(file);
                },
                child: const Text(
                    'Delete', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );
  }

  Future<void> _playVideo(String path) async {
    try {
      // Try playing internally first
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VideoPlayerScreen(streamUrl: path),
        ),
      );
    } catch (e) {
      debugPrint("Internal player failed: $e");

      // Fallback to external player
      final result = await OpenFile.open(path);

      if (result.type != ResultType.done) {
        showErrorSnackbar(context, 'Could not open file: ${result.message}');
      }
    }
  }

  Future<void> _shareFile(String path) async {
    // This will open the system share sheet
    // Note: For iOS, you might need to use the share_plus package
    final uri = Uri.file(path);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open file')),
        );
      }
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    var i = (log(bytes) / log(1024)).floor();
    return '${(bytes / pow(1024, i)).toStringAsFixed(1)} ${suffixes[i]}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Downloads'),
        actions: [
          if (_downloadedFiles.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              onPressed: () => _showDeleteConfirmationForAll(),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _downloadedFiles.isEmpty
          ? const Center(
        child: Text('No downloads yet'),
      )
          : ListView.builder(
        itemCount: _downloadedFiles.length,
        itemBuilder: (context, index) {
          final file = _downloadedFiles[index];
          final fileStat = FileStat.statSync(file.path);
          final fileSize = _formatFileSize(fileStat.size);
          final lastModified = fileStat.modified;

          return ListTile(
            leading: const Icon(Icons.video_library, size: 40),
            title: Text(
              file.path
                  .split('/')
                  .last,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              '$fileSize • ${lastModified.toString().split('.')[0]}',
            ),
            onTap: () => _playVideo(file.path),
            onLongPress: () => _showFileOptions(file),
            trailing: IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () => _showFileOptions(file),
            ),
          );
        },
      ),
    );
  }

  void _showDeleteConfirmationForAll() {
    showDialog(
      context: context,
      builder: (context) =>
          AlertDialog(
            title: const Text('Delete All Downloads'),
            content: const Text(
                'Are you sure you want to delete all downloads?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _deleteAllDownloads();
                },
                child: const Text(
                    'Delete All', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );
  }

  Future<void> _deleteAllDownloads() async {
    try {
      for (var file in _downloadedFiles) {
        await file.delete();
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All downloads deleted')),
        );
      }
      _loadDownloadedFiles(); // Refresh the list
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting files: $e')),
        );
      }
    }
  }
}