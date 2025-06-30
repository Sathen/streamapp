import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart' show sha256;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../models/models/jellyfin_models.dart';

class JellyfinAuthClient {
  static const String _accessTokenKey = 'jellyfin_access_token';
  static const String _userIdKey = 'jellyfin_user_id';
  static const String _serverUrlKey = 'jellyfin_server_url';
  static const String _credentialsKey = 'jellyfin_credentials';
  static const String _rememberCredentialsKey = 'jellyfin_remember_credentials';

  late SharedPreferences _prefs;
  final _secureStorage = const FlutterSecureStorage();

  final String _client = "Jellyserr";
  String _device = "Unknown Device";
  String _deviceId = "Unknown";
  final String _version = "1.0.0";

  // Current session data
  String? _accessToken;
  String? _userId;
  String? _serverUrl;
  JellyfinUser? _currentUser;
  JellyfinCredentials? _savedCredentials;

  // Getters
  bool get isLoggedIn =>
      _accessToken != null && _userId != null && _serverUrl != null;

  String? get accessToken => _accessToken;

  String? get userId => _userId;

  String? get serverUrl => _serverUrl;

  JellyfinUser? get currentUser => _currentUser;

  String get deviceId => _deviceId;

  JellyfinCredentials? get savedCredentials => _savedCredentials;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    await _initializeDeviceInfo();
    await _loadSavedSession();
    await _loadSavedCredentials();
  }

  Future<void> _initializeDeviceInfo() async {
    try {
      final deviceInfo = DeviceInfoPlugin();

      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        _device = "${androidInfo.brand} ${androidInfo.model}";
        _deviceId = _generateDeviceId(androidInfo.id);
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        _device = "${iosInfo.name} ${iosInfo.model}";
        _deviceId = _generateDeviceId(iosInfo.identifierForVendor ?? 'unknown');
      } else {
        _device = Platform.operatingSystem;
        _deviceId = _generateDeviceId(
          'desktop_${DateTime.now().millisecondsSinceEpoch}',
        );
      }
    } catch (e) {
      _device = "Unknown Device";
      _deviceId = _generateDeviceId(
        'fallback_${DateTime.now().millisecondsSinceEpoch}',
      );
    }
  }

  String _generateDeviceId(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString().substring(0, 32);
  }

  Future<bool> testServerConnection(String serverUrl) async {
    try {
      final cleanUrl = _cleanServerUrl(serverUrl);
      final response = await http
          .get(
            Uri.parse('$cleanUrl/System/Info/Public'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 10));

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>?> getServerInfo(String serverUrl) async {
    try {
      final cleanUrl = _cleanServerUrl(serverUrl);
      final response = await http
          .get(
            Uri.parse('$cleanUrl/System/Info/Public'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Login with username and password
  Future<bool> login({
    required String serverUrl,
    required String username,
    required String password,
    bool rememberCredentials = false,
  }) async {
    try {
      final cleanUrl = _cleanServerUrl(serverUrl);

      // Test connection first
      if (!await testServerConnection(cleanUrl)) {
        throw JellyfinAuthException('Cannot connect to server at $cleanUrl');
      }

      final headers = {
        'Content-Type': 'application/json',
        'Authorization': _getAuthorizationHeader(),
      };

      final body = json.encode({'Username': username, 'Pw': password});

      final response = await http
          .post(
            Uri.parse('$cleanUrl/Users/AuthenticateByName'),
            headers: headers,
            body: body,
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        _accessToken = data['AccessToken'];
        _userId = data['User']['Id'];
        _serverUrl = cleanUrl;
        _currentUser = JellyfinUser.fromJson(data['User']);

        // Save session
        await _saveSession();

        // Save credentials if requested
        if (rememberCredentials) {
          await _saveCredentials(
            JellyfinCredentials(
              serverUrl: cleanUrl,
              username: username,
              password: password,
            ),
          );
        }

        return true;
      } else {
        final errorData = json.decode(response.body);
        throw JellyfinAuthException(
          errorData['Message'] ?? 'Authentication failed',
          response.statusCode,
        );
      }
    } catch (e) {
      if (e is JellyfinAuthException) rethrow;
      throw JellyfinAuthException('Login failed: ${e.toString()}');
    }
  }

  /// Auto-login using saved credentials
  Future<bool> autoLogin() async {
    if (_savedCredentials == null) return false;

    try {
      return await login(
        serverUrl: _savedCredentials!.serverUrl,
        username: _savedCredentials!.username,
        password: _savedCredentials!.password,
        rememberCredentials: true,
      );
    } catch (e) {
      return false;
    }
  }

  /// Refresh token
  Future<bool> refreshToken() async {
    if (_savedCredentials == null) return false;
    return await autoLogin();
  }

  /// Logout and clear all data
  Future<void> logout({bool clearCredentials = false}) async {
    _accessToken = null;
    _userId = null;
    _serverUrl = null;
    _currentUser = null;

    await _secureStorage.delete(key: _accessTokenKey);
    await _secureStorage.delete(key: _userIdKey);
    await _prefs.remove(_serverUrlKey);

    if (clearCredentials) {
      await clearSavedCredentials();
    }
  }

  /// Get authorization headers for API calls
  Map<String, String> getAuthHeaders() {
    if (_accessToken == null) {
      throw JellyfinAuthException('Not authenticated');
    }

    return {
      'Authorization': _getAuthorizationHeader(_accessToken),
      'Content-Type': 'application/json',
    };
  }

  Future<void> _saveCredentials(JellyfinCredentials credentials) async {
    final credentialsJson = json.encode(credentials.toJson());
    await _secureStorage.write(key: _credentialsKey, value: credentialsJson);
    await _prefs.setBool(_rememberCredentialsKey, true);
    _savedCredentials = credentials;
  }

  Future<void> _loadSavedCredentials() async {
    try {
      final rememberCredentials =
          _prefs.getBool(_rememberCredentialsKey) ?? false;
      if (!rememberCredentials) return;

      final credentialsJson = await _secureStorage.read(key: _credentialsKey);
      if (credentialsJson != null) {
        final credentialsMap = Map<String, String>.from(
          json.decode(credentialsJson),
        );
        _savedCredentials = JellyfinCredentials.fromJson(credentialsMap);
      }
    } catch (e) {
      // Ignore errors when loading credentials
    }
  }

  Future<void> clearSavedCredentials() async {
    await _secureStorage.delete(key: _credentialsKey);
    await _prefs.remove(_rememberCredentialsKey);
    _savedCredentials = null;
  }

  Future<void> _saveSession() async {
    if (_accessToken != null && _userId != null && _serverUrl != null) {
      await _secureStorage.write(key: _accessTokenKey, value: _accessToken!);
      await _secureStorage.write(key: _userIdKey, value: _userId!);
      await _prefs.setString(_serverUrlKey, _serverUrl!);
    }
  }

  Future<void> _loadSavedSession() async {
    try {
      _accessToken = await _secureStorage.read(key: _accessTokenKey);
      _userId = await _secureStorage.read(key: _userIdKey);
      _serverUrl = _prefs.getString(_serverUrlKey);
    } catch (e) {
      // Ignore errors when loading session
    }
  }

  String _getAuthorizationHeader([String? token]) {
    final authToken = token ?? '';
    return 'MediaBrowser Client="$_client", Device="$_device", DeviceId="$_deviceId", Version="$_version"${token != null ? ', Token="$authToken"' : ''}';
  }

  String _cleanServerUrl(String url) {
    String cleanUrl = url.trim();

    if (cleanUrl.endsWith('/')) {
      cleanUrl = cleanUrl.substring(0, cleanUrl.length - 1);
    }

    if (!cleanUrl.startsWith('http://') && !cleanUrl.startsWith('https://')) {
      cleanUrl = 'https://$cleanUrl';
    }

    return cleanUrl;
  }

  Future<bool> checkConnection() async {
    if (!isLoggedIn) return false;

    try {
      final response = await http
          .get(Uri.parse('$_serverUrl/System/Info'), headers: getAuthHeaders())
          .timeout(const Duration(seconds: 10));

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  String? getUserAvatarUrl() {
    if (_currentUser?.primaryImageTag == null ||
        _serverUrl == null ||
        _userId == null) {
      return null;
    }

    return '$_serverUrl/Users/$_userId/Images/Primary?tag=${_currentUser!.primaryImageTag}';
  }
}
