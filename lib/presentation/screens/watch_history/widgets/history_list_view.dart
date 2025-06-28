import 'package:flutter/cupertino.dart';

import '../../../../data/models/models/watch_history.dart';
import 'history_item_card.dart';

class HistoryListView extends StatelessWidget {
  final List<WatchHistoryItem> items;
  final Function(WatchHistoryItem) onItemTap;

  const HistoryListView({
    super.key,
    required this.items,
    required this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return HistoryItemCard(
          item: item,
          onTap: () => onItemTap(item),
          isGridView: false,
        );
      },
    );
  }
}
