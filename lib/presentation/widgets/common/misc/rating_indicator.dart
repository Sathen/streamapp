import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

class RatingIndicator extends StatelessWidget {
  final double rating;
  final double maxRating;
  final int? voteCount;
  final double size;
  final bool showPercentage;

  const RatingIndicator({
    super.key,
    required this.rating,
    this.maxRating = 10.0,
    this.voteCount,
    this.size = 48,
    this.showPercentage = true,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = (rating / maxRating).clamp(0.0, 1.0);
    final color = _getRatingColor(percentage);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
        border: Border.all(color: color.withOpacity(0.3), width: 2),
      ),
      child: Stack(
        children: [
          Center(
            child: SizedBox(
              width: size * 0.75,
              height: size * 0.75,
              child: CircularProgressIndicator(
                value: percentage,
                strokeWidth: size * 0.08,
                backgroundColor: AppTheme.outlineVariant,
                color: color,
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  showPercentage
                      ? '${(percentage * 100).round()}%'
                      : rating.toStringAsFixed(1),
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: size * 0.2,
                  ),
                ),
                if (voteCount != null && size > 40) ...[
                  Text(
                    _formatVoteCount(voteCount!),
                    style: TextStyle(
                      color: AppTheme.lowEmphasisText,
                      fontSize: size * 0.12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getRatingColor(double percentage) {
    if (percentage >= 0.7) return Colors.green;
    if (percentage >= 0.5) return Colors.orange;
    return Colors.red;
  }

  String _formatVoteCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }
}
