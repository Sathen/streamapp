import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:stream_flutter/data/models/models/jellyfin_models.dart';
import 'package:stream_flutter/presentation/screens/jellyfin/widgets/jellyfin_media_card.dart';

import '../../../core/theme/app_theme.dart';
import '../../providers/jellyfin/jellyfin_auth_provider.dart';
import '../../providers/jellyfin/jellyfin_data_provider.dart';

class JellyfinScreen extends StatefulWidget {
  const JellyfinScreen({Key? key}) : super(key: key);

  @override
  State<JellyfinScreen> createState() => _JellyfinScreenState();
}

class _JellyfinScreenState extends State<JellyfinScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

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
                ],
            body: _buildCombinedContent(dataProvider),
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

  Widget _buildCombinedContent(JellyfinDataProvider dataProvider) {
    return RefreshIndicator(
      onRefresh: () => dataProvider.refreshAll(),
      color: AppTheme.accentBlue,
      child: CustomScrollView(
        slivers: [
          // Continue Watching Section
          if (dataProvider.continueWatching.isNotEmpty)
            _buildHorizontalSection(
              'Continue Watching',
              dataProvider.continueWatching,
              showProgress: true,
              isLoading: dataProvider.isLoadingContinueWatching,
              error: dataProvider.continueWatchingError,
              onRefresh: () => dataProvider.loadContinueWatching(force: true),
            ),

          // Recently Added Section
          if (dataProvider.recentlyAdded.isNotEmpty)
            _buildHorizontalSection(
              'Recently Added',
              dataProvider.recentlyAdded,
              isLoading: dataProvider.isLoadingRecentlyAdded,
              error: dataProvider.recentlyAddedError,
              onRefresh: () => dataProvider.loadRecentlyAdded(force: true),
            ),

          // Next Up Episodes Section
          if (dataProvider.nextUpEpisodes.isNotEmpty)
            _buildHorizontalSection(
              'Next Up',
              dataProvider.nextUpEpisodes,
              isLoading: dataProvider.isLoadingNextUp,
            ),

          // Libraries Section
          _buildLibrariesSection(dataProvider),

          // Bottom padding
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildLibrariesSection(JellyfinDataProvider dataProvider) {
    final libraries = dataProvider.libraries;

    if (dataProvider.isLoadingLibraries && libraries.isEmpty) {
      return SliverToBoxAdapter(
        child: Container(
          height: 200,
          child: const Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (libraries.isEmpty) {
      return SliverToBoxAdapter(
        child: Container(
          height: 200,
          child: _buildEmptyState(
            icon: Icons.library_books_outlined,
            title: 'No Libraries Found',
            subtitle: 'Your Jellyfin libraries will appear here',
            onRetry: () => dataProvider.loadLibraries(force: true),
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final libraryName = libraries.keys.elementAt(index);
        final libraryItems = libraries[libraryName]!;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: _buildLibrarySection(libraryName, libraryItems, dataProvider),
        );
      }, childCount: libraries.length),
    );
  }

  Widget _buildLibrarySection(
    String libraryName,
    List<JellyfinMediaItem> items,
    JellyfinDataProvider dataProvider,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Library Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              Icon(
                _getLibraryIcon(libraryName),
                color: AppTheme.accentBlue,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      libraryName,
                      style: Theme.of(
                        context,
                      ).textTheme.headlineSmall?.copyWith(
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
              IconButton(
                onPressed: () => _viewLibrary(libraryName, dataProvider),
                icon: Icon(Icons.arrow_forward_rounded),
                tooltip: 'View All',
              ),
            ],
          ),
        ),

        if (items.isNotEmpty)
          SizedBox(
            height: 280,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
              itemCount: items.take(10).length,
              itemBuilder: (context, index) {
                final item = items[index];
                return Container(
                  width: 140,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  child: JellyfinMediaCard(
                    item: item,
                    heroTag:
                        'jellyfin_library_${libraryName}_${item.id}_$index',
                  ),
                );
              },
            ),
          ),
      ],
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
          // Section Header
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
                        style: Theme.of(
                          context,
                        ).textTheme.headlineSmall?.copyWith(
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
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.accentBlue,
                    ),
                  ),
                if (error != null)
                  IconButton(
                    onPressed: onRefresh,
                    icon: Icon(Icons.refresh_rounded),
                    tooltip: 'Retry',
                  ),
              ],
            ),
          ),

          if (error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                error,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppTheme.warningColor),
              ),
            ),

          const SizedBox(height: 12),

          // Horizontal list of items
          if (items.isNotEmpty)
            SizedBox(
              height: showProgress ? 300 : 280,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  return Container(
                    width: 140,
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    child: JellyfinMediaCard(
                      item: item,
                      showProgress: showProgress,
                      heroTag:
                          '${title.toLowerCase().replaceAll(' ', '_')}_${item.id}_$index',
                    ),
                  );
                },
              ),
            ),

          const SizedBox(height: 24),
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: theme.colorScheme.onSurface.withOpacity(0.4),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.5),
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
    );
  }

  Widget _buildNotLoggedInState() {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: _buildEmptyState(
        icon: Icons.login_rounded,
        title: 'Not Connected',
        subtitle: 'Please connect to your Jellyfin server in settings',
        onRetry: () => context.go('/settings/jellyfin'),
      ),
    );
  }

  Widget _buildFloatingActionButton(JellyfinDataProvider dataProvider) {
    if (!dataProvider.canLoadData) return const SizedBox.shrink();

    return FloatingActionButton(
      onPressed: () => dataProvider.refreshAll(),
      backgroundColor: AppTheme.accentBlue,
      tooltip: 'Refresh All Content',
      child: Icon(Icons.refresh_rounded, color: Colors.white),
    );
  }

  IconData _getLibraryIcon(String libraryName) {
    final name = libraryName.toLowerCase();
    if (name.contains('movie')) return Icons.movie_rounded;
    if (name.contains('tv') || name.contains('show')) return Icons.tv_rounded;
    return Icons.folder_rounded;
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
