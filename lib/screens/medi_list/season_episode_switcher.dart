import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../models/generic_media_details.dart';
import '../../providers/download_manager.dart';
import 'episode_list_item.dart';

class SeasonEpisodeSwitcher extends StatefulWidget {
  final List<GenericSeason> allSeasons;
  final String? mediaId;
  final GenericMediaData? mediaData;
  final GenericEpisode? loadingEpisode;
  final Function(GenericSeason season, GenericEpisode episode, String? embedUrl, String? contentTitle) onEpisodeTap;

  const SeasonEpisodeSwitcher({
    super.key,
    required this.allSeasons,
    this.mediaId,
    this.mediaData,
    this.loadingEpisode,
    required this.onEpisodeTap,
  });

  @override
  State<SeasonEpisodeSwitcher> createState() => _SeasonEpisodeSwitcherState();
}

class _SeasonEpisodeSwitcherState extends State<SeasonEpisodeSwitcher>
    with TickerProviderStateMixin {
  late GenericSeason _selectedSeason;
  List<GenericSeason> _displayableSeasons = [];
  late AnimationController _animationController;
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
    _setupAnimations();
    _updateDisplayableSeasonsAndSelectDefault();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.forward();
  }

  void _updateDisplayableSeasonsAndSelectDefault() {
    _displayableSeasons = widget.allSeasons.where((s) => s.seasonNumber > 0).toList();

    if (_displayableSeasons.isNotEmpty) {
      _selectedSeason = _displayableSeasons.first;
    }
  }

  @override
  void didUpdateWidget(covariant SeasonEpisodeSwitcher oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.allSeasons != oldWidget.allSeasons) {
      _updateDisplayableSeasonsAndSelectDefault();
      _animationController.reset();
      _animationController.forward();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onSeasonChanged(int seasonNumber) {
    setState(() {
      _selectedSeason = _displayableSeasons.firstWhere(
            (s) => s.seasonNumber == seasonNumber,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_displayableSeasons.isEmpty) {
      return _buildEmptyState(theme);
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Season selector - only show if multiple seasons
          if (_displayableSeasons.length > 1) ...[
            _buildSeasonSelector(theme),
            SizedBox(height: _isPortraitPhone ? 16 : 20),
          ],

          // Episodes list
          _buildEpisodesList(theme),
        ],
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
            "No episodes available",
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSeasonSelector(ThemeData theme) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: _isPortraitPhone ? 16 : 20),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _displayableSeasons.asMap().entries.map((entry) {
            final index = entry.key;
            final season = entry.value;
            final isSelected = _selectedSeason.seasonNumber == season.seasonNumber;

            return Container(
              margin: EdgeInsets.only(right: _isPortraitPhone ? 8 : 12),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _onSeasonChanged(season.seasonNumber),
                  borderRadius: BorderRadius.circular(_isPortraitPhone ? 20 : 24),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: EdgeInsets.symmetric(
                      horizontal: _isPortraitPhone ? 16 : 20,
                      vertical: _isPortraitPhone ? 8 : 10,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.surfaceVariant.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(_isPortraitPhone ? 20 : 24),
                    ),
                    child: Text(
                      'Season ${season.seasonNumber}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: _isPortraitPhone ? 13 : 14,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: isSelected
                            ? Colors.white
                            : theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildEpisodesList(ThemeData theme) {
    if (_selectedSeason.episodes.isEmpty) {
      return Container(
        padding: EdgeInsets.all(_isPortraitPhone ? 32 : 48),
        child: Column(
          children: [
            Icon(
              Icons.playlist_remove_rounded,
              size: _isPortraitPhone ? 40 : 48,
              color: theme.colorScheme.onSurface.withOpacity(0.3),
            ),
            SizedBox(height: _isPortraitPhone ? 12 : 16),
            Text(
              "No episodes in Season ${_selectedSeason.seasonNumber}",
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _selectedSeason.episodes.length,
      separatorBuilder: (context, index) => Container(
        height: 1,
        margin: EdgeInsets.symmetric(horizontal: _isPortraitPhone ? 16 : 20),
        color: theme.colorScheme.outline.withOpacity(0.1),
      ),
      itemBuilder: (context, index) {
        final episode = _selectedSeason.episodes[index];
        final bool isCurrentlyLoading = widget.loadingEpisode?.episodeNumber == episode.episodeNumber;
        final String episodeKey = generateEpisodeKey(
          widget.mediaData!.tmdbId,
          _selectedSeason.seasonNumber.toString(),
          episode.episodeNumber.toString(),
        );

        return EpisodeListItem(
          episode: episode,
          season: _selectedSeason,
          mediaData: widget.mediaData,
          episodeKey: episodeKey,
          isCurrentlyLoading: isCurrentlyLoading,
          onTap: () {
            widget.onEpisodeTap(
              _selectedSeason,
              episode,
              episode.embedUrl,
              widget.mediaData?.title,
            );
          },
        );
      },
    );
  }
}