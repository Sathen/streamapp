import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../../core/enums/display_category.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../providers/media/media_provider.dart';
import 'category_button.dart';

class CategorySelector extends StatelessWidget {
  const CategorySelector({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<MediaProvider>(
      builder: (context, mediaProvider, child) {
        return Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppTheme.surfaceBlue,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.outlineVariant, width: 1),
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
                child: CategoryButton(
                  category: DisplayCategory.movies,
                  icon: Icons.movie_rounded,
                  label: 'Movies',
                  isSelected: mediaProvider.selectedCategory == DisplayCategory.movies,
                  onTap: () => _onCategoryChanged(context, DisplayCategory.movies),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: CategoryButton(
                  category: DisplayCategory.tv,
                  icon: Icons.tv_rounded,
                  label: 'TV Shows',
                  isSelected: mediaProvider.selectedCategory == DisplayCategory.tv,
                  onTap: () => _onCategoryChanged(context, DisplayCategory.tv),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _onCategoryChanged(BuildContext context, DisplayCategory category) {
    HapticFeedback.lightImpact();

    // Update the MediaProvider with the selected category
    context.read<MediaProvider>().setSelectedCategory(category);
  }
}