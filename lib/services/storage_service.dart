import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/channel_model.dart';
import '../utils/constants.dart';

class StorageService {
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static SharedPreferences get prefs {
    if (_prefs == null) {
      throw Exception("StorageService must be initialized before use.");
    }
    return _prefs!;
  }

  // ---------------------------------------------------------------------------
  // 1. LOCAL SUBSCRIPTIONS (Strictly Zero Account / Zero History)
  // ---------------------------------------------------------------------------

  static List<SubscribedChannel> getSubscriptions() {
    if (_prefs == null) return [];
    final raw = _prefs!.getString(AppConstants.keySubscriptions);
    if (raw == null || raw.isEmpty) return [];
    try {
      final List decoded = jsonDecode(raw);
      return decoded.map((item) => SubscribedChannel.fromJson(item)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<bool> isSubscribed(String channelId) async {
    final subs = getSubscriptions();
    return subs.any((c) => c.id == channelId);
  }

  static Future<void> toggleSubscription(SubscribedChannel channel) async {
    if (_prefs == null) return;
    final subs = getSubscriptions();
    final index = subs.indexWhere((c) => c.id == channel.id);
    if (index >= 0) {
      subs.removeAt(index);
    } else {
      subs.insert(0, channel);
    }
    await _prefs!.setString(
      AppConstants.keySubscriptions,
      jsonEncode(subs.map((e) => e.toJson()).toList()),
    );
  }

  // ---------------------------------------------------------------------------
  // 2. LOCAL IN-APP LIKES (Visual toggle only)
  // ---------------------------------------------------------------------------

  static Set<String> getLikedVideoIds() {
    if (_prefs == null) return {};
    final list = _prefs!.getStringList(AppConstants.keyLikedVideoIds) ?? [];
    return list.toSet();
  }

  static Future<bool> toggleLikeVideo(String videoId) async {
    if (_prefs == null) return false;
    final liked = getLikedVideoIds();
    bool isLikedNow = false;
    if (liked.contains(videoId)) {
      liked.remove(videoId);
      isLikedNow = false;
    } else {
      liked.add(videoId);
      isLikedNow = true;
    }
    await _prefs!.setStringList(AppConstants.keyLikedVideoIds, liked.toList());
    return isLikedNow;
  }

  static bool isVideoLiked(String videoId) {
    return getLikedVideoIds().contains(videoId);
  }

  // NOTE ON PRIVACY:
  // Watch history and search queries are NEVER saved. Zero tracking.
}
