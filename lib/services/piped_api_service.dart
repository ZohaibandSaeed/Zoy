import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/channel_model.dart';
import '../models/comment_model.dart';
import '../models/stream_info.dart';
import '../models/video_model.dart';
import '../utils/constants.dart';
import '../utils/env_config.dart';

class PipedApiService {
  static final PipedApiService _instance = PipedApiService._internal();
  factory PipedApiService() => _instance;
  PipedApiService._internal();

  int _currentInstanceIndex = 0;

  List<String> get _instances => EnvConfig.allPipedInstances;
  List<String> get _invidiousInstances => AppConstants.invidiousInstances;

  String get currentBaseUrl {
    if (_instances.isEmpty) return 'https://pipedapi.ducks.party';
    if (_currentInstanceIndex >= _instances.length) {
      _currentInstanceIndex = 0;
    }
    return _instances[_currentInstanceIndex];
  }

  void _rotateInstance() {
    if (_instances.isEmpty) return;
    _currentInstanceIndex = (_currentInstanceIndex + 1) % _instances.length;
  }

  // Safe HTTP GET with automatic failover across verified nodes
  Future<dynamic> _getWithFailover(String path) async {
    int attempts = 0;
    final maxAttempts = _instances.length;

    while (attempts < maxAttempts) {
      final base = currentBaseUrl;
      final uri = Uri.parse('$base$path');
      try {
        final response = await http
            .get(
              uri,
              headers: {
                'Accept': 'application/json',
                'User-Agent': 'zoy/1.0',
              },
            )
            .timeout(const Duration(seconds: 5));

        if (response.statusCode == 200) {
          final decoded = jsonDecode(utf8.decode(response.bodyBytes));
          return decoded;
        } else {
          _rotateInstance();
        }
      } catch (_) {
        _rotateInstance();
      }
      attempts++;
    }

    throw Exception("zoy Privacy Engine: Node response timed out for $path.");
  }

