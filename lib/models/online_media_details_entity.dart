import 'dart:convert';

class OnlineMediaDetailsEntity {
  late String title;
  late String description;
  late List<String> cast = [];
  late String year;
  late double rating;
  late String posterPath;
  late String backdropPath;
  late String? embedUrl;
  late List<OnlineMediaDetailsSeasons> seasons = [];

  OnlineMediaDetailsEntity();

  OnlineMediaDetailsEntity.fromJson(Map<String, dynamic> data) {
    title = data["title"];
    description = data["description"];
    year = data["year"];
    rating = data["rating"];
    posterPath = data["posterPath"];
    backdropPath = data["backdropPath"];
    embedUrl = data["embed_url"];

    data["cast"].forEach((actor) => cast.add(actor));
    data["seasons"]?.forEach((season) => seasons.add(OnlineMediaDetailsSeasons.fromJson(season)));
  }

  @override
  String toString() {
    return jsonEncode(this);
  }
}

class OnlineMediaDetailsSeasons {
  late String seasonNumber;
  late String url;
  late int numberOfEpisodes;
  late Map<int, String> embedEpisodesUrls;

  OnlineMediaDetailsSeasons();

  OnlineMediaDetailsSeasons.fromJson(Map<String, dynamic> data) {
    seasonNumber = data["seasonNumber"];
    url = data["url"];
    numberOfEpisodes = int.parse(data["numberOfEpisodes"]);
    embedEpisodesUrls = (data["embed_episodes_urls"]as Map<String, dynamic>).map(
          (key, value) => MapEntry(int.parse(key), value.toString()),
    );
  }

  @override
  String toString() {
    return jsonEncode(this);
  }
}
