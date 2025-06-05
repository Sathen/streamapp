// chip_list.dart
import 'package:flutter/material.dart';

class ChipList extends StatelessWidget {
  final List<String> items;
  final ThemeData theme;

  const ChipList({
    super.key,
    required this.items,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12.0,
      runSpacing: 8.0,
      children: items.map((item) {
        return Chip(
          label: Text(
            item,
            style: theme.textTheme.bodySmall,
          ),
          backgroundColor: theme.colorScheme.surfaceVariant,
          side: BorderSide(
            color: theme.colorScheme.outlineVariant.withOpacity(0.5),
          ),
        );
      }).toList(),
    );
  }
}
