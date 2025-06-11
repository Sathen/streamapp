import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

class SearchAppBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onBackPressed;
  final Function(String) onSearch;
  final VoidCallback onClear;

  const SearchAppBar({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onBackPressed,
    required this.onSearch,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceBlue.withOpacity(0.8),
        border: Border(
          bottom: BorderSide(color: AppTheme.outlineVariant, width: 1),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onBackPressed,
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.surfaceBlue,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.outlineVariant, width: 1),
              ),
              child: Icon(
                Icons.arrow_back_rounded,
                color: AppTheme.highEmphasisText,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.surfaceBlue,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color:
                      focusNode.hasFocus
                          ? AppTheme.accentBlue
                          : AppTheme.outlineColor,
                  width: focusNode.hasFocus ? 2 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                style: TextStyle(
                  color: AppTheme.highEmphasisText,
                  fontSize: 16,
                ),
                decoration: InputDecoration(
                  hintText: 'Search movies, TV shows...',
                  hintStyle: TextStyle(
                    color: AppTheme.lowEmphasisText,
                    fontSize: 16,
                  ),
                  prefixIcon: Container(
                    margin: const EdgeInsets.all(12),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.accentBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.search_rounded,
                      color: AppTheme.accentBlue,
                      size: 20,
                    ),
                  ),
                  suffixIcon:
                      controller.text.isNotEmpty
                          ? IconButton(
                            onPressed: onClear,
                            icon: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: AppTheme.lowEmphasisText.withOpacity(
                                  0.1,
                                ),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Icon(
                                Icons.clear_rounded,
                                color: AppTheme.lowEmphasisText,
                                size: 16,
                              ),
                            ),
                          )
                          : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
                onSubmitted: onSearch,
                textInputAction: TextInputAction.search,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
