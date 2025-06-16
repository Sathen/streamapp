import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

class RecentSearches extends StatelessWidget {
  final List<String> recentSearches;
  final Function(String) onSearchTap;
  final VoidCallback onClearAll;
  final Function(String)?
  onRemoveSearch; // New callback for removing individual searches

  const RecentSearches({
    super.key,
    required this.recentSearches,
    required this.onSearchTap,
    required this.onClearAll,
    this.onRemoveSearch,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.history_rounded, color: AppTheme.accentBlue, size: 24),
              const SizedBox(width: 12),
              Text(
                'Recent Searches',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppTheme.highEmphasisText,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: onClearAll,
                child: Text(
                  'Clear All',
                  style: TextStyle(color: AppTheme.accentBlue),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.separated(
              itemCount: recentSearches.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final search = recentSearches[index];
                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => onSearchTap(search),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceBlue,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.outlineVariant,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.search_rounded,
                            color: AppTheme.mediumEmphasisText,
                            size: 20,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              search,
                              style: Theme.of(context).textTheme.bodyLarge
                                  ?.copyWith(color: AppTheme.highEmphasisText),
                            ),
                          ),
                          if (onRemoveSearch != null)
                            IconButton(
                              onPressed: () => onRemoveSearch!(search),
                              icon: Icon(
                                Icons.close,
                                color: AppTheme.lowEmphasisText,
                                size: 16,
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 32,
                                minHeight: 32,
                              ),
                            ),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            color: AppTheme.lowEmphasisText,
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
