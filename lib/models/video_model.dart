class VideoModel {
  final String id;
  final String title;
  final String thumbnailUrl;
  final String uploaderName;
  final String? uploaderId;
  final String? uploaderUrl;
  final String? uploaderAvatar;
  final String? uploadedDate;
  final int? uploadedTimestamp;
  final int? duration; // in seconds
  final int? views;
  final bool isShort;
  final String? description;

  VideoModel({
    required this.id,
    required this.title,
    required this.thumbnailUrl,
    required this.uploaderName,
    this.uploaderId,
    this.uploaderUrl,
    this.uploaderAvatar,
    this.uploadedDate,
    this.uploadedTimestamp,
    this.duration,
    this.views,
    this.isShort = false,
    this.description,
  });

  factory VideoModel.fromJson(Map<String, dynamic> json) {
    // Extract video ID safely
    String videoId = '';
    if (json['url'] != null) {
      final url = json['url'].toString();
      if (url.contains('/watch?v=')) {
        videoId = url.split('/watch?v=').last;
      } else if (url.startsWith('/watch?')) {
        videoId = Uri.tryParse(url)?.queryParameters['v'] ?? '';
      } else {
        videoId = url.replaceAll('/watch?v=', '').replaceAll('/', '');
      }
    }
    if (videoId.isEmpty && json['id'] != null) {
      videoId = json['id'].toString();
    }
    if (videoId.isEmpty && json['videoId'] != null) {
      videoId = json['videoId'].toString();
    }

    // Extract uploader ID safely
    String? uploaderId;
    if (json['uploaderUrl'] != null) {
      final uUrl = json['uploaderUrl'].toString();
      uploaderId = uUrl.replaceAll('/channel/', '').replaceAll('/', '');
    } else if (json['authorId'] != null) {
      uploaderId = json['authorId'].toString();
    }

    // Extract thumbnail safely
    String thumb = json['thumbnail'] ?? json['thumbnailUrl'] ?? '';
    if (thumb.isEmpty && json['videoThumbnails'] is List && (json['videoThumbnails'] as List).isNotEmpty) {
      thumb = json['videoThumbnails'][0]['url'] ?? '';
    }

    // Duration safely
    int? dur = json['duration'] is int
        ? json['duration']
        : (json['lengthSeconds'] is int ? json['lengthSeconds'] : null);

    // Views safely
    int? views = json['views'] is int
        ? json['views']
        : (json['viewCount'] is int ? json['viewCount'] : int.tryParse(json['views']?.toString() ?? ''));

    // Description safely
    String? desc = json['shortDescription'] ?? json['description'];

    return VideoModel(
      id: videoId,
      title: json['title'] ?? 'Untitled Video',
      thumbnailUrl: thumb,
      uploaderName: json['uploaderName'] ?? json['uploader'] ?? json['author'] ?? 'Creator',
      uploaderId: uploaderId,
      uploaderUrl: json['uploaderUrl'] ?? (uploaderId != null ? '/channel/$uploaderId' : null),
      uploaderAvatar: json['uploaderAvatar'],
      uploadedDate: json['uploadedDate'] ?? json['uploadDate'] ?? json['publishedText'],
      uploadedTimestamp: json['uploaded'] is int ? json['uploaded'] : null,
      duration: dur,
      views: views,
      isShort: json['isShort'] == true,
      description: desc,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'thumbnail': thumbnailUrl,
      'uploaderName': uploaderName,
      'uploaderId': uploaderId,
      'uploaderUrl': uploaderUrl,
      'uploaderAvatar': uploaderAvatar,
      'uploadedDate': uploadedDate,
      'uploaded': uploadedTimestamp,
      'duration': duration,
      'views': views,
      'isShort': isShort,
      'description': description,
    };
  }

  // Generate standard YouTube link for sharing
  String get youtubeUrl => 'https://youtu.be/$id';
}

