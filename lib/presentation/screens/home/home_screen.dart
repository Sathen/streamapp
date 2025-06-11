import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:stream_flutter/presentation/screens/home/widgets/media_content.dart';

import '../../../core/theme/app_theme.dart';
import '../../providers/media/media_provider.dart';
import 'widgets/category_selector.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Initialize media data when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MediaProvider>().initializeData();
    });
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
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CategorySelector(),
                  ),

                  // Content
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: () => mediaProvider.initializeData(),
                      child: MediaContent(provider: mediaProvider),
                    ),
                  ),
                ],
              ),
            ),
          ),
          bottomNavigationBar: _buildBottomNavigationBar(),
        );
      },
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
                  'Discover amazing content',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.mediumEmphasisText,
                  ),
                ),
              ],
            ),
          ),
        ],
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
            onTap: (index) {
              switch (index) {
                case 0:
                  // Already on home
                  break;
                case 1:
                  context.go('/search');
                  break;
                case 2:
                  context.go('/downloads');
                  break;
              }
            },
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
                icon: Icon(Icons.download_rounded),
                label: 'Downloads',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
