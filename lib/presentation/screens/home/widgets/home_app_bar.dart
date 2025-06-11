import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_theme.dart';
import 'category_selector.dart';

class HomeAppBar extends StatefulWidget {
  final bool innerBoxIsScrolled;

  const HomeAppBar({super.key, required this.innerBoxIsScrolled});

  @override
  State<HomeAppBar> createState() => _HomeAppBarState();
}

class _HomeAppBarState extends State<HomeAppBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _segmentedButtonController;
  late Animation<double> _segmentedButtonAnimation;

  @override
  void initState() {
    super.initState();
    _segmentedButtonController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _segmentedButtonAnimation = CurvedAnimation(
      parent: _segmentedButtonController,
      curve: Curves.easeOutCubic,
    );

    _segmentedButtonController.forward();
  }

  @override
  void dispose() {
    _segmentedButtonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                  AnimatedBuilder(
                    animation: _segmentedButtonAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: 0.8 + (0.2 * _segmentedButtonAnimation.value),
                        child: Opacity(
                          opacity: _segmentedButtonAnimation.value,
                          child: const CategorySelector(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
