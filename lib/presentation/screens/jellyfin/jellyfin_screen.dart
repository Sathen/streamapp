import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:stream_flutter/data/models/models/jellyfin_models.dart';
import 'package:stream_flutter/presentation/screens/jellyfin/widgets/jellyfin_media_card.dart';
import 'package:stream_flutter/presentation/screens/video_player/video_player_screen.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/models/tmdb_models.dart';
import '../../providers/jellyfin/jellyfin_auth_provider.dart';
import '../../providers/jellyfin/jellyfin_data_provider.dart';

class JellyfinScreen extends StatefulWidget {
  const JellyfinScreen({Key? key}) : super(key: key);

  @override
  State<JellyfinScreen> createState() => _JellyfinScreenState();
}

class _JellyfinScreenState extends State<JellyfinScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    // Load data if authenticated
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<JellyfinAuthProvider>();
      final dataProvider = context.read<JellyfinDataProvider>();

      if (authProvider.isLoggedIn && !dataProvider.hasAnyContent) {
        dataProvider.loadAllContent();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<JellyfinAuthProvider, JellyfinDataProvider>(
      builder: (context, authProvider, dataProvider, child) {
        if (!authProvider.isLoggedIn) {
          return _buildNotLoggedInState();
        }

        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.background,
          body: NestedScrollView(
            controller: _scrollController,
            headerSliverBuilder:
                (context, innerBoxIsScrolled) => [
                  _buildAppBar(authProvider, dataProvider),
                  _buildTabBar(),
                ],
            body: TabBarView(
              controller: _tabController,
              children: [
                _buildHomeTab(dataProvider),
                _buildLibrariesTab(dataProvider),
              ],
            ),
          ),
          floatingActionButton: _buildFloatingActionButton(dataProvider),
        );
      },
    );
  }

  Widget _buildAppBar(
    JellyfinAuthProvider authProvider,
    JellyfinDataProvider dataProvider,
  ) {
    final theme = Theme.of(context);

    return SliverAppBar(
      expandedHeight: 120.0,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: theme.colorScheme.surface,
      flexibleSpace: FlexibleSpaceBar(
        title: Row(
          children: [
            Icon(
              Icons.video_library_rounded,
              color: AppTheme.accentBlue,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              'Jellyfin',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppTheme.accentBlue.withOpacity(0.1),
                theme.colorScheme.surface,
              ],
            ),
          ),
        ),
      ),
      actions: [
        // Connection status
        Container(
          margin: const EdgeInsets.only(right: 8),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color:
                      dataProvider.canLoadData
                          ? AppTheme.successColor
                          : AppTheme.warningColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                dataProvider.canLoadData ? 'Connected' : 'Offline',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),

        // User avatar
        if (authProvider.userAvatarUrl != null)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: CircleAvatar(
              radius: 16,
              backgroundImage: NetworkImage(authProvider.userAvatarUrl!),
              onBackgroundImageError: (exception, stackTrace) {},
              child:
                  authProvider.userAvatarUrl == null
                      ? Icon(Icons.person_rounded, size: 16)
                      : null,
            ),
          ),

        // Settings button
        IconButton(
          onPressed: () => context.go('/settings/jellyfin'),
          icon: Icon(Icons.settings_rounded),
          tooltip: 'Jellyfin Settings',
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _SliverTabBarDelegate(
        TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Home', icon: Icon(Icons.home_rounded, size: 20)),
            Tab(
              text: 'Libraries',
              icon: Icon(Icons.library_books_rounded, size: 20),
            ),
          ],
          indicatorColor: AppTheme.accentBlue,
          labelColor: Theme.of(context).colorScheme.onSurface,
          unselectedLabelColor: Theme.of(
            context,
          ).colorScheme.onSurface.withOpacity(0.6),
        ),
      ),
    );
  }

  Widget _buildHomeTab(JellyfinDataProvider dataProvider) {
    return RefreshIndicator(
      onRefresh: () => dataProvider.refreshAll(),
      color: AppTheme.accentBlue,
      child: CustomScrollView(
        slivers: [
          // Continue Watching
          if (dataProvider.continueWatching.isNotEmpty)
            _buildHorizontalSection(
              'Continue Watching',
              dataProvider.continueWatching,
              showProgress: true,
              isLoading: dataProvider.isLoadingContinueWatching,
              error: dataProvider.continueWatchingError,
              onRefresh: () => dataProvider.loadContinueWatching(force: true),
            ),

          // Recently Added
          if (dataProvider.recentlyAdded.isNotEmpty)
            _buildHorizontalSection(
              'Recently Added',
              dataProvider.recentlyAdded,
              isLoading: dataProvider.isLoadingRecentlyAdded,
              error: dataProvider.recentlyAddedError,
              onRefresh: () => dataProvider.loadRecentlyAdded(force: true),
            ),

          // Next Up Episodes
          if (dataProvider.nextUpEpisodes.isNotEmpty)
            _buildHorizontalSection(
              'Next Up',
              dataProvider.nextUpEpisodes,
              isLoading: dataProvider.isLoadingNextUp,
            ),

          // Bottom padding
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildLibrariesTab(JellyfinDataProvider dataProvider) {
    final libraries = dataProvider.libraries;

    if (dataProvider.isLoadingLibraries && libraries.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (libraries.isEmpty) {
      return _buildEmptyState(
        icon: Icons.library_books_outlined,
        title: 'No Libraries Found',
        subtitle: 'Your Jellyfin libraries will appear here',
        onRetry: () => dataProvider.loadLibraries(force: true),
      );
    }

    return RefreshIndicator(
      onRefresh: () => dataProvider.loadLibraries(force: true),
      color: AppTheme.accentBlue,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: libraries.length,
        itemBuilder: (context, index) {
          final libraryName = libraries.keys.elementAt(index);
          final libraryItems = libraries[libraryName]!;

          return _buildLibraryCard(libraryName, libraryItems, dataProvider);
        },
      ),
    );
  }

  Widget _buildHorizontalSection(
      String title,
      List<JellyfinMediaItem> items, {
        bool showProgress = false,
        bool isLoading = false,
        String? error,
        VoidCallback? onRefresh,
      }) {
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header - matching MediaSection style
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        height: 3,
                        width: 40,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Theme.of(context).colorScheme.primary,
                              Theme.of(context).colorScheme.secondary,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ],
                  ),
                ),

                if (isLoading)
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),

                if (error != null && onRefresh != null)
                  TextButton.icon(
                    onPressed: onRefresh,
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('Retry'),
                    style: TextButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          if (error != null)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.errorColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.errorColor.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: AppTheme.errorColor,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      error,
                      style: TextStyle(
                        color: AppTheme.errorColor,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
          // Media List - matching MediaSection dimensions
            SizedBox(
              height: 280, // Same as MediaSection
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8), // Same as MediaSection
                itemCount: items.length,
                itemBuilder: (context, index) {
                  return TweenAnimationBuilder<double>(
                    duration: Duration(milliseconds: 300 + (index * 100)),
                    tween: Tween(begin: 0.0, end: 1.0),
                    curve: Curves.elasticOut,
                    builder: (context, value, child) {
                      return Transform.scale(
                        scale: value,
                        child: _buildMediaCard(
                          items[index],
                          context.read<JellyfinDataProvider>(),
                          showProgress: showProgress,
                          index: index,
                        ),
                      );
                    },
                  );
                },
              ),
            ),

          const SizedBox(height: 24), // Same spacing as MediaSection
        ],
      ),
    );
  }

  Widget _buildMediaCard(
      JellyfinMediaItem item,
      JellyfinDataProvider dataProvider, {
        bool showProgress = false,
        int? index,
      }) {
    return Container(
      width: 160, // Same width as MediaSection
      margin: const EdgeInsets.symmetric(horizontal: 8), // Same margin as MediaSection
      child: JellyfinMediaCard(
        item: item,
        dataProvider: dataProvider,
        showProgress: showProgress,
        heroTag: index != null ? 'jellyfin_media_${item.id}_index_$index' : null,
      ),
    );
  }

  Widget _buildLibraryCard(
      String libraryName,
      List<JellyfinMediaItem> items,
      JellyfinDataProvider dataProvider,
      ) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(_getLibraryIcon(libraryName), color: AppTheme.accentBlue),
                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        libraryName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${items.length} items',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),

                IconButton(
                  onPressed: () => _viewLibrary(libraryName, dataProvider),
                  icon: Icon(Icons.arrow_forward_rounded),
                  tooltip: 'View All',
                ),
              ],
            ),
          ),

          if (items.isNotEmpty)
          // Updated library card ListView to match MediaSection
            SizedBox(
              height: 280, // Same height as main sections
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 16), // Consistent padding
                itemCount: items.take(10).length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  return Container(
                    width: 140, // Same width as main sections
                    margin: const EdgeInsets.symmetric(horizontal: 8), // Consistent margin
                    child: JellyfinMediaCard(
                      item: item,
                      dataProvider: dataProvider,
                      heroTag: 'jellyfin_library_${libraryName}_${item.id}_$index',
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRecentActivity(JellyfinDataProvider dataProvider) {
    final recentActivity = dataProvider.getRecentActivity(limit: 10);

    if (recentActivity.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Activity',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          ...recentActivity
              .take(5)
              .map(
                (item) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: theme.colorScheme.outline.withOpacity(0.1),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: _getMediaTypeColor(
                            item.type,
                          ).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          _getMediaTypeIcon(item.type),
                          color: _getMediaTypeColor(item.type),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.name,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              _getMediaTypeDisplay(item.type),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface.withOpacity(
                                  0.6,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      IconButton(
                        onPressed: () => _playItem(item, dataProvider),
                        icon: Icon(Icons.play_arrow_rounded),
                        tooltip: 'Play',
                      ),
                    ],
                  ),
                ),
              ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onRetry,
  }) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(60),
              ),
              child: Icon(
                icon,
                size: 48,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),

            Text(
              title,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            Text(
              subtitle,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),

            if (onRetry != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: Icon(Icons.refresh_rounded),
                label: Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentBlue,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNotLoggedInState() {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.login_rounded, size: 64, color: AppTheme.accentBlue),
              const SizedBox(height: 24),

              Text(
                'Connect to Jellyfin',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              Text(
                'Please login to access your media library',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              ElevatedButton.icon(
                onPressed: () => context.go('/settings/jellyfin'),
                icon: Icon(Icons.settings_rounded),
                label: Text('Open Settings'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }



  Widget _buildFloatingActionButton(JellyfinDataProvider dataProvider) {
    return FloatingActionButton.extended(
      onPressed: () => dataProvider.refreshAll(),
      backgroundColor: AppTheme.accentBlue,
      label: Text('Refresh'),
      icon: Icon(Icons.refresh_rounded),
    );
  }

  // Helper methods
  Color _getMediaTypeColor(MediaType type) {
    switch (type) {
      case MediaType.movie:
        return AppTheme.accentBlue;
      case MediaType.tv:
        return AppTheme.successColor;
      case MediaType.unknown:
        return AppTheme.mediumEmphasisText;
    }
  }

  String _getMediaTypeDisplay(MediaType type) {
    switch (type) {
      case MediaType.movie:
        return 'Movie';
      case MediaType.tv:
        return 'TV Show';
      case MediaType.unknown:
        return 'Media';
    }
  }

  IconData _getMediaTypeIcon(MediaType type) {
    switch (type) {
      case MediaType.movie:
        return Icons.movie_rounded;
      case MediaType.tv:
        return Icons.tv_rounded;
      case MediaType.unknown:
        return Icons.video_library_rounded;
    }
  }

  IconData _getLibraryIcon(String libraryName) {
    final name = libraryName.toLowerCase();
    if (name.contains('movie')) return Icons.movie_rounded;
    if (name.contains('tv') || name.contains('show')) return Icons.tv_rounded;
    return Icons.folder_rounded;
  }

  VideoPlayerScreen _playItem(
    JellyfinMediaItem item,
    JellyfinDataProvider dataProvider,
  ) {
    // Get stream URL and play the content
    final streamUrl = dataProvider.service.getStreamUrl(item.id);

    // Start playback session
    dataProvider.service.startPlaybackSession(itemId: item.id);

    return VideoPlayerScreen(streamUrl: streamUrl);
  }

  void _viewLibrary(String libraryName, JellyfinDataProvider dataProvider) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening $libraryName library'),
        backgroundColor: AppTheme.accentBlue,
      ),
    );
  }
}

// Custom tab bar delegate
class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  _SliverTabBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;

  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return false;
  }
}
