import 'package:flutter/material.dart';
import 'package:stream_flutter/providers/download_manager.dart';
import 'package:stream_flutter/screens/medi_list/season_episode_switcher.dart';
import 'package:stream_flutter/screens/media_back_drop_appbar.dart';
import 'package:stream_flutter/screens/movie_play_button.dart';

import '../data/models/models/generic_media_details.dart';
import '../data/models/models/online_media_details_entity.dart';
import '../data/models/models/search_result.dart';
import 'base_media_screen.dart';
import 'media_header_section.dart';

class OnlineMediaDetailScreen extends BaseMediaDetailScreen {
  final SearchItem searchItem;

  const OnlineMediaDetailScreen({super.key, required this.searchItem});

  @override
  State<OnlineMediaDetailScreen> createState() =>
      _OnlineMediaDetailScreenState();
}

class _OnlineMediaDetailScreenState
    extends BaseMediaDetailScreenState<OnlineMediaDetailScreen>
    with TickerProviderStateMixin {
  OnlineMediaDetailsEntity? _mediaDetails;
  OnlineMediaDetailsEpisode? _loadingEpisode;

  AnimationController? _contentAnimationController;
  AnimationController? _loadingAnimationController;
  Animation<double>? _fadeInAnimation;
  Animation<Offset>? _slideInAnimation;
  Animation<double>? _loadingPulseAnimation;

  @override
  void initState() {
    _initializeAnimations();
    super.initState();
  }

  void _initializeAnimations() {
    _contentAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _loadingAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeInAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _contentAnimationController!,
        curve: Curves.easeOutCubic,
      ),
    );

    _slideInAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _contentAnimationController!,
        curve: Curves.easeOutCubic,
      ),
    );

    _loadingPulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(
        parent: _loadingAnimationController!,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _contentAnimationController?.dispose();
    _loadingAnimationController?.dispose();
    super.dispose();
  }

  @override
  Future<void> loadData() async {
    setLoadingState(true);
    _loadingAnimationController?.repeat(reverse: true);

    try {
      final mediaDetail = await serverApi.get(widget.searchItem);

      if (!mounted) return;

      _loadingAnimationController?.stop();
      _contentAnimationController?.forward();

      setState(() {
        _mediaDetails = mediaDetail;
        isLoading = false;
        errorMessage = null;
      });
    } catch (e) {
      _loadingAnimationController?.stop();
      handleError(e, 'Failed to load media details. Please try again.');
    }
  }

  @override
  Widget buildContent() {
    final theme = Theme.of(context);

    if (isLoading) {
      return _buildLoadingState(theme);
    }

    if (_mediaDetails == null) {
      return _buildErrorState(theme);
    }

    final mediaDetails = _mediaDetails!;

    return FadeTransition(
      opacity: _fadeInAnimation ?? const AlwaysStoppedAnimation(1.0),
      child: SlideTransition(
        position:
            _slideInAnimation ?? const AlwaysStoppedAnimation(Offset.zero),
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Enhanced backdrop app bar
            MediaBackdropAppBar(
              title: mediaDetails.title,
              backdropPath: mediaDetails.backdropPath,
            ),

            // Header section with enhanced styling
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.surface,
                      theme.colorScheme.surfaceVariant.withOpacity(0.3),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
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
                child: MediaHeaderSection(mediaDetail: mediaDetails),
              ),
            ),

            // Enhanced spacing
            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            // Movie play button with enhanced styling
            if (mediaDetails.seasons.isEmpty)
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildEnhancedPlayButton(theme, mediaDetails),
                ),
              ),

            // TV seasons list with enhanced container
            if (mediaDetails.seasons.isNotEmpty)
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                sliver: SliverToBoxAdapter(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          theme.colorScheme.surface,
                          theme.colorScheme.surfaceVariant.withOpacity(0.3),
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
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                        BoxShadow(
                          color: theme.colorScheme.secondary.withOpacity(0.05),
                          blurRadius: 24,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const SizedBox(height: 8),
                        _buildSeasonsContent(mediaDetails, theme),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
              ),

            // Enhanced bottom padding
            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            theme.colorScheme.surface,
            theme.colorScheme.surfaceVariant.withOpacity(0.3),
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation:
                  _loadingPulseAnimation ?? const AlwaysStoppedAnimation(1.0),
              builder: (context, child) {
                final animationValue = _loadingPulseAnimation?.value ?? 1.0;
                return Transform.scale(
                  scale: animationValue,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          theme.colorScheme.primary.withOpacity(0.2),
                          theme.colorScheme.secondary.withOpacity(0.1),
                        ],
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: theme.colorScheme.primary.withOpacity(0.3),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.primary.withOpacity(0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        theme.colorScheme.primary,
                      ),
                      strokeWidth: 4,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 32),
            Text(
              'Loading online media...',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.8),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Fetching content details from server',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            theme.colorScheme.surface,
            theme.colorScheme.surfaceVariant.withOpacity(0.3),
          ],
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.error.withOpacity(0.15),
                      theme.colorScheme.error.withOpacity(0.05),
                    ],
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: theme.colorScheme.error.withOpacity(0.3),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.error.withOpacity(0.1),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.cloud_off_outlined,
                  size: 64,
                  color: theme.colorScheme.error,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Content Not Available',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Unable to load content details from the server.\nPlease check your connection and try again.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Go Back'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.colorScheme.onSurface.withOpacity(
                        0.8,
                      ),
                      side: BorderSide(
                        color: theme.colorScheme.outline.withOpacity(0.5),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  FilledButton.icon(
                    onPressed: () => loadData(),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                    style: FilledButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedPlayButton(
    ThemeData theme,
    OnlineMediaDetailsEntity mediaDetails,
  ) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.surface,
            theme.colorScheme.surfaceVariant.withOpacity(0.3),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withOpacity(0.1),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.05),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: MoviePlayButton(
          onPlayPressed: () => _handleMoviePlay(mediaDetails),
          episodeKey: generateMovieKey(mediaDetails.title),
          theme: theme,
          isFetchingStreams: isFetchingStreams,
        ),
      ),
    );
  }

  @override
  PreferredSizeWidget? buildAppBar() {
    return null;
  }

  Widget _buildSeasonsContent(
    OnlineMediaDetailsEntity mediaDetails,
    ThemeData theme,
  ) {
    if (mediaDetails.seasons.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(
              Icons.tv_off,
              size: 48,
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              "No seasons available",
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ),
      );
    }

    // Cast to the generic types that SeasonEpisodeSwitcher expects
    final List<OnlineMediaDetailsSeasons> genericSeasons =
        mediaDetails.seasons.cast<OnlineMediaDetailsSeasons>().toList();
    final GenericEpisode? genericLoadingEpisode = _loadingEpisode;
    final OnlineMediaDetailsEntity genericMediaData = mediaDetails;

    final String mediaIdForSwitcher = mediaDetails.title.replaceAll(' ', '_');

    return SeasonEpisodeSwitcher(
      allSeasons: genericSeasons,
      mediaId: mediaIdForSwitcher,
      mediaData: genericMediaData,
      loadingEpisode: genericLoadingEpisode,
      onEpisodeTap: (
        GenericSeason season,
        GenericEpisode episode,
        String? embedUrl,
        String? contentTitle,
      ) {
        if (season is OnlineMediaDetailsSeasons &&
            episode is OnlineMediaDetailsEpisode) {
          _handleEpisodeTap(season, episode, embedUrl, contentTitle);
        } else {
          debugPrint(
            "Error: Could not cast GenericSeason/GenericEpisode back to Online Media specific types.",
          );
        }
      },
    );
  }

  Future<void> _handleMoviePlay(OnlineMediaDetailsEntity mediaDetails) async {
    if (mediaDetails.embedUrl == null) {
      _showEnhancedSnackbar(
        'Stream Not Available',
        'No embed URL available for this movie.',
        Icons.warning_amber,
        Theme.of(context).colorScheme.error,
      );
      return;
    }

    try {
      await showStreamSelectorFromEmbedUrl(
        context: context,
        embedUrl: mediaDetails.embedUrl!,
        contentTitle: mediaDetails.title,
        episodeKey: generateMovieKey(mediaDetails.title),
        fileName: mediaDetails.title.replaceAll(" ", "_"),
      );
    } catch (e) {
      if (mounted) {
        _showEnhancedSnackbar(
          'Playback Error',
          'Failed to start playback. Please try again.',
          Icons.error_outline,
          Theme.of(context).colorScheme.error,
        );
      }
    }
  }

  Future<void> _handleEpisodeTap(
    season,
    OnlineMediaDetailsEpisode episode,
    String? embedUrl,
    String? contentTitle,
  ) async {
    if (_mediaDetails == null || embedUrl == null) {
      _showEnhancedSnackbar(
        'Episode Unavailable',
        'No stream available for this episode.',
        Icons.warning_amber,
        Theme.of(context).colorScheme.error,
      );
      return;
    }

    setState(() {
      _loadingEpisode = episode;
    });

    try {
      await showStreamSelectorFromEmbedUrl(
        context: context,
        embedUrl: embedUrl,
        contentTitle: contentTitle ?? _mediaDetails!.title,
        episodeKey: generateEpisodeKey(
          _mediaDetails!.tmdbId,
          season.seasonNumber.toString(),
          episode.episodeNumber.toString(),
        ),
        fileName:
            '${_mediaDetails!.title.replaceAll(" ", "_")}_S${season.seasonNumber}.E${episode.episodeNumber}',
      );
    } catch (e) {
      debugPrint('Error showing stream selector: $e');
      if (mounted) {
        _showEnhancedSnackbar(
          'Stream Error',
          'Failed to load episode stream. Please try again.',
          Icons.error_outline,
          Theme.of(context).colorScheme.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _loadingEpisode = null;
        });
      }
    }
  }

  void _showEnhancedSnackbar(
    String title,
    String message,
    IconData icon,
    Color color,
  ) {
    if (!mounted) return;

    final theme = Theme.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Container(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      message,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        backgroundColor: theme.colorScheme.surfaceVariant,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: theme.colorScheme.outline.withOpacity(0.2)),
        ),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
      ),
    );
  }
}
