// lib/presentation/screens/watch_history/widgets/history_app_bar.dart

import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../data/models/models/watch_history.dart';

class HistoryAppBar extends StatefulWidget {
  final VoidCallback onBackPressed;
  final WatchHistoryType? selectedFilter;
  final Function(WatchHistoryType?) onFilterChanged;
  final String searchQuery;
  final Function(String) onSearchChanged;
  final bool isGridView;
  final VoidCallback onViewToggle;
  final String sortBy;
  final bool sortAscending;
  final Function(String, bool) onSortChanged;
  final int totalItems;
  final int moviesCount;
  final int tvShowsCount;

  const HistoryAppBar({
    super.key,
    required this.onBackPressed,
    required this.selectedFilter,
    required this.onFilterChanged,
    required this.searchQuery,
    required this.onSearchChanged,
    required this.isGridView,
    required this.onViewToggle,
    required this.sortBy,
    required this.sortAscending,
    required this.onSortChanged,
    required this.totalItems,
    required this.moviesCount,
    required this.tvShowsCount,
  });

  @override
  State<HistoryAppBar> createState() => _HistoryAppBarState();
}

class _HistoryAppBarState extends State<HistoryAppBar> {
  bool _isSearching = false;
  late TextEditingController _searchController;
  late FocusNode _searchFocusNode;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.searchQuery);
    _searchFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceBlue.withOpacity(0.8),
        border: Border(
          bottom: BorderSide(color: AppTheme.outlineVariant, width: 1),
        ),
      ),
      child: Column(
        children: [
          // Main header
          Padding(
            padding: const EdgeInsets.all(16),
            child: _isSearching ? _buildSearchHeader() : _buildMainHeader(),
          ),

          // Filter tabs
          if (!_isSearching) _buildFilterTabs(),
        ],
      ),
    );
  }

  Widget _buildMainHeader() {
    return Row(
      children: [
        IconButton(
          onPressed: widget.onBackPressed,
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.surfaceBlue,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.outlineVariant, width: 1),
            ),
            child: Icon(
              Icons.arrow_back_rounded,
              color: AppTheme.highEmphasisText,
              size: 20,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTheme.primaryBlue, AppTheme.accentBlue],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(Icons.history_rounded, size: 24, color: Colors.white),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Watch History',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppTheme.highEmphasisText,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${widget.totalItems} items • ${widget.moviesCount} movies • ${widget.tvShowsCount} shows',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.mediumEmphasisText,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () {
            setState(() => _isSearching = true);
            _searchFocusNode.requestFocus();
          },
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.surfaceBlue,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.outlineVariant, width: 1),
            ),
            child: Icon(
              Icons.search_rounded,
              color: AppTheme.highEmphasisText,
              size: 20,
            ),
          ),
        ),
        const SizedBox(width: 8),
        PopupMenuButton<String>(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.surfaceBlue,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.outlineVariant, width: 1),
            ),
            child: Icon(
              Icons.sort_rounded,
              color: AppTheme.highEmphasisText,
              size: 20,
            ),
          ),
          color: AppTheme.surfaceBlue,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: AppTheme.outlineVariant),
          ),
          onSelected: (value) {
            if (value.startsWith('sort_')) {
              final sortBy = value.substring(5);
              widget.onSortChanged(sortBy, widget.sortAscending);
            } else if (value == 'toggle_order') {
              widget.onSortChanged(widget.sortBy, !widget.sortAscending);
            }
          },
          itemBuilder:
              (context) => [
                PopupMenuItem(
                  value: 'sort_lastWatched',
                  child: Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 16,
                        color: AppTheme.mediumEmphasisText,
                      ),
                      const SizedBox(width: 12),
                      Text('Last Watched'),
                      if (widget.sortBy == 'lastWatched') ...[
                        const Spacer(),
                        Icon(Icons.check, size: 16, color: AppTheme.accentBlue),
                      ],
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'sort_title',
                  child: Row(
                    children: [
                      Icon(
                        Icons.title,
                        size: 16,
                        color: AppTheme.mediumEmphasisText,
                      ),
                      const SizedBox(width: 12),
                      Text('Title'),
                      if (widget.sortBy == 'title') ...[
                        const Spacer(),
                        Icon(Icons.check, size: 16, color: AppTheme.accentBlue),
                      ],
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'sort_watchCount',
                  child: Row(
                    children: [
                      Icon(
                        Icons.repeat,
                        size: 16,
                        color: AppTheme.mediumEmphasisText,
                      ),
                      const SizedBox(width: 12),
                      Text('Watch Count'),
                      if (widget.sortBy == 'watchCount') ...[
                        const Spacer(),
                        Icon(Icons.check, size: 16, color: AppTheme.accentBlue),
                      ],
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                PopupMenuItem(
                  value: 'toggle_order',
                  child: Row(
                    children: [
                      Icon(
                        widget.sortAscending
                            ? Icons.arrow_upward
                            : Icons.arrow_downward,
                        size: 16,
                        color: AppTheme.mediumEmphasisText,
                      ),
                      const SizedBox(width: 12),
                      Text(widget.sortAscending ? 'Ascending' : 'Descending'),
                    ],
                  ),
                ),
              ],
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: widget.onViewToggle,
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.surfaceBlue,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.outlineVariant, width: 1),
            ),
            child: Icon(
              widget.isGridView ? Icons.view_list : Icons.grid_view,
              color: AppTheme.highEmphasisText,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchHeader() {
    return Row(
      children: [
        IconButton(
          onPressed: () {
            setState(() => _isSearching = false);
            _searchController.clear();
            widget.onSearchChanged('');
            _searchFocusNode.unfocus();
          },
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.surfaceBlue,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.outlineVariant, width: 1),
            ),
            child: Icon(
              Icons.arrow_back_rounded,
              color: AppTheme.highEmphasisText,
              size: 20,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.surfaceBlue,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color:
                    _searchFocusNode.hasFocus
                        ? AppTheme.accentBlue
                        : AppTheme.outlineColor,
                width: _searchFocusNode.hasFocus ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              style: TextStyle(color: AppTheme.highEmphasisText, fontSize: 16),
              decoration: InputDecoration(
                hintText: 'Search your watch history...',
                hintStyle: TextStyle(
                  color: AppTheme.lowEmphasisText,
                  fontSize: 16,
                ),
                prefixIcon: Container(
                  margin: const EdgeInsets.all(12),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.accentBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.search_rounded,
                    color: AppTheme.accentBlue,
                    size: 20,
                  ),
                ),
                suffixIcon:
                    _searchController.text.isNotEmpty
                        ? IconButton(
                          onPressed: () {
                            _searchController.clear();
                            widget.onSearchChanged('');
                          },
                          icon: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppTheme.lowEmphasisText.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Icon(
                              Icons.clear_rounded,
                              color: AppTheme.lowEmphasisText,
                              size: 16,
                            ),
                          ),
                        )
                        : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
              onChanged: widget.onSearchChanged,
              textInputAction: TextInputAction.search,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterTabs() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('All', null),
                  const SizedBox(width: 8),
                  _buildFilterChip('Movies', WatchHistoryType.movie),
                  const SizedBox(width: 8),
                  _buildFilterChip('TV Shows', WatchHistoryType.tv),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, WatchHistoryType? type) {
    final isSelected = widget.selectedFilter == type;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => widget.onFilterChanged(type),
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            gradient:
                isSelected
                    ? LinearGradient(
                      colors: [AppTheme.primaryBlue, AppTheme.accentBlue],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                    : null,
            color: isSelected ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? Colors.transparent : AppTheme.outlineColor,
              width: 1,
            ),
            boxShadow:
                isSelected
                    ? [
                      BoxShadow(
                        color: AppTheme.primaryBlue.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                    : null,
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: isSelected ? Colors.white : AppTheme.mediumEmphasisText,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}
