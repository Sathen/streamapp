// media_backdrop_app_bar.dart
import 'package:flutter/material.dart';

class MediaBackdropAppBar extends StatelessWidget {
  final String title;
  final String? backdropPath;

  const MediaBackdropAppBar({
    super.key,
    required this.title,
    this.backdropPath,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SliverAppBar(
      expandedHeight: 250.0,
      floating: false,
      pinned: true,
      stretch: true,
      elevation: 0,
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
      backgroundColor: theme.colorScheme.primary.withOpacity(0.8),
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground],
        centerTitle: true,
        titlePadding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
        background: Stack(
          fit: StackFit.expand,
          children: [
            backdropPath != null
                ? Image.network(
                  'https://image.tmdb.org/t/p/w780$backdropPath',
                  fit: BoxFit.cover,
                  errorBuilder:
                      (context, error, stackTrace) =>
                          Container(color: Colors.grey[800]),
                )
                : Container(color: Colors.grey[800]),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.2),
                    Colors.black.withOpacity(0.7),
                    theme.scaffoldBackgroundColor.withOpacity(0.9),
                    theme.scaffoldBackgroundColor,
                  ],
                  stops: const [0.0, 0.4, 0.6, 0.8, 1.0],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
