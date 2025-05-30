import 'package:stream_flutter/models/online_media_details_entity.dart';

class MediaDetail {
  final String id;
  final String name;
  final String overview;
  final String? backdropPath;
  final String? posterPath;
  final int? duration;
  final String? videoQuality;
  final List<String> genres;
  final List<Map<String, dynamic>> cast;
  final bool isFavorite;
  final String? releaseYear;
  final String? mediaType;
  final List<Map<String, dynamic>> streams;
  final List<Map<String, dynamic>>? episodes;
  final String? parentId;
  final String? studio;
  final List<String> directors;
  final List<String> writers;
  final double? communityRating;
  final int? resumePosition;
  final String? videoCodec;
  final String? audioCodec;
  final String? container;
  final int? bitrate;

  MediaDetail({
    required this.id,
    required this.name,
    required this.overview,
    this.backdropPath,
    this.posterPath,
    this.duration,
    this.videoQuality,
    required this.genres,
    required this.cast,
    this.isFavorite = false,
    this.releaseYear,
    this.mediaType,
    required this.streams,
    this.episodes,
    this.parentId,
    this.studio,
    this.directors = const [],
    this.writers = const [],
    this.communityRating,
    this.resumePosition,
    this.videoCodec,
    this.audioCodec,
    this.container,
    this.bitrate,
  });

  factory MediaDetail.fromOnline(OnlineMediaDetailsEntity entity) {
    List<Map<String, dynamic>> cast =
        entity.cast.map((name) => {"name": name}).toList();
    return MediaDetail(
      id: '',
      name: entity.title,
      releaseYear: entity.year,
      backdropPath: entity.backdropPath,
      posterPath: entity.posterPath,
      communityRating: entity.rating,
      overview: entity.description,
      genres: [],
      cast: cast,
      streams: [],
    );
  }

  factory MediaDetail.fromJson(String serverUrl, Map<String, dynamic> json) {
    return MediaDetail(
      id: json['Id'],
      name: json['Name'],
      backdropPath:
          json['BackdropImageTags'] != null
              ? '$serverUrl/Items/${json['Id']}/Images/Backdrop/0'
              : null,
      overview: json['Overview'] ?? '',
      posterPath:
          json['ImageTags']?['Primary'] != null
              ? '$serverUrl/Items/${json['Id']}/Images/Primary/0'
              : null,
      duration:
          json['RunTimeTicks'] != null
              ? (json['RunTimeTicks'] / 10000000 / 60).round()
              : null,
      videoQuality: json['Type'] != 'Series' ? _parseVideoQuality(json) : null,
      genres: List<String>.from(json['Genres'] ?? []),
      cast: _parseCast(json),
      isFavorite: json['UserData']?['IsFavorite'] ?? false,
      releaseYear: json['ProductionYear']?.toString(),
      mediaType: json['Type'],
      streams: _parseStreams(json),
      episodes: json['Type'] == 'Series' ? _parseEpisodes(json) : null,
      parentId: json['ParentId'],
      studio: json['Studio'],
      directors: List<String>.from(
        json['People']
                ?.where((p) => p['Type'] == 'Director')
                .map((p) => p['Name']) ??
            [],
      ),
      writers: List<String>.from(
        json['People']
                ?.where((p) => p['Type'] == 'Writer')
                .map((p) => p['Name']) ??
            [],
      ),
      communityRating: json['CommunityRating']?.toDouble(),
      resumePosition: json['UserData']?['PlaybackPositionTicks'],
      videoCodec: json['MediaStreams']?[0]?['Codec'],
      audioCodec:
          json['MediaStreams']?.firstWhere(
            (s) => s['Type'] == 'Audio',
            orElse: () => {},
          )?['Codec'],
      container: json['Container'],
      bitrate: json['Bitrate'],
    );
  }

  static String _parseVideoQuality(Map<String, dynamic> json) {
    final width = json['Width'];
    if (width == null) return 'Unknown';
    if (width >= 3840) return '4K';
    if (width >= 1920) return '1080p';
    if (width >= 1280) return '720p';
    return 'SD';
  }

  static List<Map<String, dynamic>> _parseCast(Map<String, dynamic> json) {
    final people = json['People'] as List? ?? [];
    return people
        .where((person) => person['Type'] == 'Actor')
        .map(
          (person) => {
            'name': person['Name'],
            'role': person['Role'] ?? '',
            'id': person['Id'],
          },
        )
        .toList();
  }

  static List<Map<String, dynamic>> _parseStreams(Map<String, dynamic> json) {
    final mediaStreams = json['MediaStreams'] as List? ?? [];
    return mediaStreams
        .map(
          (stream) => {
            'type': stream['Type'],
            'codec': stream['Codec'],
            'language': stream['Language'],
            'displayTitle': stream['DisplayTitle'],
          },
        )
        .toList();
  }

  static List<Map<String, dynamic>>? _parseEpisodes(Map<String, dynamic> json) {
    if (json['Type'] != 'Series' || json['Episodes'] == null) {
      return null;
    }

    final episodes = json['Episodes'] as List;
    return episodes
        .map(
          (episode) => {
            'id': episode['Id'],
            'name': episode['Name'],
            'overview': episode['Overview'] ?? '',
            'seasonNumber': episode['ParentIndexNumber'] ?? 0,
            'episodeNumber': episode['IndexNumber'] ?? 0,
            'runtime':
                episode['RunTimeTicks'] != null
                    ? (episode['RunTimeTicks'] / 10000000 / 60).round()
                    : null,
            'imagePath':
                episode['ImageTags']?['Primary'] != null
                    ? 'Items/${episode['Id']}/Images/Primary/0'
                    : null,
          },
        )
        .toList();
  }
}
