import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../providers/home_screen_provider.dart';
import 'media_section.dart';

// Enum to represent the selected display category
enum DisplayCategory { movies, tv }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin {
  // State variable to keep track of the selected category
  DisplayCategory _selectedCategory = DisplayCategory.movies;

  // Animation controllers for smooth transitions
  late AnimationController _segmentedButtonController;
  late AnimationController _contentController;
  late AnimationController _loadingController;
  late Animation<double> _segmentedButtonAnimation;
  late Animation<double> _contentAnimation;
  late Animation<double> _loadingAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize animation controllers
    _segmentedButtonController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _contentController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _loadingController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    _segmentedButtonAnimation = CurvedAnimation(
      parent: _segmentedButtonController,
      curve: Curves.easeOutCubic,
    );

    _contentAnimation = CurvedAnimation(
      parent: _contentController,
      curve: Curves.easeInOutCubic,
    );

    _loadingAnimation = CurvedAnimation(
      parent: _loadingController,
      curve: Curves.easeInOut,
    );

    // Start animations
    _segmentedButtonController.forward();
    _contentController.forward();
  }

  @override
  void dispose() {
    _segmentedButtonController.dispose();
    _contentController.dispose();
    _loadingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HomeScreenProvider>();

    if (provider.isLoading) {
      return _buildLoadingScreen(context);
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundBlue,
      extendBodyBehindAppBar: true,
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
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            _buildSliverAppBar(context, innerBoxIsScrolled),
          ],
          body: _buildBody(provider),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(context),
    );
  }

  Widget _buildLoadingScreen(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBlue,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.backgroundBlue,
              AppTheme.surfaceBlue.withOpacity(0.3),
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceBlue,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: AppTheme.outlineVariant,
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedBuilder(
                      animation: _loadingAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: 1.0 + (_loadingAnimation.value * 0.1),
                          child: Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppTheme.accentBlue,
                                  AppTheme.primaryBlue,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(32),
                            ),
                            child: Center(
                              child: SizedBox(
                                width: 32,
                                height: 32,
                                child: CircularProgressIndicator(
                                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                                  strokeWidth: 3,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Loading your entertainment...',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.highEmphasisText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Preparing the best content for you',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.mediumEmphasisText,
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

  Widget _buildSliverAppBar(BuildContext context, bool innerBoxIsScrolled) {
    return SliverAppBar(
      expandedHeight: 160,
      floating: true,
      pinned: true,
      snap: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.backgroundBlue,
                AppTheme.surfaceBlue.withOpacity(0.3),
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSegmentedButtonSection(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSegmentedButtonSection(BuildContext context) {
    return AnimatedBuilder(
      animation: _segmentedButtonAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: 0.8 + (0.2 * _segmentedButtonAnimation.value),
          child: Opacity(
            opacity: _segmentedButtonAnimation.value,
            child: _buildSegmentedButton(context),
          ),
        );
      },
    );
  }

  Widget _buildSegmentedButton(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.surfaceBlue,
        borderRadius: BorderRadius.circular(20),
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
      child: Row(
        children: [
          Expanded(
            child: _buildCategoryButton(
              context,
              DisplayCategory.movies,
              Icons.movie_rounded,
              'Movies',
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _buildCategoryButton(
              context,
              DisplayCategory.tv,
              Icons.tv_rounded,
              'TV Shows',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryButton(
      BuildContext context,
      DisplayCategory category,
      IconData icon,
      String label,
      ) {
    final isSelected = _selectedCategory == category;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          setState(() {
            _selectedCategory = category;
          });
          _contentController.reset();
          _contentController.forward();
        },
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
              colors: [
                AppTheme.primaryBlue,
                AppTheme.accentBlue,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            )
                : null,
            color: isSelected ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            boxShadow: isSelected
                ? [
              BoxShadow(
                color: AppTheme.primaryBlue.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : AppTheme.mediumEmphasisText,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isSelected ? Colors.white : AppTheme.mediumEmphasisText,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(HomeScreenProvider provider) {
    List<Widget> slivers = _getSliversForCategory(provider, _selectedCategory);

    return AnimatedBuilder(
      animation: _contentAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _contentAnimation.value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - _contentAnimation.value)),
            child: RefreshIndicator(
              onRefresh: () async {
                HapticFeedback.mediumImpact();
                await provider.initializeData();
                if (mounted) {
                  setState(() {});
                }
              },
              color: AppTheme.accentBlue,
              backgroundColor: AppTheme.surfaceBlue,
              strokeWidth: 3,
              displacement: 60,
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  const SliverToBoxAdapter(
                    child: SizedBox(height: 16),
                  ),
                  if (slivers.isEmpty) _buildEmptyState(context),
                  ...slivers,
                  const SliverToBoxAdapter(
                    child: SizedBox(height: 100),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AppTheme.surfaceBlue,
          borderRadius: BorderRadius.circular(24),
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
                _selectedCategory == DisplayCategory.movies
                    ? Icons.movie_outlined
                    : Icons.tv_outlined,
                size: 48,
                color: AppTheme.accentBlue,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Content Available',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppTheme.highEmphasisText,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'We\'re working on getting the best ${_selectedCategory == DisplayCategory.movies ? 'movies' : 'TV shows'} for you.',
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

  List<Widget> _getSliversForCategory(
      HomeScreenProvider provider,
      DisplayCategory category,
      ) {
    if (category == DisplayCategory.movies) {
      return [
        if (provider.nowPlayingMovies.isNotEmpty)
          MediaSection(
            title: '🎬 Now Playing',
            items: provider.nowPlayingMovies,
          ),
        if (provider.popularMovies.isNotEmpty)
          MediaSection(
            title: '🔥 Trending Movies',
            items: provider.popularMovies,
          ),
        if (provider.topRatedMovies.isNotEmpty)
          MediaSection(
            title: '⭐ Top Rated',
            items: provider.topRatedMovies,
          ),
        if (provider.newestMovies.isNotEmpty)
          MediaSection(
            title: '🆕 Latest Releases',
            items: provider.newestMovies,
          ),
      ];
    } else if (category == DisplayCategory.tv) {
      return [
        if (provider.popularTV.isNotEmpty)
          MediaSection(
            title: '📺 Trending Shows',
            items: provider.popularTV,
          ),
        if (provider.topRatedTV.isNotEmpty)
          MediaSection(
            title: '🏆 Critically Acclaimed',
            items: provider.topRatedTV,
          ),
        if (provider.newestTV.isNotEmpty)
          MediaSection(
            title: '🗓️ Fresh Episodes',
            items: provider.newestTV,
          ),
      ];
    }
    return [];
  }

  Widget _buildBottomNavigationBar(BuildContext context) {
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
              top: BorderSide(
                color: AppTheme.outlineVariant,
                width: 1,
              ),
            ),
          ),
          child: BottomNavigationBar(
            currentIndex: 0,
            backgroundColor: Colors.transparent,
            selectedItemColor: AppTheme.accentBlue,
            unselectedItemColor: AppTheme.mediumEmphasisText,
            type: BottomNavigationBarType.fixed,
            elevation: 0,
            selectedLabelStyle: TextStyle(
              fontWeight: FontWeight.w600,
              color: AppTheme.accentBlue,
            ),
            unselectedLabelStyle: TextStyle(
              fontWeight: FontWeight.normal,
              color: AppTheme.mediumEmphasisText,
            ),
            onTap: (index) {
              HapticFeedback.lightImpact();
              switch (index) {
                case 0:
                // Already on home
                  break;
                case 1:
                  context.push('/search');
                  break;
                case 2:
                  context.push('/downloads');
                  break;
              }
            },
            items: [
              BottomNavigationBarItem(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.accentBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.home_rounded, size: 24),
                ),
                activeIcon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppTheme.accentBlue, AppTheme.primaryBlue],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.accentBlue.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(Icons.home_rounded, color: Colors.white, size: 24),
                ),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  child: Icon(Icons.search_rounded, size: 24),
                ),
                label: 'Search',
              ),
              BottomNavigationBarItem(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  child: Icon(Icons.download_rounded, size: 24),
                ),
                label: 'Downloads',
              ),
            ],
          ),
        ),
      ),
    );
  }
}