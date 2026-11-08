import 'video_model.dart';

class VideoStreamTrack {
  final String url;
  final String quality;
  final String format;
  final int? bitrate;
  final bool videoOnly;
  final int? width;
  final int? height;

  VideoStreamTrack({
    required this.url,
    required this.quality,
    required this.format,
    this.bitrate,
    required this.videoOnly,
    this.width,
    this.height,
  });

  factory VideoStreamTrack.fromJson(Map<String, dynamic> json) {
    return VideoStreamTrack(
      url: json['url'] ?? '',
      quality: json['quality'] ?? 'unknown',
      format: json['format'] ?? 'mp4',
      bitrate: json['bitrate'] is int ? json['bitrate'] : null,
      videoOnly: json['videoOnly'] == true,
      width: json['width'] is int ? json['width'] : null,
      height: json['height'] is int ? json['height'] : null,
    );
  }
}

class AudioStreamTrack {
  final String url;
  final String format;
  final String quality;
  final int? bitrate;

  AudioStreamTrack({
    required this.url,
    required this.format,
    required this.quality,
    this.bitrate,
  });

  factory AudioStreamTrack.fromJson(Map<String, dynamic> json) {
    return AudioStreamTrack(
      url: json['url'] ?? '',
      format: json['format'] ?? 'm4a',
      quality: json['quality'] ?? 'unknown',
      bitrate: json['bitrate'] is int ? json['bitrate'] : null,
    );
  }
}

class StreamInfo {
  final String id;
  final String title;
  final String description;
  final String uploadDate;
  final int? views;
  final int? likes;
  final int? dislikes;
  final String uploader;
  final String? uploaderId;
  final String? uploaderUrl;
  final String? uploaderAvatar;
  final int? uploaderSubscriberCount;
  final bool uploaderVerified;
  final String? hlsUrl;
  final List<VideoStreamTrack> videoStreams;
  final List<AudioStreamTrack> audioStreams;
  final List<VideoModel> relatedStreams;

  StreamInfo({
    required this.id,
    required this.title,
    required this.description,
    required this.uploadDate,
    this.views,
    this.likes,
    this.dislikes,
    required this.uploader,
    this.uploaderId,
    this.uploaderUrl,
    this.uploaderAvatar,
    this.uploaderSubscriberCount,
    this.uploaderVerified = false,
    this.hlsUrl,
    required this.videoStreams,
    required this.audioStreams,
    required this.relatedStreams,
  });

  factory StreamInfo.fromJson(String videoId, Map<String, dynamic> json) {
    // Parse video streams
    List<VideoStreamTrack> vStreams = [];
    if (json['videoStreams'] != null && json['videoStreams'] is List) {
      vStreams = (json['videoStreams'] as List)
          .map((item) => VideoStreamTrack.fromJson(item))
          .toList();
    }

    // Parse audio streams
    List<AudioStreamTrack> aStreams = [];
    if (json['audioStreams'] != null && json['audioStreams'] is List) {
      aStreams = (json['audioStreams'] as List)
          .map((item) => AudioStreamTrack.fromJson(item))
          .toList();
    }

    // Parse related streams
    List<VideoModel> related = [];
    if (json['relatedStreams'] != null && json['relatedStreams'] is List) {
      related = (json['relatedStreams'] as List)
          .where((item) => item['type'] == 'stream' || item['url'] != null)
          .map((item) => VideoModel.fromJson(item))
          .toList();
    }

    // Uploader ID extract
    String? uploaderId;
    if (json['uploaderUrl'] != null) {
      uploaderId = json['uploaderUrl'].toString().replaceAll('/channel/', '').replaceAll('/', '');
    }

    return StreamInfo(
      id: videoId,
      title: json['title'] ?? 'Untitled Video',
      description: json['description'] ?? '',
      uploadDate: json['uploadDate'] ?? '',
      views: json['views'] is int ? json['views'] : int.tryParse(json['views']?.toString() ?? ''),
      likes: json['likes'] is int ? json['likes'] : int.tryParse(json['likes']?.toString() ?? ''),
      dislikes: json['dislikes'] is int ? json['dislikes'] : int.tryParse(json['dislikes']?.toString() ?? ''),
      uploader: json['uploader'] ?? 'Creator',
      uploaderId: uploaderId,
      uploaderUrl: json['uploaderUrl'],
      uploaderAvatar: json['uploaderAvatar'],
      uploaderSubscriberCount: json['uploaderSubscriberCount'] is int
          ? json['uploaderSubscriberCount']
          : int.tryParse(json['uploaderSubscriberCount']?.toString() ?? ''),
      uploaderVerified: json['uploaderVerified'] == true,
      hlsUrl: json['hlsUrl'],
      videoStreams: vStreams,
      audioStreams: aStreams,
      relatedStreams: related,
    );
  }

  factory StreamInfo.fromInvidiousJson(String videoId, Map<String, dynamic> json) {
    // Parse recommended/related videos
    List<VideoModel> related = [];
    if (json['recommendedVideos'] != null && json['recommendedVideos'] is List) {
      related = (json['recommendedVideos'] as List)
          .map((item) => VideoModel.fromJson(item))
          .toList();
    }

    // Avatar from authorThumbnails
    String? authorAvatar;
    if (json['authorThumbnails'] is List && (json['authorThumbnails'] as List).isNotEmpty) {
      authorAvatar = json['authorThumbnails'][0]['url'];
    }

    return StreamInfo(
      id: videoId,
      title: json['title'] ?? 'Untitled Video',
      description: json['description'] ?? '',
      uploadDate: json['publishedText'] ?? '',
      views: json['viewCount'] is int
          ? json['viewCount']
          : int.tryParse(json['viewCount']?.toString() ?? ''),
      likes: json['likeCount'] is int
          ? json['likeCount']
          : int.tryParse(json['likeCount']?.toString() ?? ''),
      uploader: json['author'] ?? 'Creator',
      uploaderId: json['authorId'],
      uploaderUrl: json['authorUrl'],
      uploaderAvatar: authorAvatar,
      uploaderSubscriberCount: int.tryParse(json['subCountText']?.toString() ?? ''),
      videoStreams: [],
      audioStreams: [],
      relatedStreams: related,
    );
  }

  // Best playable URL:
  // Preference 1: Non-video-only MP4 (has embedded audio, perfect for Flutter video_player)
  // Preference 2: HLS url
  // Preference 3: Highest quality progressive stream
  String? get bestPlayableUrl {
    // 1. Check for normal video+audio stream (videoOnly == false)
    final muxedStreams = videoStreams.where((s) => !s.videoOnly && s.format.toLowerCase() == 'mp4').toList();
    if (muxedStreams.isNotEmpty) {
      // Prefer 720p or 480p or 360p for fast buffer & audio compatibility
      final preferred = muxedStreams.firstWhere(
        (s) => s.quality.contains('720p'),
        orElse: () => muxedStreams.firstWhere(
          (s) => s.quality.contains('480p') || s.quality.contains('360p'),
          orElse: () => muxedStreams.first,
        ),
      );
      return preferred.url;
    }

    // 2. Check for HLS stream
    if (hlsUrl != null && hlsUrl!.isNotEmpty) {
      return hlsUrl;
    }

    // 3. Fallback to any non-video-only stream
    final anyMuxed = videoStreams.where((s) => !s.videoOnly).toList();
    if (anyMuxed.isNotEmpty) {
      return anyMuxed.first.url;
    }

    // 4. Fallback to first video stream
    if (videoStreams.isNotEmpty) {
      return videoStreams.first.url;
    }

    return null;
  }
}

