import 'package:flutter/material.dart';

import '../data/models/models/online_media_details_entity.dart';
import '../data/models/models/tmdb_models.dart';

class MediaHeaderSection extends StatefulWidget {
  final TmdbMediaDetails? media;
  final OnlineMediaDetailsEntity? mediaDetail;

  const MediaHeaderSection({
    super.key,
    this.media,
    this.mediaDetail,
  });

  @override
  State<MediaHeaderSection> createState() => _MediaHeaderSectionState();
}

class _MediaHeaderSectionState extends State<MediaHeaderSection> {
  bool _isOverviewExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.shortestSide >= 600;

    final title = widget.media?.title ?? widget.mediaDetail?.title;
    final overview = widget.media?.overview ?? widget.mediaDetail?.description;
    final genres = widget.media?.genres.map((g) => g.name).toList();
    final rating = widget.media?.voteAverage ?? widget.mediaDetail?.rating;
    final voteCount = widget.media?.voteCount;
    final releaseDate = (widget.media is MovieDetails)
        ? (widget.media as MovieDetails).releaseDate
        : widget.mediaDetail?.year?.toString();
    final runtime = (widget.media is MovieDetails)
        ? (widget.media as MovieDetails).runtime
        : null;
    final firstAirDate = (widget.media is TVDetails)
        ? (widget.media as TVDetails).firstAirDate
        : widget.mediaDetail?.year?.toString();

