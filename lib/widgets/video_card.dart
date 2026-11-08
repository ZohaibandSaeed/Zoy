import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../models/video_model.dart';
import '../utils/formatters.dart';
import '../utils/theme.dart';

class VideoCard extends StatelessWidget {
  final VideoModel video;
  final VoidCallback onTap;
  final Function(String channelId, String channelName)? onChannelTap;

  const VideoCard({
    super.key,
    required this.video,
    required this.onTap,
    this.onChannelTap,
  });

  void _showVideoOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: YouTubeTheme.ytSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[600],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.share_outlined, color: Colors.white),
                title: const Text('Share Video', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(ctx);
                  SharePlus.instance.share(
                    ShareParams(
                      text: '${video.title}\n${video.youtubeUrl}',
                      subject: video.title,
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.copy_outlined, color: Colors.white),
                title: const Text('Copy link', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(ctx);
                  Clipboard.setData(ClipboardData(text: video.youtubeUrl));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Link copied to clipboard!'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
              ),
              if (video.uploaderId != null && onChannelTap != null)
                ListTile(
                  leading: const Icon(Icons.account_circle_outlined, color: Colors.white),
                  title: Text('Go to ${video.uploaderName}', style: const TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.pop(ctx);
                    onChannelTap!(video.uploaderId!, video.uploaderName);
                  },
                ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Thumbnail Container (16:9) with Duration Badge
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CachedNetworkImage(
                  imageUrl: video.thumbnailUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: YouTubeTheme.ytSurface,
                    child: const Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: YouTubeTheme.ytRed,
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: YouTubeTheme.ytSurface,
                    child: const Icon(Icons.play_circle_fill, size: 48, color: Colors.grey),
                  ),
                ),

                // Duration badge at bottom-right
                if (video.duration != null && video.duration! > 0)
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        Formatters.formatDuration(video.duration),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // 2. Details Row (Avatar, 2-line Title, Metadata, 3-dots)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 8, 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Creator Avatar
                GestureDetector(
                  onTap: () {
                    if (video.uploaderId != null && onChannelTap != null) {
                      onChannelTap!(video.uploaderId!, video.uploaderName);
                    }
                  },
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: YouTubeTheme.ytSurfaceLight,
                    backgroundImage: (video.uploaderAvatar != null && video.uploaderAvatar!.isNotEmpty)
                        ? CachedNetworkImageProvider(video.uploaderAvatar!)
                        : null,
                    child: (video.uploaderAvatar == null || video.uploaderAvatar!.isEmpty)
                        ? Text(
                            video.uploaderName.isNotEmpty ? video.uploaderName[0].toUpperCase() : 'Y',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 12),

                // Video Title & Metadata
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        video.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: YouTubeTheme.ytTextPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${video.uploaderName} • ${Formatters.formatViews(video.views)} • ${Formatters.formatUploadDate(video.uploadedDate, video.uploadedTimestamp)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: YouTubeTheme.ytTextSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),

                // 3-dots options button
                IconButton(
                  icon: const Icon(Icons.more_vert, size: 20, color: YouTubeTheme.ytTextSecondary),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  onPressed: () => _showVideoOptions(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
