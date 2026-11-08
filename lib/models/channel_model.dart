import 'video_model.dart';

class SubscribedChannel {
  final String id;
  final String name;
  final String avatarUrl;
  final String? subscriberCount;
  final DateTime subscribedAt;

  SubscribedChannel({
    required this.id,
    required this.name,
    required this.avatarUrl,
    this.subscriberCount,
    required this.subscribedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'avatarUrl': avatarUrl,
      'subscriberCount': subscriberCount,
      'subscribedAt': subscribedAt.toIso8601String(),
    };
  }

  factory SubscribedChannel.fromJson(Map<String, dynamic> json) {
    return SubscribedChannel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      avatarUrl: json['avatarUrl'] ?? '',
      subscriberCount: json['subscriberCount'],
      subscribedAt: json['subscribedAt'] != null
          ? DateTime.tryParse(json['subscribedAt']) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

class ChannelDetails {
  final String id;
  final String name;
  final String? avatarUrl;
  final String? bannerUrl;
  final String? description;
  final int? subscriberCount;
  final bool verified;
  final List<VideoModel> latestVideos;
  final String? nextPageToken;

  ChannelDetails({
    required this.id,
    required this.name,
    this.avatarUrl,
    this.bannerUrl,
    this.description,
    this.subscriberCount,
    this.verified = false,
    required this.latestVideos,
    this.nextPageToken,
  });

  factory ChannelDetails.fromJson(String channelId, Map<String, dynamic> json) {
    List<VideoModel> videos = [];
    if (json['relatedStreams'] != null && json['relatedStreams'] is List) {
      videos = (json['relatedStreams'] as List)
          .where((v) => v['type'] == 'stream' || v['url'] != null)
          .map((v) => VideoModel.fromJson(v))
          .toList();
    }

    return ChannelDetails(
      id: channelId,
      name: json['name'] ?? 'Channel',
      avatarUrl: json['avatarUrl'] ?? json['avatar'],
      bannerUrl: json['bannerUrl'] ?? json['banner'],
      description: json['description'],
      subscriberCount: json['subscriberCount'] is int
          ? json['subscriberCount']
          : int.tryParse(json['subscriberCount']?.toString() ?? ''),
      verified: json['verified'] == true,
      latestVideos: videos,
      nextPageToken: json['nextpage'],
    );
  }
}

