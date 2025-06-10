import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stream_flutter/models/search_result.dart';
import 'package:stream_flutter/screens/search/search_result_section.dart';
import '../../providers/search_provider.dart';
import '../theme.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen>
    with TickerProviderStateMixin {

  late TextEditingController _searchController;
  late FocusNode _searchFocusNode;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  bool _showRecentSearches = false;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchFocusNode = FocusNode();

    // Listen to focus changes to show/hide recent searches
    _searchFocusNode.addListener(() {
      _updateRecentSearchesVisibility();
    });

    // Listen to text changes with debouncing to prevent flickering
    _searchController.addListener(() {
      _debounceTimer?.cancel();
      _debounceTimer = Timer(const Duration(milliseconds: 150), () {
        if (mounted) {
          _updateRecentSearchesVisibility();
        }
      });
    });

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _updateRecentSearchesVisibility() {
    final shouldShow = _searchFocusNode.hasFocus && _searchController.text.isEmpty;
    if (_showRecentSearches != shouldShow) {
      setState(() {
        _showRecentSearches = shouldShow;
      });
    }
  }

  void _performSearch(String query) {
    if (query.trim().isNotEmpty) {
      _searchFocusNode.unfocus();
      setState(() {
        _showRecentSearches = false;
      });
      Provider.of<SearchProvider>(context, listen: false).search(query.trim());
    }
  }

  void _clearSearch() {
    _searchController.clear();
    // Show recent searches immediately when clearing
    setState(() {
      _showRecentSearches = _searchFocusNode.hasFocus;
    });
    Provider.of<SearchProvider>(context, listen: false).clearRecentSearches();
  }

  void _selectRecentSearch(String searchTerm) {
    _searchController.text = searchTerm;
    // Hide recent searches and perform search
    setState(() {
      _showRecentSearches = false;
    });
    _performSearch(searchTerm);
  }

  // Helper to check if device is phone-sized
  bool get _isPhoneScreen {
    final size = MediaQuery.of(context).size;
    return size.width < 600;
  }

  @override
  Widget build(BuildContext context) {
    final isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

    return Scaffold(
      backgroundColor: AppTheme.backgroundBlue,
      resizeToAvoidBottomInset: true,
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(context),
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
          child: SlideTransition(
            position: _slideAnimation,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  // Compact search section
                  _buildCompactSearchSection(context, isKeyboardVisible),
                  // Expanded content section - this gets most of the screen space
                  Expanded(
                    child: _buildContentSection(context, isKeyboardVisible),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      toolbarHeight: _isPhoneScreen ? 48 : 56, // Shorter on phones
      leading: IconButton(
        onPressed: () => Navigator.of(context).pop(),
        icon: Container(
          padding: EdgeInsets.all(_isPhoneScreen ? 6 : 8),
          decoration: BoxDecoration(
            color: AppTheme.surfaceBlue.withOpacity(0.8),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: AppTheme.outlineVariant,
              width: 1,
            ),
          ),
          child: Icon(
            Icons.arrow_back_rounded,
            color: AppTheme.highEmphasisText,
            size: _isPhoneScreen ? 18 : 20,
          ),
        ),
      ),
      title: Container(
        padding: EdgeInsets.symmetric(
            horizontal: _isPhoneScreen ? 12 : 16,
            vertical: _isPhoneScreen ? 6 : 8
        ),
        decoration: BoxDecoration(
          color: AppTheme.surfaceBlue.withOpacity(0.8),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppTheme.outlineVariant,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_rounded,
              color: AppTheme.accentBlue,
              size: _isPhoneScreen ? 16 : 20,
            ),
            SizedBox(width: _isPhoneScreen ? 6 : 8),
            Text(
              'Search',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontSize: _isPhoneScreen ? 16 : null,
                color: AppTheme.highEmphasisText,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      centerTitle: true,
    );
  }

  Widget _buildCompactSearchSection(BuildContext context, bool isKeyboardVisible) {
    return Container(
      margin: EdgeInsets.fromLTRB(
          _isPhoneScreen ? 8 : 16,
          _isPhoneScreen ? 4 : 8,
          _isPhoneScreen ? 8 : 16,
          0
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Compact search bar
          _buildCompactSearchBar(context),

          // Recent searches - only show when focused and no text, and not on small screens with keyboard
          if (_showRecentSearches &&
              (!isKeyboardVisible || !_isPhoneScreen)) ...[
            SizedBox(height: _isPhoneScreen ? 6 : 8),
            _buildHorizontalRecentSearches(context),
          ],
        ],
      ),
    );
  }

  Widget _buildCompactSearchBar(BuildContext context) {
    return Consumer<SearchProvider>(
      builder: (context, provider, child) {
        return Container(
          height: _isPhoneScreen ? 48 : 56, // Fixed height
          decoration: BoxDecoration(
            color: AppTheme.surfaceBlue,
            borderRadius: BorderRadius.circular(_isPhoneScreen ? 12 : 16),
            border: Border.all(
              color: _searchFocusNode.hasFocus
                  ? AppTheme.accentBlue
                  : AppTheme.outlineColor,
              width: _searchFocusNode.hasFocus ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: _isPhoneScreen ? 4 : 8,
                offset: Offset(0, _isPhoneScreen ? 1 : 2),
              ),
            ],
          ),
          child: TextField(
            controller: _searchController,
            focusNode: _searchFocusNode,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontSize: _isPhoneScreen ? 14 : 16,
              color: AppTheme.highEmphasisText,
            ),
            decoration: InputDecoration(
              hintText: _isPhoneScreen ? 'Search movies, shows...' : 'Search for movies, TV shows...',
              hintStyle: TextStyle(
                color: AppTheme.lowEmphasisText,
                fontSize: _isPhoneScreen ? 14 : 16,
              ),
              prefixIcon: Container(
                margin: EdgeInsets.all(_isPhoneScreen ? 8 : 12),
                padding: EdgeInsets.all(_isPhoneScreen ? 6 : 8),
                decoration: BoxDecoration(
                  color: AppTheme.accentBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(_isPhoneScreen ? 6 : 8),
                ),
                child: Icon(
                  Icons.search_rounded,
                  color: AppTheme.accentBlue,
                  size: _isPhoneScreen ? 16 : 20,
                ),
              ),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                onPressed: _clearSearch,
                icon: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppTheme.lowEmphasisText.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    Icons.clear_rounded,
                    color: AppTheme.lowEmphasisText,
                    size: _isPhoneScreen ? 14 : 16,
                  ),
                ),
              )
                  : provider.isLoading
                  ? Container(
                margin: EdgeInsets.all(_isPhoneScreen ? 8 : 12),
                width: _isPhoneScreen ? 16 : 20,
                height: _isPhoneScreen ? 16 : 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppTheme.accentBlue,
                  ),
                ),
              )
                  : null,
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: _isPhoneScreen ? 12 : 16,
                vertical: _isPhoneScreen ? 12 : 16,
              ),
            ),
            onSubmitted: _performSearch,
            onChanged: (value) {
              // Don't immediately hide recent searches, let the controller listener handle it with delay
            },
            textInputAction: TextInputAction.search,
          ),
        );
      },
    );
  }

  Widget _buildHorizontalRecentSearches(BuildContext context) {
    return Consumer<SearchProvider>(
      builder: (context, provider, child) {
        if (provider.recentSearches.isEmpty) {
          return const SizedBox.shrink();
        }

        return Container(
          height: _isPhoneScreen ? 28 : 32, // Very compact height
          child: Row(
            children: [
              // Small label
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: _isPhoneScreen ? 6 : 8,
                  vertical: _isPhoneScreen ? 4 : 6,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceBlue.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(_isPhoneScreen ? 6 : 8),
                  border: Border.all(
                    color: AppTheme.outlineVariant,
                    width: 1,
                  ),
                ),
                child: Text(
                  'Recent',
                  style: TextStyle(
                    color: AppTheme.mediumEmphasisText,
                    fontSize: _isPhoneScreen ? 10 : 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              SizedBox(width: _isPhoneScreen ? 6 : 8),

              // Horizontal scrollable recent searches
              Expanded(
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: provider.recentSearches.take(_isPhoneScreen ? 5 : 8).length,
                  separatorBuilder: (context, index) => SizedBox(width: _isPhoneScreen ? 4 : 6),
                  itemBuilder: (context, index) {
                    final searchTerm = provider.recentSearches[index];
                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _selectRecentSearch(searchTerm),
                        borderRadius: BorderRadius.circular(_isPhoneScreen ? 10 : 12),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: _isPhoneScreen ? 8 : 10,
                            vertical: _isPhoneScreen ? 4 : 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryBlue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(_isPhoneScreen ? 10 : 12),
                            border: Border.all(
                              color: AppTheme.primaryBlue.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            searchTerm,
                            style: TextStyle(
                              color: AppTheme.primaryBlue,
                              fontSize: _isPhoneScreen ? 10 : 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Clear button
              IconButton(
                onPressed: provider.clearRecentSearches,
                icon: Icon(
                  Icons.close_rounded,
                  size: _isPhoneScreen ? 16 : 18,
                  color: AppTheme.lowEmphasisText,
                ),
                padding: EdgeInsets.all(_isPhoneScreen ? 4 : 6),
                constraints: BoxConstraints(
                  minWidth: _isPhoneScreen ? 24 : 28,
                  minHeight: _isPhoneScreen ? 24 : 28,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildContentSection(BuildContext context, bool isKeyboardVisible) {
    return Consumer<SearchProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.results.items.isEmpty) {
          return _buildLoadingState(context, isKeyboardVisible);
        }

        if (provider.error != null) {
          return _buildErrorState(context, provider.error!, isKeyboardVisible);
        }

        if (provider.results.items.isEmpty && !provider.isLoading) {
          return _buildEmptyState(context, isKeyboardVisible);
        }

        return SearchResultSection(
          searchResult: provider.results,
          isLoading: provider.isLoading,
          onLoadMore: null,
          hasMore: false,
        );
      },
    );
  }

  Widget _buildLoadingState(BuildContext context, bool isKeyboardVisible) {
    return Center(
      child: Container(
        margin: EdgeInsets.all(_isPhoneScreen ? 12 : 16),
        padding: EdgeInsets.all(_isPhoneScreen ? 20 : 32),
        decoration: BoxDecoration(
          color: AppTheme.surfaceBlue,
          borderRadius: BorderRadius.circular(_isPhoneScreen ? 16 : 20),
          border: Border.all(
            color: AppTheme.outlineVariant,
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: _isPhoneScreen ? 32 : 48,
              height: _isPhoneScreen ? 32 : 48,
              child: CircularProgressIndicator(
                strokeWidth: _isPhoneScreen ? 3 : 4,
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentBlue),
              ),
            ),
            SizedBox(height: _isPhoneScreen ? 12 : 16),
            Text(
              'Searching...',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontSize: _isPhoneScreen ? 16 : null,
                color: AppTheme.highEmphasisText,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: _isPhoneScreen ? 6 : 8),
            Text(
              'Finding the best results for you',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontSize: _isPhoneScreen ? 12 : null,
                color: AppTheme.mediumEmphasisText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String error, bool isKeyboardVisible) {
    return Center(
      child: SingleChildScrollView(
        child: Container(
          margin: EdgeInsets.all(_isPhoneScreen ? 12 : 16),
          padding: EdgeInsets.all(_isPhoneScreen ? 16 : 24),
          decoration: BoxDecoration(
            color: AppTheme.surfaceBlue,
            borderRadius: BorderRadius.circular(_isPhoneScreen ? 16 : 20),
            border: Border.all(
              color: AppTheme.outlineVariant,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(_isPhoneScreen ? 12 : 16),
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
                  size: _isPhoneScreen ? 32 : 48,
                  color: AppTheme.errorColor,
                ),
              ),
              SizedBox(height: _isPhoneScreen ? 12 : 20),
              Text(
                'Search Error',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontSize: _isPhoneScreen ? 18 : null,
                  color: AppTheme.highEmphasisText,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: _isPhoneScreen ? 6 : 8),
              Text(
                error,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: _isPhoneScreen ? 12 : null,
                  color: AppTheme.mediumEmphasisText,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: _isPhoneScreen ? 12 : 20),
              ElevatedButton.icon(
                onPressed: () {
                  if (_searchController.text.isNotEmpty) {
                    _performSearch(_searchController.text);
                  }
                },
                icon: Icon(Icons.refresh_rounded, size: _isPhoneScreen ? 16 : 18),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                      horizontal: _isPhoneScreen ? 16 : 24,
                      vertical: _isPhoneScreen ? 8 : 12
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isKeyboardVisible) {
    return Center(
      child: SingleChildScrollView(
        child: Container(
          margin: EdgeInsets.all(_isPhoneScreen ? 12 : 16),
          padding: EdgeInsets.all(_isPhoneScreen ? 20 : 32),
          decoration: BoxDecoration(
            color: AppTheme.surfaceBlue,
            borderRadius: BorderRadius.circular(_isPhoneScreen ? 16 : 24),
            border: Border.all(
              color: AppTheme.outlineVariant,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(_isPhoneScreen ? 16 : 20),
                decoration: BoxDecoration(
                  color: AppTheme.accentBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(50),
                  border: Border.all(
                    color: AppTheme.accentBlue.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: Icon(
                  Icons.search_rounded,
                  size: _isPhoneScreen ? 32 : 48,
                  color: AppTheme.accentBlue,
                ),
              ),
              SizedBox(height: _isPhoneScreen ? 16 : 24),
              Text(
                'Start Your Search',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontSize: _isPhoneScreen ? 18 : null,
                  color: AppTheme.highEmphasisText,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: _isPhoneScreen ? 8 : 12),
              Text(
                'Enter a movie or TV show title in the search bar above to discover amazing content.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: _isPhoneScreen ? 12 : null,
                  color: AppTheme.mediumEmphasisText,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: _isPhoneScreen ? 12 : 20),
              Container(
                padding: EdgeInsets.symmetric(
                    horizontal: _isPhoneScreen ? 10 : 16,
                    vertical: _isPhoneScreen ? 6 : 8
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.primaryBlue.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.lightbulb_outline_rounded,
                      size: _isPhoneScreen ? 12 : 16,
                      color: AppTheme.primaryBlue,
                    ),
                    SizedBox(width: _isPhoneScreen ? 4 : 8),
                    Text(
                      'Try searching for popular titles',
                      style: TextStyle(
                        color: AppTheme.primaryBlue,
                        fontSize: _isPhoneScreen ? 10 : 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}