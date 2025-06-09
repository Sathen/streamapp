import 'dart:convert';

import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:stream_flutter/models/search_result.dart';
import 'package:stream_flutter/providers/auth_provider.dart';
import 'package:stream_flutter/providers/home_screen_provider.dart';
import 'package:stream_flutter/providers/search_provider.dart';
import 'package:stream_flutter/screens/downloads_screen.dart';
import 'package:stream_flutter/screens/home_screen.dart';
import 'package:stream_flutter/screens/online_media_details_screen.dart';
import 'package:stream_flutter/screens/search/search_screen.dart';
import 'package:stream_flutter/screens/tmdb_media_details_screen.dart';
import 'package:stream_flutter/services/media_service.dart';

import 'models/tmdb_models.dart';

GoRouter createRouter(AuthProvider authProvider) {
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
  var mediaOnlineDetails = GoRoute(
        path: '/media/online',
        builder:
            (context, state) {
              SearchItem item = state.extra as SearchItem;
              return OnlineMediaDetailScreen(searchItem: item);
            },
      );
  var downloadsScreen = GoRoute(
        path: '/downloads',
        builder:
            (context, state) {
              return DownloadsScreen();
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
      homeR,
      searchR,
      mediaOnlineDetails,
      mediaTmdbDetails,
      downloadsScreen
    ],
  );
}
