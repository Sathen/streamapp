import 'package:flutter/foundation.dart';
import '../client/auth_jellyfin_server.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;
  bool _isAuthenticated = false;
  bool _isInitialized = false;
  String? _serverUrl;
  String? _userId;
  Map<String, String>? _authHeaders;

  AuthProvider(this._authService) {
    _checkAuthStatus();
  }

  bool get isAuthenticated => _isAuthenticated;
  bool get isInitialized => _isInitialized;
  String? get serverUrl => _serverUrl;
  String? get userId => _userId;
  Map<String, String>? get authHeaders => _authHeaders;

  Future<void> _checkAuthStatus() async {
    try {
      _isAuthenticated = await _authService.isLoggedIn();
      if (_isAuthenticated) {
        _serverUrl = await _authService.getServerUrl();
        _userId = await _authService.getUserId();
        _authHeaders = await _authService.getAuthHeaders();
      }
    } catch (e) {
      _isAuthenticated = false;
      _serverUrl = null;
      _userId = null;
      _authHeaders = null;
    } finally {
      _isInitialized = true;
      notifyListeners();
    }
  }

  Future<bool> login(String serverUrl, String username, String password) async {
    try {
      final result = await _authService.login(serverUrl, username, password);
      if (result['success'] == true) {
        _isAuthenticated = true;
        await _updateUserData();
        _isInitialized = true;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _resetState();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    _isAuthenticated = false;
    _serverUrl = null;
    notifyListeners();
  }

  Future<void> _updateUserData() async {
    _serverUrl = await _authService.getServerUrl();
    _userId = await _authService.getUserId();
    _authHeaders = await _authService.getAuthHeaders();
  }

  void _resetState() {
    _isAuthenticated = false;
    _serverUrl = null;
    _userId = null;
    _authHeaders = null;
    _isInitialized = true;
  }
}