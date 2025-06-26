import 'dart:convert';
import 'dart:developer';

import 'package:http/http.dart' as http;

import '../../../models/models/online_media_details_entity.dart';
import '../../../models/models/search_result.dart';
import '../../../models/models/video_streams.dart';

class OnlineServerApi {
  static const HOST =  'https://fetcher.domcinema.win';

  OnlineServerApi();

  Future<SearchResult> search(String name) async {
    try {
      final response = await http.get(
        Uri.parse("$HOST/online/search?name=$name"),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return SearchResult.fromJson(json.decode(response.body));
      } else {
        log("Error response: ${response.statusCode}");
        return SearchResult();
      }
    } catch (e) {
      log(e.toString());
      return SearchResult();
    }
  }

  Future<OnlineMediaDetailsEntity> get(SearchItem item) async {
    try {
      final response = await http.post(
        Uri.parse("$HOST/online/get"),
        body: item.toString(),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return OnlineMediaDetailsEntity.fromJson(json.decode(response.body));
      } else {
        log("Error response: ${response.statusCode}");
        return OnlineMediaDetailsEntity();
      }
    } catch (e) {
      log(e.toString());
      return OnlineMediaDetailsEntity();
    }
  }

  /// Updated method to use the new POST endpoint
  Future<VideoStreams> getVideoSteams({
    required String title,
    String? originalTitle,
    int? year,
    int? seasonNumber,
    int? episodeNumber,
    String mediaType = 'tv',
    int? totalEpisodes,
  }) async {
    try {
      // Prepare the request body
      final requestBody = {
        'title': title,
        'media_type': mediaType,
      };

      // Add optional fields only if they're not null
      if (originalTitle != null) {
        requestBody['original_title'] = originalTitle;
      }
      if (year != null) {
        requestBody['year'] = year.toString();
      }
      if (seasonNumber != null) {
        requestBody['season_number'] = seasonNumber.toString();
      }
      if (episodeNumber != null) {
        requestBody['episode_number'] = episodeNumber.toString();
      }
      if (totalEpisodes != null) {
        requestBody['total_episodes'] = totalEpisodes.toString();
      }

      final response = await http.post(
        Uri.parse("$HOST/online/film-streams"),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(requestBody),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return VideoStreams.fromJson(json.decode(response.body));
      } else {
        log("Error response: ${response.statusCode} - ${response.body}");
        return VideoStreams();
      }
    } catch (e) {
      log("Error getting video streams: ${e.toString()}");
      return VideoStreams();
    }
  }


  Future<VideoStreams> getVideoStreamsByPath(String path) async {
    try {
      final response = await http.get(
        Uri.parse("$HOST/online/videos?path=$path"),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return VideoStreams.fromJson(json.decode(response.body));
      } else {
        log("Error response: ${response.statusCode}");
        return VideoStreams();
      }
    } catch (e) {
      log(e.toString());
      return VideoStreams();
    }

  }

}
