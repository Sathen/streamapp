import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/media_item.dart';

class MediaService {
  final String? serverUrl;
  final String? userId;
  final Map<String, String>? headers;

  MediaService(this.serverUrl, this.userId, this.headers);

  Future<List<MediaItem>> fetchContinueWatching() async {
    final response = await http.get(
      Uri.parse('$serverUrl/Users/$userId/Items/Resume?Limit=10'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return (data['Items'] as List)
          .map((item) => MediaItem.fromJson(item))
          .toList();
    } else {
      throw Exception('Failed to load continue watching');
    }
  }

  Future<List<MediaItem>> fetchRecentlyAdded() async {
    final response = await http.get(
      Uri.parse('$serverUrl/Users/$userId/Items/Latest'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body) as List;
      return data.map((item) => MediaItem.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load recently added');
    }
  }

  Future<Map<String, List<MediaItem>>> fetchLibraries() async {
    final response = await http.get(
      Uri.parse('$serverUrl/Users/$userId/Views'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final views = data['Items'] as List;

      final libraries = <String, List<MediaItem>>{};
      for (final view in views) {
        final viewId = view['Id'];
        final viewName = view['Name'];

        final itemsResponse = await http.get(
          Uri.parse('$serverUrl/Users/$userId/Items?ParentId=$viewId&Limit=10'),
          headers: headers,
        );

        if (itemsResponse.statusCode == 200) {
          final itemsData = json.decode(itemsResponse.body);
          libraries[viewName] =
              (itemsData['Items'] as List)
                  .map((item) => MediaItem.fromJson(item))
                  .toList();
        }
      }

      return libraries;
    } else {
      throw Exception('Failed to load libraries');
    }
  }
}
