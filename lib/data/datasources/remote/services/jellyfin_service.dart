import 'dart:convert';
import 'dart:developer' as developer;

import 'package:http/http.dart' as http;
import 'package:stream_flutter/data/datasources/remote/client/jellyfin_auth_client.dart';

import '../../../models/models/media_item.dart';

class JellyfinException implements Exception {
  final String message;
  final int? statusCode;

  JellyfinException(this.message, [this.statusCode]);

  @override
  String toString() => 'JellyfinException: $message';
}

class JellyfinService {
  final JellyfinAuthClient _authService;

  JellyfinService(this._authService);

  // Helper method to get auth headers
  Map<String, String> get _headers => _authService.getAuthHeaders();

  String? get _serverUrl => _authService.serverUrl;

  String? get _userId => _authService.userId;

  Future<List<MediaItem>> fetchContinueWatching({int limit = 12}) async {
    _ensureAuthenticated();

    try {
      final response = await http
          .get(
            Uri.parse(
              '$_serverUrl/Users/$_userId/Items/Resume?Limit=$limit&Fields=BasicSyncInfo,CanDelete,PrimaryImageAspectRatio,ProductionYear',
            ),
            headers: _headers,
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final items =
            (data['Items'] as List? ?? [])
                .map((item) => MediaItem.fromJson(item))
                .toList();

        developer.log('Fetched ${items.length} continue watching items');
        return items;
      } else {
        throw JellyfinException(
          'Failed to fetch continue watching',
          response.statusCode,
        );
      }
    } catch (e) {
      developer.log('Error fetching continue watching: $e');
      if (e is JellyfinException) rethrow;
      throw JellyfinException('Network error: ${e.toString()}');
    }
  }

  /// Fetch recently added items
  Future<List<MediaItem>> fetchRecentlyAdded({int limit = 16}) async {
    _ensureAuthenticated();

    try {
      final response = await http
          .get(
            Uri.parse(
              '$_serverUrl/Users/$_userId/Items/Latest?Limit=$limit&Fields=BasicSyncInfo,CanDelete,PrimaryImageAspectRatio,ProductionYear',
            ),
            headers: _headers,
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List;
        final items = data.map((item) => MediaItem.fromJson(item)).toList();

        developer.log('Fetched ${items.length} recently added items');
        return items;
      } else {
        throw JellyfinException(
          'Failed to fetch recently added',
          response.statusCode,
        );
      }
    } catch (e) {
      developer.log('Error fetching recently added: $e');
      if (e is JellyfinException) rethrow;
      throw JellyfinException('Network error: ${e.toString()}');
    }
  }

  /// Fetch all libraries/views
  Future<Map<String, List<MediaItem>>> fetchLibraries() async {
    _ensureAuthenticated();

    try {
      // First get the views/libraries
      final viewsResponse = await http
          .get(Uri.parse('$_serverUrl/Users/$_userId/Views'), headers: _headers)
          .timeout(const Duration(seconds: 15));

      if (viewsResponse.statusCode != 200) {
        throw JellyfinException(
          'Failed to fetch libraries',
          viewsResponse.statusCode,
        );
      }

      final viewsData = json.decode(viewsResponse.body);
      final views = viewsData['Items'] as List? ?? [];

      final libraries = <String, List<MediaItem>>{};

      // Fetch items for each library
      for (final view in views) {
        final viewId = view['Id'];
        final viewName = view['Name'] ?? 'Unknown Library';

        try {
          final itemsResponse = await http
              .get(
                Uri.parse(
                  '$_serverUrl/Users/$_userId/Items?ParentId=$viewId&Limit=20&Fields=BasicSyncInfo,CanDelete,PrimaryImageAspectRatio,ProductionYear&SortBy=SortName&SortOrder=Ascending',
                ),
                headers: _headers,
              )
              .timeout(const Duration(seconds: 10));

          if (itemsResponse.statusCode == 200) {
            final itemsData = json.decode(itemsResponse.body);
            final items =
                (itemsData['Items'] as List? ?? [])
                    .map((item) => MediaItem.fromJson(item))
                    .toList();

            libraries[viewName] = items;
            developer.log(
              'Fetched ${items.length} items for library: $viewName',
            );
          }
        } catch (e) {
          developer.log('Error fetching items for library $viewName: $e');
          // Continue with other libraries even if one fails
          libraries[viewName] = [];
        }
      }

      return libraries;
    } catch (e) {
      developer.log('Error fetching libraries: $e');
      if (e is JellyfinException) rethrow;
      throw JellyfinException('Network error: ${e.toString()}');
    }
  }

