import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../../core/enums/display_category.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../providers/media/media_provider.dart';
import 'category_selector.dart';

class HomeAppBar extends StatefulWidget {
  final bool innerBoxIsScrolled;
  final VoidCallback? onCategoryChanged;
  final VoidCallback? onScrollToTop;

  const HomeAppBar({
    super.key,
    required this.innerBoxIsScrolled,
    this.onCategoryChanged,
    this.onScrollToTop,
  });

  @override
  State<HomeAppBar> createState() => _HomeAppBarState();
}

class _HomeAppBarState extends State<HomeAppBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _segmentedButtonController;
  late Animation<double> _segmentedButtonAnimation;

  @override
  void initState() {
    super.initState();
    _segmentedButtonController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _segmentedButtonAnimation = CurvedAnimation(
      parent: _segmentedButtonController,
      curve: Curves.easeOutCubic,
    );

    _segmentedButtonController.forward();
  }

  @override
  void dispose() {
    _segmentedButtonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Calculate opacity and scale based on scroll state
    final scrollOpacity = widget.innerBoxIsScrolled ? 0.95 : 1.0;
    final backgroundOpacity = widget.innerBoxIsScrolled ? 0.85 : 0.3;
    final expandedContentOpacity = widget.innerBoxIsScrolled ? 0.0 : 1.0;
    final categoryScale = widget.innerBoxIsScrolled ? 0.9 : 1.0;

    return SliverAppBar(
      expandedHeight: 160,
      floating: true,
      pinned: true,
      snap: true,
      elevation: widget.innerBoxIsScrolled ? 4 : 0,
      backgroundColor:
          widget.innerBoxIsScrolled
              ? AppTheme.surfaceBlue.withOpacity(0.9)
              : Colors.transparent,
      systemOverlayStyle: SystemUiOverlayStyle.light,

      // Collapsed title shows category selector instead of app name
      title: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: widget.innerBoxIsScrolled ? 1.0 : 0.0,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          transform: Matrix4.identity()..scale(categoryScale),
          child: Row(
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
                child: const Icon(
                  Icons.movie_rounded,
                  size: 16,
                  color: Colors.white,
                ),
              ),
              // Category selector in collapsed state
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceBlue,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppTheme.outlineVariant,
                      width: 1,
                    ),
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
                              mediaProvider.selectedCategory ==
                                  DisplayCategory.tv,
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
          ),
        ),
      ),

      flexibleSpace: FlexibleSpaceBar(
        background: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.backgroundBlue.withOpacity(scrollOpacity),
                AppTheme.surfaceBlue.withOpacity(backgroundOpacity),
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // App title section (hidden when scrolled)
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 300),
                    opacity: expandedContentOpacity,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      transform: Matrix4.translationValues(
                        0,
                        widget.innerBoxIsScrolled ? -20 : 0,
                        0,
                      ),
                      child: Row(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppTheme.primaryBlue,
                                  AppTheme.accentBlue,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(50),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primaryBlue.withOpacity(
                                    widget.innerBoxIsScrolled ? 0.1 : 0.3,
                                  ),
                                  blurRadius:
                                      widget.innerBoxIsScrolled ? 6 : 12,
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
                                AnimatedDefaultTextStyle(
                                  duration: const Duration(milliseconds: 300),
                                  style:
                                      Theme.of(
                                        context,
                                      ).textTheme.titleLarge?.copyWith(
                                        color: AppTheme.highEmphasisText
                                            .withOpacity(
                                              expandedContentOpacity,
                                            ),
                                        fontWeight: FontWeight.bold,
                                      ) ??
                                      const TextStyle(),
                                  child: const Text('Streaming App'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Category selector with scroll-based animation (hidden when scrolled)
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 300),
                    opacity: expandedContentOpacity,
                    child: AnimatedBuilder(
                      animation: _segmentedButtonAnimation,
                      builder: (context, child) {
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          transform:
                              Matrix4.identity()..scale(
                                _segmentedButtonAnimation.value,
                                _segmentedButtonAnimation.value,
                              ),
                          child: CategorySelector(
                            onCategoryChanged: widget.onCategoryChanged,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
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
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
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

    // Scroll to top and notify parent
    widget.onScrollToTop?.call();
    widget.onCategoryChanged?.call();
  }
}
