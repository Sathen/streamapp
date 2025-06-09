import 'dart:convert';

class SearchResult {
  late List<SearchItem> items = [];

  SearchResult();

  SearchResult.fromJson(Map<String, dynamic> data) {
    data["items"]
        .forEach((item) => items.add(SearchItem.fromJson(item)));
  }

  @override
  String toString() {
    return jsonEncode(this);
  }
}

class SearchItem {
  late String title;
  late String? path;
  late String? img;
  late int? year;
  late double? rating;

  SearchItem();

  SearchItem.fromJson(Map<String, dynamic> data) {
    title = data["title"];
    path = data["path"];
    img = data["img"];
    year = data["year"];
    rating = data["rating"];
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'path': path,
      'img': img,
      'year': year,
      'rating': rating,
    };
  }

  @override
  String toString() {
    return jsonEncode(toJson());
  }
}
