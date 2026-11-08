class CommentModel {
  final String author;
  final String? authorAvatar;
  final String text;
  final String time;
  final int likes;
  final bool isHearted;

  CommentModel({
    required this.author,
    this.authorAvatar,
    required this.text,
    required this.time,
    this.likes = 0,
    this.isHearted = false,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    // Clean html break tags from comment text
    String rawText = json['commentText'] ?? json['content'] ?? json['text'] ?? '';
    String cleanText = rawText
        .replaceAll('<br>', '\n')
        .replaceAll('<br/>', '\n')
        .replaceAll('<b>', '')
        .replaceAll('</b>', '')
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>');

    // Avatar extraction (Piped thumbnail or Invidious authorThumbnails)
    String? avatar = json['thumbnail'];
    if (avatar == null &&
        json['authorThumbnails'] is List &&
        (json['authorThumbnails'] as List).isNotEmpty) {
      avatar = json['authorThumbnails'][0]['url'];
    }

    // Time extraction
    String timeStr = json['commentedTime'] ?? json['publishedText'] ?? '';

    return CommentModel(
      author: json['author'] ?? 'User',
      authorAvatar: avatar,
      text: cleanText,
      time: timeStr,
      likes: json['likeCount'] is int
          ? json['likeCount']
          : int.tryParse(json['likeCount']?.toString() ?? '0') ?? 0,
      isHearted: json['hearted'] == true || json['isHearted'] == true,
    );
  }
}
