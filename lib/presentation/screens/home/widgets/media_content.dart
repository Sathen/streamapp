import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../screens/media_section.dart';
import '../../../providers/media/media_provider.dart';

class MediaContent extends StatelessWidget {
  final MediaProvider provider;

  const MediaContent({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    if (provider.isLoading) {
      return _buildLoadingState();
    }

    if (provider.hasError) {
      return _buildErrorState(context);
    }

    return CustomScrollView(slivers: _buildContent());
  }

  Widget _buildLoadingState() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AppTheme.surfaceBlue,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppTheme.outlineVariant, width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 48,
              height: 48,
              child: CircularProgressIndicator(
                strokeWidth: 4,
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentBlue),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Loading content...',
              style: TextStyle(
                color: AppTheme.highEmphasisText,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(32),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AppTheme.surfaceBlue,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppTheme.outlineVariant, width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 64, color: AppTheme.errorColor),
            const SizedBox(height: 24),
            Text(
              'Something went wrong',
              style: TextStyle(
                color: AppTheme.highEmphasisText,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              provider.error ?? 'Unknown error occurred',
              style: TextStyle(
                color: AppTheme.mediumEmphasisText,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => provider.initializeData(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildContent() {
    final category = provider.selectedCategory;

    if (category == DisplayCategory.movies) {
      return [
        if (provider.nowPlayingMovies.isNotEmpty)
          MediaSection(
            title: '🎬 Now Playing',
            items: provider.nowPlayingMovies,
          ),
        if (provider.popularMovies.isNotEmpty)
          MediaSection(
            title: '🔥 Popular Movies',
            items: provider.popularMovies,
          ),
        if (provider.topRatedMovies.isNotEmpty)
          MediaSection(title: '⭐ Top Rated', items: provider.topRatedMovies),
        if (provider.newestMovies.isNotEmpty)
          MediaSection(
            title: '🆕 Latest Releases',
            items: provider.newestMovies,
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ];
    } else {
      return [
        if (provider.popularTV.isNotEmpty)
          MediaSection(title: '📺 Popular TV Shows', items: provider.popularTV),
        if (provider.topRatedTV.isNotEmpty)
          MediaSection(title: '🏆 Top Rated Shows', items: provider.topRatedTV),
        if (provider.newestTV.isNotEmpty)
          MediaSection(title: '🗓️ Latest Episodes', items: provider.newestTV),
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ];
    }
  }
}
