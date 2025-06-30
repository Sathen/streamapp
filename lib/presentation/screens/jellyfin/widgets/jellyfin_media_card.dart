import 'package:flutter/material.dart';
import 'package:stream_flutter/presentation/screens/jellyfin/widgets/jellyfin_image_widget.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../data/models/models/jellyfin_models.dart';
import '../../../../data/models/models/tmdb_models.dart';
import '../../../providers/jellyfin/jellyfin_data_provider.dart';

class JellyfinMediaCard extends StatelessWidget {
  final JellyfinMediaItem item;
  final JellyfinDataProvider dataProvider;
  final VoidCallback? onTap;
  final bool showProgress;
  final bool showFavoriteIcon;

  const JellyfinMediaCard({
    required this.item,
    required this.dataProvider,
    this.onTap,
    this.showProgress = false,
    this.showFavoriteIcon = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Poster
            Expanded(
              flex: 3,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                      color: theme.colorScheme.surfaceContainerHighest,
                    ),
                    child: JellyfinImageWidget(item: item, type: 'Primary'),
                  ),

                ],
              ),
            ),

            // Content info
            Expanded(
              flex: 1,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      softWrap: true,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),

                    Row(
                      children: [
                        if (item.type != MediaType.unknown)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: _getMediaTypeColor(
                                item.type,
                              ).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              _getMediaTypeDisplay(item.type),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: _getMediaTypeColor(item.type),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),

                        const Spacer(),

                        if (dataProvider.isFavorite(item.id))
                          Icon(
                            Icons.favorite_rounded,
                            size: 12,
                            color: AppTheme.errorColor,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Center(
        child: Icon(
          _getMediaTypeIcon(item.type),
          size: 32,
          color: theme.colorScheme.onSurfaceVariant,
        ),
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
