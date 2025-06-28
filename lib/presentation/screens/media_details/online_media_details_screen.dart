import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/models/search_result.dart';
import '../../providers/media_details/media_details_provider.dart';
import 'widgets/media_details_app_bar.dart';
import 'widgets/media_details_content.dart';

class OnlineMediaDetailsScreen extends StatefulWidget {
  final SearchItem searchItem;

  const OnlineMediaDetailsScreen({super.key, required this.searchItem});

  @override
  State<OnlineMediaDetailsScreen> createState() =>
      _OnlineMediaDetailsScreenState();
}

class _OnlineMediaDetailsScreenState extends State<OnlineMediaDetailsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MediaDetailsProvider>().loadOnlineMediaDetails(
        widget.searchItem,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MediaDetailsProvider>(
      builder: (context, provider, child) {
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
            child: MediaDetailsAppBar(
              title: provider.onlineMediaData?.title ?? widget.searchItem.title,
              backdropPath: provider.onlineMediaData?.backdropPath,
              child: MediaDetailsContent(
                provider: provider,
                isOnlineMedia: true,
              ),
            ),
          ),
        );
      },
    );
  }
}
