import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;
import '../models/web_player_info.dart';

class WebPlayerBridge {
  static final Map<String, web.HTMLIFrameElement> _iframes = {};
  static final ValueNotifier<WebPlayerInfo> playerStateNotifier =
      ValueNotifier(const WebPlayerInfo(isPlaying: true, currentTime: 0.0));
  static bool _listenerAttached = false;
  static Timer? _playbackTicker;
  static double _currentSpeed = 1.0;

  static void initListener() {
    if (_listenerAttached) return;
    _listenerAttached = true;

    web.window.addEventListener(
      'message',
      (web.MessageEvent event) {
        try {
          final jsData = event.data;
          if (jsData == null) return;

          Map<String, dynamic>? messageMap;
          final dartified = jsData.dartify();

          if (dartified is String) {
            try {
              final dec = jsonDecode(dartified);
              if (dec is Map) {
                messageMap = Map<String, dynamic>.from(dec);
              }
            } catch (_) {}
          } else if (dartified is Map) {
            messageMap = Map<String, dynamic>.from(dartified);
          }

          if (messageMap == null) return;

          final info = messageMap['info'];
          if (info is Map) {
            final infoMap = Map<String, dynamic>.from(info);
            double? cur;
            double? dur;
            bool? playing;
            int? vol;
            bool? muted;

            if (infoMap['currentTime'] is num) {
              cur = (infoMap['currentTime'] as num).toDouble();
            }
            if (infoMap['duration'] is num && (infoMap['duration'] as num) > 0) {
              dur = (infoMap['duration'] as num).toDouble();
            }
            if (infoMap['playerState'] == 1) {
              playing = true;
            } else if (infoMap['playerState'] == 2 || infoMap['playerState'] == 0) {
              playing = false;
            }
            if (infoMap['volume'] is num) {
              vol = (infoMap['volume'] as num).toInt();
            }
            if (infoMap['muted'] is bool) {
              muted = infoMap['muted'] as bool;
            }

            if (cur != null || dur != null || playing != null || vol != null || muted != null) {
              playerStateNotifier.value = playerStateNotifier.value.copyWith(
                currentTime: cur,
                duration: dur,
                isPlaying: playing,
                volume: vol,
                isMuted: muted,
              );
            }
          }
        } catch (_) {}
      }.toJS,
    );
  }

  static void startPlaybackTicker() {
    _playbackTicker?.cancel();
    _playbackTicker = Timer.periodic(const Duration(milliseconds: 250), (_) {
      final state = playerStateNotifier.value;
      if (state.isPlaying) {
        final cur = state.currentTime + (0.25 * _currentSpeed);
        final dur = state.duration > 0 ? state.duration : 100000.0;
        final nextTime = cur.clamp(0.0, dur);
        playerStateNotifier.value = state.copyWith(currentTime: nextTime);
      }
    });
  }

  static void sendHandshake(String videoId) {
    final iframe = _iframes[videoId];
    if (iframe == null) return;
    try {
      final payload = jsonEncode({
        'event': 'listening',
        'id': iframe.id,
      });
      iframe.contentWindow?.postMessage(payload.toJS, '*'.toJS);
    } catch (_) {}
  }

  static void sendCommand(String videoId, String command, [List<dynamic>? args]) {
    final iframe = _iframes[videoId];
    if (iframe == null) return;
    try {
      final payload = jsonEncode({
        'event': 'command',
        'func': command,
        'args': args ?? [],
      });
      iframe.contentWindow?.postMessage(payload.toJS, '*'.toJS);
    } catch (_) {}
  }

  static void seekTo(String videoId, double seconds) {
    playerStateNotifier.value =
        playerStateNotifier.value.copyWith(currentTime: seconds);
    sendCommand(videoId, 'seekTo', [seconds, true]);
    sendCommand(videoId, 'playVideo');
  }

  static void seekRelative(String videoId, int seconds) {
    final cur = playerStateNotifier.value.currentTime;
    final dur = playerStateNotifier.value.duration;
    final target = (cur + seconds).clamp(0.0, dur > 0 ? dur : 100000.0);
    seekTo(videoId, target);
  }

  static void togglePlay(String videoId) {
    if (playerStateNotifier.value.isPlaying) {
      sendCommand(videoId, 'pauseVideo');
      playerStateNotifier.value =
          playerStateNotifier.value.copyWith(isPlaying: false);
    } else {
      sendCommand(videoId, 'playVideo');
      playerStateNotifier.value =
          playerStateNotifier.value.copyWith(isPlaying: true);
    }
  }

