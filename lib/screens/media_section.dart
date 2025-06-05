import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/media_item.dart';

class MediaSection extends StatelessWidget {
  final String title;
  final List<MediaItem> items;

  const MediaSection({
    super.key,
    required this.title,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Text(title, style: Theme.of(context).textTheme.titleLarge),
                const Spacer(),
              ],
            ),
          ),
          SizedBox(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: items.length,
              itemBuilder: (context, index) =>
                  _buildMediaCard(context, items[index]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaCard(BuildContext context, MediaItem item) {
    // final serverUrl = context.read<AuthProvider>().serverUrl;
    // final headers = context.read<AuthProvider>().authHeaders;

    return GestureDetector(
      onTap: () => context.push('/media/tmdb/${item.type.name}/${item.id}'),
      child: Container(
        width: 120,
        margin: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          image: DecorationImage(
            image: NetworkImage(
              item.posterPath!,
            ),
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              width: double.infinity,
              color: Colors.black54,
              child: Text(
                item.name,
                style: Theme.of(context).textTheme.bodyMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}