import 'package:stream_flutter/data/models/models/tmdb_models.dart';

class MediaItem {
  final String id;
  final String name;
  final MediaType type;
  final double? progress;
  final String? posterPath;
  final String? logoPath;
  final String? thumdbPath;
  final double? rating;

  MediaItem({
    required this.id,
    required this.name,
    required this.type,
    this.progress,
    this.posterPath,
    this.logoPath,
    this.thumdbPath,
    this.rating,
  });

  factory MediaItem.fromJson(Map<String, dynamic> json) {
    return MediaItem(
      id: json['Id'] ?? '',
      name: json['Name'] ?? 'Unknown',
      posterPath: json['ImageTags']?['Primary'],
      logoPath: json['ImageTags']?['Logo'],
      thumdbPath: json['ImageTags']?['Thumb'],
      progress: null,
      type: MediaType.unknown,
      rating: null,
    );
  }

  factory MediaItem.fromTmdbJson(
    Map<String, dynamic> json,
    MediaType mediaType,
  ) {
    return MediaItem(
      id: json['id'].toString(),
      name: json['title'] ?? json['name'] ?? 'Unknown',
      rating: (json['vote_average'] as num?)?.toDouble(),
      progress: null,
      type: mediaType,
      posterPath:
          json['poster_path'] != null
              ? 'https://image.tmdb.org/t/p/w500${json['poster_path']}'
              : null,
    );
  }
}
