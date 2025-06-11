import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/enums/display_category.dart';
import '../../../../core/theme/app_theme.dart';
import 'category_button.dart';

class CategorySelector extends StatefulWidget {
  const CategorySelector({super.key});

  @override
  State<CategorySelector> createState() => _CategorySelectorState();
}

class _CategorySelectorState extends State<CategorySelector> {
  DisplayCategory _selectedCategory = DisplayCategory.movies;

  @override
  Widget build(BuildContext context) {
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
              isSelected: _selectedCategory == DisplayCategory.movies,
              onTap: () => _onCategoryChanged(DisplayCategory.movies),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: CategoryButton(
              category: DisplayCategory.tv,
              icon: Icons.tv_rounded,
              label: 'TV Shows',
              isSelected: _selectedCategory == DisplayCategory.tv,
              onTap: () => _onCategoryChanged(DisplayCategory.tv),
            ),
          ),
        ],
      ),
    );
  }

  void _onCategoryChanged(DisplayCategory category) {
    HapticFeedback.lightImpact();
    setState(() {
      _selectedCategory = category;
    });
    // Notify parent about category change
    // context.read<HomeScreenProvider>().setSelectedCategory(category);
  }
}
