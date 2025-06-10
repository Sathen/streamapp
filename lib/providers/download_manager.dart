import 'dart:developer' as developer;
import 'dart:io';
import 'dart:async'; // For Stopwatch
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DownloadInfo {
  double progress;
  int downloadedBytes;
  double speedBytesPerSecond;
  String? totalSize; // Formatted string like "100 MB"
  bool isCompleted;

  DownloadInfo({
    this.progress = 0.0,
    this.downloadedBytes = 0,
    this.speedBytesPerSecond = 0.0,
    this.totalSize,
    this.isCompleted = false,
  });

  String get formattedSpeed {
    if (speedBytesPerSecond <= 0) return '0 KB/s';
    if (speedBytesPerSecond < 1024) return '${speedBytesPerSecond.toStringAsFixed(1)} B/s';
    if (speedBytesPerSecond < 1024 * 1024) return '${(speedBytesPerSecond / 1024).toStringAsFixed(1)} KB/s';
    return '${(speedBytesPerSecond / (1024 * 1024)).toStringAsFixed(1)} MB/s';
  }
}

class DownloadManager extends ChangeNotifier {
  final Map<String, DownloadInfo> _downloadInfoMap = {}; // episodeKey -> DownloadInfo (active downloads)
  final Map<String, CancelToken> _cancelTokens = {}; // episodeKey -> cancel token
  final Map<String, Stopwatch> _stopwatches = {}; // episodeKey -> stopwatch for speed calculation
  final Map<String, int> _totalSegmentLengths = {}; // episodeKey -> sum of TS segment lengths in bytes

  // Track completed downloads
  final Set<String> _downloadedEpisodes = {}; // episodeKey set for completed downloads
  final Map<String, String> _downloadedFilePaths = {}; // episodeKey -> file path

  Map<String, DownloadInfo> get downloadInfoMap => Map.unmodifiable(_downloadInfoMap);
  Set<String> get downloadedEpisodes => Set.unmodifiable(_downloadedEpisodes);

  bool isDownloading(String episodeKey) => _downloadInfoMap.containsKey(episodeKey);
  bool isDownloaded(String episodeKey) => _downloadedEpisodes.contains(episodeKey);

  String? getDownloadedFilePath(String episodeKey) => _downloadedFilePaths[episodeKey];

  DownloadInfo getDownloadInfo(String episodeKey) {
    if (_downloadInfoMap.containsKey(episodeKey)) {
      return _downloadInfoMap[episodeKey]!;
    }
    // If not currently downloading but is downloaded, return completed info
    if (_downloadedEpisodes.contains(episodeKey)) {
      return DownloadInfo(progress: 1.0, isCompleted: true);
    }
    return DownloadInfo();
  }

  // Initialize and load saved download states
  Future<void> initialize() async {
    await _loadDownloadedEpisodes();
  }

  // Load downloaded episodes from SharedPreferences and verify files exist
  Future<void> _loadDownloadedEpisodes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final downloadedKeys = prefs.getStringList('downloaded_episodes') ?? [];

