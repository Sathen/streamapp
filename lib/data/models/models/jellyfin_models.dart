import 'package:stream_flutter/data/models/models/media_item.dart';
import 'package:stream_flutter/data/models/models/tmdb_models.dart';

class JellyfinAuthException implements Exception {
  final String message;
  final int? statusCode;

  JellyfinAuthException(this.message, [this.statusCode]);

  @override
  String toString() => 'JellyfinAuthException: $message';
}

class JellyfinCredentials {
  final String serverUrl;
  final String username;
  final String password;

  JellyfinCredentials({
    required this.serverUrl,
    required this.username,
    required this.password,
  });

  Map<String, String> toJson() => {
    'serverUrl': serverUrl,
    'username': username,
    'password': password,
  };

  factory JellyfinCredentials.fromJson(Map<String, String> json) {
    return JellyfinCredentials(
      serverUrl: json['serverUrl'] ?? '',
      username: json['username'] ?? '',
      password: json['password'] ?? '',
    );
  }
}

class JellyfinUser {
  final String id;
  final String name;
  final String? primaryImageTag;
  final bool hasPassword;
  final bool hasConfiguredPassword;
  final bool hasConfiguredEasyPassword;
  final bool enableAutoLogin;

  JellyfinUser({
    required this.id,
    required this.name,
    this.primaryImageTag,
    this.hasPassword = false,
    this.hasConfiguredPassword = false,
    this.hasConfiguredEasyPassword = false,
    this.enableAutoLogin = false,
  });

  factory JellyfinUser.fromJson(Map<String, dynamic> json) {
    return JellyfinUser(
      id: json['Id'] ?? '',
      name: json['Name'] ?? '',
      primaryImageTag: json['PrimaryImageTag'],
      hasPassword: json['HasPassword'] ?? false,
      hasConfiguredPassword: json['HasConfiguredPassword'] ?? false,
      hasConfiguredEasyPassword: json['HasConfiguredEasyPassword'] ?? false,
      enableAutoLogin: json['EnableAutoLogin'] ?? false,
    );
  }
}

class JellyfinMediaItem extends MediaItem {

  JellyfinMediaItem({
    required super.id,
    required super.name,
    required super.type,
    required posterPath,
    required logoPath,
    required thumdbPath,
    required progress,
    required rating,
  });

  factory JellyfinMediaItem.fromJson(Map<String, dynamic> json) {
    return JellyfinMediaItem(
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
}