  /// Fetch specific library content with pagination
  Future<List<MediaItem>> fetchLibraryContent(
    String libraryId, {
    int startIndex = 0,
    int limit = 50,
    String? sortBy,
    String? sortOrder,
    String? searchTerm,
  }) async {
    _ensureAuthenticated();

    try {
      final params = <String, String>{
        'ParentId': libraryId,
        'StartIndex': startIndex.toString(),
        'Limit': limit.toString(),
        'Fields':
            'BasicSyncInfo,CanDelete,PrimaryImageAspectRatio,ProductionYear',
        'UserId': _userId!,
      };

      if (sortBy != null) params['SortBy'] = sortBy;
      if (sortOrder != null) params['SortOrder'] = sortOrder;
      if (searchTerm != null && searchTerm.isNotEmpty) {
        params['SearchTerm'] = searchTerm;
      }

      final uri = Uri.parse(
        '$_serverUrl/Users/$_userId/Items',
      ).replace(queryParameters: params);
      final response = await http
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final items =
            (data['Items'] as List? ?? [])
                .map((item) => MediaItem.fromJson(item))
                .toList();

        developer.log('Fetched ${items.length} items for library $libraryId');
        return items;
      } else {
        throw JellyfinException(
          'Failed to fetch library content',
          response.statusCode,
        );
      }
    } catch (e) {
      developer.log('Error fetching library content: $e');
      if (e is JellyfinException) rethrow;
      throw JellyfinException('Network error: ${e.toString()}');
    }
  }

  /// Search content across all libraries
  Future<List<MediaItem>> searchContent(String query, {int limit = 50}) async {
    _ensureAuthenticated();

    if (query.trim().isEmpty) return [];

    try {
      final params = {
        'SearchTerm': query.trim(),
        'Limit': limit.toString(),
        'Fields':
            'BasicSyncInfo,CanDelete,PrimaryImageAspectRatio,ProductionYear',
        'UserId': _userId!,
        'IncludeItemTypes': 'Movie,Series,Episode,Season',
      };

      final uri = Uri.parse(
        '$_serverUrl/Users/$_userId/Items',
      ).replace(queryParameters: params);
      final response = await http
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final items =
            (data['Items'] as List? ?? [])
                .map((item) => MediaItem.fromJson(item))
                .toList();

        developer.log('Found ${items.length} search results for: $query');
        return items;
      } else {
        throw JellyfinException(
          'Failed to search content',
          response.statusCode,
        );
      }
    } catch (e) {
      developer.log('Error searching content: $e');
      if (e is JellyfinException) rethrow;
      throw JellyfinException('Network error: ${e.toString()}');
    }
  }

  /// Get item details
  Future<MediaItem?> getItemDetails(String itemId) async {
    _ensureAuthenticated();

    try {
      final response = await http
          .get(
            Uri.parse(
              '$_serverUrl/Users/$_userId/Items/$itemId?Fields=BasicSyncInfo,CanDelete,PrimaryImageAspectRatio,ProductionYear,Overview,Genres,Studios,People',
            ),
            headers: _headers,
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return MediaItem.fromJson(data);
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw JellyfinException(
          'Failed to get item details',
          response.statusCode,
        );
      }
    } catch (e) {
      developer.log('Error fetching item details: $e');
      if (e is JellyfinException) rethrow;
      throw JellyfinException('Network error: ${e.toString()}');
    }
  }

  /// Get favorites
  Future<List<MediaItem>> getFavorites({int limit = 50}) async {
    _ensureAuthenticated();

    try {
      final params = {
        'Filters': 'IsFavorite',
        'Limit': limit.toString(),
        'Fields':
            'BasicSyncInfo,CanDelete,PrimaryImageAspectRatio,ProductionYear',
        'UserId': _userId!,
      };

      final uri = Uri.parse(
        '$_serverUrl/Users/$_userId/Items',
      ).replace(queryParameters: params);
      final response = await http
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final items =
            (data['Items'] as List? ?? [])
                .map((item) => MediaItem.fromJson(item))
                .toList();

        developer.log('Fetched ${items.length} favorite items');
        return items;
      } else {
        throw JellyfinException(
          'Failed to fetch favorites',
          response.statusCode,
        );
      }
    } catch (e) {
      developer.log('Error fetching favorites: $e');
      if (e is JellyfinException) rethrow;
      throw JellyfinException('Network error: ${e.toString()}');
    }
  }

  /// Toggle favorite status
  Future<void> toggleFavorite(String itemId, bool isFavorite) async {
    _ensureAuthenticated();

    try {
      final endpoint =
          isFavorite
              ? '$_serverUrl/Users/$_userId/FavoriteItems/$itemId'
              : '$_serverUrl/Users/$_userId/FavoriteItems/$itemId';

      final response =
          isFavorite
              ? await http.post(Uri.parse(endpoint), headers: _headers)
              : await http.delete(Uri.parse(endpoint), headers: _headers);

      if (response.statusCode != 200) {
        throw JellyfinException(
          'Failed to update favorite status',
          response.statusCode,
        );
      }

      developer.log(
        '${isFavorite ? 'Added to' : 'Removed from'} favorites: $itemId',
      );
    } catch (e) {
      developer.log('Error toggling favorite: $e');
      if (e is JellyfinException) rethrow;
      throw JellyfinException('Network error: ${e.toString()}');
    }
  }

  /// Mark item as played
  Future<void> markAsPlayed(String itemId) async {
    _ensureAuthenticated();

    try {
      final response = await http
          .post(
            Uri.parse('$_serverUrl/Users/$_userId/PlayedItems/$itemId'),
            headers: _headers,
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        throw JellyfinException(
          'Failed to mark as played',
          response.statusCode,
        );
      }

      developer.log('Marked as played: $itemId');
    } catch (e) {
      developer.log('Error marking as played: $e');
      if (e is JellyfinException) rethrow;
      throw JellyfinException('Network error: ${e.toString()}');
    }
  }

  /// Mark item as unplayed
  Future<void> markAsUnplayed(String itemId) async {
    _ensureAuthenticated();

    try {
      final response = await http
          .delete(
            Uri.parse('$_serverUrl/Users/$_userId/PlayedItems/$itemId'),
            headers: _headers,
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        throw JellyfinException(
          'Failed to mark as unplayed',
          response.statusCode,
        );
      }

      developer.log('Marked as unplayed: $itemId');
    } catch (e) {
      developer.log('Error marking as unplayed: $e');
      if (e is JellyfinException) rethrow;
      throw JellyfinException('Network error: ${e.toString()}');
    }
  }

  /// Update playback progress
  Future<void> updatePlaybackProgress({
    required String itemId,
    required int positionTicks,
    bool isPaused = false,
  }) async {
    _ensureAuthenticated();

    try {
      final body = json.encode({
        'ItemId': itemId,
        'PositionTicks': positionTicks,
        'IsPaused': isPaused,
      });

      final response = await http
          .post(
            Uri.parse('$_serverUrl/Sessions/Playing/Progress'),
            headers: _headers,
            body: body,
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 204) {
        throw JellyfinException(
          'Failed to update playback progress',
          response.statusCode,
        );
      }

      developer.log(
        'Updated playback progress for $itemId: ${positionTicks ~/ 10000000}s',
      );
    } catch (e) {
      developer.log('Error updating playback progress: $e');
      if (e is JellyfinException) rethrow;
      throw JellyfinException('Network error: ${e.toString()}');
    }
  }

  /// Start playback session
  Future<void> startPlaybackSession({
    required String itemId,
    int positionTicks = 0,
  }) async {
    _ensureAuthenticated();

    try {
      final body = json.encode({
        'ItemId': itemId,
        'PositionTicks': positionTicks,
      });

      final response = await http
          .post(
            Uri.parse('$_serverUrl/Sessions/Playing'),
            headers: _headers,
            body: body,
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 204) {
        throw JellyfinException(
          'Failed to start playback session',
          response.statusCode,
        );
      }

      developer.log('Started playback session for: $itemId');
    } catch (e) {
      developer.log('Error starting playback session: $e');
      if (e is JellyfinException) rethrow;
      throw JellyfinException('Network error: ${e.toString()}');
    }
  }

  /// Stop playback session
  Future<void> stopPlaybackSession({
    required String itemId,
    required int positionTicks,
  }) async {
    _ensureAuthenticated();

    try {
      final body = json.encode({
        'ItemId': itemId,
        'PositionTicks': positionTicks,
      });

      final response = await http
          .post(
            Uri.parse('$_serverUrl/Sessions/Playing/Stopped'),
            headers: _headers,
            body: body,
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 204) {
        throw JellyfinException(
          'Failed to stop playback session',
          response.statusCode,
        );
      }

      developer.log('Stopped playback session for: $itemId');
    } catch (e) {
      developer.log('Error stopping playback session: $e');
      if (e is JellyfinException) rethrow;
      throw JellyfinException('Network error: ${e.toString()}');
    }
  }

  /// Get stream URL for direct play
  String getStreamUrl(
    String itemId, {
    String? audioStreamIndex,
    String? subtitleStreamIndex,
    int? maxStreamingBitrate,
  }) {
    _ensureAuthenticated();

    final params = <String, String>{
      'UserId': _userId!,
      'DeviceId': _authService.deviceId,
    };

    if (audioStreamIndex != null) params['AudioStreamIndex'] = audioStreamIndex;
    if (subtitleStreamIndex != null) params['SubtitleStreamIndex'] = subtitleStreamIndex;
    if (maxStreamingBitrate != null) params['MaxStreamingBitrate'] = maxStreamingBitrate.toString();

    final uri = Uri.parse(
      '$_serverUrl/Videos/$itemId/stream',
    ).replace(queryParameters: params);
    return uri.toString();
  }

  /// Get image URL
  String getImageUrl(
    String itemId, {
    String imageType = 'Primary',
    int? width,
    int? height,
    int? quality,
  }) {
    if (_serverUrl == null) throw JellyfinException('Not connected to server');

    final params = <String, String>{};
    if (width != null) params['width'] = width.toString();
    if (height != null) params['height'] = height.toString();
    if (quality != null) params['quality'] = quality.toString();

    final uri = Uri.parse(
      '$_serverUrl/Items/$itemId/Images/$imageType',
    ).replace(queryParameters: params);
    return uri.toString();
  }

  /// Get next up episodes for TV series
  Future<List<MediaItem>> getNextUpEpisodes({int limit = 10}) async {
    _ensureAuthenticated();

    try {
      final response = await http
          .get(
            Uri.parse(
              '$_serverUrl/Shows/NextUp?UserId=$_userId&Limit=$limit&Fields=BasicSyncInfo,PrimaryImageAspectRatio',
            ),
            headers: _headers,
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final items =
            (data['Items'] as List? ?? [])
                .map((item) => MediaItem.fromJson(item))
                .toList();

        developer.log('Fetched ${items.length} next up episodes');
        return items;
      } else {
        throw JellyfinException(
          'Failed to fetch next up episodes',
          response.statusCode,
        );
      }
    } catch (e) {
      developer.log('Error fetching next up episodes: $e');
      if (e is JellyfinException) rethrow;
      throw JellyfinException('Network error: ${e.toString()}');
    }
  }

  /// Get server statistics
  Future<Map<String, dynamic>?> getServerStats() async {
    _ensureAuthenticated();

    try {
      final response = await http
          .get(
            Uri.parse('$_serverUrl/Items/Counts?UserId=$_userId'),
            headers: _headers,
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw JellyfinException(
          'Failed to fetch server stats',
          response.statusCode,
        );
      }
    } catch (e) {
      developer.log('Error fetching server stats: $e');
      return null;
    }
  }

  /// Private helper to ensure user is authenticated
  void _ensureAuthenticated() {
    if (!_authService.isLoggedIn) {
      throw JellyfinException('Not authenticated. Please login first.');
    }
  }
}
