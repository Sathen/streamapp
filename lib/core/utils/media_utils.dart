// lib/utils/media_utils.dart
import 'package:flutter/material.dart';

class MediaUtils {
  static String sanitizeFileName(String filename) {
    return filename.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
  }

  static String generateMovieFileName(String title, {String? id}) {
    final sanitized = sanitizeFileName(title);
    return id != null ? 'Movie_${id}_$sanitized' : sanitized;
  }

  static String generateEpisodeFileName(
    String seriesTitle,
    int season,
    int episode, {
    String? episodeTitle,
  }) {
    final sanitized = sanitizeFileName(seriesTitle);
    final episodePart =
        episodeTitle != null ? '_${sanitizeFileName(episodeTitle)}' : '';
    return '${sanitized}_S${season.toString().padLeft(2, '0')}E${episode.toString().padLeft(2, '0')}$episodePart';
  }

  static void showLoadingDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            content: Row(
              children: [
                const CircularProgressIndicator(),
                const SizedBox(width: 16),
                Expanded(child: Text(message)),
              ],
            ),
          ),
    );
  }

  static void hideLoadingDialog(BuildContext context) {
    Navigator.of(context, rootNavigator: true).pop();
  }

  static void showErrorDialog(
    BuildContext context,
    String title,
    String message,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  static String formatDuration(int? minutes) {
    if (minutes == null || minutes == 0) return 'Unknown';

    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;

    if (hours > 0) {
      return '${hours}h ${remainingMinutes}m';
    } else {
      return '${remainingMinutes}m';
    }
  }

  static String formatReleaseDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return 'Unknown';

    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString; // Return original if parsing fails
    }
  }

  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'released':
      case 'ended':
        return Colors.green;
      case 'in production':
      case 'returning series':
        return Colors.blue;
      case 'planned':
      case 'pilot':
        return Colors.orange;
      case 'canceled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  static IconData getMediaTypeIcon(String mediaType) {
    switch (mediaType.toLowerCase()) {
      case 'movie':
        return Icons.movie;
      case 'tv':
      case 'series':
        return Icons.tv;
      case 'documentary':
        return Icons.library_books;
      case 'animation':
        return Icons.animation;
      default:
        return Icons.play_circle_outline;
    }
  }
}
