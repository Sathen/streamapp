import 'dart:developer';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class DownloadManager extends ChangeNotifier {
  final Map<String, double> _progressMap = {}; // episodeKey -> progress
  final Map<String, CancelToken> _cancelTokens =
      {}; // episodeKey -> cancel token

  Map<String, double> get progressMap => Map.unmodifiable(_progressMap);

  bool isDownloading(String episodeKey) => _progressMap.containsKey(episodeKey);

  double getProgress(String episodeKey) => _progressMap[episodeKey] ?? 0.0;

  Future<void> downloadEpisode({
    required String episodeKey, // e.g. "movie_87234" or "tv_1253_s1e1"
    required String m3u8Url,
    required String fileName,
  }) async {
    if (_progressMap.containsKey(episodeKey)) return; // already downloading

    log("Start download with episode key: $episodeKey ");

    final cancelToken = CancelToken();
    _cancelTokens[episodeKey] = cancelToken;
    _progressMap[episodeKey] = 0;
    notifyListeners();

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
      if (await outputFile.exists()) await outputFile.delete();
      final sink = outputFile.openWrite();

      for (int i = 0; i < tsUrls.length; i++) {
        final url = tsUrls[i];
        final tsResp = await Dio().get(
          url,
          options: Options(responseType: ResponseType.bytes),
          cancelToken: cancelToken,
        );
        sink.add(tsResp.data);
        _progressMap[episodeKey] = (i + 1) / tsUrls.length;
        notifyListeners();
      }

      await sink.flush();
      await sink.close();
    } catch (e) {
      debugPrint('Download failed for \$episodeKey: \$e');
    } finally {
      _progressMap.remove(episodeKey);
      _cancelTokens.remove(episodeKey);
      notifyListeners();
    }
  }

  void cancelDownload(String episodeKey) {
    _cancelTokens[episodeKey]?.cancel();
    _progressMap.remove(episodeKey);
    _cancelTokens.remove(episodeKey);
    notifyListeners();
  }
}
