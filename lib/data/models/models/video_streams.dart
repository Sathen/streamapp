import 'dart:convert';

class VideoStreams {
  List<VideoSource> data = [];

  VideoStreams();

  VideoStreams.fromJson(Map<String, dynamic> json) {
    if (json['data'] != null) {
      data = (json['data'] as List)
          .map((item) => VideoSource.fromJson(item))
          .toList();
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'data': data.map((source) => source.toJson()).toList(),
    };
  }

  @override
  String toString() => jsonEncode(toJson());
}

class VideoSource {
  late String sourceName;
  late List<VideoStream> sources = [];

  VideoSource();

  VideoSource.fromJson(Map<String, dynamic> data) {
    sourceName = data["source_name"] ?? "";
    if (data["sources"] != null) {
      sources = (data["sources"] as List)
          .map((source) => VideoStream.fromJson(source))
          .toList();
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'source_name': sourceName,
      'sources': sources.map((stream) => stream.toJson()).toList(),
    };
  }

  @override
  String toString() => jsonEncode(toJson());
}

class VideoStream {
  late String name;
  late List<VideoLink> links = [];

  VideoStream();

  VideoStream.fromJson(Map<String, dynamic> data) {
    name = data["name"] ?? "";
    if (data["links"] != null) {
      links = (data["links"] as List)
          .map((link) => VideoLink.fromJson(link))
          .toList();
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'links': links.map((link) => link.toJson()).toList(),
    };
  }

  @override
  String toString() => jsonEncode(toJson());
}

class VideoLink {
  late String quality;
  late String url;

  VideoLink();

  VideoLink.fromJson(Map<String, dynamic> data) {
    quality = data["quality"]?.toString() ?? "";
    url = data["url"] ?? "";
  }

  Map<String, dynamic> toJson() {
    return {
      'quality': quality,
      'url': url,
    };
  }

  @override
  String toString() => jsonEncode(toJson());
}