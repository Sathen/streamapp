import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:stream_flutter/presentation/screens/home/widgets/loading_shimer.dart';
import 'package:stream_flutter/presentation/screens/home/widgets/media_content.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/errors.dart';
import '../../providers/media/media_provider.dart';
import 'widgets/category_selector.dart';
import 'widgets/error_retry_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  bool _isInitialized = false;
  String? _lastError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Initialize media data when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Refresh data when app comes back to foreground
    if (state == AppLifecycleState.resumed && _isInitialized) {
      _refreshData(showLoading: false);
    }
  }

  Future<void> _initializeData() async {
    final provider = context.read<MediaProvider>();

    final result = await provider.initializeData();

    if (mounted) {
      result.fold(
        (data) {
          setState(() {
            _isInitialized = true;
            _lastError = null;
          });
          // No success message for initial load - it's expected behavior
        },
        (error, exception) {
          setState(() {
            _lastError = error;
          });
          _handleInitializationError(error, exception);
        },
      );
    }
  }

  Future<void> _refreshData({bool showLoading = true}) async {
    final provider = context.read<MediaProvider>();

    if (!showLoading) {
      // Silent refresh - just update data without showing loading state
      await provider.initializeData();
      return;
    }

    final result = await provider.initializeData();

    if (mounted) {
      result.fold(
        (data) {
          setState(() {
            _lastError = null;
          });
          // Only show success for manual refresh, and only if user explicitly pulled
          // No automatic success messages
        },
        (error, exception) {
          setState(() {
            _lastError = error;
          });
          showErrorSnackbar(context, 'Failed to refresh: $error');
        },
      );
    }
  }

  Future<void> _refreshCategory() async {
    final provider = context.read<MediaProvider>();

    final result = await provider.refreshCategory(provider.selectedCategory);

    if (mounted) {
      result.fold(
        (data) {
          // Silent success - no message needed for category switching
          // The UI update itself indicates success
        },
        (error, exception) {
          showErrorSnackbar(context, 'Failed to refresh category: $error');
        },
      );
    }
  }

  void _handleInitializationError(String error, Exception? exception) {
    // Log error for debugging
    debugPrint('HomeScreen initialization error: $error');
    if (exception != null) {
      debugPrint('Exception: $exception');
    }

    // Show appropriate error message based on error type
    if (error.toLowerCase().contains('network') ||
        error.toLowerCase().contains('connection')) {
      showErrorSnackbar(
        context,
        'Check your internet connection and try again',
      );
    } else if (error.toLowerCase().contains('timeout')) {
      showErrorSnackbar(context, 'Request timed out. Please try again');
    } else {
      showErrorSnackbar(context, 'Failed to load content. Please try again');
    }
  }

  void _showSuccessMessage(String message) {
    // Reserved for significant user actions only
    // Like successful downloads, login, etc.
    // Not for basic content loading
    showSuccessSnackbar(context, message);
  }

  void _onCategoryChanged() {
    // Category changed, refresh that category's data
    _refreshCategory();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MediaProvider>(
      builder: (context, mediaProvider, child) {
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
                  // App Bar
                  _buildAppBar(),

                  // Category Selector
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: CategorySelector(
                      onCategoryChanged: _onCategoryChanged,
                    ),
                  ),

                  // Content
                  Expanded(child: _buildContent(mediaProvider)),
                ],
              ),
            ),
          ),
          bottomNavigationBar: _buildBottomNavigationBar(),
        );
      },
    );
  }

  Widget _buildContent(MediaProvider provider) {
    // Show loading shimmer during initial load
    if (provider.isLoading && !_isInitialized) {
      return const HomeLoadingShimmer();
    }

    // Show error state if there's an error and no data
    if (provider.hasError && !_hasAnyData(provider)) {
      return ErrorRetryWidget(error: provider.error!, onRetry: _initializeData);
    }

    // Show content with pull-to-refresh
    return RefreshIndicator(
      onRefresh: _refreshData,
      color: AppTheme.accentBlue,
      backgroundColor: AppTheme.surfaceBlue,
      strokeWidth: 3,
      child: Stack(
        children: [
          // Main content
          MediaContent(provider: provider),

          // Loading overlay for refresh operations
          if (provider.isLoading && _isInitialized) _buildLoadingOverlay(),

          // Error overlay for temporary errors
          if (provider.hasError && _hasAnyData(provider))
            _buildErrorOverlay(provider.error!),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.primaryBlue, AppTheme.accentBlue],
              ),
              borderRadius: BorderRadius.circular(50),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryBlue.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.movie_rounded,
              size: 32,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Streaming App',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppTheme.highEmphasisText,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _getSubtitleText(),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.mediumEmphasisText,
                  ),
                ),
              ],
            ),
          ),
          // Connection status indicator
          _buildConnectionIndicator(),
        ],
      ),
    );
  }

  String _getSubtitleText() {
    if (_lastError != null) {
      return 'Tap to retry loading content';
    }
    return 'Discover amazing content';
  }

  Widget _buildConnectionIndicator() {
    return Consumer<MediaProvider>(
      builder: (context, provider, child) {
        final hasError = provider.hasError;
        final isLoading = provider.isLoading;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color:
                hasError
                    ? AppTheme.errorColor.withOpacity(0.1)
                    : isLoading
                    ? AppTheme.accentBlue.withOpacity(0.1)
                    : AppTheme.successColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color:
                  hasError
                      ? AppTheme.errorColor.withOpacity(0.3)
                      : isLoading
                      ? AppTheme.accentBlue.withOpacity(0.3)
                      : AppTheme.successColor.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Icon(
            hasError
                ? Icons.error_outline
                : isLoading
                ? Icons.sync
                : Icons.check_circle_outline,
            size: 20,
            color:
                hasError
                    ? AppTheme.errorColor
                    : isLoading
                    ? AppTheme.accentBlue
                    : AppTheme.successColor,
          ),
        );
      },
    );
  }

  Widget _buildLoadingOverlay() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        height: 4,
        child: LinearProgressIndicator(
          backgroundColor: Colors.transparent,
          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentBlue),
        ),
      ),
    );
  }

  Widget _buildErrorOverlay(String error) {
    return Positioned(
      top: 16,
      left: 16,
      right: 16,
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.errorColor.withOpacity(0.9),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  error,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              TextButton(
                onPressed: _refreshData,
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.surfaceBlue,
            border: Border(
              top: BorderSide(color: AppTheme.outlineVariant, width: 1),
            ),
          ),
          child: BottomNavigationBar(
            currentIndex: 0,
            backgroundColor: Colors.transparent,
            selectedItemColor: AppTheme.accentBlue,
            unselectedItemColor: AppTheme.mediumEmphasisText,
            type: BottomNavigationBarType.fixed,
            elevation: 0,
            onTap: (index) => _handleBottomNavTap(index),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_rounded),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.search_rounded),
                label: 'Search',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.history_rounded),
                label: 'History',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.download_rounded),
                label: 'Downloads',
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleBottomNavTap(int index) {
    switch (index) {
      case 0:
        // Already on home
        break;
      case 1:
        context.go('/search');
        break;
      case 2:
        context.go('/history');
        break;
      case 3:
        context.go('/downloads');
        break;
    }
  }

  bool _hasAnyData(MediaProvider provider) {
    return provider.popularMovies.isNotEmpty ||
        provider.popularTV.isNotEmpty ||
        provider.nowPlayingMovies.isNotEmpty;
  }
}
