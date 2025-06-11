import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../providers/download/download_provider.dart';
import 'widgets/downloads_app_bar.dart';
import 'widgets/downloads_content.dart';

class DownloadsScreen extends StatefulWidget {
  const DownloadsScreen({super.key});

  @override
  State<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends State<DownloadsScreen> {
  bool _isGridView = false;

  @override
  void initState() {
    super.initState();
    // Load downloads when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DownloadProvider>().loadDownloadedFiles();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DownloadProvider>(
      builder: (context, downloadProvider, child) {
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
                  DownloadsAppBar(
                    downloadProvider: downloadProvider,
                    isGridView: _isGridView,
                    onViewToggle:
                        () => setState(() => _isGridView = !_isGridView),
                  ),
                  Expanded(
                    child: DownloadsContent(
                      downloadProvider: downloadProvider,
                      isGridView: _isGridView,
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
}
