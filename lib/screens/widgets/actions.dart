import 'package:flutter/material.dart';
import 'package:stream_flutter/models/media_detail.dart';

class ActionsSection extends StatelessWidget {

  final MediaDetail mediaDetail;

  const ActionsSection({super.key, required this.mediaDetail});

  @override
  Widget build(BuildContext context) {
    return  Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildActionButton(
          context: context,
          icon:
          mediaDetail.isFavorite ? Icons.favorite : Icons.favorite_border,
          label: 'Favorite',
          onPressed: _toggleFavorite,
        ),
        _buildActionButton(
          context: context,
          icon: Icons.download,
          label: 'Download',
          onPressed: _downloadMedia,
        ),
        _buildActionButton(
          context: context,
          icon: Icons.cast,
          label: 'Cast',
          onPressed: () => _showCastDevices(context),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Column(
      children: [
        IconButton(
          icon: Icon(icon),
          onPressed: onPressed,
          color: Theme.of(context).colorScheme.secondary,
        ),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }


  Future<void> _toggleFavorite() async {
    // TODO: Implement favorite toggle using Jellyfin API
  }

  Future<void> _downloadMedia() async {
    // TODO: Implement download functionality
  }

  Future<void> _showCastDevices(BuildContext context) async {
    // TODO: Implement cast device selection
    showModalBottomSheet(
      context: context,
      builder:
          (context) => ListView(
        children: [
          ListTile(
            title: const Text('Available Devices'),
            subtitle: const Text('Searching...'),
            leading: const Icon(Icons.cast),
          ),
        ],
      ),
    );
  }


}