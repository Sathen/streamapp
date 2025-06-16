// lib/presentation/screens/watch_history/watch_history_screen.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/models/watch_history.dart';
import '../../providers/watch_history/watch_history_provider.dart';
import 'widgets/history_app_bar.dart';
import 'widgets/history_content.dart';

class WatchHistoryScreen extends StatefulWidget {
  const WatchHistoryScreen({super.key});

  @override
  State<WatchHistoryScreen> createState() => _WatchHistoryScreenState();
}

class _WatchHistoryScreenState extends State<WatchHistoryScreen> {
  WatchHistoryType? _selectedFilter;
  String _searchQuery = '';
  bool _isGridView = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<WatchHistoryProvider>(
      builder: (context, historyProvider, child) {
        return Scaffold(
          backgroundColor: AppTheme.backgroundBlue,
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
            child: SafeArea(
              child: Column(
                children: [
                  HistoryAppBar(
                    onBackPressed: () => context.go('/'),
                    selectedFilter: _selectedFilter,
                    onFilterChanged: (filter) {
                      setState(() => _selectedFilter = filter);
                    },
                    searchQuery: _searchQuery,
                    onSearchChanged: (query) {
                      setState(() => _searchQuery = query);
                    },
                    isGridView: _isGridView,
                    onViewToggle: () {
                      setState(() => _isGridView = !_isGridView);
                    },
                    sortBy: historyProvider.sortBy,
                    sortAscending: historyProvider.sortAscending,
                    onSortChanged: (sortBy, ascending) {
                      historyProvider.setSorting(sortBy, ascending: ascending);
                    },
                    totalItems: historyProvider.totalItems,
                    moviesCount: historyProvider.totalMovies,
                    tvShowsCount: historyProvider.totalTVShows,
                  ),
                  Expanded(
                    child: HistoryContent(
                      historyProvider: historyProvider,
                      selectedFilter: _selectedFilter,
                      searchQuery: _searchQuery,
                      isGridView: _isGridView,
                      onItemTap: (item) => _handleItemTap(context, item),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _handleItemTap(BuildContext context, WatchHistoryItem item) {
    switch (item.type) {
      case WatchHistoryType.movie:
        context.push('/media/tmdb/movie/${item.id}');
        break;
      case WatchHistoryType.tv:
        context.push('/media/tmdb/tv/${item.id}');
        break;
    }
  }
}
