import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

// Models
import 'core/di/service_locator.dart';
import 'core/theme/app_theme.dart';
import 'data/models/models/search_result.dart';
import 'data/models/models/tmdb_models.dart';
import 'presentation/providers/download/download_provider.dart';
import 'presentation/providers/media/media_provider.dart';
import 'presentation/providers/media_details/media_details_provider.dart';
import 'presentation/providers/search/search_provider.dart';
import 'presentation/screens/downloads/downloads_screen.dart';
// Your existing screens
import 'presentation/screens/home/home_screen.dart';
import 'presentation/screens/media_details/online_media_details_screen.dart';
import 'presentation/screens/media_details/tmdb_media_details_screen.dart';
import 'presentation/screens/search/search_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize dependencies BEFORE running the app
  await initializeDependencies();

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<MediaProvider>(
          create: (_) => MediaProvider(),
        ),
        ChangeNotifierProvider<SearchProvider>(
          create: (_) => SearchProvider(),
        ),
        ChangeNotifierProvider<MediaDetailsProvider>(
          create: (_) => MediaDetailsProvider(),
        ),
        ChangeNotifierProvider<DownloadProvider>(
          create: (_) => DownloadProvider(), // This one is singleton
        ),
      ],
      child: MaterialApp.router(
        title: 'Streaming App',
        theme: AppTheme.darkTheme,
        routerConfig: _buildRouter(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }

  GoRouter _buildRouter() {
    return GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
        GoRoute(
          path: '/search',
          builder: (context, state) => const SearchScreen(),
        ),
        GoRoute(
          path: '/downloads',
          builder: (context, state) => const DownloadsScreen(),
        ),
        GoRoute(
          path: '/media/tmdb/:type/:id',
          builder: (context, state) {
            final type = state.pathParameters['type']!;
            final id = int.parse(state.pathParameters['id']!);
            return TmdbMediaDetailsScreen(
              tmdbId: id,
              type: type == 'movie' ? MediaType.movie : MediaType.tv,
            );
          },
        ),
        GoRoute(
          path: '/media/online',
          builder: (context, state) {
            final searchItem = state.extra as SearchItem;
            return OnlineMediaDetailsScreen(searchItem: searchItem);
          },
        ),
      ],
    );
  }
}
