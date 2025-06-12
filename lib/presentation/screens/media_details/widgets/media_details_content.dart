import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../data/models/models/tmdb_models.dart';
import '../../../providers/media_details/media_details_provider.dart';
import '../../../widgets/common/loading/loading_indicator.dart';
import '../../../widgets/common/misc/empty_state.dart';
import 'media_header_section.dart';
import 'movie_play_section.dart';
import 'production_info_section.dart';
import 'tv_seasons_section.dart';

class MediaDetailsContent extends StatelessWidget {
  final MediaDetailsProvider provider;
  final MediaType? mediaType;
  final int? tmdbId;
  final bool isOnlineMedia;

  const MediaDetailsContent({
    super.key,
    required this.provider,
    this.mediaType,
    this.tmdbId,
    this.isOnlineMedia = false,
  });

  @override
  Widget build(BuildContext context) {
    if (provider.isLoading) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(
          child: LoadingIndicator(
            message: 'Loading media details...',
            size: 64,
          ),
        ),
      );
    }

    if (provider.hasError) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: EmptyState(
          icon: Icons.error_outline,
          title: 'Error Loading Details',
          message: provider.error!,
          actionText: 'Retry',
          onAction: () => _retryLoad(context),
        ),
      );
    }

    final hasData =
        isOnlineMedia
            ? provider.onlineMediaData != null
            : provider.mediaData != null;

    if (!hasData) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: EmptyState(
          icon: Icons.movie_outlined,
          title: 'No Details Available',
          message: 'Unable to load media information.',
        ),
      );
    }

    return Column(
      children: [
        // Header Section
        MediaHeaderSection(
          mediaData: provider.mediaData,
          onlineMediaData: provider.onlineMediaData,
        ),

        const SizedBox(height: 16),

        // Play Section (Movie or Online Media without seasons)
        if (_shouldShowPlaySection())
          MoviePlaySection(
            provider: provider,
            tmdbId: tmdbId,
            isOnlineMedia: isOnlineMedia,
          ),

        // TV Seasons Section
        if (_shouldShowSeasonsSection())
          TvSeasonsSection(provider: provider, tmdbId: tmdbId!),

        const SizedBox(height: 16),

        // Production Info Section
        if (!isOnlineMedia && provider.mediaData != null)
          ProductionInfoSection(mediaData: provider.mediaData!),

        const SizedBox(height: 40),
      ],
    );
  }

  bool _shouldShowPlaySection() {
    if (isOnlineMedia) {
      return provider.onlineMediaData?.seasons.isEmpty ?? true;
    }
    return mediaType == MediaType.movie;
  }

  bool _shouldShowSeasonsSection() {
    if (isOnlineMedia) {
      return provider.onlineMediaData?.seasons.isNotEmpty ?? false;
    }
    return mediaType == MediaType.tv &&
        provider.seasonDetails?.isNotEmpty == true;
  }

  void _retryLoad(BuildContext context) {
    if (isOnlineMedia) {
      // Would need SearchItem to retry online media
      provider.clearData();
    } else if (tmdbId != null && mediaType != null) {
      provider.loadTmdbMediaDetails(tmdbId!, mediaType!);
    }
  }
}
