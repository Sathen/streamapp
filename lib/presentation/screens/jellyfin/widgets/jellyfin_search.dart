import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:stream_flutter/presentation/screens/video_player/video_player_screen.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../data/models/models/media_item.dart';
import '../../../providers/jellyfin/jellyfin_data_provider.dart';
import 'jellyfin_media_card.dart';

class JellyfinSearchWidget extends StatefulWidget {
  final JellyfinDataProvider dataProvider;

  const JellyfinSearchWidget({super.key, required this.dataProvider});

  @override
  State<JellyfinSearchWidget> createState() => JellyfinSearchWidgetState();
}


class JellyfinSearchWidgetState extends State<JellyfinSearchWidget> {
  final TextEditingController _searchController = TextEditingController();
  List<MediaItem> _searchResults = [];
  bool _isSearching = false;
  String? _searchError;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // Search bar
        Container(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search your Jellyfin library...',
              prefixIcon: Icon(Icons.search_rounded),
              suffixIcon: _isSearching
                  ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
                  : _searchController.text.isNotEmpty
                  ? IconButton(
                onPressed: _clearSearch,
                icon: Icon(Icons.clear_rounded),
              )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: theme.colorScheme.surface,
            ),
            onSubmitted: _performSearch,
            textInputAction: TextInputAction.search,
          ),
        ),

        // Search results
        Expanded(
          child: _buildSearchResults(),
        ),
      ],
    );
  }

  Widget _buildSearchResults() {
    final theme = Theme.of(context);

    if (_searchController.text.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_rounded,
              size: 64,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'Search your library',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha:0.6),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Enter a title, actor, or genre to find content',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha:0.4),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (_isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_searchError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: AppTheme.errorColor,
            ),
            const SizedBox(height: 16),
            Text(
              'Search Error',
              style: theme.textTheme.titleMedium?.copyWith(
                color: AppTheme.errorColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchError!,
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _performSearch(_searchController.text),
              child: Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 64,
              color: theme.colorScheme.onSurface.withValues(alpha:0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No results found',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha:0.6),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try different keywords or check spelling',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha:0.4),
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final item = _searchResults[index];
        return JellyfinMediaCard(
          item: item,
          dataProvider: widget.dataProvider,
          onTap: () => _playItem(item),
        );
      },
    );
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) return;

    setState(() {
      _isSearching = true;
      _searchError = null;
    });

    try {
      final results = await widget.dataProvider.searchContent(query.trim());

      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _searchError = e.toString();
          _isSearching = false;
        });
      }
    }
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchResults.clear();
      _searchError = null;
    });
  }

  VideoPlayerScreen _playItem(MediaItem item) {
    // Get stream URL and play
    final streamUrl = widget.dataProvider.service.getStreamUrl(item.id);

    widget.dataProvider.service.startPlaybackSession(itemId: item.id);

    return VideoPlayerScreen(streamUrl: streamUrl,);
  }
}