
class MediaItem {
  final String id;
  final String name;
  final double? progress;
  final String? posterPath;

  MediaItem({
    required this.id,
    required this.name,
    this.progress,
    this.posterPath,
  });

  factory MediaItem.fromJson(Map<String, dynamic> json) {
    return MediaItem(
      id: json['Id'] ?? '',
      name: json['Name'] ?? 'Unknown',
      posterPath: json['ImageTags']?['Primary'],
    );
  }

}