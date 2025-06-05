
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../models/generic_media_details.dart';
import '../../providers/download_manager.dart';
import 'episode_list_item.dart';

class SeasonEpisodeSwitcher extends StatefulWidget {
  final List<GenericSeason> allSeasons;
  final String? mediaId; // tmdbId or similar, used for generating unique keys
  final GenericMediaData? mediaData; // For overall media title
  final GenericEpisode? loadingEpisode; // To show loading state on a specific episode
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

class _SeasonEpisodeSwitcherState extends State<SeasonEpisodeSwitcher> {
  late GenericSeason _selectedSeason;
  List<GenericSeason> _displayableSeasons = [];

  @override
  void initState() {
    super.initState();
    _updateDisplayableSeasonsAndSelectDefault();
  }

  void _updateDisplayableSeasonsAndSelectDefault() {
    // Filter out seasons with seasonNumber 0 (Specials)
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
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_displayableSeasons.isEmpty) {
      // This case means only season 0 was present, or no seasons at all.
      return SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(_selectedSeason.title, style: theme.textTheme.titleMedium),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Only show switcher if there's more than one displayable (non-special) season
        if (_displayableSeasons.length > 1)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: SegmentedButton<int>(
              segments: _displayableSeasons.map((season) {
                return ButtonSegment<int>(
                  value: season.seasonNumber,
                  label: Text('Season ${season.seasonNumber}',
                      style: const TextStyle(fontSize: 13)),
                  // No icon for specials as they are filtered out
                );
              }).toList(),
              selected: <int>{_selectedSeason.seasonNumber},
              onSelectionChanged: (Set<int> newSelection) {
                setState(() {
                  // Find the season from _displayableSeasons (which are already filtered)
                  _selectedSeason = _displayableSeasons.firstWhere(
                        (s) => s.seasonNumber == newSelection.first,
                  );
                });
              },
              style: SegmentedButton.styleFrom(
                backgroundColor: colorScheme.surfaceVariant.withOpacity(0.5),
                foregroundColor: colorScheme.onSurfaceVariant,
                selectedForegroundColor: colorScheme.onPrimary,
                selectedBackgroundColor: colorScheme.primary,
                visualDensity: VisualDensity.compact,
              ),
              showSelectedIcon: false,
            ),
          )
        else if (_displayableSeasons.length == 1)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Text('Season ${_displayableSeasons.first.seasonNumber}',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),

        // Display episodes of the selected season (which will always be a non-special season or the empty placeholder)
        if ( _selectedSeason.episodes.isEmpty)
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Center(child: Text(
                "No episodes available for this season.",
                style: theme.textTheme.bodyMedium)),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _selectedSeason.episodes.length,
            itemBuilder: (context, index) {
              final episode = _selectedSeason.episodes[index];
              final bool isCurrentlyLoading = widget.loadingEpisode?.episodeNumber == episode.episodeNumber;
              final String episodeKey = generateEpisodeKey(
                widget.mediaId!,
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
            separatorBuilder: (context, index) => Divider(
              height: 1,
              thickness: 0.5,
              indent: 16,
              endIndent: 16,
              color: theme.dividerColor.withOpacity(0.5),
            ),
          ),
      ],
    );
  }
}