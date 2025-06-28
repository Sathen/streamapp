import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/errors.dart';
import '../../../providers/search/search_provider.dart';
import 'recent_searches.dart';
import 'search_empty_state.dart';
import 'search_results.dart';

class SearchContent extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final Function(String) onRecentSearchTap;

  const SearchContent({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onRecentSearchTap,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<SearchProvider>(
      builder: (context, searchProvider, child) {
        // Show recent searches when focused and no query
        final showRecentSearches =
            focusNode.hasFocus &&
            controller.text.isEmpty &&
            searchProvider.hasRecentSearches;

        if (showRecentSearches) {
          return RecentSearches(
            recentSearches: searchProvider.recentSearches,
            onSearchTap: onRecentSearchTap,
            onClearAll: () => _clearRecentSearches(context, searchProvider),
            onRemoveSearch:
                (query) => _removeRecentSearch(context, searchProvider, query),
          );
        }

        // Show loading state
        if (searchProvider.isLoading) {
          return _buildLoadingState();
        }

        // Show error state
        if (searchProvider.hasError) {
          return _buildErrorState(context, searchProvider);
        }

        // Show results or empty state
        if (searchProvider.hasResults) {
          return SearchResults(searchResult: searchProvider.results);
        } else if (searchProvider.currentQuery.isNotEmpty) {
          return SearchEmptyState(query: searchProvider.currentQuery);
        } else {
          return const SearchEmptyState();
        }
      },
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AppTheme.surfaceBlue,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppTheme.outlineVariant, width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 48,
              height: 48,
              child: CircularProgressIndicator(
                strokeWidth: 4,
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentBlue),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Searching...',
              style: TextStyle(
                color: AppTheme.highEmphasisText,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Finding the best results for you',
              style: TextStyle(
                color: AppTheme.mediumEmphasisText,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, SearchProvider searchProvider) {
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
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.errorColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(50),
                border: Border.all(
                  color: AppTheme.errorColor.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: AppTheme.errorColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Search Error',
              style: TextStyle(
                color: AppTheme.highEmphasisText,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              searchProvider.error!,
              style: TextStyle(
                color: AppTheme.mediumEmphasisText,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                if (searchProvider.currentQuery.isNotEmpty) {
                  searchProvider.search(searchProvider.currentQuery);
                }
              },
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _clearRecentSearches(
    BuildContext context,
    SearchProvider provider,
  ) async {
    final result = await provider.clearRecentSearches();

    if (context.mounted) {
      result.fold(
        (data) {
          // Success - no message needed, UI update shows success
        },
        (error, exception) {
          showErrorSnackbar(context, 'Failed to clear searches: $error');
        },
      );
    }
  }

  Future<void> _removeRecentSearch(
    BuildContext context,
    SearchProvider provider,
    String query,
  ) async {
    final result = await provider.removeRecentSearch(query);

    if (context.mounted) {
      result.fold(
        (data) {
          // Success - no message needed, UI update shows success
        },
        (error, exception) {
          showErrorSnackbar(context, 'Failed to remove search: $error');
        },
      );
    }
  }
}
