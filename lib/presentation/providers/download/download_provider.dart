import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../base/base_provider.dart';

// Keep your existing DownloadInfo class
class DownloadInfo {
  double progress;
  int downloadedBytes;
  double speedBytesPerSecond;
  String? totalSize;
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
    if (speedBytesPerSecond < 1024)
      return '${speedBytesPerSecond.toStringAsFixed(1)} B/s';
    if (speedBytesPerSecond < 1024 * 1024)
      return '${(speedBytesPerSecond / 1024).toStringAsFixed(1)} KB/s';
    return '${(speedBytesPerSecond / (1024 * 1024)).toStringAsFixed(1)} MB/s';
  }
}

class DownloadProvider extends BaseProvider {
  final Map<String, DownloadInfo> _downloadInfoMap = {};
  final Map<String, CancelToken> _cancelTokens = {};
  final Map<String, Stopwatch> _stopwatches = {};
  final Map<String, int> _totalSegmentLengths = {};
  final Set<String> _downloadedEpisodes = {};
  final Map<String, String> _downloadedFilePaths = {};

  // Getters
  Map<String, DownloadInfo> get downloadInfoMap =>
      Map.unmodifiable(_downloadInfoMap);

  Set<String> get downloadedEpisodes => Set.unmodifiable(_downloadedEpisodes);

  bool isDownloading(String episodeKey) =>
      _downloadInfoMap.containsKey(episodeKey);

  bool isDownloaded(String episodeKey) =>
      _downloadedEpisodes.contains(episodeKey);

  String? getDownloadedFilePath(String episodeKey) =>
      _downloadedFilePaths[episodeKey];

  DownloadInfo getDownloadInfo(String episodeKey) {
    if (_downloadInfoMap.containsKey(episodeKey)) {
      return _downloadInfoMap[episodeKey]!;
    }
    if (_downloadedEpisodes.contains(episodeKey)) {
      return DownloadInfo(progress: 1.0, isCompleted: true);
    }
    return DownloadInfo();
  }

  Future<void> initialize() async {
    try {
      setLoading(true);
      await _loadDownloadedEpisodes();
    } catch (e) {
      setError('Failed to initialize downloads: ${e.toString()}');
    } finally {
      setLoading(false);
    }
  }

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
          await _removeDownloadedEpisode(episodeKey);
        }
      }
      safeNotifyListeners();
    } catch (e) {
      developer.log('Error loading downloaded episodes: $e');
    }
  }

  Future<void> downloadEpisode({
    required String episodeKey,
    required String m3u8Url,
    required String fileName,
  }) async {
    if (_downloadInfoMap.containsKey(episodeKey)) return;
    if (_downloadedEpisodes.contains(episodeKey)) return;

    fileName = _sanitizeFileName(fileName);
    developer.log(
      "Start download with episode key: $episodeKey and fileName: $fileName",
    );

    final cancelToken = CancelToken();
    _cancelTokens[episodeKey] = cancelToken;

    _downloadInfoMap[episodeKey] = DownloadInfo(
      progress: 0.0,
      downloadedBytes: 0,
      speedBytesPerSecond: 0.0,
    );
    _stopwatches[episodeKey] = Stopwatch()..start();
    _totalSegmentLengths[episodeKey] = 0;
    safeNotifyListeners();

    String? finalFilePath;

    try {
      final response = await Dio().get(m3u8Url);
      final lines = response.data.toString().split('\n');
      final tsUrls =
          lines
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

            _totalSegmentLengths[episodeKey] =
                (_totalSegmentLengths[episodeKey] ?? 0) + segmentBytes.length;

            final elapsedSeconds =
                _stopwatches[episodeKey]!.elapsedMilliseconds / 1000;
            final speed =
                elapsedSeconds > 0
                    ? currentDownloadedBytes / elapsedSeconds
                    : 0.0;
            final progress = (i + 1) / tsUrls.length;

            _downloadInfoMap[episodeKey] = DownloadInfo(
              progress: progress,
              downloadedBytes: currentDownloadedBytes,
              speedBytesPerSecond: speed,
              totalSize: _formatBytes(_totalSegmentLengths[episodeKey]!),
            );
            safeNotifyListeners();
          }
        } on DioException catch (e) {
          if (e.type == DioExceptionType.cancel) {
            developer.log('Download for $episodeKey cancelled at segment $i');
            break;
          }
          debugPrint('Failed to download segment $i for $episodeKey: $e');
          continue;
        } catch (e) {
          debugPrint('Error downloading segment $i for $episodeKey: $e');
          continue;
        }
      }

      await sink.flush();
      await sink.close();

      if (!cancelToken.isCancelled && await File(finalFilePath).exists()) {
        await _saveDownloadedEpisode(episodeKey, finalFilePath);
        developer.log('Download completed for $episodeKey at $finalFilePath');
      }
    } catch (e) {
      if (e is DioException && e.type == DioExceptionType.cancel) {
        developer.log('Download for $episodeKey was cancelled.');
        if (finalFilePath != null && await File(finalFilePath).exists()) {
          await File(finalFilePath).delete();
        }
      } else {
        setError('Download failed for $episodeKey: $e');
      }
    } finally {
      _stopwatches[episodeKey]?.stop();
      _downloadInfoMap.remove(episodeKey);
      _cancelTokens.remove(episodeKey);
      _stopwatches.remove(episodeKey);
      _totalSegmentLengths.remove(episodeKey);
      safeNotifyListeners();
    }
  }

  void cancelDownload(String episodeKey) {
    _cancelTokens[episodeKey]?.cancel();
  }

  Future<bool> deleteDownloadedEpisode(String episodeKey) async {
    try {
      final filePath = _downloadedFilePaths[episodeKey];
      if (filePath != null && await File(filePath).exists()) {
        await File(filePath).delete();
      }
      await _removeDownloadedEpisode(episodeKey);
      safeNotifyListeners();
      return true;
    } catch (e) {
      setError('Error deleting downloaded episode $episodeKey: $e');
      return false;
    }
  }

  Future<void> _saveDownloadedEpisode(
    String episodeKey,
    String filePath,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _downloadedEpisodes.add(episodeKey);
      _downloadedFilePaths[episodeKey] = filePath;

      await prefs.setStringList(
        'downloaded_episodes',
        _downloadedEpisodes.toList(),
      );
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

      await prefs.setStringList(
        'downloaded_episodes',
        _downloadedEpisodes.toList(),
      );
      await prefs.remove('file_path_$episodeKey');
    } catch (e) {
      developer.log('Error removing downloaded episode: $e');
    }
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    var i = (log(bytes) / log(1024)).floor();
    return '${(bytes / pow(1024, i)).toStringAsFixed(1)} ${suffixes[i]}';
  }
}

// Helper functions (keep your existing ones)
String _sanitizeFileName(String fileName) {
  String sanitized =
      fileName
          .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')
          .replaceAll(RegExp(r'\s+'), '_')
          .replaceAll(RegExp(r'_+'), '_')
          .trim();

  sanitized = sanitized.replaceAll(RegExp(r'^_+|_+$'), '');

  if (sanitized.isEmpty) sanitized = 'download';
  if (sanitized.length > 200) sanitized = sanitized.substring(0, 200);

  return sanitized;
}

String generateEpisodeKey(
  String id,
  String seasonNumber,
  String episodeNumber,
) => 'tv_${_sanitizeFileName(id)}_s$seasonNumber.e$episodeNumber';

String generateMovieKey(String tmdbId) => 'movie_$tmdbId';
