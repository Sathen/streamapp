import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/home_screen_provider.dart';
import 'media_section.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<HomeScreenProvider>();

    return FutureBuilder(
      future: provider.initializeData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: Center(child: Text('Error: ${snapshot.error}')),
          );
        }

        return Scaffold(
          appBar: _buildAppBar(context),
          body: _buildBody(context.watch<HomeScreenProvider>()),
          bottomNavigationBar: _buildBottomNavigationBar(context),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      title: const Text('Streamyfin'),
      actions: [
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: () => context.push('/search'),
        ),
        IconButton(
          icon: const Icon(Icons.logout),
          onPressed: () => context.read<AuthProvider>().logout(),
        ),
      ],
    );
  }

  Widget _buildBody(HomeScreenProvider provider) {
    return CustomScrollView(
      slivers: [
        MediaSection(
          title: 'Continue Watching',
          items: provider.continueWatching,
          showProgress: true,
        ),
        MediaSection(title: 'Recently Added', items: provider.recentlyAdded),
        ...provider.libraries.entries.map(
          (entry) => MediaSection(title: entry.key, items: entry.value),
        ),
      ],
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
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
        BottomNavigationBarItem(icon: Icon(Icons.file_download), label: 'Downloads'),
        BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
      ],
    );
  }
}
