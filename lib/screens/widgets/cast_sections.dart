import 'package:flutter/material.dart';

class CastChipList extends StatelessWidget {
  final List<Map<String, dynamic>> cast;

  const CastChipList({super.key, required this.cast});

  @override
  Widget build(BuildContext context) {
    if (cast.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: cast
          .map(
            (actor) => Chip(
              label: Text(
                '${actor['name']} (${actor['role'] ?? 'Unknown Role'})',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              backgroundColor: Theme.of(context).colorScheme.surface,
            ),
          )
          .toList(),
    );
  }
}