    return Padding(
      padding: EdgeInsets.all(screenSize.width * 0.04), // Adaptive padding
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Genre chips - adaptive design
          if (genres != null && genres.isNotEmpty) ...[
            _buildGenreChips(theme, genres, screenSize, isTablet),
            SizedBox(height: screenSize.height * 0.025), // Adaptive spacing
          ],

          // Rating and info card - adaptive
          if (rating != null || releaseDate != null || runtime != null || firstAirDate != null)
            _buildInfoCard(theme, rating, voteCount, releaseDate, runtime, firstAirDate, screenSize, isTablet),

          SizedBox(height: screenSize.height * 0.03),

          // Overview section - adaptive
          if (overview != null && overview.isNotEmpty)
            _buildOverviewSection(theme, overview, screenSize, isTablet),
        ],
      ),
    );
  }

  Widget _buildGenreChips(ThemeData theme, List<String> genres, Size screenSize, bool isTablet) {
    // Adaptive genre limit based on screen size
    final maxGenres = isTablet ? 6 : (screenSize.width > 360 ? 4 : 3);

    return Wrap(
      spacing: screenSize.width * 0.02, // Adaptive spacing
      runSpacing: screenSize.width * 0.02,
      children: genres.take(maxGenres).map((genre) => Container(
        padding: EdgeInsets.symmetric(
          horizontal: screenSize.width * 0.03,
          vertical: screenSize.height * 0.008,
        ),
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(screenSize.width * 0.05), // Adaptive border radius
          border: Border.all(
            color: theme.colorScheme.primary.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Text(
          genre,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onPrimaryContainer,
            fontSize: (screenSize.width * 0.03).clamp(10.0, 14.0), // Adaptive font size
          ),
        ),
      )).toList(),
    );
  }

  Widget _buildInfoCard(ThemeData theme, double? rating, int? voteCount,
      String? releaseDate, int? runtime, String? firstAirDate, Size screenSize, bool isTablet) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(screenSize.width * 0.04), // Adaptive padding
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(screenSize.width * 0.04), // Adaptive border radius
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Rating section
          if (rating != null) ...[
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(screenSize.width * 0.02),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(screenSize.width * 0.02),
                  ),
                  child: Icon(
                    Icons.star_rounded,
                    color: Colors.amber.shade700,
                    size: (screenSize.width * 0.05).clamp(16.0, 24.0), // Adaptive icon size
                  ),
                ),
                SizedBox(width: screenSize.width * 0.03),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${rating.toStringAsFixed(1)}/10',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: (screenSize.width * 0.04).clamp(14.0, 18.0),
                        ),
                      ),
                      if (voteCount != null)
                        Text(
                          '${_formatVoteCount(voteCount)} reviews',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                            fontSize: (screenSize.width * 0.03).clamp(10.0, 14.0),
                          ),
                        ),
                    ],
                  ),
                ),
                // Adaptive rating indicator
                _buildAdaptiveRatingIndicator(theme, rating, screenSize),
              ],
            ),
            SizedBox(height: screenSize.height * 0.02),
          ],

          // Meta information
          _buildMetaInfo(theme, releaseDate, runtime, firstAirDate, screenSize, isTablet),
        ],
      ),
    );
  }

  Widget _buildAdaptiveRatingIndicator(ThemeData theme, double rating, Size screenSize) {
    final percentage = (rating / 10.0).clamp(0.0, 1.0);
    final size = (screenSize.width * 0.12).clamp(40.0, 60.0); // Adaptive size

    Color ratingColor;
    if (percentage >= 0.7) {
      ratingColor = Colors.green;
    } else if (percentage >= 0.5) {
      ratingColor = Colors.orange;
    } else {
      ratingColor = Colors.red;
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: ratingColor.withOpacity(0.1),
        shape: BoxShape.circle,
        border: Border.all(
          color: ratingColor.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Stack(
        children: [
          Center(
            child: SizedBox(
              width: size * 0.75, // 75% of container size
              height: size * 0.75,
              child: CircularProgressIndicator(
                value: percentage,
                strokeWidth: (size * 0.08).clamp(2.0, 4.0), // Adaptive stroke width
                backgroundColor: theme.colorScheme.outline.withOpacity(0.2),
                color: ratingColor,
              ),
            ),
          ),
          Center(
            child: Text(
              '${(percentage * 100).round()}',
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: ratingColor,
                fontSize: (size * 0.2).clamp(8.0, 12.0), // Adaptive font size
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatVoteCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }

  Widget _buildMetaInfo(ThemeData theme, String? releaseDate, int? runtime,
      String? firstAirDate, Size screenSize, bool isTablet) {
    final metaItems = <Widget>[];

    if (releaseDate != null && releaseDate.isNotEmpty) {
      metaItems.add(_buildMetaChip(
        theme,
        Icons.calendar_today,
        releaseDate,
        screenSize,
      ));
    }

    if (runtime != null && runtime > 0) {
      metaItems.add(_buildMetaChip(
        theme,
        Icons.access_time,
        '${runtime}min',
        screenSize,
      ));
    }

    if (firstAirDate != null && firstAirDate.isNotEmpty) {
      metaItems.add(_buildMetaChip(
        theme,
        Icons.tv,
        firstAirDate,
        screenSize,
      ));
    }

    if (metaItems.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: screenSize.width * 0.02, // Adaptive spacing
      runSpacing: screenSize.width * 0.02,
      children: metaItems,
    );
  }

  Widget _buildMetaChip(ThemeData theme, IconData icon, String value, Size screenSize) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: screenSize.width * 0.02,
        vertical: screenSize.height * 0.005,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(screenSize.width * 0.02),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: (screenSize.width * 0.035).clamp(12.0, 16.0), // Adaptive icon size
            color: theme.colorScheme.onSurface.withOpacity(0.7),
          ),
          SizedBox(width: screenSize.width * 0.01),
          Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
              fontSize: (screenSize.width * 0.03).clamp(10.0, 14.0),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewSection(ThemeData theme, String overview, Size screenSize, bool isTablet) {
    // Adaptive threshold based on screen size
    final expansionThreshold = isTablet ? 250 : (screenSize.width > 360 ? 180 : 120);
    final shouldShowExpansion = overview.length > expansionThreshold;
    final truncatedOverview = shouldShowExpansion
        ? '${overview.substring(0, expansionThreshold)}...'
        : overview;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Row(
          children: [
            Icon(
              Icons.description_outlined,
              color: theme.colorScheme.primary,
              size: (screenSize.width * 0.05).clamp(18.0, 24.0), // Adaptive icon size
            ),
            SizedBox(width: screenSize.width * 0.02),
            Text(
              'Overview',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
                fontSize: (screenSize.width * 0.04).clamp(14.0, 18.0),
              ),
            ),
          ],
        ),
        SizedBox(height: screenSize.height * 0.015),

        // Overview text
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 300),
          crossFadeState: _isOverviewExpanded || !shouldShowExpansion
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          firstChild: Text(
            truncatedOverview,
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.5,
              color: theme.colorScheme.onSurface.withOpacity(0.8),
              fontSize: (screenSize.width * 0.035).clamp(12.0, 16.0),
            ),
          ),
          secondChild: Text(
            overview,
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.5,
              color: theme.colorScheme.onSurface.withOpacity(0.8),
              fontSize: (screenSize.width * 0.035).clamp(12.0, 16.0),
            ),
          ),
        ),

        // Read more/less button
        if (shouldShowExpansion) ...[
          SizedBox(height: screenSize.height * 0.01),
          GestureDetector(
            onTap: () => setState(() => _isOverviewExpanded = !_isOverviewExpanded),
            child: Text(
              _isOverviewExpanded ? 'Show less' : 'Read more',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
                fontSize: (screenSize.width * 0.035).clamp(12.0, 16.0),
              ),
            ),
          ),
        ],
      ],
    );
  }
}