import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:modern_player/modern_player.dart';

class PlatformVideoPlayer extends StatelessWidget {
  final String url;

  const PlatformVideoPlayer({super.key, required this.url});

  @override
  Widget build(BuildContext context) {
    return InternalPlayerScreen(url: url);
  }
}

class InternalPlayerScreen extends StatelessWidget {
  final String url;

  const InternalPlayerScreen({super.key, required this.url});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          ModernPlayer.createPlayer(
            video: ModernPlayerVideo.single(
              source: url,
              sourceType: ModernPlayerSourceType.network,
            ),
            defaultSelectionOptions: ModernPlayerDefaultSelectionOptions(
              defaultAudioSelectors: [ DefaultSelectorLabel("Ukrainian"),  DefaultSelectorLabel("UKR")],
              defaultSubtitleSelectors: [ DefaultSelectorLabel("Ukrainian"),  DefaultSelectorLabel("UKR")],
            ),
            callbackOptions: ModernPlayerCallbackOptions(
              onBackPressed: () async {
              // Set preferred orientations back to portrait before popping
              await SystemChrome.setPreferredOrientations([
                DeviceOrientation.portraitUp,
                DeviceOrientation.portraitDown,
              ]);
              // Return to previous screen
              Navigator.pop(context);
              },
            ),
          ),
        ],
      ),
    );
  }
}
