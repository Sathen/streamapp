import 'package:flutter/material.dart';

import '../models/online_media_details_entity.dart';
import '../models/tmdb_models.dart';

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

class _MediaHeaderSectionState extends State<MediaHeaderSection>
    with SingleTickerProviderStateMixin {
  bool _isOverviewExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title Section with enhanced styling
              if (title != null) _buildTitleSection(theme, title),

              const SizedBox(height: 20),

              // Genre Tags with improved design
              if (genres != null && genres.isNotEmpty)
                _buildGenreTags(theme, genres),

              const SizedBox(height: 24),

              // Rating and Meta Info Section with enhanced cards
              _buildInfoSection(theme, rating, voteCount, releaseDate, runtime, firstAirDate),

              const SizedBox(height: 32),

              // Overview Section with premium styling
              _buildOverviewSection(theme, overview),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTitleSection(ThemeData theme, String title) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.8,
              height: 1.1,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 4,
            width: 60,
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
    );
  }

  Widget _buildGenreTags(ThemeData theme, List<String> genres) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: genres.map((genre) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.primary.withOpacity(0.15),
              theme.colorScheme.secondary.withOpacity(0.1),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: theme.colorScheme.primary.withOpacity(0.4),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.primary.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          genre,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.primary,
            letterSpacing: 0.3,
          ),
        ),
      )).toList(),
    );
  }

  Widget _buildInfoSection(ThemeData theme, double? rating, int? voteCount,
      String? releaseDate, int? runtime, String? firstAirDate) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.surfaceVariant.withOpacity(0.6),
            theme.colorScheme.surface.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withOpacity(0.15),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.05),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          // Rating Row with enhanced design
          if (rating != null) _buildRatingRow(theme, rating, voteCount),

          if (rating != null && (releaseDate != null || runtime != null || firstAirDate != null))
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Divider(
                color: theme.colorScheme.outline.withOpacity(0.2),
                thickness: 1,
              ),
            ),

          // Meta Info Row with improved layout
          _buildMetaInfoRow(theme, releaseDate, runtime, firstAirDate),
        ],
      ),
    );
  }

  Widget _buildRatingRow(ThemeData theme, double rating, int? voteCount) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.amber.withOpacity(0.2),
                Colors.orange.withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.amber.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Icon(
            Icons.star_rounded,
            color: Colors.amber.shade600,
            size: 28,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${rating.toStringAsFixed(1)}/10',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              if (voteCount != null)
                Text(
                  '${_formatVoteCount(voteCount)} reviews',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
        ),
        _buildRatingIndicator(theme, rating),
      ],
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

  Widget _buildRatingIndicator(ThemeData theme, double rating) {
    final percentage = (rating / 10.0).clamp(0.0, 1.0);
    Color ratingColor;
    Color backgroundColor;

    if (percentage >= 0.7) {
      ratingColor = const Color(0xFF4CAF50); // Green
      backgroundColor = const Color(0xFF4CAF50).withOpacity(0.1);
    } else if (percentage >= 0.5) {
      ratingColor = const Color(0xFFFF9800); // Orange
      backgroundColor = const Color(0xFFFF9800).withOpacity(0.1);
    } else {
      ratingColor = const Color(0xFFF44336); // Red
      backgroundColor = const Color(0xFFF44336).withOpacity(0.1);
    }

    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: backgroundColor,
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
              width: 56,
              height: 56,
              child: CircularProgressIndicator(
                value: 1.0,
                strokeWidth: 5,
                backgroundColor: theme.colorScheme.outline.withOpacity(0.2),
                color: Colors.transparent,
              ),
            ),
          ),
          Center(
            child: SizedBox(
              width: 56,
              height: 56,
              child: CircularProgressIndicator(
                value: percentage,
                strokeWidth: 5,
                backgroundColor: Colors.transparent,
                color: ratingColor,
              ),
            ),
          ),
          Center(
            child: Text(
              '${(percentage * 100).round()}%',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: ratingColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaInfoRow(ThemeData theme, String? releaseDate, int? runtime, String? firstAirDate) {
    final metaItems = <Widget>[];

    if (releaseDate != null && releaseDate.isNotEmpty) {
      metaItems.add(_buildMetaItem(
        theme,
        Icons.calendar_today_rounded,
        'Release',
        releaseDate,
        theme.colorScheme.secondary,
      ));
    }

    if (runtime != null && runtime > 0) {
      metaItems.add(_buildMetaItem(
        theme,
        Icons.access_time_rounded,
        'Runtime',
        '${runtime}m',
        theme.colorScheme.primary,
      ));
    }

    if (firstAirDate != null && firstAirDate.isNotEmpty) {
      metaItems.add(_buildMetaItem(
        theme,
        Icons.tv_rounded,
        'First Air',
        firstAirDate,
        const Color(0xFF9C27B0), // Purple
      ));
    }

    if (metaItems.isEmpty) return const SizedBox.shrink();

    return Column(
      children: metaItems.map((item) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: item,
      )).toList(),
    );
  }

  Widget _buildMetaItem(ThemeData theme, IconData icon, String label, String value, Color accentColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: accentColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: accentColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 18,
              color: accentColor,
            ),
          ),
          const SizedBox(width: 16),
          Text(
            '$label: ',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface.withOpacity(0.8),
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewSection(ThemeData theme, String? overview) {
    final hasOverview = overview != null && overview.isNotEmpty;
    final overviewText = overview ?? 'No overview available.';
    final shouldShowExpansion = overviewText.length > 200;
    final truncatedOverview = shouldShowExpansion
        ? '${overviewText.substring(0, 200)}...'
        : overviewText;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.surface,
            theme.colorScheme.surfaceVariant.withOpacity(0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.05),
            blurRadius: 32,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primary.withOpacity(0.2),
                      theme.colorScheme.secondary.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: theme.colorScheme.primary.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Icon(
                  Icons.description_rounded,
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Overview',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      height: 2,
                      width: 40,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            theme.colorScheme.primary,
                            theme.colorScheme.secondary,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 400),
            crossFadeState: _isOverviewExpanded || !shouldShowExpansion
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: Text(
              truncatedOverview,
              style: theme.textTheme.bodyLarge?.copyWith(
                height: 1.7,
                color: theme.colorScheme.onSurface.withOpacity(0.85),
                fontWeight: FontWeight.w400,
              ),
            ),
            secondChild: Text(
              overviewText,
              style: theme.textTheme.bodyLarge?.copyWith(
                height: 1.7,
                color: theme.colorScheme.onSurface.withOpacity(0.85),
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          if (shouldShowExpansion) ...[
            const SizedBox(height: 16),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => setState(() => _isOverviewExpanded = !_isOverviewExpanded),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.primary.withOpacity(0.1),
                        theme.colorScheme.secondary.withOpacity(0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.colorScheme.primary.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _isOverviewExpanded ? 'Show less' : 'Read more',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 8),
                      AnimatedRotation(
                        duration: const Duration(milliseconds: 300),
                        turns: _isOverviewExpanded ? 0.5 : 0,
                        child: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: theme.colorScheme.primary,
                          size: 22,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}