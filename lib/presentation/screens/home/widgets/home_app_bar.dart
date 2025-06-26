import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../../core/enums/display_category.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../providers/media/media_provider.dart';
import 'category_selector.dart';

class HomeAppBar extends StatefulWidget {
  final ScrollController scrollController;
  final VoidCallback? onCategoryChanged;
  final VoidCallback? onScrollToTop;

  const HomeAppBar({
    super.key,
    required this.scrollController,
    this.onCategoryChanged,
    this.onScrollToTop,
  });

  @override
  State<HomeAppBar> createState() => _HomeAppBarState();
}

class _HomeAppBarState extends State<HomeAppBar> {
  bool _isMinimized = false;
  double _lastScrollOffset = 0.0;
  static const double _topThreshold = 10.0; // How close to top to expand again

  @override
  void initState() {
    super.initState();
    widget.scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_onScroll);
    super.dispose();
  }

  void _onScroll() {
    final currentOffset = widget.scrollController.offset;

    // Check if we're at the very top (0-50px)
    if (currentOffset <= _topThreshold) {
      if (_isMinimized) {
        setState(() {
          _isMinimized = false;
        });
      }
    }
    // Minimize as soon as user scrolls down past the threshold
    else if (currentOffset > _topThreshold) {
      if (!_isMinimized) {
        setState(() {
          _isMinimized = true;
        });
      }
    }

    _lastScrollOffset = currentOffset;
  }

  @override
  Widget build(BuildContext context) {
    // Calculate states based on minimized state
    final expandedHeight = _isMinimized ? 80.0 : 160.0;
    final showCollapsedContent = _isMinimized;

    return SliverAppBar(
      expandedHeight: expandedHeight,
      floating: true,
      pinned: true,
      snap: false,
      elevation: _isMinimized ? 8 : 0,
      backgroundColor:
          _isMinimized
              ? AppTheme.surfaceBlue.withOpacity(0.95)
              : Colors.transparent,
      systemOverlayStyle: SystemUiOverlayStyle.light,

      // Collapsed title shows category selector when minimized
      title: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: showCollapsedContent ? 1.0 : 0.0,
        child:
            showCollapsedContent
                ? _buildCollapsedTitle()
                : const SizedBox.shrink(),
      ),

      flexibleSpace:
          _isMinimized
              ? null // Remove FlexibleSpaceBar completely when minimized
              : FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppTheme.backgroundBlue,
                        AppTheme.surfaceBlue.withOpacity(0.3),
                      ],
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                      child: _buildExpandedContent(),
                    ),
                  ),
                ),
              ),
    );
  }

  Widget _buildCollapsedTitle() {
    return Row(
      children: [
        // Small app icon for branding
        Container(
          padding: const EdgeInsets.all(6),
          margin: const EdgeInsets.only(right: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTheme.primaryBlue, AppTheme.accentBlue],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.movie_rounded, size: 16, color: Colors.white),
        ),
        // Category selector in collapsed state
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: AppTheme.surfaceBlue,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.outlineVariant, width: 1),
            ),
            child: Consumer<MediaProvider>(
              builder: (context, mediaProvider, child) {
                return Row(
                  children: [
                    Expanded(
                      child: _buildCompactCategoryButton(
                        'Movies',
                        Icons.movie_rounded,
                        DisplayCategory.movies,
                        mediaProvider.selectedCategory ==
                            DisplayCategory.movies,
                        () => _onCategoryTap(DisplayCategory.movies),
                      ),
                    ),
                    const SizedBox(width: 2),
                    Expanded(
                      child: _buildCompactCategoryButton(
                        'TV Shows',
                        Icons.tv_rounded,
                        DisplayCategory.tv,
                        mediaProvider.selectedCategory == DisplayCategory.tv,
                        () => _onCategoryTap(DisplayCategory.tv),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExpandedContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // App title section
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primaryBlue, AppTheme.accentBlue],
                ),
                borderRadius: BorderRadius.circular(50),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryBlue.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.movie_rounded,
                size: 28,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Streaming App',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppTheme.highEmphasisText,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        // Category selector
        CategorySelector(onCategoryChanged: widget.onCategoryChanged),
      ],
    );
  }

  Widget _buildCompactCategoryButton(
    String label,
    IconData icon,
    DisplayCategory category,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            gradient:
                isSelected
                    ? LinearGradient(
                      colors: [AppTheme.primaryBlue, AppTheme.accentBlue],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                    : null,
            color: isSelected ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            boxShadow:
                isSelected
                    ? [
                      BoxShadow(
                        color: AppTheme.primaryBlue.withOpacity(0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ]
                    : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : AppTheme.mediumEmphasisText,
                size: 16,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    color:
                        isSelected ? Colors.white : AppTheme.mediumEmphasisText,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onCategoryTap(DisplayCategory category) {
    HapticFeedback.lightImpact();

    // Update the MediaProvider with the selected category
    context.read<MediaProvider>().setSelectedCategory(category);

    // Scroll to top when category changes
    widget.scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
    );

    // Notify parent
    widget.onScrollToTop?.call();
    widget.onCategoryChanged?.call();
  }
}
