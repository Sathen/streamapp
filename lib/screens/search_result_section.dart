import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:stream_flutter/models/search_result.dart';

class SearchResultSection extends StatelessWidget {
  final SearchResult searchResult;

  const SearchResultSection({super.key, required this.searchResult});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    const double spacing = 12.0;

    // Calculate optimal card width based on screen size
    double targetCardWidth = screenWidth < 600
        ? 120
        : screenWidth < 900
        ? 140
        : 160;

    int crossAxisCount = (screenWidth / (targetCardWidth + spacing)).floor();
    crossAxisCount = crossAxisCount.clamp(2, 6);

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: searchResult.items.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: spacing,
        mainAxisSpacing: spacing,
        childAspectRatio: 3 / 4.5,
      ),
      itemBuilder: (context, index) {
        return AspectRatio(
          aspectRatio: 3 / 4.5,
          child: _buildMediaCard(context, searchResult.items[index]),
        );
      },
    );
  }

  Widget _buildMediaCard(BuildContext context, SearchItem item) {
    return GestureDetector(
      onTap: () => context.push(
        '/media/online',
        extra: item
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            SizedBox(
              width: double.infinity,
              height: double.infinity,
              child: Image.network(
                "https://corsproxy.io/?url=${item.img!}",
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  );
                },
                errorBuilder: (context, error, _) => const Center(
                  child: Icon(
                    Icons.broken_image,
                    size: 40,
                    color: Colors.white54,
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                color: Colors.black.withOpacity(0.5),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Text(
                  item.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
