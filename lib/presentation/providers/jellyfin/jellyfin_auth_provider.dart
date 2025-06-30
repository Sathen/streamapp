import 'package:stream_flutter/data/datasources/remote/client/jellyfin_auth_client.dart';

import '../../../core/di/service_locator.dart';
import '../../../core/utils/result.dart';
import '../../../data/models/models/jellyfin_models.dart';
import '../base/base_provider.dart';

class JellyfinAuthProvider extends BaseProvider {
  final JellyfinAuthClient _authService = get<JellyfinAuthClient>();

  // ===========================
  // AUTHENTICATION STATE ONLY
  // ===========================

  bool _isInitialized = false;
  bool _isLoggingIn = false;
  bool _isLoggingOut = false;
  String? _lastLoginError;
  String? _connectionTestResult;

  // ===========================
  // GETTERS
  // ===========================

  // Auth state
  bool get isLoggedIn => _authService.isLoggedIn;

  bool get isInitialized => _isInitialized;

  bool get isLoggingIn => _isLoggingIn;

  bool get isLoggingOut => _isLoggingOut;

  String? get lastLoginError => _lastLoginError;

  String? get connectionTestResult => _connectionTestResult;

  // User info
  JellyfinUser? get currentUser => _authService.currentUser;

  String? get serverUrl => _authService.serverUrl;

  JellyfinCredentials? get savedCredentials => _authService.savedCredentials;

  String? get userAvatarUrl => _authService.getUserAvatarUrl();

  // Computed properties
  String get userDisplayName =>
      _authService.currentUser?.name ?? 'Unknown User';

  bool get hasServerConfigured => _authService.serverUrl != null;

  bool get hasCredentialsSaved => _authService.savedCredentials != null;

  // ===========================
  // INITIALIZATION
  // ===========================

  Future<void> initialize() async {
    if (_isInitialized) return;

    await executeOperation(() async {
      setLoading(true);

      // Initialize auth service (loads saved credentials)
      await _authService.init();

      // Try auto-login if credentials are saved
      if (_authService.savedCredentials != null && !_authService.isLoggedIn) {
        await _attemptAutoLogin();
      }

      _isInitialized = true;
      _clearErrors();
      safeNotifyListeners();
    }, errorPrefix: 'Failed to initialize authentication');
  }

  // ===========================
  // LOGIN OPERATIONS
  // ===========================

  /// Test server connection without authentication
  Future<bool> testConnection(String serverUrl) async {
    final result =  await executeOperation(() async {
      _connectionTestResult = null;
      safeNotifyListeners();

      final isConnected = await _authService.testServerConnection(serverUrl);

      if (isConnected) {
        _connectionTestResult = 'Connection successful!';

        // Try to get server info
        final serverInfo = await _authService.getServerInfo(serverUrl);
        if (serverInfo != null) {
          final serverName = serverInfo['ServerName'] ?? 'Unknown';
          final version = serverInfo['Version'] ?? 'Unknown';
          _connectionTestResult = 'Connected to $serverName (v$version)';
        }
      } else {
        _connectionTestResult = 'Cannot connect to server';
      }

      safeNotifyListeners();
      return isConnected;
    }, errorPrefix: 'Connection test failed');

    return result.getOrElse(false);
  }

  /// Login with credentials
  Future<bool> login({
    required String serverUrl,
    required String username,
    required String password,
    bool rememberCredentials = false,
  }) async {
     var result = await executeOperation(() async {
      _isLoggingIn = true;
      _lastLoginError = null;
      _connectionTestResult = null;
      safeNotifyListeners();

      try {
        final success = await _authService.login(
          serverUrl: serverUrl,
          username: username,
          password: password,
          rememberCredentials: rememberCredentials,
        );

        if (success) {
          _clearErrors();
        }

        return success;
      } on JellyfinAuthException catch (e) {
        _lastLoginError = e.message;
        return false;
      } catch (e) {
        _lastLoginError = 'Login failed: ${e.toString()}';
        return false;
      } finally {
        _isLoggingIn = false;
        safeNotifyListeners();
      }
    }, errorPrefix: 'Login operation failed');
     return result.getOrElse(false);
  }

