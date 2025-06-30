import 'package:stream_flutter/data/models/models/tmdb_models.dart';

abstract class  MediaItem {
  final String id;
  final String name;
  final MediaType type;
  final double? progress;
  final String? posterPath;
  final double? rating;

  MediaItem({
    required this.id,
    required this.name,
    required this.type,
    this.progress,
    this.posterPath,
    this.rating,
  });

}
