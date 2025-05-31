import 'dart:convert';

import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:stream_flutter/providers/auth_provider.dart';
import 'package:stream_flutter/providers/home_screen_provider.dart';
import 'package:stream_flutter/providers/search_provider.dart';
import 'package:stream_flutter/screens/home_screen.dart';
import 'package:stream_flutter/screens/media_detail_screen.dart';
import 'package:stream_flutter/screens/online_media_details_screen.dart';
import 'package:stream_flutter/screens/search_screen.dart';
import 'package:stream_flutter/screens/tmdb_media_details_screen.dart';
import 'package:stream_flutter/services/media_service.dart';

import 'models/tmdb_models.dart';

GoRouter createRouter(AuthProvider authProvider) {
  // var loginR = GoRoute(path: '/login', builder: (context, state) => LoginScreen());
  var homeR = GoRoute(
        path: '/',
        builder: (context, state) {
          return ChangeNotifierProvider(
            create:
                (_) {
                  final provider = HomeScreenProvider(
                    mediaService: MediaService(authProvider.serverUrl, authProvider.userId, authProvider.authHeaders),
                  );
                  provider.initializeData();
                  return provider;
                },
            child: const HomeScreen(),
          );
        },
      );
  var searchR =GoRoute(
    path: '/search',
    builder: (context, state) {
      return ChangeNotifierProvider(
        create: (_) => SearchProvider(),
        child: const SearchScreen(),
      );
    },
  );
  var mediaDetails = GoRoute(
        path: '/media/:id',
        builder:
            (context, state) =>
                JellyfinMediaDetailScreen(mediaId: state.pathParameters['id']!),
      );
  var mediaOnlineDetails = GoRoute(
        path: '/media/online/:id',
        builder:
            (context, state) {
              String pathParameter = state.pathParameters['id']!;
              var path = Utf8Decoder().convert(Base64Decoder().convert(pathParameter));
              return OnlineMediaDetailScreen(path: path);
            },
      );
  var mediaTmdbDetails = GoRoute(
        path: '/media/tmdb/:type/:id',
        builder:
            (context, state) {
              var type = MediaType.values.byName(state.pathParameters['type']!);
              var id = int.parse(state.pathParameters['id']!);
              return MediaDetailsScreen(tmdbId: id, type: type,);
            },
      );

  return GoRouter(
    refreshListenable: authProvider,
    initialLocation: '/',
    debugLogDiagnostics: true,
    routes: [
      // loginR,
      homeR,
      mediaDetails,
      searchR,
      mediaOnlineDetails,
      mediaTmdbDetails
    ],
  );
}
