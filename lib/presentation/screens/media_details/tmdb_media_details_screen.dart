import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stream_flutter/presentation/screens/media_details/widgets/media_details_app_bar.dart';
import 'package:stream_flutter/presentation/screens/media_details/widgets/media_details_content.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/models/tmdb_models.dart';
import '../../providers/media_details/media_details_provider.dart';

class TmdbMediaDetailsScreen extends StatefulWidget {
  final int tmdbId;
  final MediaType type;

  const TmdbMediaDetailsScreen({
    super.key,
    required this.tmdbId,
    required this.type,
  });

  @override
  State<TmdbMediaDetailsScreen> createState() => _TmdbMediaDetailsScreenState();
}

class _TmdbMediaDetailsScreenState extends State<TmdbMediaDetailsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MediaDetailsProvider>().loadTmdbMediaDetails(
        widget.tmdbId,
        widget.type,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MediaDetailsProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          backgroundColor: AppTheme.backgroundBlue,
          extendBodyBehindAppBar: true,
          body: Container(
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
            child: MediaDetailsAppBar(
              title: provider.tmdbMediaData?.title ?? 'Details',
              backdropPath: provider.tmdbMediaData?.backdropPath,
              child: MediaDetailsContent(
                provider: provider,
                mediaType: widget.type,
                tmdbId: widget.tmdbId,
              ),
            ),
          ),
        );
      },
    );
  }
}
