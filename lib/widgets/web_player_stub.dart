import 'package:flutter/material.dart';
import '../models/web_player_info.dart';

Widget buildWebIframePlayer(String videoId) {
  return const Center(
    child: Text(
      'Web player only available on Web platform',
      style: TextStyle(color: Colors.white),
    ),
  );
}

ValueNotifier<WebPlayerInfo> getWebPlayerStateNotifier() {
  return ValueNotifier(const WebPlayerInfo());
}

void triggerWebSeekTo(String videoId, double seconds) {}
void triggerWebSeek(String videoId, int seconds) {}
void triggerWebPlayPause(String videoId) {}
void triggerWebSpeed(String videoId, double speed) {}
void triggerWebVolume(String videoId, int volume) {}
void triggerWebToggleMute(String videoId) {}
void triggerWebFullscreen(String videoId) {}
void triggerWebToggleCaptions(String videoId, bool enable) {}
