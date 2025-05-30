import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/series_models.dart';

class JellyfinSeriesService {
  final String baseUrl;
  final Map<String, String> headers;

  JellyfinSeriesService({
    required this.baseUrl,
    required this.headers,
  });

  /// Fetches series details including season count
  Future<SeriesDetails> getSeriesDetails(String seriesId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/Items/$seriesId'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return SeriesDetails.fromJson(data, baseUrl);
    }
    throw Exception('Failed to load series details');
  }

  /// Fetches all seasons for a series
  Future<List<Season>> getSeasons(String seriesId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/Shows/$seriesId/Seasons'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final items = List<Map<String, dynamic>>.from(data['Items']);
      return items
          .map((json) => Season.fromJson(json, baseUrl))
          .toList()
        ..sort((a, b) => a.seasonNumber.compareTo(b.seasonNumber));
    }
    throw Exception('Failed to load seasons');
  }

  /// Fetches episodes for a specific season
  Future<List<Episode>> getEpisodes(String seriesId, String seasonId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/Shows/$seriesId/Episodes?seasonId=$seasonId'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final items = List<Map<String, dynamic>>.from(data['Items']);
      return items
          .map((json) => Episode.fromJson(json, baseUrl))
          .toList()
        ..sort((a, b) => a.episodeNumber.compareTo(b.episodeNumber));
    }
    throw Exception('Failed to load episodes');
  }

  /// Fetches next up episodes for a series
  Future<List<Episode>> getNextUpEpisodes(String seriesId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/Shows/NextUp?seriesId=$seriesId'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final items = List<Map<String, dynamic>>.from(data['Items']);
      return items
          .map((json) => Episode.fromJson(json, baseUrl))
          .toList();
    }
    throw Exception('Failed to load next up episodes');
  }

  /// Get complete series information including seasons and episodes
  Future<SeriesInfo> getCompleteSeriesInfo(String seriesId) async {
    final series = await getSeriesDetails(seriesId);
    final seasons = await getSeasons(seriesId);
    
    // Create a map of season ID to episodes
    final Map<String, List<Episode>> episodesBySeason = {};
    for (final season in seasons) {
      episodesBySeason[season.id] = await getEpisodes(seriesId, season.id);
    }

    return SeriesInfo(
      details: series,
      seasons: seasons,
      episodesBySeason: episodesBySeason,
    );
  }
}