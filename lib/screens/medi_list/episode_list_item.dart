import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/generic_media_details.dart';
import '../../providers/download_manager.dart';
import '../../screens/video_player_screen.dart'; // Add this import

class EpisodeListItem extends StatefulWidget {
  final GenericEpisode episode;
  final GenericSeason season;
  final GenericMediaData? mediaData;
  final String episodeKey;
  final bool isCurrentlyLoading;
  final VoidCallback onTap;

  const EpisodeListItem({
    super.key,
    required this.episode,
    required this.season,
    this.mediaData,
    required this.episodeKey,
    required this.isCurrentlyLoading,
    required this.onTap,
  });

  @override
  State<EpisodeListItem> createState() => _EpisodeListItemState();
}

class _EpisodeListItemState extends State<EpisodeListItem> {
  bool _isPressed = false;
  bool _isDownloadingFile = false;
  double _downloadProgress = 0.0;
  bool _isDownloaded = false;
  DownloadManager? _downloadManager;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupDownloadListener();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _setupDownloadListener();
  }

  void _setupDownloadListener() {
    _downloadManager = context.read<DownloadManager>();
    _updateDownloadState();

    // Add listener for real-time updates
    _downloadManager?.addListener(_onDownloadStateChanged);
  }

  @override
  void dispose() {
    _downloadManager?.removeListener(_onDownloadStateChanged);
    super.dispose();
  }

  void _onDownloadStateChanged() {
    if (mounted) {
      _updateDownloadState();
    }
  }

  void _updateDownloadState() {
    if (_downloadManager == null) return;

    final wasDownloading = _isDownloadingFile;
    final wasDownloaded = _isDownloaded;
    final oldProgress = _downloadProgress;

    _isDownloadingFile = _downloadManager!.isDownloading(widget.episodeKey);
    _isDownloaded = _downloadManager!.isDownloaded(widget.episodeKey);
    final downloadInfo = _downloadManager!.getDownloadInfo(widget.episodeKey);
    _downloadProgress = downloadInfo.progress;

    // Only setState if something actually changed
    if (wasDownloading != _isDownloadingFile ||
        wasDownloaded != _isDownloaded ||
        oldProgress != _downloadProgress) {
      setState(() {});
    }
  }

  void _handleTap() {
    if (widget.isCurrentlyLoading || _isPressed) return;

    setState(() => _isPressed = true);

    if (_isDownloaded) {
      // Play from downloaded file
      _playDownloadedEpisode();
    } else {
      // Stream online
      widget.onTap();
    }

    // Reset after delay
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) {
        setState(() => _isPressed = false);
      }
    });
  }

  void _playDownloadedEpisode() {
    final filePath = _downloadManager?.getDownloadedFilePath(widget.episodeKey);
    if (filePath != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VideoPlayerScreen(streamUrl: filePath),
        ),
      );
    } else {
      // Fallback to online streaming if file not found
      widget.onTap();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      // Use constraints instead of fixed height for flexibility
      constraints: const BoxConstraints(
        minHeight: 100, // Minimum height to prevent collapse
        maxHeight: 140, // Maximum height to prevent excessive growth
      ),
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: _handleTap,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.surface,
                  theme.colorScheme.surfaceVariant.withOpacity(0.3),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _isDownloaded
                    ? theme.colorScheme.primary.withOpacity(0.4)
                    : theme.colorScheme.outline.withOpacity(0.2),
                width: _isDownloaded ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.shadow.withOpacity(0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
                if (_isDownloaded)
                  BoxShadow(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Responsive thumbnail with aspect ratio
                _buildThumbnail(theme),
                const SizedBox(width: 16),
                // Episode info - flexible expansion
                Expanded(
                  child: _buildEpisodeInfo(theme),
                ),
                const SizedBox(width: 12),
                // Action button - maintains consistent size
                _buildActionButton(theme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnail(ThemeData theme) {
    return Container(
      // Use flexible sizing based on screen width
      width: MediaQuery.of(context).size.width * 0.2, // 20% of screen width
      constraints: const BoxConstraints(
        minWidth: 80,
        maxWidth: 120,
        minHeight: 60,
        maxHeight: 90,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isDownloaded
              ? theme.colorScheme.primary.withOpacity(0.4)
              : theme.colorScheme.outline.withOpacity(0.2),
          width: _isDownloaded ? 2 : 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: Stack(
          children: [
            AspectRatio(
              aspectRatio: 16 / 9, // Maintain proper aspect ratio
              child: widget.episode.stillPath != null && widget.episode.stillPath!.isNotEmpty
                  ? Image.network(
                'https://image.tmdb.org/t/p/w300${widget.episode.stillPath!}',
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return _buildPlaceholder(theme, isLoading: true);
                },
                errorBuilder: (context, error, stackTrace) => _buildPlaceholder(theme),
              )
                  : _buildPlaceholder(theme),
            ),
            // Downloaded indicator overlay
            if (_isDownloaded)
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.download_done,
                    color: theme.colorScheme.onPrimary,
                    size: 12,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder(ThemeData theme, {bool isLoading = false}) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.surfaceVariant.withOpacity(0.6),
            theme.colorScheme.surfaceVariant.withOpacity(0.3),
          ],
        ),
      ),
      child: Center(
        child: isLoading
            ? SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(
              theme.colorScheme.primary,
            ),
          ),
        )
            : Icon(
          Icons.movie_creation_outlined,
          size: 24,
          color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
        ),
      ),
    );
  }

  Widget _buildEpisodeInfo(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Episode title - flexible but constrained
        ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: 20, // Minimum space for title
            maxHeight: 50, // Maximum to prevent excessive growth
          ),
          child: Text(
            'E${widget.episode.episodeNumber}: ${widget.episode.name.isNotEmpty ? widget.episode.name : "Episode ${widget.episode.episodeNumber}"}',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
              height: 1.3,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),

        const SizedBox(height: 8),

        // Status row - maintains consistent height but flexible content
        _buildStatusRow(theme),
      ],
    );
  }

  Widget _buildStatusRow(ThemeData theme) {
    Widget content;

    if (_isDownloadingFile) {
      content = Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.primary.withOpacity(0.2),
              theme.colorScheme.secondary.withOpacity(0.1),
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
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                value: _downloadProgress,
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  theme.colorScheme.primary,
                ),
                backgroundColor: theme.colorScheme.primary.withOpacity(0.3),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              'Downloading ${(_downloadProgress * 100).toStringAsFixed(0)}%',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    } else if (_isDownloaded) {
      content = Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.primary.withOpacity(0.2),
              theme.colorScheme.primary.withOpacity(0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.primary.withOpacity(0.4),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.download_done,
              size: 14,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 6),
            Text(
              'Downloaded',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    } else if (widget.episode.airDate != null && widget.episode.airDate!.isNotEmpty) {
      content = Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.outline.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.calendar_today,
              size: 12,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Text(
              'Aired: ${widget.episode.airDate}',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    } else {
      // Empty space but maintain minimum height for layout stability
      content = const SizedBox(height: 24);
    }

    // Wrap in consistent container to prevent layout jumps
    return SizedBox(
      height: 32, // Consistent height for status area
      child: Align(
        alignment: Alignment.centerLeft,
        child: content,
      ),
    );
  }

  Widget _buildActionButton(ThemeData theme) {
    // Use responsive sizing for action button
    final buttonSize = MediaQuery.of(context).size.width * 0.12;
    final clampedSize = buttonSize.clamp(44.0, 56.0); // Minimum 44px for accessibility, max 56px

    Widget buttonContent;

    if (widget.isCurrentlyLoading) {
      buttonContent = SizedBox(
        width: clampedSize * 0.4,
        height: clampedSize * 0.4,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(
            theme.colorScheme.primary,
          ),
        ),
      );
    } else if (_isDownloadingFile) {
      buttonContent = Icon(
        Icons.close_rounded,
        color: theme.colorScheme.error,
        size: clampedSize * 0.5,
      );
    } else {
      buttonContent = Icon(
        _isDownloaded
            ? Icons.play_circle_filled_rounded
            : Icons.play_arrow_rounded,
        color: _isDownloaded
            ? theme.colorScheme.primary
            : theme.colorScheme.secondary,
        size: clampedSize * 0.6,
      );
    }

    return Container(
      width: clampedSize,
      height: clampedSize,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: widget.isCurrentlyLoading
              ? [
            theme.colorScheme.surfaceVariant.withOpacity(0.5),
            theme.colorScheme.surfaceVariant.withOpacity(0.2),
          ]
              : _isDownloadingFile
              ? [
            theme.colorScheme.error.withOpacity(0.2),
            theme.colorScheme.error.withOpacity(0.1),
          ]
              : _isDownloaded
              ? [
            theme.colorScheme.primary.withOpacity(0.3),
            theme.colorScheme.primary.withOpacity(0.1),
          ]
              : [
            theme.colorScheme.secondary.withOpacity(0.2),
            theme.colorScheme.secondary.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(clampedSize / 2),
        border: Border.all(
          color: widget.isCurrentlyLoading
              ? theme.colorScheme.outline.withOpacity(0.3)
              : _isDownloadingFile
              ? theme.colorScheme.error.withOpacity(0.3)
              : _isDownloaded
              ? theme.colorScheme.primary.withOpacity(0.5)
              : theme.colorScheme.secondary.withOpacity(0.4),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: (widget.isCurrentlyLoading
                ? theme.colorScheme.shadow
                : _isDownloadingFile
                ? theme.colorScheme.error
                : _isDownloaded
                ? theme.colorScheme.primary
                : theme.colorScheme.secondary)
                .withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(clampedSize / 2),
          onTap: widget.isCurrentlyLoading || _isPressed
              ? null
              : _isDownloadingFile
              ? () {
            _downloadManager?.cancelDownload(widget.episodeKey);
            setState(() {
              _isDownloadingFile = false;
              _downloadProgress = 0.0;
            });
            _showCancelSnackbar(context, theme);
          }
              : _handleTap,
          child: Center(child: buttonContent),
        ),
      ),
    );
  }

  void _showCancelSnackbar(BuildContext context, ThemeData theme) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Container(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.error.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.cancel_outlined,
                  color: theme.colorScheme.error,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Download Cancelled',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Episode ${widget.episode.episodeNumber} download stopped',
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
          side: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.2),
          ),
        ),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}