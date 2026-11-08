import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/feed_provider.dart';
import '../utils/theme.dart';
import '../widgets/shimmer_loader.dart';
import '../widgets/video_card.dart';
import 'channel_screen.dart';
import 'player_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<FeedProvider>(
      builder: (context, feedProvider, child) {
        return RefreshIndicator(
          color: YouTubeTheme.ytRed,
          backgroundColor: YouTubeTheme.ytSurface,
          onRefresh: () => feedProvider.loadFeed(),
          child: CustomScrollView(
            slivers: [
              // 1. YouTube Category Filter Chips Bar
              SliverToBoxAdapter(
                child: Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: feedProvider.categories.length,
                    separatorBuilder: (context, index) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final category = feedProvider.categories[index];
                      final isSelected = feedProvider.selectedCategory == category;
                      return ChoiceChip(
                        label: Text(
                          category,
                          style: TextStyle(
                            color: isSelected
                                ? YouTubeTheme.ytPillActiveText
                                : YouTubeTheme.ytTextPrimary,
                            fontSize: 13,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: YouTubeTheme.ytPillActiveBg,
                        backgroundColor: YouTubeTheme.ytPillBg,
                        showCheckmark: false,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        side: BorderSide.none,
                        onSelected: (_) => feedProvider.selectCategory(category),
                      );
                    },
                  ),
                ),
              ),

              // 2. Video Feed Content
              if (feedProvider.isLoading)
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => const VideoCardSkeleton(),
                    childCount: 5,
                  ),
                )
              else if (feedProvider.errorMessage != null && feedProvider.videos.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.wifi_off_rounded, size: 56, color: Colors.grey),
                          const SizedBox(height: 16),
                          const Text(
                            'Could not load videos',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            feedProvider.errorMessage ?? 'Network timeout. Check your connection or API instance.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 12, color: YouTubeTheme.ytTextSecondary),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: YouTubeTheme.ytSurfaceLight,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            icon: const Icon(Icons.refresh, size: 18),
                            label: const Text('Try again'),
                            onPressed: () => feedProvider.loadFeed(),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else if (feedProvider.videos.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Text(
                      'No videos found',
                      style: TextStyle(color: YouTubeTheme.ytTextSecondary),
                    ),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final video = feedProvider.videos[index];
                      return VideoCard(
                        video: video,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PlayerScreen(videoId: video.id, initialVideo: video),
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
                    childCount: feedProvider.videos.length,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
