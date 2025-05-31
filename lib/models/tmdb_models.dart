enum MediaType { movie, tv, unknown }

abstract class TmdbMediaDetails {
  final int id;
  final String overview;
  final String title;
  final String? posterPath;
  final String? backdropPath;
  final double voteAverage;
  final int voteCount;
  final List<Genre> genres;
  final List<ProductionCompany> productionCompanies;

  TmdbMediaDetails({
    required this.id,
    required this.overview,
    required this.title,
    this.posterPath,
    this.backdropPath,
    required this.voteAverage,
    required this.voteCount,
    required this.genres,
    required this.productionCompanies,
  });
}

class TVDetails extends TmdbMediaDetails {
  final String firstAirDate;
  final List<String> episodeRunTime;
  final List<TVSeasonSummary> seasons;

  TVDetails({
    required super.id,
    required super.overview,
    required super.title,
    super.posterPath,
    super.backdropPath,
    required this.firstAirDate,
    required super.voteAverage,
    required super.voteCount,
    required super.genres,
    required this.episodeRunTime,
    required super.productionCompanies,
    required this.seasons,
  });

  factory TVDetails.fromJson(Map<String, dynamic> json) {
    return TVDetails(
      id: json['id'],
      title: json['name'] ?? json['original_name'],
      overview: json['overview'],
      posterPath: json['poster_path'],
      backdropPath: json['backdrop_path'],
      firstAirDate: json['first_air_date'],
      voteAverage: (json['vote_average'] as num).toDouble(),
      voteCount: json['vote_count'],
      genres:
          (json['genres'] as List)
              .map((genre) => Genre.fromJson(genre))
              .toList(),
      episodeRunTime:
          (json['episode_run_time'] as List).map((e) => e.toString()).toList(),
      productionCompanies:
          (json['production_companies'] as List)
              .map((company) => ProductionCompany.fromJson(company))
              .toList(),
      seasons: (json['seasons'] as List? ?? [])
          .map((season) => TVSeasonSummary.fromJson(season))
          .toList(),
    );
  }
}

class TVSeasonSummary {
  final String? airDate;
  final int episodeCount;
  final int id;
  final String name;
  final String overview;
  final String? posterPath;
  final int seasonNumber;

  TVSeasonSummary({
    this.airDate,
    required this.episodeCount,
    required this.id,
    required this.name,
    required this.overview,
    this.posterPath,
    required this.seasonNumber,
  });

  factory TVSeasonSummary.fromJson(Map<String, dynamic> json) {
    return TVSeasonSummary(
      airDate: json['air_date'],
      episodeCount: json['episode_count'] ?? 0,
      id: json['id'],
      name: json['name'] ?? '',
      overview: json['overview'] ?? '',
      posterPath: json['poster_path'],
      seasonNumber: json['season_number'],
    );
  }
}

class TVEpisode {
  final int episodeNumber;
  final String name;
  final String overview;
  final String? stillPath;
  final String airDate;
  final double voteAverage;

  TVEpisode({
    required this.episodeNumber,
    required this.name,
    required this.overview,
    this.stillPath,
    required this.airDate,
    required this.voteAverage,
  });

  factory TVEpisode.fromJson(Map<String, dynamic> json) {
    return TVEpisode(
      episodeNumber: json['episode_number'],
      name: json['name'],
      overview: json['overview'],
      stillPath: json['still_path'],
      airDate: json['air_date'] ?? '',
      voteAverage: (json['vote_average'] as num).toDouble(),
    );
  }
}

class TVSeasonDetails {
  final int seasonNumber;
  final String name;
  final String overview;
  final String? posterPath;
  final String airDate;
  final List<TVEpisode> episodes;

  TVSeasonDetails({
    required this.seasonNumber,
    required this.name,
    required this.overview,
    this.posterPath,
    required this.airDate,
    required this.episodes,
  });

  factory TVSeasonDetails.fromJson(Map<String, dynamic> json) {
    return TVSeasonDetails(
      seasonNumber: json['season_number'],
      name: json['name'],
      overview: json['overview'],
      posterPath: json['poster_path'],
      airDate: json['air_date'] ?? '',
      episodes:
          (json['episodes'] as List)
              .map((episode) => TVEpisode.fromJson(episode))
              .toList(),
    );
  }
}

class MovieDetails extends TmdbMediaDetails {
  final String releaseDate;
  final int runtime;

  MovieDetails({
    required super.id,
    required super.title,
    required super.overview,
    super.posterPath,
    super.backdropPath,
    required this.releaseDate,
    required super.voteAverage,
    required super.voteCount,
    required super.genres,
    required this.runtime,
    required super.productionCompanies,
  });

  factory MovieDetails.fromJson(Map<String, dynamic> json) {
    return MovieDetails(
      id: json['id'],
      title: json['title'],
      overview: json['overview'],
      posterPath: json['poster_path'],
      backdropPath: json['backdrop_path'],
      releaseDate: json['release_date'],
      voteAverage: (json['vote_average'] as num).toDouble(),
      voteCount: json['vote_count'],
      genres:
          (json['genres'] as List)
              .map((genre) => Genre.fromJson(genre))
              .toList(),
      runtime: json['runtime'] ?? 0,
      productionCompanies:
          (json['production_companies'] as List)
              .map((company) => ProductionCompany.fromJson(company))
              .toList(),
    );
  }
}

class Genre {
  final int id;
  final String name;

  Genre({required this.id, required this.name});

  factory Genre.fromJson(Map<String, dynamic> json) {
    return Genre(id: json['id'], name: json['name']);
  }
}

class ProductionCompany {
  final int id;
  final String name;
  final String? logoPath;

  ProductionCompany({required this.id, required this.name, this.logoPath});

  factory ProductionCompany.fromJson(Map<String, dynamic> json) {
    return ProductionCompany(
      id: json['id'],
      name: json['name'],
      logoPath: json['logo_path'],
    );
  }
}