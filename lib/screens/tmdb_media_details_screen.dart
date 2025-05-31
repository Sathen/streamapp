import 'package:flutter/material.dart';
import 'package:stream_flutter/services/media_service.dart';
import '../models/tmdb_models.dart';

class MediaDetailsScreen extends StatefulWidget {
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

class _MediaDetailsScreenState extends State<MediaDetailsScreen> {
  final tmdbService = MediaService(null, null, null);
  bool isLoading = true;

  TmdbMediaDetails? _mediaData;
  List<TVSeasonDetails>? seasonDetails;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);
    _mediaData = null;
    seasonDetails = null;

    if (widget.type == MediaType.movie) {
      _mediaData = await tmdbService.fetchMovieDetails(widget.tmdbId);
    } else if (widget.type == MediaType.tv) {
      final tvSpecificDetails = await tmdbService.fetchTVDetails(widget.tmdbId);
      _mediaData = tvSpecificDetails;
      seasonDetails = await Future.wait(
        tvSpecificDetails.seasons.map(
          (s) =>
              tmdbService.fetchTVSeasonDetails(widget.tmdbId, s.seasonNumber),
        ),
      );
    }

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final backdropPath = _mediaData?.backdropPath;
    final posterPath = _mediaData?.posterPath;
    final title = _mediaData?.title ?? 'Details';
    final overview = _mediaData?.overview;
    final genresList = _mediaData?.genres.map((g) => g.name).toList();
    final rating = _mediaData?.voteAverage;
    final voteCount = _mediaData?.voteCount;

    // Movie specific
    final releaseDate = (_mediaData is MovieDetails) ? (_mediaData as MovieDetails).releaseDate : null;
    final runtime = (_mediaData is MovieDetails) ? (_mediaData as MovieDetails).runtime : null;

    // TV specific
    final firstAirDate = (_mediaData is TVDetails) ? (_mediaData as TVDetails).firstAirDate : null;
    // final episodeRunTime = (_mediaData is TVDetails) ? (_mediaData as TVDetails).episodeRunTime : null;

    return Scaffold(
      extendBodyBehindAppBar: true, // Allow body to extend behind AppBar
      body: CustomScrollView(
        slivers: <Widget>[
          SliverAppBar(
            expandedHeight: 250.0,
            floating: false,
            pinned: true,
            stretch: true,
            elevation: 0, // Match online_media_details_screen.dart style
            title: Text(title, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
            backgroundColor: theme.colorScheme.primary.withOpacity(0.8), // Kept for pinned title readability
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [StretchMode.zoomBackground],
              centerTitle: true,
              titlePadding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
              background: backdropPath != null
                  ? Image.network(
                      'https://image.tmdb.org/t/p/w780$backdropPath',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey[800]),
                    )
                  : Container(color: Colors.grey[800]),
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.favorite_border, color: Colors.white),
                onPressed: () {
                  // TODO: Implement favorite action
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Favorite action not implemented yet.')),
                  );
                },
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (posterPath != null)
                        SizedBox(
                          width: 120,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8.0),
                            child: Image.network(
                              'https://image.tmdb.org/t/p/w342$posterPath',
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => 
                                Container(height: 180, color: Colors.grey[300], child: Icon(Icons.movie, size: 50, color: Colors.grey[600])),
                            ),
                          ),
                        ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(title, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            if (genresList != null && genresList.isNotEmpty)
                              Text('Genres: ${genresList.join(', ')}', style: theme.textTheme.bodyMedium),
                            const SizedBox(height: 4),
                            if (rating != null)
                              Row(
                                children: [
                                  Icon(Icons.star, color: Colors.amber, size: 20),
                                  const SizedBox(width: 4),
                                  Text('${rating.toStringAsFixed(1)}/10', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                                  if (voteCount != null)
                                    Text(' ($voteCount votes)', style: theme.textTheme.bodySmall),
                                ],
                              ),
                            const SizedBox(height: 8),
                            if (releaseDate != null && releaseDate.isNotEmpty)
                              Text('Release: $releaseDate', style: theme.textTheme.bodyMedium),
                            if (runtime != null && runtime > 0)
                              Text('Runtime: $runtime min', style: theme.textTheme.bodyMedium),
                            if (firstAirDate != null && firstAirDate.isNotEmpty)
                              Text('First Air: $firstAirDate', style: theme.textTheme.bodyMedium),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text('Overview', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(overview ?? 'No overview available.', style: theme.textTheme.bodyLarge, textAlign: TextAlign.justify),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          if (widget.type == MediaType.tv && seasonDetails != null && seasonDetails!.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text('Seasons', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              ),
            ),
          if (widget.type == MediaType.tv && seasonDetails != null)
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (BuildContext context, int index) {
                  final season = seasonDetails![index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
                    child: _buildSeasonCard(season, theme),
                  );
                },
                childCount: seasonDetails!.length,
              ),
            ),
          if (_mediaData?.productionCompanies != null && _mediaData!.productionCompanies.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Production Companies', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12.0,
                      runSpacing: 8.0,
                      children: _mediaData!.productionCompanies.map((company) {
                        return Chip(
                          avatar: company.logoPath != null
                              ? CircleAvatar(
                                  backgroundImage: NetworkImage('https://image.tmdb.org/t/p/w92${company.logoPath}'),
                                  backgroundColor: Colors.transparent,
                                )
                              : null,
                          label: Text(company.name, style: theme.textTheme.bodySmall),
                          backgroundColor: theme.colorScheme.surfaceVariant,
                          side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
          SliverToBoxAdapter(child: SizedBox(height: 20)), // Bottom padding
        ],
      ),
    );
  }

  Widget _buildSeasonCard(TVSeasonDetails season, ThemeData theme) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      elevation: 2.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      clipBehavior: Clip.antiAlias, // Ensures content respects border radius
      child: ExpansionTile(
        backgroundColor: theme.colorScheme.surfaceVariant.withOpacity(0.3),
        collapsedBackgroundColor: theme.colorScheme.surface.withOpacity(0.5),
        title: Text('Season ${season.seasonNumber}: ${season.name}', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        subtitle: Text('${season.episodes.length} episodes • ${season.airDate ?? 'N/A'}', style: theme.textTheme.bodySmall),
        childrenPadding: EdgeInsets.zero,
        tilePadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        children: season.episodes.map((e) {
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
            leading: e.stillPath != null
                ? SizedBox(
                    width: 120, 
                    height: 67.5, // 16:9 aspect ratio for 120 width
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6.0),
                      child: Image.network(
                        'https://image.tmdb.org/t/p/w300${e.stillPath}', // w300 for better quality still
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => 
                          Container(color: Colors.grey[300], child: Icon(Icons.broken_image, size: 30, color: Colors.grey[600])),
                      ),
                    ),
                  )
                : Container(width: 120, height: 67.5, decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(6.0)), child: Icon(Icons.tv, size: 40, color: Colors.grey[500])),
            title: Text('E${e.episodeNumber}: ${e.name}', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (e.airDate.isNotEmpty) Text('Aired: ${e.airDate}', style: theme.textTheme.bodySmall?.copyWith(color: theme.textTheme.bodySmall?.color?.withOpacity(0.8))),
                if (e.overview.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    e.overview,
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.textTheme.bodySmall?.color?.withOpacity(0.7)),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ]
              ],
            ),
            isThreeLine: e.overview.isNotEmpty, // Allow more space if overview is present
            // onTap: () { /* TODO: Implement episode tap action */ },
          );
        }).toList(),
      ),
    );
  }
}
