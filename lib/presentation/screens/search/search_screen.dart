import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../providers/search/search_provider.dart';
import 'widgets/search_app_bar.dart';
import 'widgets/search_content.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late TextEditingController _searchController;
  late FocusNode _searchFocusNode;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
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
              SearchAppBar(
                controller: _searchController,
                focusNode: _searchFocusNode,
                onBackPressed: () => context.push('/'),
                onSearch: (query) => _performSearch(query),
                onClear: () => _clearSearch(),
              ),
              Expanded(
                child: SearchContent(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  onRecentSearchTap: (query) => _selectRecentSearch(query),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _performSearch(String query) {
    if (query.trim().isNotEmpty) {
      _searchFocusNode.unfocus();
      context.read<SearchProvider>().search(query.trim());
    }
  }

  void _clearSearch() {
    _searchController.clear();
    context.read<SearchProvider>().clearResults();
  }

  void _selectRecentSearch(String query) {
    _searchController.text = query;
    _performSearch(query);
  }
}
