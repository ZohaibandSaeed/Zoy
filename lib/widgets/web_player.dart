import 'web_player_stub.dart'
    if (dart.library.js_interop) 'web_player_web.dart' as player_impl;
import 'package:flutter/material.dart';
import '../models/web_player_info.dart';

export '../models/web_player_info.dart';

Widget getPlatformWebPlayer(String videoId) {
  return player_impl.buildWebIframePlayer(videoId);
}

ValueNotifier<WebPlayerInfo> getPlatformPlayerNotifier() {
  return player_impl.getWebPlayerStateNotifier();
}

void sendWebSeekTo(String videoId, double seconds) {
  player_impl.triggerWebSeekTo(videoId, seconds);
}

void sendWebSeek(String videoId, int seconds) {
  player_impl.triggerWebSeek(videoId, seconds);
}

void sendWebPlayPause(String videoId) {
  player_impl.triggerWebPlayPause(videoId);
}

void sendWebSpeed(String videoId, double speed) {
  player_impl.triggerWebSpeed(videoId, speed);
}

void sendWebVolume(String videoId, int volume) {
  player_impl.triggerWebVolume(videoId, volume);
}

void sendWebToggleMute(String videoId) {
  player_impl.triggerWebToggleMute(videoId);
}

void sendWebFullscreen(String videoId) {
  player_impl.triggerWebFullscreen(videoId);
}

void sendWebToggleCaptions(String videoId, bool enable) {
  player_impl.triggerWebToggleCaptions(videoId, enable);
}
