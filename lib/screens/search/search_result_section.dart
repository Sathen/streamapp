import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:stream_flutter/models/search_result.dart';

import '../theme.dart';

class SearchResultSection extends StatefulWidget {
  final SearchResult searchResult;
  final bool isLoading;
  final VoidCallback? onLoadMore;
  final bool hasMore;

  const SearchResultSection({
    super.key,
    required this.searchResult,
    this.isLoading = false,
    this.onLoadMore,
    this.hasMore = false,
  });

  @override
  State<SearchResultSection> createState() => _SearchResultSectionState();
}

class _SearchResultSectionState extends State<SearchResultSection>
    with AutomaticKeepAliveClientMixin {

  late ScrollController _scrollController;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      if (widget.hasMore && !widget.isLoading && widget.onLoadMore != null) {
        widget.onLoadMore!();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (widget.searchResult.items.isEmpty && !widget.isLoading) {
      return _buildEmptyState(context);
    }

    final screenWidth = MediaQuery.of(context).size.width;
    const double spacing = 16.0;

    // Enhanced responsive design
    double targetCardWidth = _getOptimalCardWidth(screenWidth);
    int crossAxisCount = _calculateCrossAxisCount(screenWidth, targetCardWidth, spacing);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppTheme.backgroundBlue,
            AppTheme.surfaceBlue.withOpacity(0.1),
          ],
        ),
      ),
      child: CustomScrollView(
        controller: _scrollController,
        slivers: [
          _buildResultsHeader(context),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: spacing,
                mainAxisSpacing: spacing,
                childAspectRatio: _getChildAspectRatio(screenWidth),
              ),
              delegate: SliverChildBuilderDelegate(
                    (context, index) {
                  if (index < widget.searchResult.items.length) {
                    return _buildMediaCard(context, widget.searchResult.items[index], index);
                  }
                  return null;
                },
                childCount: widget.searchResult.items.length,
              ),
            ),
          ),
          if (widget.isLoading) _buildLoadingIndicator(),
          if (widget.hasMore && !widget.isLoading) _buildLoadMoreButton(),
          const SliverToBoxAdapter(child: SizedBox(height: 20)),
        ],
      ),
    );
  }

  double _getOptimalCardWidth(double screenWidth) {
    if (screenWidth < 600) return 140;
    if (screenWidth < 900) return 160;
    if (screenWidth < 1200) return 180;
    return 200;
  }

  int _calculateCrossAxisCount(double screenWidth, double cardWidth, double spacing) {
    int count = ((screenWidth - 32) / (cardWidth + spacing)).floor();
    return count.clamp(2, 8);
  }

  double _getChildAspectRatio(double screenWidth) {
    if (screenWidth < 600) return 0.65;
    if (screenWidth < 900) return 0.68;
    return 0.7;
  }

  Widget _buildResultsHeader(BuildContext context) {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceBlue,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.outlineVariant,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.accentBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppTheme.accentBlue.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.search_rounded,
                color: AppTheme.accentBlue,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Search Results',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppTheme.highEmphasisText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${widget.searchResult.items.length} result${widget.searchResult.items.length != 1 ? 's' : ''} found',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.mediumEmphasisText,
                    ),
                  ),
                ],
              ),
            ),
            _buildResultCount(),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCount() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.primaryBlue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primaryBlue.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.format_list_numbered_rounded,
            size: 16,
            color: AppTheme.primaryBlue,
          ),
          const SizedBox(width: 4),
          Text(
            '${widget.searchResult.items.length}',
            style: TextStyle(
              color: AppTheme.primaryBlue,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaCard(BuildContext context, SearchItem item, int index) {
    return Hero(
      tag: 'search_item_${item.title}_$index',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.push('/media/online', extra: item),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppTheme.outlineVariant,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _buildPosterImage(item),
                  _buildGradientOverlay(),
                  _buildCardContent(context, item),
                  _buildRatingBadge(item),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPosterImage(SearchItem item) {
    return Container(
      color: AppTheme.surfaceVariant,
      child: item.img != null
          ? Image.network(
        "https://corsproxy.io/?url=${item.img!}",
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            color: AppTheme.surfaceVariant,
            child: Center(
              child: SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentBlue),
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                      : null,
                ),
              ),
            ),
          );
        },
        errorBuilder: (context, error, _) => _buildErrorPlaceholder(),
      )
          : _buildErrorPlaceholder(),
    );
  }

  Widget _buildErrorPlaceholder() {
    return Container(
      color: AppTheme.surfaceVariant,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.movie_rounded,
            size: 40,
            color: AppTheme.lowEmphasisText,
          ),
          const SizedBox(height: 8),
          Text(
            'No Image',
            style: TextStyle(
              color: AppTheme.lowEmphasisText,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGradientOverlay() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.transparent,
            Colors.black.withOpacity(0.3),
            Colors.black.withOpacity(0.8),
          ],
          stops: const [0.0, 0.4, 0.7, 1.0],
        ),
      ),
    );
  }

  Widget _buildCardContent(BuildContext context, SearchItem item) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              item.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                height: 1.2,
              ),
            ),
            if (item.year != null) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.accentBlue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: AppTheme.accentBlue.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  item.year.toString(),
                  style: TextStyle(
                    color: AppTheme.accentBlue,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRatingBadge(SearchItem item) {
    if (item.rating == null) return const SizedBox.shrink();

    return Positioned(
      top: 8,
      right: 8,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppTheme.accentBlue.withOpacity(0.5),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.star_rounded,
              size: 12,
              color: AppTheme.accentBlue,
            ),
            const SizedBox(width: 2),
            Text(
              item.rating!.toStringAsFixed(1),
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            children: [
              SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentBlue),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Loading more results...',
                style: TextStyle(
                  color: AppTheme.mediumEmphasisText,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadMoreButton() {
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Center(
          child: ElevatedButton.icon(
            onPressed: widget.onLoadMore,
            icon: Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Load More'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppTheme.backgroundBlue,
            AppTheme.surfaceBlue.withOpacity(0.3),
          ],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppTheme.surfaceBlue,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: AppTheme.outlineVariant,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.accentBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(50),
                    border: Border.all(
                      color: AppTheme.accentBlue.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    Icons.search_off_rounded,
                    size: 48,
                    color: AppTheme.accentBlue,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'No Results Found',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppTheme.highEmphasisText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Try adjusting your search terms or filters to find what you\'re looking for.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.mediumEmphasisText,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}