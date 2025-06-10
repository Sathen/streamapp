import 'dart:convert';

import 'generic_media_details.dart';

class OnlineMediaDetailsEntity implements GenericMediaData {
  // Implement GenericMediaData
  @override
  late String title;
  late String description;
  late List<String> cast = [];
  late String year;
  @override
  late String tmdbId;
  late double rating;
  @override
  late String posterPath;
  @override
  late String backdropPath;
  late String? embedUrl;
  late List<OnlineMediaDetailsSeasons> seasons = [];

  OnlineMediaDetailsEntity();

  OnlineMediaDetailsEntity.fromJson(Map<String, dynamic> data) {
    title = data["title"];
    description = data["description"];
    year = data["year"];
    tmdbId = data["tmdb"].toString();
    rating = data["rating"];
    posterPath = data["posterPath"];
    backdropPath = data["backdropPath"];
    embedUrl = data["embed_url"];

    if (data["cast"] != null) {
      data["cast"].forEach((actor) => cast.add(actor));
    }
    if (data["seasons"] != null) {
      data["seasons"]?.forEach(
        (season) => seasons.add(OnlineMediaDetailsSeasons.fromJson(season)),
      );
    }
  }

  @override
  String toString() {
    return jsonEncode(this);
  }
}

class OnlineMediaDetailsEpisode implements GenericEpisode {
  // Implement GenericEpisode
  @override
  late int episodeNumber;
  @override
  late String name;
  @override
  late String airDate;
  @override
  late String? stillPath;
  @override
  late String embedUrl;

  OnlineMediaDetailsEpisode();

  OnlineMediaDetailsEpisode.fromJson(Map<String, dynamic> data) {
    episodeNumber = data["episode_number"];
    name = data["name"];
    airDate = data["air_date"];
    stillPath = data["still_path"];
    embedUrl = data["embed_url"];
  }

  @override
  String toString() => jsonEncode(this);
}

class OnlineMediaDetailsSeasons implements GenericSeason {
  // Implement GenericSeason
  @override
  late int seasonNumber;
  @override
  late String title;
  late String url;
  @override
  late int numberOfEpisodes;
  @override
  late Map<int, String> embedEpisodesUrls;
  @override
  late String posterPath;

  @override
  late List<OnlineMediaDetailsEpisode> episodes = [];

  OnlineMediaDetailsSeasons();

  OnlineMediaDetailsSeasons.fromJson(Map<String, dynamic> data) {
    seasonNumber = data["seasonNumber"];
    title = data["name"];
    url = data["url"];
    posterPath = data['poster_path'];
    numberOfEpisodes = data["numberOfEpisodes"];

    final embedMap = data["embed_episodes_urls"] as Map<String, dynamic>? ?? {};
    embedEpisodesUrls = embedMap.map(
      (key, value) => MapEntry(int.parse(key), value.toString()),
    );

    if (data["episodes"] != null) {
      episodes =
          List.from(
            data["episodes"],
          ).map((ep) => OnlineMediaDetailsEpisode.fromJson(ep)).toList();
    }
  }

  @override
  String toString() => jsonEncode(this);
}
