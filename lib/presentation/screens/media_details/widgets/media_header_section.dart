import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../data/models/models/online_media_details_entity.dart';
import '../../../../data/models/models/tmdb_models.dart';
import '../../../widgets/common/misc/rating_indicator.dart';

class MediaHeaderSection extends StatefulWidget {
  final TmdbMediaDetails? mediaData;
  final OnlineMediaDetailsEntity? onlineMediaData;

  const MediaHeaderSection({super.key, this.mediaData, this.onlineMediaData});

  @override
  State<MediaHeaderSection> createState() => _MediaHeaderSectionState();
}

class _MediaHeaderSectionState extends State<MediaHeaderSection> {
  bool _isOverviewExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenSize = MediaQuery.of(context).size;

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.surfaceBlue,
            AppTheme.surfaceVariant.withOpacity(0.8),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.outlineVariant, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildMetaInfo(theme, screenSize),
              const SizedBox(height: 20),
              _buildOverviewSection(theme, screenSize),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetaInfo(ThemeData theme, Size screenSize) {
    final title =
        widget.mediaData?.title ?? widget.onlineMediaData?.title ?? '';
    final rating =
        widget.mediaData?.voteAverage ?? widget.onlineMediaData?.rating;
    final voteCount = widget.mediaData?.voteCount;
    final genres = widget.mediaData?.genres.map((g) => g.name).toList() ?? [];
    final year = _getYear();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Rating indicator
        if (rating != null)
          RatingIndicator(rating: rating, voteCount: voteCount, size: 64),

        if (rating != null) const SizedBox(width: 20),

        // Title and info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.highEmphasisText,
                ),
              ),

              if (year != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.accentBlue.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    year,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppTheme.accentBlue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],

              if (genres.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children:
                      genres
                          .take(3)
                          .map(
                            (genre) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryBlue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppTheme.primaryBlue.withOpacity(0.3),
                                ),
                              ),
                              child: Text(
                                genre,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: AppTheme.primaryBlue,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOverviewSection(ThemeData theme, Size screenSize) {
    final overview =
        widget.mediaData?.overview ?? widget.onlineMediaData?.description ?? '';

    if (overview.isEmpty) return const SizedBox.shrink();

    final shouldShowExpansion = overview.length > 200;
    final truncatedOverview =
        shouldShowExpansion && !_isOverviewExpanded
            ? '${overview.substring(0, 200)}...'
            : overview;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.description_outlined,
              color: AppTheme.primaryBlue,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Overview',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryBlue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        AnimatedCrossFade(
          duration: const Duration(milliseconds: 300),
          crossFadeState:
              _isOverviewExpanded || !shouldShowExpansion
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
          firstChild: Text(
            truncatedOverview,
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.5,
              color: AppTheme.mediumEmphasisText,
            ),
          ),
          secondChild: Text(
            overview,
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.5,
              color: AppTheme.mediumEmphasisText,
            ),
          ),
        ),

        if (shouldShowExpansion) ...[
          const SizedBox(height: 8),
          GestureDetector(
            onTap:
                () =>
                    setState(() => _isOverviewExpanded = !_isOverviewExpanded),
            child: Text(
              _isOverviewExpanded ? 'Show less' : 'Read more',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.accentBlue,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );
  }

  String? _getYear() {
    if (widget.mediaData is MovieDetails) {
      final releaseDate = (widget.mediaData as MovieDetails).releaseDate;
      if (releaseDate.isNotEmpty) {
        return DateTime.parse(releaseDate).year.toString();
      }
    } else if (widget.mediaData is TVDetails) {
      final firstAirDate = (widget.mediaData as TVDetails).firstAirDate;
      if (firstAirDate.isNotEmpty) {
        return DateTime.parse(firstAirDate).year.toString();
      }
    } else if (widget.onlineMediaData != null) {
      return widget.onlineMediaData!.year;
    }
    return null;
  }
}
