import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../providers/home_screen_provider.dart'; // Assuming this path is correct
import 'media_section.dart'; // Assuming this path is correct

// Enum to represent the selected display category
enum DisplayCategory { movies, tv }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // State variable to keep track of the selected category
  DisplayCategory _selectedCategory =
      DisplayCategory.movies; // Default to movies

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HomeScreenProvider>();

    if (provider.isLoading) {
      return const Scaffold(
        appBar: null, // Keep AppBar consistent or hide during initial full load
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: _buildAppBar(context),
      body: _buildBody(provider),
      bottomNavigationBar: _buildBottomNavigationBar(context),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      // Add the SegmentedButton as the bottom part of the AppBar
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(
          TextSelectionToolbar.kToolbarContentDistanceBelow,
        ),
        // Standard height for AppBar bottom
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: SegmentedButton<DisplayCategory>(
            segments: const <ButtonSegment<DisplayCategory>>[
              ButtonSegment<DisplayCategory>(
                value: DisplayCategory.movies,
                label: Text('Movies'),
                icon: Icon(Icons.movie),
              ),
              ButtonSegment<DisplayCategory>(
                value: DisplayCategory.tv,
                label: Text('TV Shows'),
                icon: Icon(Icons.tv),
              ),
            ],
            selected: <DisplayCategory>{_selectedCategory},
            onSelectionChanged: (Set<DisplayCategory> newSelection) {
              setState(() {
                _selectedCategory = newSelection.first;
              });
            },
            style: SegmentedButton.styleFrom(
              // UI Improvement: Customized SegmentedButton style
              backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
              foregroundColor:
                  Theme.of(
                    context,
                  ).colorScheme.onSurfaceVariant, // Text color for unselected
              selectedForegroundColor:
                  Theme.of(
                    context,
                  ).colorScheme.onPrimary, // Text color for selected
              selectedBackgroundColor:
                  Theme.of(
                    context,
                  ).colorScheme.primary, // Background for selected
              // shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), // Optional: more rounded
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(HomeScreenProvider provider) {
    List<Widget> slivers = _getSliversForCategory(provider, _selectedCategory);

    return RefreshIndicator(
      onRefresh: () async {
        await provider.initializeData();
        if (mounted) {
          setState(() {});
        }
      },
      child: CustomScrollView(
        // UI Improvement suggestion (apply in MediaSection for card list):
        // physics: const BouncingScrollPhysics(),
        slivers: slivers,
      ),
    );
  }

  List<Widget> _getSliversForCategory(
    HomeScreenProvider provider,
    DisplayCategory category,
  ) {
    if (category == DisplayCategory.movies) {
      return [
        if (provider.nowPlayingMovies.isNotEmpty)
          MediaSection(
            title: '🎬 Now Playing Movies',
            items: provider.nowPlayingMovies,
          ),
        if (provider.popularMovies.isNotEmpty)
          MediaSection(
            title: '🔥 Popular Movies',
            items: provider.popularMovies,
          ),
        if (provider.topRatedMovies.isNotEmpty)
          MediaSection(
            title: '⭐ Top Rated Movies',
            items: provider.topRatedMovies,
          ),
        if (provider.newestMovies.isNotEmpty)
          MediaSection(title: '🆕 Newest Movies', items: provider.newestMovies),
      ];
    } else if (category == DisplayCategory.tv) {
      return [
        if (provider.popularTV.isNotEmpty)
          MediaSection(title: '📺 Popular TV Shows', items: provider.popularTV),
        if (provider.topRatedTV.isNotEmpty)
          MediaSection(
            title: '🏆 Top Rated TV Shows',
            items: provider.topRatedTV,
          ),
        if (provider.newestTV.isNotEmpty)
          MediaSection(title: '🗓️ Newest TV Shows', items: provider.newestTV),
      ];
    }
    return [];
  }

  Widget _buildBottomNavigationBar(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: 0,
      backgroundColor: Theme.of(context).colorScheme.surface,
      selectedItemColor: Theme.of(context).colorScheme.secondary,
      // UI Improvement: Consistent unselected item color
      unselectedItemColor: Theme.of(
        context,
      ).colorScheme.onSurface.withOpacity(0.7),
      type: BottomNavigationBarType.fixed,
      onTap: (index) {
        if (index == 0) {
          // context.go('/'); // Or context.push('/');
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
