// lib/presentation/screens/watch_history/widgets/history_item_card.dart

import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../data/models/models/watch_history.dart';

class HistoryItemCard extends StatefulWidget {
  final WatchHistoryItem item;
  final VoidCallback onTap;
  final bool isGridView;

  const HistoryItemCard({
    super.key,
    required this.item,
    required this.onTap,
    this.isGridView = false,
  });

  @override
  State<HistoryItemCard> createState() => _HistoryItemCardState();
}

class _HistoryItemCardState extends State<HistoryItemCard>
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
      end: 1.02,
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
    return widget.isGridView ? _buildGridCard() : _buildListCard();
  }

  Widget _buildGridCard() {
    return GestureDetector(
      onTap: widget.onTap,
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
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: _elevationAnimation.value,
                    offset: Offset(0, _elevationAnimation.value / 3),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _buildPosterImage(),
                    _buildGradientOverlay(),
                    _buildGridContentOverlay(),
                    _buildWatchIndicators(),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildListCard() {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => _hoverController.forward(),
      onTapUp: (_) => _hoverController.reverse(),
      onTapCancel: () => _hoverController.reverse(),
      child: AnimatedBuilder(
        animation: _hoverController,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.surfaceBlue,
                    AppTheme.surfaceVariant.withOpacity(0.3),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.outlineVariant, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: _elevationAnimation.value,
                    offset: Offset(0, _elevationAnimation.value / 3),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    _buildListThumbnail(),
                    const SizedBox(width: 16),
                    Expanded(child: _buildListContent()),
                    const SizedBox(width: 12),
                    _buildListTrailing(),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPosterImage() {
    return widget.item.posterPath != null
        ? Image.network(
          'https://image.tmdb.org/t/p/w500${widget.item.posterPath}',
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return _buildImagePlaceholder(isLoading: true);
          },
          errorBuilder: (context, error, stackTrace) {
            return _buildImagePlaceholder();
          },
        )
        : _buildImagePlaceholder();
  }

  Widget _buildImagePlaceholder({bool isLoading = false}) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.surfaceVariant, AppTheme.surfaceBlue],
        ),
      ),
      child: Center(
        child:
            isLoading
                ? const CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppTheme.accentBlue,
                  ),
                )
                : Icon(
                  widget.item.type.icon,
                  size: 48,
                  color: AppTheme.mediumEmphasisText,
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
            Colors.black.withOpacity(0.4),
            Colors.black.withOpacity(0.8),
          ],
          stops: const [0.0, 0.5, 0.8, 1.0],
        ),
      ),
    );
  }

  Widget _buildGridContentOverlay() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.item.title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                shadows: [
                  Shadow(
                    offset: const Offset(0, 1),
                    blurRadius: 3,
                    color: Colors.black.withOpacity(0.8),
                  ),
                ],
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(widget.item.type.icon, color: Colors.white70, size: 14),
                const SizedBox(width: 4),
                Text(
                  widget.item.type.displayName,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                Text(
                  widget.item.formattedLastWatched,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListThumbnail() {
    return Container(
      width: 80,
      height: 120,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.outlineVariant, width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: Stack(
          children: [
            _buildPosterImage(),
            Positioned(
              top: 6,
              right: 6,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color:
                      widget.item.type == WatchHistoryType.movie
                          ? AppTheme.primaryBlue
                          : AppTheme.accentBlue,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  widget.item.type.icon,
                  color: Colors.white,
                  size: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.item.title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppTheme.highEmphasisText,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        if (widget.item.originalTitle != widget.item.title) ...[
          const SizedBox(height: 4),
          Text(
            widget.item.originalTitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.lowEmphasisText,
              fontStyle: FontStyle.italic,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
        const SizedBox(height: 8),
        _buildWatchInfo(),
        const SizedBox(height: 8),
        Text(
          'Last watched ${widget.item.formattedLastWatched}',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppTheme.mediumEmphasisText),
        ),
      ],
    );
  }

  Widget _buildListTrailing() {
    return Column(
      children: [
        if (widget.item.rating != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.accentBlue.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppTheme.accentBlue.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.star_rounded, size: 14, color: AppTheme.accentBlue),
                const SizedBox(width: 4),
                Text(
                  widget.item.rating!.toStringAsFixed(1),
                  style: TextStyle(
                    color: AppTheme.accentBlue,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
        Icon(
          Icons.arrow_forward_ios_rounded,
          color: AppTheme.lowEmphasisText,
          size: 16,
        ),
      ],
    );
  }

  Widget _buildWatchInfo() {
    if (widget.item.type == WatchHistoryType.tv) {
      final watchedEpisodes = widget.item.getTotalWatchedEpisodes();
      final seasons = widget.item.getWatchedSeasonsNumbers();

      return Wrap(
        spacing: 8,
        runSpacing: 4,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppTheme.primaryBlue.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Text(
              '$watchedEpisodes episodes',
              style: TextStyle(
                color: AppTheme.primaryBlue,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.accentBlue.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppTheme.accentBlue.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Text(
              '${seasons.length} seasons',
              style: TextStyle(
                color: AppTheme.accentBlue,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ],
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color:
              widget.item.isCompleted
                  ? AppTheme.successColor.withOpacity(0.2)
                  : AppTheme.warningColor.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color:
                widget.item.isCompleted
                    ? AppTheme.successColor.withOpacity(0.3)
                    : AppTheme.warningColor.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              widget.item.isCompleted ? Icons.check_circle : Icons.play_circle,
              size: 14,
              color:
                  widget.item.isCompleted
                      ? AppTheme.successColor
                      : AppTheme.warningColor,
            ),
            const SizedBox(width: 4),
            Text(
              widget.item.isCompleted ? 'Completed' : 'In Progress',
              style: TextStyle(
                color:
                    widget.item.isCompleted
                        ? AppTheme.successColor
                        : AppTheme.warningColor,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildWatchIndicators() {
    return Positioned(
      top: 8,
      left: 8,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Text(
              widget.item.type.displayName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (widget.item.watchCount > 1) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: AppTheme.accentBlue.withOpacity(0.9),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Text(
                '${widget.item.watchCount}x',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
