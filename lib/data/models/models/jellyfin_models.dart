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
