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
    const double minCardWidth = 120.0; // Можете налаштувати це значення
    const double spacing = 12.0;

    int crossAxisCount = (screenWidth / (minCardWidth + spacing)).floor();

    if (crossAxisCount < 2) {
      crossAxisCount = 2;
    }

    if (crossAxisCount > 6) {
      crossAxisCount = 6;
    }

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
      onTap:
          () => context.push(
            '/media/online/${Base64Encoder.urlSafe().convert(item.path!.codeUnits)}',
          ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            // Image with spinner and fallback
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
                errorBuilder:
                    (context, error, _) => const Center(
                      child: Icon(
                        Icons.broken_image,
                        size: 40,
                        color: Colors.white54,
                      ),
                    ),
              ),
            ),

            // Title overlay
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
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
