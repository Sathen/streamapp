class SeriesDetails {
  final String id;
  final String name;
  final String overview;
  final int seasonCount;
  final int episodeCount;
  final String? posterPath;
  final List<String> genres;
  final String? productionYear;
  final bool hasEnded;

  SeriesDetails({
    required this.id,
    required this.name,
    required this.overview,
    required this.seasonCount,
    required this.episodeCount,
    this.posterPath,
    required this.genres,
    this.productionYear,
    required this.hasEnded,
  });

  factory SeriesDetails.fromJson(Map<String, dynamic> json, String baseUrl) {
    return SeriesDetails(
      id: json['Id'],
      name: json['Name'],
      overview: json['Overview'] ?? '',
      seasonCount: json['ChildCount'] ?? 0,
      episodeCount: json['RecursiveItemCount'] ?? 0,
      posterPath: json['ImageTags']?['Primary'] != null
          ? '$baseUrl/Items/${json['Id']}/Images/Primary/0'
          : null,
      genres: List<String>.from(json['Genres'] ?? []),
      productionYear: json['ProductionYear']?.toString(),
      hasEnded: json['Status'] == 'Ended',
    );
  }
}

class Season {
  final String id;
  final String name;
  final int seasonNumber;
  final int episodeCount;
  final String? posterPath;
  final bool isSpecialSeason;

  Season({
    required this.id,
    required this.name,
    required this.seasonNumber,
    required this.episodeCount,
    this.posterPath,
    required this.isSpecialSeason,
  });

  factory Season.fromJson(Map<String, dynamic> json, String baseUrl) {
    return Season(
      id: json['Id'],
      name: json['Name'],
      seasonNumber: json['IndexNumber'] ?? 0,
      episodeCount: json['ChildCount'] ?? 0,
      posterPath: json['ImageTags']?['Primary'] != null
          ? '$baseUrl/Items/${json['Id']}/Images/Primary/0'
          : null,
      isSpecialSeason: json['Type'] == 'Season' && json['IndexNumber'] == 0,
    );
  }
}

class Episode {
  final String id;
  final String name;
  final int episodeNumber;
  final int seasonNumber;
  final String? overview;
  final String? stillPath;
  final Duration? runtime;
  final bool played;
  final double? playedPercentage;

  Episode({
    required this.id,
    required this.name,
    required this.episodeNumber,
    required this.seasonNumber,
    this.overview,
    this.stillPath,
    this.runtime,
    required this.played,
    this.playedPercentage,
  });

  factory Episode.fromJson(Map<String, dynamic> json, String baseUrl) {
    return Episode(
      id: json['Id'],
      name: json['Name'],
      episodeNumber: json['IndexNumber'] ?? 0,
      seasonNumber: json['ParentIndexNumber'] ?? 0,
      overview: json['Overview'],
      stillPath: json['ImageTags']?['Primary'] != null
          ? '$baseUrl/Items/${json['Id']}/Images/Primary/0'
          : null,
      runtime: json['RunTimeTicks'] != null
          ? Duration(microseconds: (json['RunTimeTicks'] ~/ 10))
          : null,
      played: json['UserData']?['Played'] ?? false,
      playedPercentage: json['UserData']?['PlayedPercentage']?.toDouble(),
    );
  }
}

class SeriesInfo {
  final SeriesDetails details;
  final List<Season> seasons;
  final Map<String, List<Episode>> episodesBySeason;

  SeriesInfo({
    required this.details,
    required this.seasons,
    required this.episodesBySeason,
  });

  /// Get episodes for a specific season
  List<Episode> getEpisodesForSeason(String seasonId) {
    return episodesBySeason[seasonId] ?? [];
  }

  /// Get the total number of episodes across all seasons
  int get totalEpisodeCount {
    return episodesBySeason.values
        .fold(0, (sum, episodes) => sum + episodes.length);
  }

  /// Get the next unwatched episode
  Episode? getNextUnwatchedEpisode() {
    for (final season in seasons) {
      final episodes = episodesBySeason[season.id] ?? [];
      for (final episode in episodes) {
        if (!episode.played) {
          return episode;
        }
      }
    }
    return null;
  }

  /// Get watch progress as a percentage
  double get watchProgress {
    final totalEpisodes = totalEpisodeCount;
    if (totalEpisodes == 0) return 0.0;

    final watchedCount = episodesBySeason.values
        .expand((episodes) => episodes)
        .where((episode) => episode.played)
        .length;

    return watchedCount / totalEpisodes;
  }
}