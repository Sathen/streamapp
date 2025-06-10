// tv_seasons_list.dart
import 'package:flutter/material.dart';
import 'package:stream_flutter/models/tmdb_models.dart'; // Your specific TMDB models
import 'package:stream_flutter/screens/medi_list/season_episode_switcher.dart';
import '../../models/generic_media_details.dart'; // Your generic models

class TVSeasonsList extends StatefulWidget {
  final List<TVSeasonDetails> seasonDetails;
  final int tmdbId;
  final TVEpisode? loadingEpisode;
  final TmdbMediaDetails? mediaData;
  final void Function(
      TVSeasonDetails season,
      TVEpisode episode,
      String? embedUrl,
      String? contentTitle,
      ) onEpisodeTap;

  const TVSeasonsList({
    super.key,
    required this.seasonDetails,
    required this.tmdbId,
    required this.loadingEpisode,
    required this.mediaData,
    required this.onEpisodeTap,
  });

  @override
  State<TVSeasonsList> createState() => _TVSeasonsListState();
}

class _TVSeasonsListState extends State<TVSeasonsList>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  // Helper to check if device is in portrait mode and small
  bool get _isPortraitPhone {
    final size = MediaQuery.of(context).size;
    final orientation = MediaQuery.of(context).orientation;
    return orientation == Orientation.portrait && size.width < 600;
  }

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    ));

    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (widget.seasonDetails.isEmpty) {
      return FadeTransition(
        opacity: _fadeAnimation,
        child: _buildEmptyState(theme),
      );
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: _buildSeasonsContent(theme),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Container(
      padding: EdgeInsets.all(_isPortraitPhone ? 32 : 48),
      child: Column(
        children: [
          Icon(
            Icons.tv_off_rounded,
            size: _isPortraitPhone ? 48 : 64,
            color: theme.colorScheme.onSurface.withOpacity(0.3),
          ),
          SizedBox(height: _isPortraitPhone ? 16 : 24),
          Text(
            "No Episodes Available",
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: _isPortraitPhone ? 8 : 12),
          Text(
            "This TV show doesn't have any episodes available.",
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSeasonsContent(ThemeData theme) {
    final List<GenericSeason> genericSeasons =
    widget.seasonDetails.cast<GenericSeason>().toList();
    final GenericEpisode? genericLoadingEpisode = widget.loadingEpisode;
    final GenericMediaData? genericMediaData = widget.mediaData;

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: _isPortraitPhone ? 0 : 16,
        vertical: _isPortraitPhone ? 0 : 8,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Optional: Simple header (only show if useful)
          if (genericSeasons.length > 1 || _getTotalEpisodes() > 10)
            _buildSimpleHeader(theme),

          // Seasons content
          SeasonEpisodeSwitcher(
            allSeasons: genericSeasons,
            mediaId: widget.tmdbId.toString(),
            mediaData: genericMediaData,
            loadingEpisode: genericLoadingEpisode,
            onEpisodeTap: _handleEpisodeTap,
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleHeader(ThemeData theme) {
    final totalEpisodes = _getTotalEpisodes();

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: _isPortraitPhone ? 16 : 20,
        vertical: _isPortraitPhone ? 12 : 16,
      ),
      child: Row(
        children: [
          Icon(
            Icons.play_circle_outline_rounded,
            color: theme.colorScheme.primary,
            size: _isPortraitPhone ? 20 : 24,
          ),
          SizedBox(width: _isPortraitPhone ? 8 : 12),
          Text(
            'Episodes',
            style: theme.textTheme.titleLarge?.copyWith(
              fontSize: _isPortraitPhone ? 18 : 22,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const Spacer(),
          if (totalEpisodes > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$totalEpisodes',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: _isPortraitPhone ? 11 : 12,
                ),
              ),
            ),
        ],
      ),
    );
  }

  int _getTotalEpisodes() {
    return widget.seasonDetails
        .fold<int>(0, (sum, season) => sum + season.episodes.length);
  }

  void _handleEpisodeTap(
      GenericSeason season,
      GenericEpisode episode,
      String? embedUrl,
      String? contentTitle,
      ) {
    if (season is TVSeasonDetails && episode is TVEpisode) {
      widget.onEpisodeTap(
        season,
        episode,
        widget.mediaData?.title,
        widget.mediaData?.originalTitle,
      );
    } else {
      // Enhanced error handling with user feedback
      debugPrint(
        "Error: Could not cast GenericSeason/GenericEpisode back to TMDB specific types in TVSeasonsList.",
      );

      // Show simple error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Episode unavailable',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            ),
            backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }
}