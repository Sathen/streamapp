import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

class SearchEmptyState extends StatelessWidget {
  final String? query;

  const SearchEmptyState({super.key, this.query});

  @override
  Widget build(BuildContext context) {
    final hasQuery = query != null && query!.isNotEmpty;

    return Center(
      child: Container(
        margin: const EdgeInsets.all(32),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AppTheme.surfaceBlue,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppTheme.outlineVariant, width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.accentBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(50),
                border: Border.all(
                  color: AppTheme.accentBlue.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: Icon(
                hasQuery ? Icons.search_off_rounded : Icons.search_rounded,
                size: 48,
                color: AppTheme.accentBlue,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              hasQuery ? 'No Results Found' : 'Start Your Search',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppTheme.highEmphasisText,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              hasQuery
                  ? 'Try adjusting your search terms or filters to find what you\'re looking for.'
                  : 'Enter a movie or TV show title in the search bar above to discover amazing content.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.mediumEmphasisText,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