      for (String episodeKey in downloadedKeys) {
        final filePath = prefs.getString('file_path_$episodeKey');
        if (filePath != null && await File(filePath).exists()) {
          _downloadedEpisodes.add(episodeKey);
          _downloadedFilePaths[episodeKey] = filePath;
        } else {
          // File doesn't exist, remove from preferences
          await _removeDownloadedEpisode(episodeKey);
        }
      }
      notifyListeners();
    } catch (e) {
      developer.log('Error loading downloaded episodes: $e');
    }
  }

  // Save downloaded episode to SharedPreferences
  Future<void> _saveDownloadedEpisode(String episodeKey, String filePath) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _downloadedEpisodes.add(episodeKey);
      _downloadedFilePaths[episodeKey] = filePath;

      await prefs.setStringList('downloaded_episodes', _downloadedEpisodes.toList());
      await prefs.setString('file_path_$episodeKey', filePath);
    } catch (e) {
      developer.log('Error saving downloaded episode: $e');
    }
  }

  Future<void> _removeDownloadedEpisode(String episodeKey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _downloadedEpisodes.remove(episodeKey);
      _downloadedFilePaths.remove(episodeKey);

      await prefs.setStringList('downloaded_episodes', _downloadedEpisodes.toList());
      await prefs.remove('file_path_$episodeKey');
    } catch (e) {
      developer.log('Error removing downloaded episode: $e');
    }
  }

  Future<void> downloadEpisode({
    required String episodeKey, // e.g. "movie_87234" or "tv_1253_s1e1"
    required String m3u8Url,
    required String fileName,
  }) async {
    if (_downloadInfoMap.containsKey(episodeKey)) return; // already downloading
    if (_downloadedEpisodes.contains(episodeKey)) return; // already downloaded

    fileName = _sanitizeFileName(fileName);
    developer.log("Start download with episode key: $episodeKey and fileName: $fileName ");

    final cancelToken = CancelToken();
    _cancelTokens[episodeKey] = cancelToken;

    // Initialize download info and stopwatch
    _downloadInfoMap[episodeKey] = DownloadInfo(progress: 0.0, downloadedBytes: 0, speedBytesPerSecond: 0.0);
    _stopwatches[episodeKey] = Stopwatch()..start();
    _totalSegmentLengths[episodeKey] = 0; // Reset for this download
    notifyListeners();

    String? finalFilePath;

    try {
      final response = await Dio().get(m3u8Url);
      final lines = response.data.toString().split('\n');
      final tsUrls = lines
          .where((line) => line.trim().isNotEmpty && !line.startsWith('#'))
          .map((line) => Uri.parse(m3u8Url).resolve(line).toString())
          .toList();

      final dir = await getApplicationDocumentsDirectory();
      final outputFile = File('${dir.path}/$fileName.ts');
      finalFilePath = outputFile.path;

      if (await outputFile.exists()) await outputFile.delete();
      final sink = outputFile.openWrite();

      int currentDownloadedBytes = 0;
      for (int i = 0; i < tsUrls.length; i++) {
        final url = tsUrls[i];
        try {
          final tsResp = await Dio().get(
            url,
            options: Options(responseType: ResponseType.bytes),
            cancelToken: cancelToken,
          );

          if (tsResp.data != null) {
            final List<int> segmentBytes = tsResp.data as List<int>;
            sink.add(segmentBytes);
            currentDownloadedBytes += segmentBytes.length;

            // Estimate total size by summing up segment lengths
            _totalSegmentLengths[episodeKey] = (_totalSegmentLengths[episodeKey] ?? 0) + segmentBytes.length;

            // Calculate progress, speed
            final elapsedSeconds = _stopwatches[episodeKey]!.elapsedMilliseconds / 1000;
            final speed = elapsedSeconds > 0 ? currentDownloadedBytes / elapsedSeconds : 0.0;
            final progress = (i + 1) / tsUrls.length;

            // Update DownloadInfo
            _downloadInfoMap[episodeKey] = DownloadInfo(
              progress: progress,
              downloadedBytes: currentDownloadedBytes,
              speedBytesPerSecond: speed,
              totalSize: _formatBytes(_totalSegmentLengths[episodeKey]!), // Format total size
            );
            notifyListeners();
          }
        } on DioException catch (e) {
          if (e.type == DioExceptionType.cancel) {
            developer.log('Download for $episodeKey cancelled at segment $i');
            break; // Exit loop if cancelled
          }
          debugPrint('Failed to download segment $i for $episodeKey: $e');
          // Decide whether to continue or break on segment failure
          continue; // Try next segment
        } catch (e) {
          debugPrint('Error downloading segment $i for $episodeKey: $e');
          continue;
        }
      }

      await sink.flush();
      await sink.close();

      // Check if download was not cancelled and file exists
      if (!cancelToken.isCancelled && await File(finalFilePath).exists()) {
        // Save as completed download
        await _saveDownloadedEpisode(episodeKey, finalFilePath);
        developer.log('Download completed for $episodeKey at $finalFilePath');
      }

    } catch (e) {
      if (e is DioException && e.type == DioExceptionType.cancel) {
        developer.log('Download for $episodeKey was cancelled.');
        // Delete partial file if it exists
        if (finalFilePath != null && await File(finalFilePath).exists()) {
          await File(finalFilePath).delete();
        }
      } else {
        debugPrint('Download failed for $episodeKey: $e');
      }
    } finally {
      _stopwatches[episodeKey]?.stop();
      _downloadInfoMap.remove(episodeKey); // Remove from active downloads
      _cancelTokens.remove(episodeKey);
      _stopwatches.remove(episodeKey);
      _totalSegmentLengths.remove(episodeKey);
      notifyListeners();
    }
  }

  void cancelDownload(String episodeKey) {
    _cancelTokens[episodeKey]?.cancel();
    // The finally block in downloadEpisode will handle removal from maps and notifyListeners
  }

  // Delete a downloaded episode
  Future<bool> deleteDownloadedEpisode(String episodeKey) async {
    try {
      final filePath = _downloadedFilePaths[episodeKey];
      if (filePath != null && await File(filePath).exists()) {
        await File(filePath).delete();
      }
      await _removeDownloadedEpisode(episodeKey);
      notifyListeners();
      return true;
    } catch (e) {
      developer.log('Error deleting downloaded episode $episodeKey: $e');
      return false;
    }
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    var i = (log(bytes) / log(1024)).floor();
    return '${(bytes / pow(1024, i)).toStringAsFixed(1)} ${suffixes[i]}';
  }
}

// Helper method to sanitize filename
String _sanitizeFileName(String fileName) {
  // Remove or replace invalid characters
  String sanitized = fileName
      .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_') // Replace invalid chars with underscore
      .replaceAll(RegExp(r'\s+'), '_') // Replace multiple spaces with single underscore
      .replaceAll(RegExp(r'_+'), '_') // Replace multiple underscores with single
      .trim();

  // Remove leading/trailing underscores
  sanitized = sanitized.replaceAll(RegExp(r'^_+|_+$'), '');

  // Ensure filename isn't empty and isn't too long
  if (sanitized.isEmpty) sanitized = 'download';
  if (sanitized.length > 200) sanitized = sanitized.substring(0, 200);

  return sanitized;
}

String generateEpisodeKey(
    String id, String seasonNumber, String episodeNumber
    ) =>
    'tv_${_sanitizeFileName(id)}_s$seasonNumber.e$episodeNumber';

String generateMovieKey(String tmdbId) => 'movie_$tmdbId';