  // Fallback GET across Invidious instances
  Future<dynamic> _getFromInvidious(String path) async {
    for (final base in _invidiousInstances) {
      try {
        final uri = Uri.parse('$base$path');
        final response = await http
            .get(
              uri,
              headers: {
                'Accept': 'application/json',
                'User-Agent': 'zoy/1.0',
              },
            )
            .timeout(const Duration(seconds: 4));

        if (response.statusCode == 200) {
          return jsonDecode(utf8.decode(response.bodyBytes));
        }
      } catch (_) {}
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // 1. TRENDING VIDEOS (Home Feed)
  // ---------------------------------------------------------------------------
  Future<List<VideoModel>> getTrending({String? region}) async {
    final reg = region ?? EnvConfig.defaultRegion;

    // 1. Try Piped API
    try {
      final data = await _getWithFailover('/trending?region=$reg');
      if (data is List) {
        return data
            .where((item) => item['type'] == 'stream' || item['url'] != null)
            .map((item) => VideoModel.fromJson(item))
            .toList();
      }
    } catch (_) {}

    // 2. Try Invidious API
    try {
      final invData = await _getFromInvidious('/api/v1/trending?region=$reg');
      if (invData is List) {
        final list = invData.map((item) => VideoModel.fromJson(item)).toList();
        if (list.isNotEmpty) return list;
      }
    } catch (_) {}

    // 3. Fallback: Search for region-specific trending content
    if (reg.toUpperCase() == 'PK') {
      try {
        final searchRes = await search('Trending Pakistan', filter: 'videos');
        if (searchRes['videos'] is List && (searchRes['videos'] as List).isNotEmpty) {
          return List<VideoModel>.from(searchRes['videos']);
        }
      } catch (_) {}
    }

    // 4. Fallback: General trending
    try {
      final defaultData = await _getWithFailover('/trending?region=US');
      if (defaultData is List) {
        return defaultData
            .where((item) => item['type'] == 'stream' || item['url'] != null)
            .map((item) => VideoModel.fromJson(item))
            .toList();
      }
    } catch (_) {}

    return [];
  }

  // ---------------------------------------------------------------------------
  // 2. SEARCH (Videos, Channels)
  // ---------------------------------------------------------------------------
  Future<Map<String, dynamic>> search(String query, {String filter = 'all'}) async {
    final encodedQuery = Uri.encodeComponent(query);

    // 1. Try Piped API
    try {
      final data = await _getWithFailover('/search?q=$encodedQuery&filter=$filter');
      List<VideoModel> videos = [];
      List<Map<String, dynamic>> channels = [];

      if (data != null && data['items'] is List) {
        for (var item in data['items']) {
          if (item['type'] == 'stream') {
            videos.add(VideoModel.fromJson(item));
          } else if (item['type'] == 'channel') {
            channels.add({
              'id': (item['url'] ?? '').toString().replaceAll('/channel/', '').replaceAll('/', ''),
              'name': item['name'] ?? 'Channel',
              'avatar': item['thumbnail'] ?? '',
              'subscribers': item['subscribers'] is int ? item['subscribers'] : null,
              'description': item['description'] ?? '',
              'verified': item['verified'] == true,
            });
          }
        }
        if (videos.isNotEmpty || channels.isNotEmpty) {
          return {'videos': videos, 'channels': channels};
        }
      }
    } catch (_) {}

    // 2. Try Invidious API
    try {
      final invData = await _getFromInvidious('/api/v1/search?q=$encodedQuery&type=video');
      if (invData is List) {
        final vids = invData.map((item) => VideoModel.fromJson(item)).toList();
        if (vids.isNotEmpty) {
          return {'videos': vids, 'channels': []};
        }
      }
    } catch (_) {}

    return {'videos': [], 'channels': []};
  }

  // ---------------------------------------------------------------------------
  // 3. STREAM DETAILS (Title, Real Description, Views, Related Videos)
  // ---------------------------------------------------------------------------
  Future<StreamInfo> getStreamInfo(String videoId) async {
    final cleanId = videoId.replaceAll('/watch?v=', '').replaceAll('/', '');

    // 1. Optional: Official YouTube Data API v3 if user provided key (100% reliable)
    final ytKey = EnvConfig.youtubeApiKey;
    if (ytKey != null && ytKey.isNotEmpty) {
      try {
        final uri = Uri.parse(
          'https://www.googleapis.com/youtube/v3/videos?part=snippet,statistics&id=$cleanId&key=$ytKey',
        );
        final res = await http.get(uri).timeout(const Duration(seconds: 4));
        if (res.statusCode == 200) {
          final decoded = jsonDecode(utf8.decode(res.bodyBytes));
          if (decoded['items'] is List && (decoded['items'] as List).isNotEmpty) {
            final item = decoded['items'][0];
            final snip = item['snippet'] ?? {};
            final stats = item['statistics'] ?? {};
            return StreamInfo(
              id: cleanId,
              title: snip['title'] ?? 'YouTube Video',
              description: snip['description'] ?? '',
              uploadDate: snip['publishedAt']?.toString().split('T').first ?? 'Recently',
              views: int.tryParse(stats['viewCount']?.toString() ?? ''),
              likes: int.tryParse(stats['likeCount']?.toString() ?? ''),
              uploader: snip['channelTitle'] ?? 'Creator',
              uploaderId: snip['channelId'],
              uploaderAvatar: snip['thumbnails']?['default']?['url'],
              videoStreams: [],
              audioStreams: [],
              relatedStreams: [],
            );
          }
        }
      } catch (_) {}
    }

    // 2. On Web: Use official YouTube oEmbed + fast metadata lookup
    // (Never call /streams on web to prevent 500 console errors)
    if (kIsWeb) {
      String? title;
      String? uploader;
      String? uploaderUrl;
      String? uploaderAvatar;

      try {
        final oembedUri = Uri.parse(
          'https://www.youtube.com/oembed?url=https://www.youtube.com/watch?v=$cleanId&format=json',
        );
        final response = await http.get(oembedUri).timeout(const Duration(seconds: 4));
        if (response.statusCode == 200) {
          final data = jsonDecode(utf8.decode(response.bodyBytes));
          title = data['title'];
          uploader = data['author_name'];
          uploaderUrl = data['author_url'];
          uploaderAvatar = data['thumbnail_url'];
        }
      } catch (_) {}

      // Try quick search query by ID to get full views and description
      int? views;
      String? desc;
      try {
        final searchRes = await search(cleanId, filter: 'videos');
        final videos = searchRes['videos'] as List<VideoModel>?;
        if (videos != null && videos.isNotEmpty) {
          final match = videos.firstWhere(
            (v) => v.id == cleanId,
            orElse: () => videos.first,
          );
          views = match.views;
          if (match.description != null && match.description!.isNotEmpty) {
            desc = match.description;
          }
          title ??= match.title;
          uploader ??= match.uploaderName;
          uploaderAvatar ??= match.uploaderAvatar;
        }
      } catch (_) {}

      return StreamInfo(
        id: cleanId,
        title: title ?? 'YouTube Video',
        description: desc ?? (uploader != null
            ? 'Uploaded by $uploader. Streamed privately with zero tracking on zoy.'
            : 'Streamed privately with zero tracking on zoy.'),
        uploadDate: 'Recently',
        views: views,
        uploader: uploader ?? 'YouTube Creator',
        uploaderUrl: uploaderUrl,
        uploaderAvatar: uploaderAvatar,
        videoStreams: [],
        audioStreams: [],
        relatedStreams: [],
      );
    }

    // 3. Native Platforms (Android/iOS/Desktop) only: Call /streams
    try {
      final data = await _getWithFailover('/streams/$cleanId');
      return StreamInfo.fromJson(cleanId, data);
    } catch (_) {}

    // 4. Default fallback to YouTube oEmbed API
    try {
      final oembedUri = Uri.parse('https://www.youtube.com/oembed?url=https://www.youtube.com/watch?v=$cleanId&format=json');
      final response = await http.get(oembedUri).timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return StreamInfo(
          id: cleanId,
          title: data['title'] ?? 'YouTube Video',
          description: 'Uploaded by ${data['author_name'] ?? 'Creator'} on YouTube.',
          uploadDate: 'Recently',
          uploader: data['author_name'] ?? 'Creator',
          uploaderUrl: data['author_url'],
          uploaderAvatar: data['thumbnail_url'],
          videoStreams: [],
          audioStreams: [],
          relatedStreams: [],
        );
      }
    } catch (_) {}

    // 5. Default minimal StreamInfo
    return StreamInfo(
      id: cleanId,
      title: 'YouTube Video',
      description: 'Streamed privately via zoy.',
      uploadDate: 'Recently',
      uploader: 'YouTube Creator',
      videoStreams: [],
      audioStreams: [],
      relatedStreams: [],
    );
  }

  // ---------------------------------------------------------------------------
  // 4. COMMENTS (`/comments/{videoId}` or YouTube API)
  // ---------------------------------------------------------------------------
  Future<List<CommentModel>> getComments(String videoId) async {
    final cleanId = videoId.replaceAll('/watch?v=', '').replaceAll('/', '');

    // 1. Official YouTube Data API v3 if user provided key (100% reliable)
    final ytKey = EnvConfig.youtubeApiKey;
    if (ytKey != null && ytKey.isNotEmpty) {
      try {
        final uri = Uri.parse(
          'https://www.googleapis.com/youtube/v3/commentThreads?part=snippet&videoId=$cleanId&maxResults=30&key=$ytKey',
        );
        final response = await http.get(uri).timeout(const Duration(seconds: 4));
        if (response.statusCode == 200) {
          final data = jsonDecode(utf8.decode(response.bodyBytes));
          if (data['items'] is List) {
            List<CommentModel> ytComments = [];
            for (var item in data['items']) {
              final top = item['snippet']?['topLevelComment']?['snippet'];
              if (top != null) {
                ytComments.add(
                  CommentModel(
                    author: top['authorDisplayName'] ?? 'User',
                    authorAvatar: top['authorProfileImageUrl'],
                    text: top['textDisplay'] ?? '',
                    time: top['publishedAt']?.toString().split('T').first ?? '',
                    likes: top['likeCount'] is int ? top['likeCount'] : 0,
                  ),
                );
              }
            }
            if (ytComments.isNotEmpty) return ytComments;
          }
        }
      } catch (_) {}
    }

    // 2. Verified Privacy Engine comments endpoint
    try {
      final data = await _getWithFailover('/comments/$cleanId');
      if (data != null && data['comments'] is List) {
        final list = (data['comments'] as List)
            .map((c) => CommentModel.fromJson(c))
            .toList();
        if (list.isNotEmpty) return list;
      }
    } catch (_) {}

    return [];
  }

  // ---------------------------------------------------------------------------
  // 5. RELATED VIDEOS (Guaranteed Up Next feed)
  // ---------------------------------------------------------------------------
  Future<List<VideoModel>> getRelatedVideos(String videoId, String title) async {
    try {
      // 1. Keyword search from title
      final query = title.split('|').first.split('-').first.split('(').first.trim();
      if (query.isNotEmpty) {
        final res = await search(query, filter: 'videos');
        final list = List<VideoModel>.from(res['videos'] ?? []);
        final filtered = list.where((v) => v.id != videoId).toList();
        if (filtered.isNotEmpty) return filtered;
      }
    } catch (_) {}

    try {
      // 2. Direct search by ID
      final res = await search(videoId, filter: 'videos');
      final list = List<VideoModel>.from(res['videos'] ?? []);
      final filtered = list.where((v) => v.id != videoId).toList();
      if (filtered.isNotEmpty) return filtered;
    } catch (_) {}

    try {
      // 3. Fallback: Trending Pakistan feed so Up Next is never empty
      final trending = await getTrending();
      final filtered = trending.where((v) => v.id != videoId).toList();
      if (filtered.isNotEmpty) return filtered;
    } catch (_) {}

    return [];
  }

  // ---------------------------------------------------------------------------
  // 6. CHANNEL DETAILS (`/channel/{channelId}`)
  // ---------------------------------------------------------------------------
  Future<ChannelDetails> getChannelDetails(String channelId) async {
    final cleanId = channelId.replaceAll('/channel/', '').replaceAll('/', '');

    // 1. Try Piped
    try {
      final data = await _getWithFailover('/channel/$cleanId');
      return ChannelDetails.fromJson(cleanId, data);
    } catch (_) {}

    // 2. Try Invidious
    try {
      final invData = await _getFromInvidious('/api/v1/channels/$cleanId');
      if (invData != null && invData is Map<String, dynamic>) {
        List<VideoModel> videos = [];
        if (invData['latestVideos'] is List) {
          videos = (invData['latestVideos'] as List)
              .map((v) => VideoModel.fromJson(v))
              .toList();
        }
        return ChannelDetails(
          id: cleanId,
          name: invData['author'] ?? 'Channel',
          avatarUrl: (invData['authorThumbnails'] is List && (invData['authorThumbnails'] as List).isNotEmpty)
              ? invData['authorThumbnails'][0]['url']
              : '',
          bannerUrl: (invData['authorBanners'] is List && (invData['authorBanners'] as List).isNotEmpty)
              ? invData['authorBanners'][0]['url']
              : null,
          subscriberCount: int.tryParse(invData['subCount']?.toString() ?? ''),
          description: invData['description'],
          verified: invData['authorVerified'] == true,
          latestVideos: videos,
        );
      }
    } catch (_) {}

    return ChannelDetails(
      id: cleanId,
      name: 'YouTube Channel',
      avatarUrl: '',
      latestVideos: [],
    );
  }
}