  /// Auto-login with saved credentials
  Future<bool> autoLogin() async {
    if (!hasCredentialsSaved || isLoggedIn) return isLoggedIn;

    final result = await executeOperation(() async {
      _lastLoginError = null;
      safeNotifyListeners();

      try {
        final success = await _authService.autoLogin();

        if (success) {
          _clearErrors();
        } else {
          _lastLoginError = 'Auto-login failed with saved credentials';
        }

        return success;
      } catch (e) {
        _lastLoginError = 'Auto-login error: ${e.toString()}';
        return false;
      } finally {
        safeNotifyListeners();
      }
    }, errorPrefix: 'Auto-login failed');
    return result.getOrElse(false);
  }

  /// Refresh authentication token
  Future<bool> refreshAuth() async {
    if (!isLoggedIn) return false;

    final result = await executeOperation(() async {
      try {
        final success = await _authService.refreshToken();

        if (!success) {
          _lastLoginError = 'Session expired. Please login again.';
        }

        return success;
      } catch (e) {
        _lastLoginError = 'Authentication refresh failed';
        return false;
      } finally {
        safeNotifyListeners();
      }
    }, errorPrefix: 'Token refresh failed');

    return result.getOrElse(false);
  }

  // ===========================
  // LOGOUT OPERATIONS
  // ===========================

  /// Logout and optionally clear saved credentials
  Future<void> logout({bool clearCredentials = false}) async {
    await executeOperation(() async {
      _isLoggingOut = true;
      safeNotifyListeners();

      try {
        await _authService.logout(clearCredentials: clearCredentials);
        _clearErrors();
      } finally {
        _isLoggingOut = false;
        safeNotifyListeners();
      }
    }, errorPrefix: 'Logout failed');
  }

  /// Clear only saved credentials (keep current session)
  Future<void> clearSavedCredentials() async {
    await executeOperation(() async {
      await _authService.clearSavedCredentials();
      safeNotifyListeners();
    }, errorPrefix: 'Failed to clear credentials');
  }

  // ===========================
  // CONNECTION MONITORING
  // ===========================

  /// Check if current connection is still valid
  Future<bool> checkConnection() async {
    if (!isLoggedIn) return false;

    try {
      return await _authService.checkConnection();
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>?> getServerInfo() async {
    if (serverUrl == null) return null;

    try {
      return await _authService.getServerInfo(serverUrl!);
    } catch (e) {
      return null;
    }
  }

  // ===========================
  // UI HELPER METHODS
  // ===========================

  /// Get connection status message for UI
  String getConnectionStatusMessage() {
    if (!isLoggedIn) {
      return _lastLoginError ?? 'Not logged in';
    } else {
      final serverName =
          serverUrl?.split('//').last.split(':').first ?? 'Jellyfin';
      return 'Connected to $serverName';
    }
  }

  /// Get authentication status for UI
  AuthenticationStatus getAuthStatus() {
    if (isLoggingIn) return AuthenticationStatus.loggingIn;
    if (isLoggingOut) return AuthenticationStatus.loggingOut;
    if (isLoggedIn) return AuthenticationStatus.authenticated;
    if (hasCredentialsSaved) return AuthenticationStatus.savedCredentials;
    return AuthenticationStatus.notAuthenticated;
  }

  /// Clear all error states
  void clearErrors() {
    _clearErrors();
    safeNotifyListeners();
  }

  /// Check if login form should show remember credentials toggle
  bool shouldShowRememberCredentials() {
    return !hasCredentialsSaved;
  }

  /// Get suggested server URL from saved credentials
  String? getSuggestedServerUrl() {
    return savedCredentials?.serverUrl;
  }

  /// Get suggested username from saved credentials
  String? getSuggestedUsername() {
    return savedCredentials?.username;
  }

  // ===========================
  // PRIVATE METHODS
  // ===========================

  Future<bool> _attemptAutoLogin() async {
    try {
      return await _authService.autoLogin();
    } catch (e) {
      // Silent fail for auto-login attempts
      return false;
    }
  }

  void _clearErrors() {
    _lastLoginError = null;
    _connectionTestResult = null;
  }
}

// ===========================
// ENUMS & MODELS
// ===========================

enum AuthenticationStatus {
  notAuthenticated,
  savedCredentials,
  loggingIn,
  authenticated,
  loggingOut,
}
