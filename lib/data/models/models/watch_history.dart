import 'package:flutter/material.dart';

class WatchHistoryItem {
  final String id;
  final String title;
  final String originalTitle;
  final WatchHistoryType type;
  final String? posterPath;
  final String? backdropPath;
  final double? rating;
  final DateTime lastWatched;
  final int watchCount;

  // For TV shows - track watched episodes
  final Map<int, Set<int>>? watchedEpisodes; // season -> episodes

  // For movies - track if completed
  final bool isCompleted;

  WatchHistoryItem({
    required this.id,
    required this.title,
    required this.originalTitle,
    required this.type,
    this.posterPath,
    this.backdropPath,
    this.rating,
    required this.lastWatched,
    this.watchCount = 1,
    this.watchedEpisodes,
    this.isCompleted = false,
  });

  factory WatchHistoryItem.fromJson(Map<String, dynamic> json) {
    Map<int, Set<int>>? episodes;
    if (json['watchedEpisodes'] != null) {
      final episodesData = json['watchedEpisodes'] as Map<String, dynamic>;
      episodes = episodesData.map(
        (seasonStr, episodesList) =>
            MapEntry(int.parse(seasonStr), Set<int>.from(episodesList as List)),
      );
    }

    return WatchHistoryItem(
      id: json['id'],
      title: json['title'],
      originalTitle: json['originalTitle'],
      type: WatchHistoryType.values.firstWhere(
        (e) => e.toString() == json['type'],
      ),
      posterPath: json['posterPath'],
      backdropPath: json['backdropPath'],
      rating: json['rating']?.toDouble(),
      lastWatched: DateTime.parse(json['lastWatched']),
      watchCount: json['watchCount'] ?? 1,
      watchedEpisodes: episodes,
      isCompleted: json['isCompleted'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic>? episodesJson;
    if (watchedEpisodes != null) {
      episodesJson = watchedEpisodes!.map(
        (season, episodes) => MapEntry(season.toString(), episodes.toList()),
      );
    }

    return {
      'id': id,
      'title': title,
      'originalTitle': originalTitle,
      'type': type.toString(),
      'posterPath': posterPath,
      'backdropPath': backdropPath,
      'rating': rating,
      'lastWatched': lastWatched.toIso8601String(),
      'watchCount': watchCount,
      'watchedEpisodes': episodesJson,
      'isCompleted': isCompleted,
    };
  }

  WatchHistoryItem copyWith({
    String? id,
    String? title,
    String? originalTitle,
    WatchHistoryType? type,
    String? posterPath,
    String? backdropPath,
    double? rating,
    DateTime? lastWatched,
    int? watchCount,
    Map<int, Set<int>>? watchedEpisodes,
    bool? isCompleted,
  }) {
    return WatchHistoryItem(
      id: id ?? this.id,
      title: title ?? this.title,
      originalTitle: originalTitle ?? this.originalTitle,
      type: type ?? this.type,
      posterPath: posterPath ?? this.posterPath,
      backdropPath: backdropPath ?? this.backdropPath,
      rating: rating ?? this.rating,
      lastWatched: lastWatched ?? this.lastWatched,
      watchCount: watchCount ?? this.watchCount,
      watchedEpisodes: watchedEpisodes ?? this.watchedEpisodes,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  // Helper methods
  bool hasWatchedEpisode(int season, int episode) {
    return watchedEpisodes?[season]?.contains(episode) ?? false;
  }

  int getTotalWatchedEpisodes() {
    if (watchedEpisodes == null) return 0;
    return watchedEpisodes!.values.fold(
      0,
      (sum, episodes) => sum + episodes.length,
    );
  }

  List<int> getWatchedSeasonsNumbers() {
    if (watchedEpisodes == null) return [];
    return watchedEpisodes!.keys.toList()..sort();
  }

  String get formattedLastWatched {
    final now = DateTime.now();
    final difference = now.difference(lastWatched);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${lastWatched.day}/${lastWatched.month}/${lastWatched.year}';
    }
  }
}

enum WatchHistoryType { movie, tv }

extension WatchHistoryTypeExtension on WatchHistoryType {
  String get displayName {
    switch (this) {
      case WatchHistoryType.movie:
        return 'Movie';
      case WatchHistoryType.tv:
        return 'TV Show';
    }
  }

  IconData get icon {
    switch (this) {
      case WatchHistoryType.movie:
        return Icons.movie_rounded;
      case WatchHistoryType.tv:
        return Icons.tv_rounded;
    }
  }
}
