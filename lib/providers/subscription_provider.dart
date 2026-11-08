import 'package:flutter/material.dart';
import '../models/channel_model.dart';
import '../models/video_model.dart';
import '../services/piped_api_service.dart';
import '../services/storage_service.dart';

class SubscriptionProvider with ChangeNotifier {
  final PipedApiService _api = PipedApiService();
  List<SubscribedChannel> _subscriptions = [];
  List<VideoModel> _subscriptionVideos = [];
  bool _isLoadingFeed = false;
  String? _errorMessage;

  List<SubscribedChannel> get subscriptions => _subscriptions;
  List<VideoModel> get subscriptionVideos => _subscriptionVideos;
  bool get isLoadingFeed => _isLoadingFeed;
  String? get errorMessage => _errorMessage;

  SubscriptionProvider() {
    loadSubscriptions();
  }

  void loadSubscriptions() {
    _subscriptions = StorageService.getSubscriptions();
    notifyListeners();
    if (_subscriptions.isNotEmpty) {
      fetchSubscriptionFeed();
    }
  }

  bool isSubscribed(String? channelId) {
    if (channelId == null || channelId.isEmpty) return false;
    return _subscriptions.any((c) => c.id == channelId);
  }

  Future<void> toggleSubscription({
    required String channelId,
    required String channelName,
    required String avatarUrl,
    String? subscriberCount,
  }) async {
    final channel = SubscribedChannel(
      id: channelId,
      name: channelName,
      avatarUrl: avatarUrl,
      subscriberCount: subscriberCount,
      subscribedAt: DateTime.now(),
    );

    await StorageService.toggleSubscription(channel);
    _subscriptions = StorageService.getSubscriptions();
    notifyListeners();

    // Refresh feed
    if (_subscriptions.isNotEmpty) {
      fetchSubscriptionFeed();
    } else {
      _subscriptionVideos = [];
      notifyListeners();
    }
  }

  Future<void> fetchSubscriptionFeed() async {
    if (_subscriptions.isEmpty) {
      _subscriptionVideos = [];
      notifyListeners();
      return;
    }

    _isLoadingFeed = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Fetch latest videos from up to 5 recently subscribed creators
      List<VideoModel> aggregated = [];
      final channelsToFetch = _subscriptions.take(5).toList();

      for (var ch in channelsToFetch) {
        try {
          final details = await _api.getChannelDetails(ch.id);
          aggregated.addAll(details.latestVideos.take(4));
        } catch (_) {
          // ignore individual channel fetch errors
        }
      }

      // Shuffle or sort if timestamps exist
      _subscriptionVideos = aggregated;
      _isLoadingFeed = false;
      notifyListeners();
    } catch (e) {
      _isLoadingFeed = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }
}

