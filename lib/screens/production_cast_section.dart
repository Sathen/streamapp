// production_cast_section.dart
import 'package:flutter/material.dart';

import '../data/models/models/tmdb_models.dart';
import 'chip_list.dart';

class ProductionCastSection extends StatelessWidget {
  final ThemeData theme;
  final List<ProductionCompany> companies;

  const ProductionCastSection({
    super.key,
    required this.theme,
    required this.companies,
  });

  @override
  Widget build(BuildContext context) {
    final companyNames = companies.map((c) => c.name).toList();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (companies.isNotEmpty) ...[
            Text(
              'Production Companies',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ChipList(items: companyNames, theme: theme),
            const SizedBox(height: 24),
          ],
        ],
      ),
    );
  }
}
