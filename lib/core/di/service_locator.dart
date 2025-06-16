import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/datasources/remote/client/auth_jellyfin_server.dart';
import '../../data/datasources/remote/client/online_server_api.dart';

// Your existing services
import '../../data/datasources/remote/services/media_service.dart';
import '../../data/datasources/remote/services/playback_service.dart';
import '../../presentation/providers/download/download_provider.dart';

// Your existing providers
import '../../presentation/providers/media/media_provider.dart';
import '../../presentation/providers/media_details/media_details_provider.dart';
import '../../presentation/providers/search/search_provider.dart';

final GetIt sl = GetIt.instance; // Service Locator

/// Initialize all dependencies
Future<void> initializeDependencies() async {
  // ===========================
  // External Dependencies
  // ===========================

  // SharedPreferences
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton<SharedPreferences>(() => sharedPreferences);

  // ===========================
  // Services (Your existing ones)
  // ===========================

  // OnlineServerApi - Singleton since it's stateless
  sl.registerLazySingleton<OnlineServerApi>(() => OnlineServerApi());

  // AuthService - Singleton and initialize it
  sl.registerLazySingleton<AuthService>(() {
    final authService = AuthService();
    authService.init();
    return authService;
  });

  // MediaService - Factory because it might need different configurations
  sl.registerFactory<MediaService>(
    () => MediaService(
      null, // serverUrl - will be set when needed
      null, // userId - will be set when needed
      null, // headers - will be set when needed
    ),
  );

  // PlaybackService - Factory since it needs dynamic serverUrl and headers
  sl.registerFactory<PlaybackService>(
    () => PlaybackService(
      serverUrl: '', // Will be injected when needed
      headers: {}, // Will be injected when needed
    ),
  );

  // ===========================
  // Providers (Your existing ones)
  // ===========================

  // MediaProvider - Factory since it holds state
  sl.registerFactory<MediaProvider>(() => MediaProvider());

  // SearchProvider - Factory since it holds state
  sl.registerFactory<SearchProvider>(() => SearchProvider());

  // MediaDetailsProvider - Factory since it holds state
  sl.registerFactory<MediaDetailsProvider>(() => MediaDetailsProvider());

  // DownloadProvider - Singleton since downloads should persist
  sl.registerLazySingleton<DownloadProvider>(() {
    final provider = DownloadProvider();
    provider.initialize(); // Initialize if needed
    return provider;
  });
}

/// Get a service/provider from the service locator
T get<T extends Object>() => sl.get<T>();

/// Check if a service is registered
bool isRegistered<T extends Object>() => sl.isRegistered<T>();

/// Reset all dependencies (useful for testing)
Future<void> resetDependencies() async {
  await sl.reset();
}
