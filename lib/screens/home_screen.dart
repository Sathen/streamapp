import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../providers/home_screen_provider.dart';
import 'media_section.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HomeScreenProvider>();

    if (provider.isLoading) {
      return const Scaffold(
        appBar: null,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // TODO: Add error handling from provider if you have an error state there

    return Scaffold(
      appBar: _buildAppBar(context),
      body: _buildBody(provider),
      bottomNavigationBar: _buildBottomNavigationBar(context),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      title: const Text('Streamyfin'),
      actions: [
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: () => context.push('/search'),
        )
      ],
    );
  }

  Widget _buildBody(HomeScreenProvider provider) {
    return RefreshIndicator(
      onRefresh: () => provider.initializeData(),
      child: CustomScrollView(
        slivers: [
          MediaSection(
            title: '🎬 Now Playing Movies',
            items: provider.nowPlayingMovies,
          ),
          MediaSection(title: '🔥 Popular Movies', items: provider.popularMovies),
          MediaSection(title: '⭐ Top Rated Movies', items: provider.topRatedMovies),
          MediaSection(title: '🆕 Newest Movies', items: provider.newestMovies),
          MediaSection(title: '📺 Popular TV Shows', items: provider.popularTV),
          MediaSection(
            title: '🏆 Top Rated TV Shows',
            items: provider.topRatedTV,
          ),
          MediaSection(title: '🗓️ Newest TV Shows', items: provider.newestTV),
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBar(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: 0,
      backgroundColor: Theme.of(context).colorScheme.surface,
      selectedItemColor: Theme.of(context).colorScheme.secondary,
      unselectedItemColor: Colors.white70,
      type: BottomNavigationBarType.fixed,
      onTap: (index) {
        if (index == 0) {
          context.push('/');
        }
        if (index == 1) {
          context.push('/search');
        }
        if (index == 2) {
          context.push('/downloads');
        }
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
        BottomNavigationBarItem(icon: Icon(Icons.download), label: 'Downloads'),
      ],
    );
  }
}
