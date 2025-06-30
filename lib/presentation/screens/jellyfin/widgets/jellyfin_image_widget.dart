import 'package:flutter/material.dart';
import 'package:stream_flutter/data/datasources/remote/services/jellyfin_service.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../data/models/models/jellyfin_models.dart';
import '../../../../data/models/models/tmdb_models.dart';

class JellyfinImageWidget extends StatelessWidget {
  final JellyfinMediaItem item;
  final BoxFit fit;
  final String type;
  final Widget? placeholder;
  final Widget? errorWidget;

  const JellyfinImageWidget({
    super.key,
    required this.item,
    required this.type,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    final jellyfinService = get<JellyfinService>();
    var imageUrl = jellyfinService.getImageUrl(item.id, imageType: type);

    return Image.network(
      imageUrl,
      fit: fit,
      headers: jellyfinService.headers,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return placeholder ?? _buildPlaceholder(context, isLoading: true);
      },
      errorBuilder: (context, error, stackTrace) {
        return errorWidget ?? _buildPlaceholder(context);
      },
    );
  }

  Widget _buildPlaceholder(BuildContext context, {bool isLoading = false}) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [theme.colorScheme.surfaceVariant, theme.colorScheme.surface],
        ),
      ),
      child: Center(
        child:
            isLoading
                ? CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    theme.colorScheme.primary,
                  ),
                )
                : Icon(
                  _getMediaTypeIcon(),
                  size: 48,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
      ),
    );
  }

  IconData _getMediaTypeIcon() {
    switch (item.type) {
      case MediaType.movie:
        return Icons.movie_rounded;
      case MediaType.tv:
        return Icons.tv_rounded;
      default:
        return Icons.video_library_rounded;
    }
  }
}
