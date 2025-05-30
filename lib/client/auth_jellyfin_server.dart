import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthException implements Exception {
  final String message;
  AuthException(this.message);
}

class AuthService {
  static const String client = "YourAppName";
  static const String device = "YourDevice";
  static const String deviceId = "UniqueDeviceId";
  static const String version = "1.0.0";

  late SharedPreferences _prefs;
  final _secureStorage = const FlutterSecureStorage();
  
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  Future<bool> isLoggedIn() async {
    try {
      final token = await _secureStorage.read(key: 'accessToken');
      final userId = await _secureStorage.read(key: 'userId');
      return token != null && userId != null;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>> login(String serverUrl, String username, String password) async {
    if (serverUrl.isEmpty || username.isEmpty || password.isEmpty) {
      throw AuthException('Server URL, username and password are required');
    }

    try {
      final url = Uri.parse('$serverUrl/Users/AuthenticateByName');
      
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'MediaBrowser Client="$client", Device="$device", DeviceId="$deviceId", Version="$version"',
      };

      final body = jsonEncode({
        'Username': username,
        'Pw': password,
      });

      final response = await http.post(url, headers: headers, body: body)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await _saveToken(data['AccessToken'], data['User']['Id'], serverUrl);
        return {'success': true};
      } else {
        final error = jsonDecode(response.body);
        throw AuthException(error['Message'] ?? 'Authentication failed');
      }
    } catch (e) {
      throw AuthException('Login failed: ${e.toString()}');
    }
  }

  Future<void> _saveToken(String token, String userId, String serverUrl) async {
    await _secureStorage.write(key: 'accessToken', value: token);
    await _secureStorage.write(key: 'userId', value: userId);
    await _prefs.setString('serverUrl', serverUrl);
  }

  Future<void> logout() async {
    await _secureStorage.deleteAll();
    await _prefs.clear();
  }

  Future<Map<String, String>> getAuthHeaders() async {
    final token = await _secureStorage.read(key: 'accessToken');
    if (token == null) throw AuthException('No authentication token found');
    
    return {
      'Authorization': 'MediaBrowser Token="$token", Client="$client", Device="$device", DeviceId="$deviceId", Version="$version"'
    };
  }

  Future<String> getUserId() async {
    final userId = await _secureStorage.read(key: 'userId');
    if (userId == null) throw AuthException('No user ID found');
    return userId;
  }

  Future<String> getServerUrl() async {
    final serverUrl = _prefs.getString('serverUrl');
    if (serverUrl == null) throw AuthException('No server URL found');
    return serverUrl;
  }

  Future<bool> refresh(String username, String password) async {
    try {
      final serverUrl = await getServerUrl();
      final result = await login(serverUrl, username, password);
      return result['success'];
    } catch (e) {
      return false;
    }
  }
}

