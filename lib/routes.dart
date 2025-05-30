import 'dart:convert';

import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:stream_flutter/providers/auth_provider.dart';
import 'package:stream_flutter/providers/home_screen_provider.dart';
import 'package:stream_flutter/providers/search_provider.dart';
import 'package:stream_flutter/screens/home_screen.dart';
import 'package:stream_flutter/screens/login_page.dart';
import 'package:stream_flutter/screens/media_detail_screen.dart';
import 'package:stream_flutter/screens/online_media_details_screen.dart';
import 'package:stream_flutter/screens/search_screen.dart';
import 'package:stream_flutter/services/media_service.dart';

GoRouter createRouter(AuthProvider authProvider) {
  var loginR = GoRoute(path: '/login', builder: (context, state) => LoginScreen());
  var homeR = GoRoute(
        path: '/',
        builder: (context, state) {
          return ChangeNotifierProvider(
            create:
                (_) => HomeScreenProvider(
                  mediaService: MediaService(authProvider.serverUrl, authProvider.userId, authProvider.authHeaders),
                ),
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

  return GoRouter(
    refreshListenable: authProvider,
    initialLocation: '/login',
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final isLoginRoute = state.matchedLocation == '/login';

      if (!authProvider.isInitialized) return null;

      if (!authProvider.isAuthenticated && !isLoginRoute) {
        return '/login';
      }

      if (authProvider.isAuthenticated && isLoginRoute) {
        return '/';
      }

      return null;
    },
    routes: [
      loginR,
      homeR,
      mediaDetails,
      searchR,
      mediaOnlineDetails
    ],
  );
}
