import 'dart:convert';
import 'package:http/http.dart' as http;

class PlaybackService {
  final String serverUrl;
  final Map<String, String> headers;

  PlaybackService({
    required this.serverUrl,
    required this.headers,
  });

  Future<Map<String, dynamic>> getPlaybackInfo(String itemId) async {
    final response = await http.get(
      Uri.parse('$serverUrl/Items/$itemId/PlaybackInfo'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception('Failed to get playback info');
  }

  String getStreamUrl(String itemId, String mediaSourceId) {
    return '$serverUrl/Videos/$itemId/stream'
        '?static=true'
        '&MediaSourceId=$mediaSourceId';
  }

  Future<Map<String, dynamic>> reportPlaybackStart(
    String itemId,
    String mediaSourceId,
  ) async {
    final response = await http.post(
      Uri.parse('$serverUrl/Sessions/Playing'),
      headers: headers,
      body: json.encode({
        'ItemId': itemId,
        'MediaSourceId': mediaSourceId,
        'PlayMethod': 'DirectStream',
      }),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception('Failed to report playback start');
  }

  Future<void> reportPlaybackProgress(
    String itemId,
    String mediaSourceId,
    Duration position,
  ) async {
    await http.post(
      Uri.parse('$serverUrl/Sessions/Playing/Progress'),
      headers: headers,
      body: json.encode({
        'ItemId': itemId,
        'MediaSourceId': mediaSourceId,
        'PositionTicks': position.inMicroseconds * 10,
      }),
    );
  }

  Future<void> reportPlaybackStopped(
    String itemId,
    String mediaSourceId,
    Duration position,
  ) async {
    await http.post(
      Uri.parse('$serverUrl/Sessions/Playing/Stopped'),
      headers: headers,
      body: json.encode({
        'ItemId': itemId,
        'MediaSourceId': mediaSourceId,
        'PositionTicks': position.inMicroseconds * 10,
      }),
    );
  }
}