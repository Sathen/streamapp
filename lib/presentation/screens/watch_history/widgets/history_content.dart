// lib/presentation/screens/watch_history/widgets/history_content.dart

import 'package:flutter/material.dart';

import '../../../../data/models/models/watch_history.dart';
import '../../../providers/watch_history/watch_history_provider.dart';
import '../../../widgets/common/misc/empty_state.dart';
import 'history_grid_view.dart';
import 'history_list_view.dart';

class HistoryContent extends StatelessWidget {
  final WatchHistoryProvider historyProvider;
  final WatchHistoryType? selectedFilter;
  final String searchQuery;
  final bool isGridView;
  final Function(WatchHistoryItem) onItemTap;

  const HistoryContent({
    super.key,
    required this.historyProvider,
    required this.selectedFilter,
    required this.searchQuery,
    required this.isGridView,
    required this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    if (historyProvider.isLoading) {
      return _buildLoadingState();
    }

    if (historyProvider.hasError) {
      return _buildErrorState(context);
    }

    final items = _getFilteredItems();

    if (items.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: () async {
        // Refresh history data if needed
        // Currently history is local, so no refresh needed
      },
      child:
          isGridView
              ? HistoryGridView(items: items, onItemTap: onItemTap)
              : HistoryListView(items: items, onItemTap: onItemTap),
    );
  }

  List<WatchHistoryItem> _getFilteredItems() {
    List<WatchHistoryItem> items;

    // Apply search filter first
    if (searchQuery.isNotEmpty) {
      items = historyProvider.searchHistory(searchQuery);
    } else {
      items = historyProvider.history;
    }

    // Apply type filter
    if (selectedFilter != null) {
      items = items.where((item) => item.type == selectedFilter).toList();
    }

    return items;
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Loading your watch history...'),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            'Error loading history',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            historyProvider.error ?? 'Unknown error occurred',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              // Retry loading
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    if (searchQuery.isNotEmpty) {
      return EmptyState(
        icon: Icons.search_off_rounded,
        title: 'No Results Found',
        message: 'No items in your watch history match "$searchQuery"',
      );
    }

    if (selectedFilter != null) {
      return EmptyState(
        icon: selectedFilter!.icon,
        title: 'No ${selectedFilter!.displayName}s Watched',
        message:
            'You haven\'t watched any ${selectedFilter!.displayName.toLowerCase()}s yet.',
      );
    }

    return const EmptyState(
      icon: Icons.history_outlined,
      title: 'No Watch History',
      message: 'Start watching movies and TV shows to build your history.',
    );
  }
}
