// lib/screens/widgets/online_media_seasons_list.dart
import 'package:flutter/material.dart';
import 'package:stream_flutter/models/online_media_details_entity.dart';
import 'package:stream_flutter/screens/medi_list/season_episode_switcher.dart';
import '../../models/generic_media_details.dart';

class OnlineMediaSeasonsList extends StatefulWidget {
  final OnlineMediaDetailsEntity mediaDetails;
  final OnlineMediaDetailsEpisode? loadingEpisode;
  final void Function(
      OnlineMediaDetailsSeasons season,
      OnlineMediaDetailsEpisode episode,
      String? embedUrl,
      String? contentTitle,
      ) onEpisodeTap;

  const OnlineMediaSeasonsList({
    super.key,
    required this.mediaDetails,
    required this.loadingEpisode,
    required this.onEpisodeTap,
  });

  @override
  State<OnlineMediaSeasonsList> createState() => _OnlineMediaSeasonsListState();
}

class _OnlineMediaSeasonsListState extends State<OnlineMediaSeasonsList>
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

    if (widget.mediaDetails.seasons.isEmpty) {
      return SliverToBoxAdapter(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: _buildEmptyState(theme),
        ),
      );
    }

    return SliverToBoxAdapter(
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: _buildSeasonsContent(theme),
      ),
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
            "This content doesn't have any episodes to stream.",
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
    // Cast to the generic types that SeasonEpisodeSwitcher expects
    final List<OnlineMediaDetailsSeasons> genericSeasons =
    widget.mediaDetails.seasons.cast<OnlineMediaDetailsSeasons>().toList();
    final GenericEpisode? genericLoadingEpisode = widget.loadingEpisode;
    final OnlineMediaDetailsEntity genericMediaData = widget.mediaDetails;

    // Generate a more robust media ID
    final String mediaIdForSwitcher = _generateMediaId();

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
            mediaId: mediaIdForSwitcher,
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
    return widget.mediaDetails.seasons
        .fold<int>(0, (sum, season) => sum + season.episodes.length);
  }

  String _generateMediaId() {
    // Create a more robust media ID using title and hashCode
    final baseId = widget.mediaDetails.title.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
    final hashSuffix = widget.mediaDetails.hashCode.abs().toString();
    return '${baseId}_$hashSuffix';
  }

  void _handleEpisodeTap(
      GenericSeason season,
      GenericEpisode episode,
      String? embedUrl,
      String? contentTitle,
      ) {
    if (season is OnlineMediaDetailsSeasons &&
        episode is OnlineMediaDetailsEpisode) {
      widget.onEpisodeTap(
        season,
        episode,
        embedUrl,
        contentTitle,
      );
    } else {
      // Enhanced error handling with user feedback
      debugPrint(
        "Error: Could not cast GenericSeason/GenericEpisode back to Online Media specific types in OnlineMediaSeasonsList.",
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