  static void setVolume(String videoId, int volume) {
    sendCommand(videoId, 'setVolume', [volume]);
    playerStateNotifier.value =
        playerStateNotifier.value.copyWith(volume: volume, isMuted: volume == 0);
  }

  static void toggleMute(String videoId) {
    if (playerStateNotifier.value.isMuted) {
      sendCommand(videoId, 'unMute');
      playerStateNotifier.value =
          playerStateNotifier.value.copyWith(isMuted: false);
    } else {
      sendCommand(videoId, 'mute');
      playerStateNotifier.value =
          playerStateNotifier.value.copyWith(isMuted: true);
    }
  }

  static void setSpeed(String videoId, double speed) {
    _currentSpeed = speed;
    sendCommand(videoId, 'setPlaybackRate', [speed]);
  }

  static void toggleFullscreen(String videoId) {
    final iframe = _iframes[videoId];
    if (iframe != null) {
      try {
        iframe.requestFullscreen();
      } catch (_) {}
    }
  }

  static void toggleCaptions(String videoId, bool enable) {
    if (enable) {
      sendCommand(videoId, 'loadModule', ['captions']);
      sendCommand(videoId, 'setOption', ['captions', 'reload', true]);
      sendCommand(videoId, 'setOption', ['captions', 'track', {'languageCode': 'en'}]);
      sendCommand(videoId, 'setOption', ['captions', 'track', {'languageCode': 'hi'}]);
      sendCommand(videoId, 'setOption', ['captions', 'track', {'languageCode': 'ur'}]);
      sendCommand(videoId, 'setOption', ['captions', 'fontSize', 1]);
    } else {
      sendCommand(videoId, 'unloadModule', ['captions']);
      sendCommand(videoId, 'setOption', ['captions', 'track', {}]);
      sendCommand(videoId, 'setOption', ['captions', 'track', {'languageCode': ''}]);
    }
  }
}

Widget buildWebIframePlayer(String videoId) {
  WebPlayerBridge.initListener();
  WebPlayerBridge._currentSpeed = 1.0;
  WebPlayerBridge.playerStateNotifier.value =
      WebPlayerBridge.playerStateNotifier.value.copyWith(
    currentTime: 0.0,
    isPlaying: true,
  );
  WebPlayerBridge.startPlaybackTicker();

  final viewType = 'youtube-iframe-$videoId';

  ui_web.platformViewRegistry.registerViewFactory(
    viewType,
    (int viewId) {
      final iframe = web.document.createElement('iframe') as web.HTMLIFrameElement;
      iframe.id = 'yt-frame-$videoId';
      iframe.src =
          'https://www.youtube-nocookie.com/embed/$videoId?autoplay=1&enablejsapi=1&controls=0&fs=1&rel=0&playsinline=1&modestbranding=1&iv_load_policy=3&cc_load_policy=1';
      iframe.style.border = 'none';
      iframe.style.width = '100%';
      iframe.style.height = '100%';
      iframe.style.pointerEvents = 'none';
      iframe.allow =
          'accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share; fullscreen';

      WebPlayerBridge._iframes[videoId] = iframe;

      iframe.onLoad.listen((_) {
        WebPlayerBridge.sendHandshake(videoId);
        Timer(const Duration(milliseconds: 600), () => WebPlayerBridge.sendHandshake(videoId));
        Timer(const Duration(seconds: 1), () => WebPlayerBridge.sendHandshake(videoId));
        Timer(const Duration(seconds: 2), () => WebPlayerBridge.sendHandshake(videoId));
      });

      return iframe;
    },
  );

  return HtmlElementView(viewType: viewType);
}

ValueNotifier<WebPlayerInfo> getWebPlayerStateNotifier() {
  return WebPlayerBridge.playerStateNotifier;
}

void triggerWebSeekTo(String videoId, double seconds) {
  WebPlayerBridge.seekTo(videoId, seconds);
}

void triggerWebSeek(String videoId, int seconds) {
  WebPlayerBridge.seekRelative(videoId, seconds);
}

void triggerWebPlayPause(String videoId) {
  WebPlayerBridge.togglePlay(videoId);
}

void triggerWebSpeed(String videoId, double speed) {
  WebPlayerBridge.setSpeed(videoId, speed);
}

void triggerWebVolume(String videoId, int volume) {
  WebPlayerBridge.setVolume(videoId, volume);
}

void triggerWebToggleMute(String videoId) {
  WebPlayerBridge.toggleMute(videoId);
}

void triggerWebFullscreen(String videoId) {
  WebPlayerBridge.toggleFullscreen(videoId);
}

void triggerWebToggleCaptions(String videoId, bool enable) {
  WebPlayerBridge.toggleCaptions(videoId, enable);
}
