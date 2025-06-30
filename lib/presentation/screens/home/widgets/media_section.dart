import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:stream_flutter/data/models/models/tmdb_models.dart';
import '../../../../data/models/models/media_item.dart';

class MediaSection extends StatefulWidget {
  final String title;
  final List<TmdbMediaItem> items;
  final VoidCallback? onSeeAll;

  const MediaSection({
    super.key,
    required this.title,
    required this.items,
    this.onSeeAll,
  });

  @override
  State<MediaSection> createState() => _MediaSectionState();
}

class _MediaSectionState extends State<MediaSection>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late String _sectionId;

  @override
  void initState() {
    super.initState();

    // Create a unique section identifier based on title and widget hash
    _sectionId = '${widget.title.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}_${widget.hashCode}';

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());

    return SliverToBoxAdapter(
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(context),
            const SizedBox(height: 12),
            _buildMediaList(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: theme.textTheme.headlineSmall?.copyWith(
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
                        theme.colorScheme.primary,
                        theme.colorScheme.secondary,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
          ),
          if (widget.onSeeAll != null)
            TextButton.icon(
              onPressed: widget.onSeeAll,
              icon: const Icon(Icons.arrow_forward_rounded, size: 18),
              label: const Text('Дивитись всі'),
              style: TextButton.styleFrom(
                foregroundColor: theme.colorScheme.primary,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMediaList() {
    return SizedBox(
      height: 280,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: widget.items.length,
        itemBuilder: (context, index) {
          return TweenAnimationBuilder<double>(
            duration: Duration(milliseconds: 300 + (index * 100)),
            tween: Tween(begin: 0.0, end: 1.0),
            curve: Curves.elasticOut,
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: _buildMediaCard(context, widget.items[index], index),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildMediaCard(BuildContext context, TmdbMediaItem item, int index) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () => context.push('/media/tmdb/${item.type.name}/${item.id}'),
      child: Container(
        width: 140,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Hero(
              tag: 'media_${item.id}_section_${_sectionId}_index_$index',
              child: _buildPosterCard(context, item, theme),
            ),
            const SizedBox(height: 8),
            _buildMediaInfo(context, item, theme),
          ],
        ),
      ),
    );
  }

  Widget _buildPosterCard(BuildContext context, TmdbMediaItem item, ThemeData theme) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Poster Image
            item.posterPath != null
                ? Image.network(
              item.posterPath!,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return _buildLoadingPlaceholder(theme);
              },
              errorBuilder: (context, error, stackTrace) {
                return _buildErrorPlaceholder(theme);
              },
            )
                : _buildErrorPlaceholder(theme),

            // Enhanced Gradient Overlay using theme colors
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    theme.colorScheme.surface.withOpacity(0.3),
                    theme.colorScheme.surface.withOpacity(0.8),
                  ],
                  stops: const [0.4, 0.7, 1.0],
                ),
              ),
            ),

            // Quality Badge (if available)
            Positioned(
              top: 8,
              right: 8,
              child: _buildQualityBadge(theme),
            ),

          ],
        ),
      ),
    );
  }

  Widget _buildQualityBadge(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.secondary,
            theme.colorScheme.secondary.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.3),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        'HD',
        style: TextStyle(
          color: Colors.white, // Always white for best contrast
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildMediaInfo(BuildContext context, MediaItem item, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          item.name,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(
              item.type.name == 'movie' ? Icons.movie_rounded : Icons.tv_rounded,
              size: 14,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                item.type.name == 'movie' ? 'Фільм' : 'Серіал',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLoadingPlaceholder(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.surfaceVariant,
            theme.colorScheme.surface,
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(
                  theme.colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Завантаження...',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorPlaceholder(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.surfaceVariant,
            theme.colorScheme.surface,
          ],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.error.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(
                color: theme.colorScheme.error.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Icon(
              Icons.broken_image_rounded,
              size: 32,
              color: theme.colorScheme.error.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Зображення\nнедоступне',
            textAlign: TextAlign.center,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}