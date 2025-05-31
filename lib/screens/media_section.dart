import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:stream_flutter/providers/auth_provider.dart';
import '../../models/media_item.dart';
import '../../util/image_util.dart';

class MediaSection extends StatelessWidget {
  final String title;
  final List<MediaItem> items;
  final bool showProgress;

  const MediaSection({
    super.key,
    required this.title,
    required this.items,
    this.showProgress = false,
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
                TextButton(
                  onPressed: () => context.push('/library/$title'),
                  child: const Text('See All'),
                ),
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
            if (showProgress)
              LinearProgressIndicator(
                value: item.progress?.toDouble() ?? 0.0,
                backgroundColor: Colors.black26,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.secondary,
                ),
              ),
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