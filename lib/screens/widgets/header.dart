import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class HeaderImage extends StatelessWidget {
  final String? backdropUrl;
  final String? fallbackPosterUrl;

  const HeaderImage({
    super.key,
    required this.backdropUrl,
    required this.fallbackPosterUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CachedNetworkImage(
          imageUrl: backdropUrl ?? '',
          height: 300,
          width: double.infinity,
          fit: BoxFit.cover,
          errorWidget:
              (context, url, error) =>
                  fallbackPosterUrl != null
                      ? CachedNetworkImage(
                        imageUrl: fallbackPosterUrl!,
                        height: 300,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      )
                      : Container(
                        height: 300,
                        color: Theme.of(context).colorScheme.surface,
                        child: const Icon(Icons.image_not_supported),
                      ),
          placeholder:
              (context, url) => Container(
                color: Theme.of(context).colorScheme.surface,
                height: 300,
              ),
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Theme.of(context).scaffoldBackgroundColor,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
