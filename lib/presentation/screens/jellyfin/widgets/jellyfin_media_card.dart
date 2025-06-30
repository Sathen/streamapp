import 'package:flutter/material.dart';
import 'package:stream_flutter/presentation/screens/jellyfin/widgets/jellyfin_image_widget.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../data/models/models/jellyfin_models.dart';
import '../../../../data/models/models/tmdb_models.dart';
import '../../../providers/jellyfin/jellyfin_data_provider.dart';

class JellyfinMediaCard extends StatefulWidget {
  final JellyfinMediaItem item;
  final JellyfinDataProvider dataProvider;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool showProgress;
  final bool showFavoriteIcon;
  final double? progress;
  final String? heroTag;

  const JellyfinMediaCard({
    super.key,
    required this.item,
    required this.dataProvider,
    this.onTap,
    this.onLongPress,
    this.showProgress = false,
    this.showFavoriteIcon = false,
    this.progress,
    this.heroTag,
  });

  @override
  State<JellyfinMediaCard> createState() => _JellyfinMediaCardState();
}

class _JellyfinMediaCardState extends State<JellyfinMediaCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _hoverController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _elevationAnimation;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(parent: _hoverController, curve: Curves.easeOut));

    _elevationAnimation = Tween<double>(
      begin: 4.0,
      end: 12.0,
    ).animate(CurvedAnimation(parent: _hoverController, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final heroTag = widget.heroTag ?? 'jellyfin_media_${widget.item.id}';

    return GestureDetector(
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      onTapDown: (_) => _hoverController.forward(),
      onTapUp: (_) => _hoverController.reverse(),
      onTapCancel: () => _hoverController.reverse(),
      child: AnimatedBuilder(
        animation: _hoverController,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: theme.colorScheme.outline.withOpacity(0.2),
                  width: 0.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.shadow.withOpacity(0.4),
                    blurRadius: _elevationAnimation.value,
                    offset: Offset(0, _elevationAnimation.value / 2),
                  ),
                  BoxShadow(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    blurRadius: _elevationAnimation.value + 8,
                    offset: Offset(0, _elevationAnimation.value / 1.5),
                  ),
                ],
              ),
              child: Hero(
                tag: heroTag,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Poster Section
                      Expanded(
                        flex: 3,
                        child: _buildPosterSection(),
                      ),
                      // Content Info Section
                      Expanded(
                        flex: 1,
                        child: _buildContentSection(theme),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPosterSection() {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Main poster image
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
          ),
          child: JellyfinImageWidget(item: widget.item, type: 'Primary')
        ),

        // Gradient overlay for better text readability
        _buildGradientOverlay(),
      ],
    );
  }

  Widget _buildPlaceholder() {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.surfaceVariant,
            AppTheme.surfaceBlue,
          ],
        ),
      ),
      child: Center(
        child: Icon(
          _getMediaTypeIcon(widget.item.type),
          size: 48,
          color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
        ),
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
            Colors.black.withOpacity(0.7),
          ],
          stops: const [0.0, 0.5, 0.8, 1.0],
        ),
      ),
    );
  }

  Widget _buildContentSection(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title - matching MediaSection style exactly
          Text(
            widget.item.name,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: 4),

          // Metadata row
          Row(
            children: [
              // Media type icon and badge
              Icon(
                _getMediaTypeIcon(widget.item.type),
                size: 12,
                color: _getMediaTypeColor(widget.item.type),
              ),
              const SizedBox(width: 4),

              if (widget.item.type != MediaType.unknown)
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: _getMediaTypeColor(widget.item.type).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _getMediaTypeDisplay(widget.item.type),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: _getMediaTypeColor(widget.item.type),
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),

              const Spacer(),

              // Rating if available
              if (widget.item.rating != null) ...[
                Icon(
                  Icons.star_rounded,
                  size: 12,
                  color: Colors.amber,
                ),
                const SizedBox(width: 2),
                Text(
                  widget.item.rating!.toStringAsFixed(1),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

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
}