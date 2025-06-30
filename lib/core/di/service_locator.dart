import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stream_flutter/data/datasources/remote/client/jellyfin_auth_client.dart';
import 'package:stream_flutter/data/datasources/remote/services/jellyfin_service.dart';

import '../../data/datasources/remote/client/online_server_api.dart';
import '../../data/datasources/remote/client/tmdb_client.dart';
import '../utils/logger.dart';

final GetIt sl = GetIt.instance;

Future<void> initializeDependencies() async {
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton<SharedPreferences>(() => sharedPreferences);

  sl.registerLazySingleton<AppLogger>(() => AppLogger());

  sl.registerLazySingleton<OnlineServerApi>(() => OnlineServerApi());

  sl.registerFactory<TmdbClient>(() => TmdbClient());

  sl.registerLazySingleton<JellyfinAuthClient>(() {
    final authService = JellyfinAuthClient();
    authService.init();
    return authService;
  });

  sl.registerLazySingleton<JellyfinService>(() {
    return JellyfinService(get<JellyfinAuthClient>());
  });
}

T get<T extends Object>() => sl.get<T>();

bool isRegistered<T extends Object>() => sl.isRegistered<T>();

Future<void> resetDependencies() async {
  await sl.reset();
}
