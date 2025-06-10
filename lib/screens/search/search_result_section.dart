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
    final screenHeight = MediaQuery.of(context).size.height;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final availableHeight = screenHeight - keyboardHeight;
    final isKeyboardVisible = keyboardHeight > 0;

    // Adjust spacing based on available space
    final double spacing = isKeyboardVisible ? 12.0 : 16.0;

    // Enhanced responsive design with keyboard consideration
    double targetCardWidth = _getOptimalCardWidth(screenWidth, isKeyboardVisible);
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
          _buildResultsHeader(context, isKeyboardVisible),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
                isKeyboardVisible ? 12 : 16,
                isKeyboardVisible ? 4 : 8,
                isKeyboardVisible ? 12 : 16,
                isKeyboardVisible ? 8 : 16
            ),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: spacing,
                mainAxisSpacing: spacing,
                childAspectRatio: _getChildAspectRatio(screenWidth, isKeyboardVisible),
              ),
              delegate: SliverChildBuilderDelegate(
                    (context, index) {
                  if (index < widget.searchResult.items.length) {
                    return _buildMediaCard(context, widget.searchResult.items[index], index, isKeyboardVisible);
                  }
                  return null;
                },
                childCount: widget.searchResult.items.length,
              ),
            ),
          ),
          if (widget.isLoading) _buildLoadingIndicator(isKeyboardVisible),
          if (widget.hasMore && !widget.isLoading) _buildLoadMoreButton(isKeyboardVisible),
          SliverToBoxAdapter(child: SizedBox(height: isKeyboardVisible ? 10 : 20)),
        ],
      ),
    );
  }

  double _getOptimalCardWidth(double screenWidth, bool isKeyboardVisible) {
    // Smaller cards when keyboard is visible to fit more content
    if (isKeyboardVisible) {
      if (screenWidth < 600) return 120;
      if (screenWidth < 900) return 140;
      if (screenWidth < 1200) return 160;
      return 180;
    } else {
      if (screenWidth < 600) return 140;
      if (screenWidth < 900) return 160;
      if (screenWidth < 1200) return 180;
      return 200;
    }
  }

  int _calculateCrossAxisCount(double screenWidth, double cardWidth, double spacing) {
    int count = ((screenWidth - 32) / (cardWidth + spacing)).floor();
    return count.clamp(2, 8);
  }

  double _getChildAspectRatio(double screenWidth, bool isKeyboardVisible) {
    // Adjust aspect ratio when keyboard is visible
    if (isKeyboardVisible) {
      if (screenWidth < 600) return 0.6;
      if (screenWidth < 900) return 0.62;
      return 0.65;
    } else {
      if (screenWidth < 600) return 0.65;
      if (screenWidth < 900) return 0.68;
      return 0.7;
    }
  }

  Widget _buildResultsHeader(BuildContext context, bool isKeyboardVisible) {
    return SliverToBoxAdapter(
      child: Container(
        margin: EdgeInsets.fromLTRB(
            isKeyboardVisible ? 12 : 16,
            isKeyboardVisible ? 8 : 16,
            isKeyboardVisible ? 12 : 16,
            isKeyboardVisible ? 4 : 8
        ),
        padding: EdgeInsets.all(isKeyboardVisible ? 12 : 16),
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
              padding: EdgeInsets.all(isKeyboardVisible ? 6 : 8),
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
                size: isKeyboardVisible ? 16 : 20,
              ),
            ),
            SizedBox(width: isKeyboardVisible ? 8 : 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Search Results',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontSize: isKeyboardVisible ? 16 : null,
                      color: AppTheme.highEmphasisText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: isKeyboardVisible ? 1 : 2),
                  Text(
                    '${widget.searchResult.items.length} result${widget.searchResult.items.length != 1 ? 's' : ''} found',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: isKeyboardVisible ? 10 : null,
                      color: AppTheme.mediumEmphasisText,
                    ),
                  ),
                ],
              ),
            ),
            _buildResultCount(isKeyboardVisible),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCount(bool isKeyboardVisible) {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: isKeyboardVisible ? 8 : 12,
          vertical: isKeyboardVisible ? 4 : 6
      ),
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
            size: isKeyboardVisible ? 12 : 16,
            color: AppTheme.primaryBlue,
          ),
          SizedBox(width: isKeyboardVisible ? 2 : 4),
          Text(
            '${widget.searchResult.items.length}',
            style: TextStyle(
              color: AppTheme.primaryBlue,
              fontWeight: FontWeight.w600,
              fontSize: isKeyboardVisible ? 12 : 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaCard(BuildContext context, SearchItem item, int index, bool isKeyboardVisible) {
    return Hero(
      tag: 'search_item_${item.title}_$index',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.push('/media/online', extra: item),
          borderRadius: BorderRadius.circular(isKeyboardVisible ? 12 : 16),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(isKeyboardVisible ? 12 : 16),
              border: Border.all(
                color: AppTheme.outlineVariant,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isKeyboardVisible ? 0.15 : 0.2),
                  blurRadius: isKeyboardVisible ? 8 : 12,
                  offset: Offset(0, isKeyboardVisible ? 2 : 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(isKeyboardVisible ? 12 : 16),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _buildPosterImage(item, isKeyboardVisible),
                  _buildGradientOverlay(),
                  _buildCardContent(context, item, isKeyboardVisible),
                  _buildRatingBadge(item, isKeyboardVisible),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPosterImage(SearchItem item, bool isKeyboardVisible) {
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
                width: isKeyboardVisible ? 24 : 32,
                height: isKeyboardVisible ? 24 : 32,
                child: CircularProgressIndicator(
                  strokeWidth: isKeyboardVisible ? 2 : 3,
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
        errorBuilder: (context, error, _) => _buildErrorPlaceholder(isKeyboardVisible),
      )
          : _buildErrorPlaceholder(isKeyboardVisible),
    );
  }

  Widget _buildErrorPlaceholder(bool isKeyboardVisible) {
    return Container(
      color: AppTheme.surfaceVariant,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.movie_rounded,
            size: isKeyboardVisible ? 32 : 40,
            color: AppTheme.lowEmphasisText,
          ),
          SizedBox(height: isKeyboardVisible ? 4 : 8),
          Text(
            'No Image',
            style: TextStyle(
              color: AppTheme.lowEmphasisText,
              fontSize: isKeyboardVisible ? 10 : 12,
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

  Widget _buildCardContent(BuildContext context, SearchItem item, bool isKeyboardVisible) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.all(isKeyboardVisible ? 8 : 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              item.title,
              maxLines: isKeyboardVisible ? 1 : 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: isKeyboardVisible ? 12 : null,
                color: Colors.white,
                fontWeight: FontWeight.w600,
                height: 1.2,
              ),
            ),
            if (item.year != null) ...[
              SizedBox(height: isKeyboardVisible ? 2 : 4),
              Container(
                padding: EdgeInsets.symmetric(
                    horizontal: isKeyboardVisible ? 4 : 6,
                    vertical: isKeyboardVisible ? 1 : 2
                ),
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
                    fontSize: isKeyboardVisible ? 8 : 10,
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

  Widget _buildRatingBadge(SearchItem item, bool isKeyboardVisible) {
    if (item.rating == null) return const SizedBox.shrink();

    return Positioned(
      top: isKeyboardVisible ? 4 : 8,
      right: isKeyboardVisible ? 4 : 8,
      child: Container(
        padding: EdgeInsets.symmetric(
            horizontal: isKeyboardVisible ? 4 : 6,
            vertical: isKeyboardVisible ? 2 : 3
        ),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(isKeyboardVisible ? 6 : 8),
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
              size: isKeyboardVisible ? 10 : 12,
              color: AppTheme.accentBlue,
            ),
            SizedBox(width: isKeyboardVisible ? 1 : 2),
            Text(
              item.rating!.toStringAsFixed(1),
              style: TextStyle(
                color: Colors.white,
                fontSize: isKeyboardVisible ? 8 : 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator(bool isKeyboardVisible) {
    return SliverToBoxAdapter(
      child: Container(
        padding: EdgeInsets.all(isKeyboardVisible ? 16 : 24),
        child: Center(
          child: Column(
            children: [
              SizedBox(
                width: isKeyboardVisible ? 24 : 32,
                height: isKeyboardVisible ? 24 : 32,
                child: CircularProgressIndicator(
                  strokeWidth: isKeyboardVisible ? 2 : 3,
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentBlue),
                ),
              ),
              SizedBox(height: isKeyboardVisible ? 8 : 12),
              Text(
                'Loading more results...',
                style: TextStyle(
                  color: AppTheme.mediumEmphasisText,
                  fontSize: isKeyboardVisible ? 12 : 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadMoreButton(bool isKeyboardVisible) {
    return SliverToBoxAdapter(
      child: Container(
        padding: EdgeInsets.symmetric(
            horizontal: isKeyboardVisible ? 12 : 16,
            vertical: isKeyboardVisible ? 4 : 8
        ),
        child: Center(
          child: ElevatedButton.icon(
            onPressed: widget.onLoadMore,
            icon: Icon(Icons.refresh_rounded, size: isKeyboardVisible ? 16 : 18),
            label: const Text('Load More'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(
                  horizontal: isKeyboardVisible ? 16 : 24,
                  vertical: isKeyboardVisible ? 8 : 12
              ),
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
    final isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

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
      child: Center(
        child: SingleChildScrollView( // Make scrollable when keyboard is visible
          child: Container(
            margin: EdgeInsets.all(isKeyboardVisible ? 8 : 16),
            padding: EdgeInsets.all(isKeyboardVisible ? 16 : 32),
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
                  padding: EdgeInsets.all(isKeyboardVisible ? 16 : 20),
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
                    size: isKeyboardVisible ? 36 : 48,
                    color: AppTheme.accentBlue,
                  ),
                ),
                SizedBox(height: isKeyboardVisible ? 16 : 24),
                Text(
                  'No Results Found',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontSize: isKeyboardVisible ? 18 : null,
                    color: AppTheme.highEmphasisText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: isKeyboardVisible ? 8 : 12),
                Text(
                  'Try adjusting your search terms or filters to find what you\'re looking for.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: isKeyboardVisible ? 12 : null,
                    color: AppTheme.mediumEmphasisText,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}