import 'package:flutter/material.dart';

// Routing
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:stream_flutter/presentation/providers/media_details/media_details_provider.dart';
import 'package:stream_flutter/presentation/screens/downloads/downloads_screen.dart';
import 'package:stream_flutter/presentation/screens/media_details/online_media_details_screen.dart';
import 'package:stream_flutter/presentation/screens/media_details/tmdb_media_details_screen.dart';
import 'package:stream_flutter/presentation/screens/search/search_screen.dart';

// Theme
import 'core/theme/app_theme.dart';

// New providers
import 'data/models/models/search_result.dart';
import 'data/models/models/tmdb_models.dart';
import 'presentation/providers/download/download_provider.dart';
import 'presentation/providers/media/media_provider.dart';
import 'presentation/providers/search/search_provider.dart';

// Screens
import 'presentation/screens/home/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize download provider
  final downloadProvider = DownloadProvider();
  await downloadProvider.initialize();

  runApp(MyApp(downloadProvider: downloadProvider));
}

class MyApp extends StatelessWidget {
  final DownloadProvider downloadProvider;

  MyApp({super.key, required this.downloadProvider});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Media Provider
        ChangeNotifierProvider<MediaProvider>(create: (_) => MediaProvider()),

        // Media Details Provider - ADD THIS!
        ChangeNotifierProvider<MediaDetailsProvider>(create: (_) => MediaDetailsProvider()),

        // Search Provider
        ChangeNotifierProvider<SearchProvider>(create: (_) => SearchProvider()),

        // Download Provider - Make sure this is the correct class name
        ChangeNotifierProvider<DownloadProvider>.value(value: downloadProvider),
      ],
      // Use builder to ensure providers are available to GoRouter
      builder: (context, child) {
        return MaterialApp.router(
          title: 'Streaming App',
          theme: AppTheme.darkTheme,
          routerConfig: _buildRouter(context),
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }

  GoRouter _buildRouter(BuildContext context) {
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
