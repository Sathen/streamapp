import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../presentation/providers/download/download_provider.dart';

class MoviePlayButton extends StatefulWidget {
  final VoidCallback onPlayPressed;
  final String episodeKey;
  final bool isFetchingStreams;
  final ThemeData theme;

  const MoviePlayButton({
    super.key,
    required this.onPlayPressed,
    required this.episodeKey,
    required this.theme,
    required this.isFetchingStreams,
  });

  @override
  State<MoviePlayButton> createState() => _MoviePlayButtonState();
}

class _MoviePlayButtonState extends State<MoviePlayButton>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _slideController;
  late Animation<double> _pulseAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 0.95,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.elasticOut,
    ));
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DownloadProvider>(
      builder: (context, manager, _) {
        final downloadInfo = manager.getDownloadInfo(widget.episodeKey);
        final isDownloading = manager.isDownloading(widget.episodeKey);

        // Trigger slide animation when download starts
        if (isDownloading && !_slideController.isCompleted) {
          _slideController.forward();
        } else if (!isDownloading && _slideController.isCompleted) {
          _slideController.reverse();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildPlayButton(),
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: isDownloading
                  ? SlideTransition(
                position: _slideAnimation,
                child: _buildDownloadSection(downloadInfo, manager),
              )
                  : const SizedBox.shrink(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPlayButton() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: widget.theme.colorScheme.primary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: widget.isFetchingStreams ? _pulseAnimation.value : 1.0,
            child: ElevatedButton.icon(
              icon: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: widget.isFetchingStreams
                    ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      widget.theme.colorScheme.onPrimary,
                    ),
                  ),
                )
                    : Icon(
                  Icons.play_arrow_rounded,
                  size: 28,
                  key: const ValueKey('play_icon'),
                ),
              ),
              label: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: widget.theme.textTheme.titleMedium!.copyWith(
                  color: widget.theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
                child: Text(widget.isFetchingStreams ? 'Завантажуємо...' : 'Відтворити'),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.theme.colorScheme.primary,
                foregroundColor: widget.theme.colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              onPressed: widget.isFetchingStreams ? null : widget.onPlayPressed,
            ),
          );
        },
      ),
    );
  }

  Widget _buildDownloadSection(downloadInfo, DownloadProvider manager) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.theme.colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: widget.theme.colorScheme.secondary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.download_rounded,
                  size: 16,
                  color: widget.theme.colorScheme.secondary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Завантаження епізоду',
                  style: widget.theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: widget.theme.colorScheme.onSurface,
                  ),
                ),
              ),
              _buildCancelButton(manager),
            ],
          ),
          const SizedBox(height: 12),
          _buildProgressBar(downloadInfo),
          const SizedBox(height: 8),
          _buildDownloadStats(downloadInfo),
        ],
      ),
    );
  }

  Widget _buildProgressBar(downloadInfo) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${(downloadInfo.progress * 100).toInt()}%',
              style: widget.theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: widget.theme.colorScheme.secondary,
              ),
            ),
            if (downloadInfo.totalSize != null)
              Text(
                downloadInfo.totalSize!,
                style: widget.theme.textTheme.labelSmall?.copyWith(
                  color: widget.theme.colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: downloadInfo.progress,
            minHeight: 6,
            backgroundColor: widget.theme.colorScheme.outline.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(
              widget.theme.colorScheme.secondary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDownloadStats(downloadInfo) {
    return Row(
      children: [
        Icon(
          Icons.speed_rounded,
          size: 14,
          color: widget.theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 4),
        Text(
          downloadInfo.formattedSpeed,
          style: widget.theme.textTheme.labelSmall?.copyWith(
            color: widget.theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildCancelButton(DownloadProvider manager) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _showCancelDialog(manager),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(
            Icons.close_rounded,
            size: 16,
            color: Colors.red,
          ),
        ),
      ),
    );
  }

  void _showCancelDialog(DownloadProvider manager) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Скасувати завантаження?'),
          content: const Text(
            'Ви впевнені, що хочете скасувати завантаження цього епізоду?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Ні'),
            ),
            ElevatedButton(
              onPressed: () {
                manager.cancelDownload(widget.episodeKey);
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Так, скасувати'),
            ),
          ],
        );
      },
    );
  }
}