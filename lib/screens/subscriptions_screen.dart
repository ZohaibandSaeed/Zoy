import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/subscription_provider.dart';
import '../utils/theme.dart';
import '../widgets/shimmer_loader.dart';
import '../widgets/video_card.dart';
import 'channel_screen.dart';
import 'player_screen.dart';

class SubscriptionsScreen extends StatelessWidget {
  final VoidCallback onExploreTap;

  const SubscriptionsScreen({
    super.key,
    required this.onExploreTap,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<SubscriptionProvider>(
      builder: (context, subProvider, _) {
        final subs = subProvider.subscriptions;
        final videos = subProvider.subscriptionVideos;

        if (subs.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.subscriptions_outlined, size: 72, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    "Don't miss a video",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Subscribe to your favorite channels on zoy. Their latest videos will appear here privately without any Google login.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: YouTubeTheme.ytTextSecondary,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    onPressed: onExploreTap,
                    child: const Text(
                      'Explore videos',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return RefreshIndicator(
          color: YouTubeTheme.ytRed,
          backgroundColor: YouTubeTheme.ytSurface,
          onRefresh: () => subProvider.fetchSubscriptionFeed(),
          child: CustomScrollView(
            slivers: [
              // 1. Horizontal Subscribed Channels Stories Bar
              SliverToBoxAdapter(
                child: Container(
                  height: 94,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: subs.length,
                    separatorBuilder: (context, index) => const SizedBox(width: 16),
                    itemBuilder: (context, index) {
                      final ch = subs[index];
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChannelScreen(channelId: ch.id, channelName: ch.name),
                            ),
                          );
                        },
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 26,
                              backgroundColor: YouTubeTheme.ytSurfaceLight,
                              backgroundImage: ch.avatarUrl.isNotEmpty
                                  ? CachedNetworkImageProvider(ch.avatarUrl)
                                  : null,
                              child: ch.avatarUrl.isEmpty
                                  ? Text(ch.name.isNotEmpty ? ch.name[0].toUpperCase() : 'C')
                                  : null,
                            ),
                            const SizedBox(height: 6),
                            SizedBox(
                              width: 60,
                              child: Text(
                                ch.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: YouTubeTheme.ytTextPrimary,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),

              const SliverToBoxAdapter(
                child: Divider(color: YouTubeTheme.ytBorder, height: 1),
              ),

              // 2. Aggregated Latest Videos from Subscriptions
              if (subProvider.isLoadingFeed)
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => const VideoCardSkeleton(),
                    childCount: 4,
                  ),
                )
              else if (videos.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Text(
                        'No recent videos from your subscriptions right now.',
                        style: TextStyle(color: YouTubeTheme.ytTextSecondary),
                      ),
                    ),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final v = videos[index];
                      return VideoCard(
                        video: v,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PlayerScreen(videoId: v.id, initialVideo: v),
                            ),
                          );
                        },
                        onChannelTap: (channelId, channelName) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChannelScreen(channelId: channelId, channelName: channelName),
                            ),
                          );
                        },
                      );
                    },
                    childCount: videos.length,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
