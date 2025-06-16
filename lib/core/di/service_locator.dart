import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/datasources/remote/client/auth_jellyfin_server.dart';
import '../../data/datasources/remote/client/online_server_api.dart';
// ONLY import services - NO providers
import '../../data/datasources/remote/services/media_service.dart';
import '../../data/datasources/remote/services/playback_service.dart';
// Core utilities
import '../utils/logger.dart';

final GetIt sl = GetIt.instance;

/// Initialize ONLY services and utilities - NO providers
Future<void> initializeDependencies() async {
  // ===========================
  // External Dependencies
  // ===========================
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton<SharedPreferences>(() => sharedPreferences);

  // ===========================
  // Core Utilities
  // ===========================
  sl.registerLazySingleton<AppLogger>(() => AppLogger());

  // ===========================
  // Services ONLY
  // ===========================

  // OnlineServerApi - Singleton (stateless)
  sl.registerLazySingleton<OnlineServerApi>(() => OnlineServerApi());

  // AuthService - Singleton and initialize
  sl.registerLazySingleton<AuthService>(() {
    final authService = AuthService();
    authService.init();
    return authService;
  });

  // MediaService - Factory (might need different configurations)
  sl.registerFactory<MediaService>(
    () => MediaService(
      null, // Will be configured when needed
      null,
      null,
    ),
  );

  // PlaybackService - Factory (needs dynamic configuration)
  sl.registerFactory<PlaybackService>(
    () => PlaybackService(
      serverUrl: '', // Will be configured when needed
      headers: {},
    ),
  );

  // NOTE: NO providers registered here!
  // Providers will be managed by Flutter's Provider system
}

/// Get a service from the service locator
T get<T extends Object>() => sl.get<T>();

/// Check if a service is registered
bool isRegistered<T extends Object>() => sl.isRegistered<T>();

/// Reset all dependencies (useful for testing)
Future<void> resetDependencies() async {
  await sl.reset();
}
