import 'dart:convert';
import 'dart:developer';

import 'package:http/http.dart' as http;
import 'package:stream_flutter/models/video_streams.dart';
import 'package:stream_flutter/models/online_media_details_entity.dart';
import 'package:stream_flutter/models/search_result.dart';

class OnlineServerApi {
  static const HOST = 'http://192.168.1.28:3535';

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

  Future<OnlineMediaDetailsEntity> get(String path) async {
    try {
      final response = await http.get(
        Uri.parse("$HOST/online/get?path=$path"),
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

  Future<VideoStreams> getVideoSteams(String name, String? originalName, int season, int episode) async {
    try {
      final response = await http.get(
        Uri.parse("$HOST/online/film-streams?name=$name&original_name=$originalName&season=$season&episode=$episode"),
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

  Future<VideoStreams> getVideoStreams(String path) async {
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
