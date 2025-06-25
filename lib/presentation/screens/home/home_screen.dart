import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:stream_flutter/presentation/screens/home/widgets/loading_shimer.dart';
import 'package:stream_flutter/presentation/screens/home/widgets/media_content.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/errors.dart';
import '../../providers/media/media_provider.dart';
import 'widgets/error_retry_widget.dart';
import 'widgets/home_app_bar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  bool _isInitialized = false;
  String? _lastError;
  final ScrollController _scrollController = ScrollController();
  bool _innerBoxIsScrolled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Defer initialization until after the build phase
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // Remove scroll listener cleanup
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    final scrolled = _scrollController.offset > 50;
    if (scrolled != _innerBoxIsScrolled) {
      // Use SchedulerBinding to avoid conflicts with gesture processing
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _innerBoxIsScrolled = scrolled;
          });
        }
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _isInitialized) {
      _refreshData();
    }
  }

  Future<void> _initializeData() async {
    // Ensure we're not in a build phase
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      SchedulerBinding.instance.addPostFrameCallback((_) => _initializeData());
      return;
    }

    final provider = context.read<MediaProvider>();
    final result = await provider.initializeData();

    if (mounted) {
      result.fold(
        (data) {
          setState(() {
            _isInitialized = true;
            _lastError = null;
          });
        },
        (error, exception) {
          setState(() {
            _lastError = error;
            _isInitialized = true;
          });
          _showErrorMessage(error);
        },
      );
    }
  }

  Future<void> _refreshData() async {
    // Ensure we're not in a build phase
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      SchedulerBinding.instance.addPostFrameCallback((_) => _refreshData());
      return;
    }

    final provider = context.read<MediaProvider>();
    final result = await provider.initializeData();

    if (mounted) {
      result.fold(
        (data) {
          setState(() => _lastError = null);
        },
        (error, exception) {
          setState(() => _lastError = error);
          _showErrorMessage(error);
        },
      );
    }
  }

  Future<void> _refreshCategory() async {
    // Ensure we're not in a build phase
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      SchedulerBinding.instance.addPostFrameCallback((_) => _refreshCategory());
      return;
    }

    final provider = context.read<MediaProvider>();
    final result = await provider.refreshCategory(provider.selectedCategory);

    if (mounted) {
      result.fold(
        (data) {
          // Silent success - no message needed for category switching
        },
        (error, exception) {
          _showErrorMessage(error);
        },
      );
    }
  }

  void _showErrorMessage(String error) {
    showErrorSnackbar(context, 'Failed to load content. Please try again');
  }

  void _showSuccessMessage(String message) {
    showSuccessSnackbar(context, message);
  }

  void _onCategoryChanged() {
    // Defer category refresh until after the current build cycle
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshCategory();
    });
  }

  void _scrollToTop() {
    // Scroll to top with smooth animation
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutCubic,
      );
    }
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
            child: NotificationListener<ScrollNotification>(
              onNotification: (scrollNotification) {
                // Alternative scroll detection that's safer for web
                if (scrollNotification is ScrollUpdateNotification) {
                  final scrolled = scrollNotification.metrics.pixels > 50;
                  if (scrolled != _innerBoxIsScrolled) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        setState(() {
                          _innerBoxIsScrolled = scrolled;
                        });
                      }
                    });
                  }
                }
                return false;
              },
              child: CustomScrollView(
                controller: _scrollController,
                slivers: [
                  // Use HomeAppBar instead of custom app bar
                  HomeAppBar(
                    innerBoxIsScrolled: _innerBoxIsScrolled,
                    onCategoryChanged: _onCategoryChanged,
                    onScrollToTop: _scrollToTop,
                  ),

                  // Content
                  SliverFillRemaining(child: _buildContent(mediaProvider)),
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

  Widget _buildLoadingOverlay() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.surfaceBlue.withOpacity(0.9),
          borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(12),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentBlue),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Refreshing content...',
              style: TextStyle(color: AppTheme.highEmphasisText, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorOverlay(String error) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.errorColor.withOpacity(0.9),
          borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(12),
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                error.contains('network')
                    ? 'Connection lost'
                    : 'Something went wrong',
                style: TextStyle(color: Colors.white, fontSize: 14),
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
