import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../models/models/media_item.dart';
import '../../../models/models/tmdb_models.dart';


class TmdbClient {

  final String tmdbApiKey = 'e96248a3a18b65337c955ab20f7ed208';

  TmdbClient();

  static const _tmdbBaseUrl = 'https://api.themoviedb.org/3';

  Future<List<dynamic>> _fetchTmdbList(
    String endpoint, [
    Map<String, String>? extraParams,
  ]) async {
    final uri = Uri.parse('$_tmdbBaseUrl$endpoint').replace(
      queryParameters: {
        'api_key': tmdbApiKey,
        'language': 'uk-UA',
        'page': '1',
        if (extraParams != null) ...extraParams,
      },
    );

    final response = await http.get(uri);
    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      return jsonData['results'] as List<dynamic>;
    } else {
      throw Exception('TMDB request failed: $endpoint');
    }
  }

  Future<Map<String, dynamic>> _fetchTmdbItem(
    String endpoint, [
    Map<String, String>? extraParams,
  ]) async {
    final uri = Uri.parse('$_tmdbBaseUrl$endpoint').replace(
      queryParameters: {
        'api_key': tmdbApiKey,
        'language': 'uk-UA',
        if (extraParams != null) ...extraParams,
      },
    );

    final response = await http.get(uri);
    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('TMDB request failed: $endpoint, Status: ${response.statusCode}, Body: ${response.body}');
    }
  }

  Future<List<TmdbMediaItem>> fetchNowPlayingMovies() async {
    final data = await _fetchTmdbList('/movie/now_playing');
    return data.map((json) => TmdbMediaItem.fromTmdbJson(json, MediaType.movie)).toList();
  }

  Future<List<TmdbMediaItem>> fetchPopularMovies() async {
    final data = await _fetchTmdbList('/movie/popular');
    return data.map((json) => TmdbMediaItem.fromTmdbJson(json, MediaType.movie)).toList();
  }

  Future<List<TmdbMediaItem>> fetchTopRatedMovies() async {
    final data = await _fetchTmdbList('/movie/top_rated');
    return data.map((json) => TmdbMediaItem.fromTmdbJson(json, MediaType.movie)).toList();
  }

  Future<List<TmdbMediaItem>> fetchNewestMovies({int voteCountGte = 100}) async {
    final today = DateTime.now().toIso8601String().split('T').first;
    final data = await _fetchTmdbList('/discover/movie', {
      'sort_by': 'release_date.desc',
      'primary_release_date.lte': today,
      'vote_count.gte': '$voteCountGte',
    });
    return data.map((json) => TmdbMediaItem.fromTmdbJson(json, MediaType.movie)).toList();
  }

  Future<List<TmdbMediaItem>> fetchPopularTV() async {
    final data = await _fetchTmdbList('/tv/popular');
    return data.map((json) => TmdbMediaItem.fromTmdbJson(json, MediaType.tv)).toList();
  }

  Future<List<TmdbMediaItem>> fetchTopRatedTV() async {
    final data = await _fetchTmdbList('/tv/top_rated');
    return data.map((json) => TmdbMediaItem.fromTmdbJson(json, MediaType.tv)).toList();
  }

  Future<List<TmdbMediaItem>> fetchNewestTV({int voteCountGte = 100}) async {
    final today = DateTime.now().toIso8601String().split('T').first;
    final data = await _fetchTmdbList('/discover/tv', {
      'sort_by': 'first_air_date.desc',
      'first_air_date.lte': today,
      'vote_count.gte': '$voteCountGte',
    });
    return data.map((json) => TmdbMediaItem.fromTmdbJson(json, MediaType.tv)).toList();
  }

  // --- New TMDB Detail Methods ---

  Future<TmdbMovieDetails> fetchMovieDetails(int movieId) async {
    final data = await _fetchTmdbItem('/movie/$movieId');
    return TmdbMovieDetails.fromJson(data);
  }

  Future<TVDetails> fetchTVDetails(int tvId) async {
    final data = await _fetchTmdbItem('/tv/$tvId');
    return TVDetails.fromJson(data);
  }

  Future<TVSeasonDetails> fetchTVSeasonDetails(int tvId, int seasonNumber) async {
    final data = await _fetchTmdbItem('/tv/$tvId/season/$seasonNumber');
    return TVSeasonDetails.fromJson(data);
  }
}
