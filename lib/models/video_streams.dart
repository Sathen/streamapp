import 'dart:convert';

class VideoStreams {
  Map<String, List<VideoStream>> streams = {};

  VideoStreams();

  VideoStreams.fromJson(Map<String, dynamic> data) {
    final raw = data['data'] as Map<String, dynamic>;
    raw.forEach((key, value) {
      streams[key] =
          (value as List).map((v) => VideoStream.fromJson(v)).toList();
    });
  }

  @override
  String toString() => jsonEncode(streams);
}

class VideoStream {
  late String name;
  late List<VideoLink> links = [];

  VideoStream();

  VideoStream.fromJson(Map<String, dynamic> data) {
    name = data["name"];
    links =
        (data["links"] as List).map((link) => VideoLink.fromJson(link)).toList();
  }

  @override
  String toString() => jsonEncode({"name": name, "links": links});
}

class VideoLink {
  late String quality;
  late String url;

  VideoLink();

  VideoLink.fromJson(Map<String, dynamic> data) {
    quality = data["quality"].toString();
    url = data["url"];
  }

  @override
  String toString() => jsonEncode({"quality": quality, "url": url});
}
