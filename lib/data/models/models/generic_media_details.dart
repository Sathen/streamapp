// lib/models/generic_media_interfaces.dart

abstract class GenericEpisode {
  int get episodeNumber;
  String get name;
  String? get airDate;
  String? get stillPath;
  String? get embedUrl;
}

abstract class GenericSeason {
  int get seasonNumber;
  String get title;
  int get numberOfEpisodes;
  List<GenericEpisode> get episodes;
  Map<int, String>? get embedEpisodesUrls;
  String? get posterPath;
}

abstract class GenericMediaData {
  String get tmdbId;
  String get title;
  String? get posterPath;
  String? get backdropPath;
}
