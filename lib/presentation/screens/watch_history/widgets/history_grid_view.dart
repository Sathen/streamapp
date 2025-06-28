// lib/presentation/screens/watch_history/widgets/history_grid_view.dart

import 'package:flutter/material.dart';

import '../../../../data/models/models/watch_history.dart';
import 'history_item_card.dart';

class HistoryGridView extends StatelessWidget {
  final List<WatchHistoryItem> items;
  final Function(WatchHistoryItem) onItemTap;

  const HistoryGridView({
    super.key,
    required this.items,
    required this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = _calculateCrossAxisCount(screenWidth);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.65,
        ),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return HistoryItemCard(
            item: item,
            onTap: () => onItemTap(item),
            isGridView: true,
          );
        },
      ),
    );
  }

  int _calculateCrossAxisCount(double screenWidth) {
    if (screenWidth < 600) return 2;
    if (screenWidth < 900) return 3;
    if (screenWidth < 1200) return 4;
    return 5;
  }
}