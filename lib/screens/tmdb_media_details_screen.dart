// lib/screens/media_details_screen.dart
import 'package:flutter/material.dart';
import 'package:stream_flutter/screens/production_cast_section.dart';
import 'package:stream_flutter/screens/medi_list/tmdb_media_seasons_list.dart';
import 'package:stream_flutter/screens/theme.dart';
import 'package:stream_flutter/services/media_service.dart';
import 'package:stream_flutter/providers/download_manager.dart';

import '../models/tmdb_models.dart';
import '../util/errors.dart';
import 'base_media_screen.dart';
import 'media_back_drop_appbar.dart';
import 'media_header_section.dart';
import 'movie_play_button.dart';

class MediaDetailsScreen extends BaseMediaDetailScreen {
  final int tmdbId;
  final MediaType type;

  const MediaDetailsScreen({
    super.key,
    required this.tmdbId,
    required this.type,
  });

  @override
  State<MediaDetailsScreen> createState() => _MediaDetailsScreenState();
}

class _MediaDetailsScreenState
    extends BaseMediaDetailScreenState<MediaDetailsScreen>
    with TickerProviderStateMixin {
  final tmdbService = MediaService(null, null, null);
  TmdbMediaDetails? _mediaData;
  List<TVSeasonDetails>? _seasonDetails;
  TVEpisode? _loadingTappedEpisode;

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

    _fadeInAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _contentAnimationController!,
      curve: Curves.easeOutCubic,
    ));

    _slideInAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _contentAnimationController!,
      curve: Curves.easeOutCubic,
    ));

    _loadingPulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _loadingAnimationController!,
      curve: Curves.easeInOut,
    ));
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
      _mediaData = null;
      _seasonDetails = null;

      if (widget.type == MediaType.movie) {
        _mediaData = await tmdbService.fetchMovieDetails(widget.tmdbId);
      } else if (widget.type == MediaType.tv) {
        final tvSpecificDetails = await tmdbService.fetchTVDetails(
          widget.tmdbId,
        );
        _mediaData = tvSpecificDetails;
        _seasonDetails = await Future.wait(
          tvSpecificDetails.seasons.map(
                (s) =>
                tmdbService.fetchTVSeasonDetails(widget.tmdbId, s.seasonNumber),
          ),
        );
      }

      if (!mounted) return;

      _loadingAnimationController?.stop();
      _contentAnimationController?.forward();

      setState(() {
        isLoading = false;
        errorMessage = null;
      });
    } catch (e) {
      _loadingAnimationController?.stop();
      handleError(e, 'Failed to load media details. Please try again.');
    }
  }

  @override
  Null buildAppBar() {
    return null;
  }

  @override
  Widget buildContent() {
    if (isLoading) {
      return _buildLoadingState();
    }

    if (_mediaData == null) {
      return _buildErrorState();
    }

    final backdropPath = _mediaData?.backdropPath;
    final title = _mediaData?.title ?? 'Details';

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppTheme.backgroundBlue,
            AppTheme.surfaceBlue.withOpacity(0.1),
          ],
        ),
      ),
      child: FadeTransition(
        opacity: _fadeInAnimation ?? const AlwaysStoppedAnimation(1.0),
        child: SlideTransition(
          position: _slideInAnimation ?? const AlwaysStoppedAnimation(Offset.zero),
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: <Widget>[
              // Enhanced backdrop app bar
              MediaBackdropAppBar(title: title, backdropPath: backdropPath),

              // Header section with enhanced styling
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                    border: Border.all(
                      color: AppTheme.outlineVariant,
                      width: 1,
                    ),
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
                    child: MediaHeaderSection(media: _mediaData!),
                  ),
                ),
              ),

              // Enhanced spacing
              const SliverToBoxAdapter(child: SizedBox(height: 16)),

              // Movie play button with enhanced styling
              if (widget.type == MediaType.movie)
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    child: _buildEnhancedPlayButton(),
                  ),
                ),

              // TV seasons list with enhanced container
              if (widget.type == MediaType.tv && _seasonDetails != null)
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: TVSeasonsList(
                      seasonDetails: _seasonDetails!,
                      tmdbId: widget.tmdbId,
                      loadingEpisode: _loadingTappedEpisode,
                      mediaData: _mediaData,
                      onEpisodeTap: _handleTVEpisodeTap,
                    ),
                  ),
                ),

              // Enhanced spacing
              const SliverToBoxAdapter(child: SizedBox(height: 16)),

              // Production companies section with enhanced styling
              if (_mediaData?.productionCompanies != null &&
                  _mediaData!.productionCompanies.isNotEmpty)
                SliverToBoxAdapter(
                  child: ProductionCastSection(
                    theme: AppTheme.darkTheme,
                    companies: _mediaData!.productionCompanies,
                  ),
                ),

              // Enhanced bottom padding
              const SliverToBoxAdapter(
                child: SizedBox(height: 40),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppTheme.backgroundBlue,
            AppTheme.surfaceBlue.withOpacity(0.3),
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _loadingPulseAnimation ?? const AlwaysStoppedAnimation(1.0),
              builder: (context, child) {
                final animationValue = _loadingPulseAnimation?.value ?? 1.0;
                return Transform.scale(
                  scale: animationValue,
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceBlue,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.outlineVariant,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.accentBlue.withOpacity(0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: SizedBox(
                      width: 48,
                      height: 48,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppTheme.accentBlue,
                        ),
                        strokeWidth: 4,
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
              decoration: BoxDecoration(
                color: AppTheme.surfaceBlue,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.outlineVariant,
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    'Loading media details...',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppTheme.highEmphasisText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please wait while we fetch the information',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.mediumEmphasisText,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppTheme.backgroundBlue,
            AppTheme.surfaceBlue.withOpacity(0.3),
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
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceBlue,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: AppTheme.outlineVariant,
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppTheme.errorColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppTheme.errorColor.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        Icons.error_outline,
                        size: 48,
                        color: AppTheme.errorColor,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Media Not Found',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: AppTheme.highEmphasisText,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No media details found for this content.\nPlease try again or go back.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppTheme.mediumEmphasisText,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton.icon(
                      onPressed: () => loadData(),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedPlayButton() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.surfaceBlue,
            AppTheme.surfaceVariant.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.outlineVariant,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: AppTheme.primaryBlue.withOpacity(0.1),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: MoviePlayButton(
          episodeKey: generateMovieKey(widget.tmdbId.toString()),
          theme: Theme.of(context),
          isFetchingStreams: isFetchingStreams,
          onPlayPressed: () => _handleMoviePlay(),
        ),
      ),
    );
  }

  Future<void> _handleMoviePlay() async {
    if (_mediaData == null) return;

    try {
      await showStreamSelectorFromApi(
        context: context,
        title: _mediaData!.title,
        originalTitle: _mediaData!.originalTitle,
        movieDetails: _mediaData as MovieDetails,
        contentTitle: _mediaData!.title,
        episodeKey: generateMovieKey(widget.tmdbId.toString()),
        fileName: 'Movie_${widget.tmdbId}',
      );
    } catch (e) {
      if (mounted) {
        showErrorSnackbar(context, 'Error playing movie: $e');
      }
    }
  }

  Future<void> _handleTVEpisodeTap(
      TVSeasonDetails season,
      TVEpisode episode,
      String? seriesTitle,
      String? seriesOriginalTitle,
      ) async {
    if (_mediaData == null) return;

    setState(() {
      _loadingTappedEpisode = episode;
    });

    try {
      await showStreamSelectorFromApi(
        context: context,
        title: seriesTitle!,
        originalTitle: seriesOriginalTitle,
        season: season,
        episode: episode,
        contentTitle: seriesTitle,
        episodeKey: generateEpisodeKey(
          _mediaData!.id.toString(),
          season.seasonNumber.toString(),
          episode.episodeNumber.toString(),
        ),
        fileName:
        '${seriesTitle.replaceAll(" ", "_")}_S${season.seasonNumber}E${episode.episodeNumber}',
      );
    } catch (e) {
      if (mounted) {
        showErrorSnackbar(context, 'Error fetching streams: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _loadingTappedEpisode = null;
        });
      }
    }
  }
}