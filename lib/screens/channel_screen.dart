import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/channel_model.dart';
import '../providers/subscription_provider.dart';
import '../services/piped_api_service.dart';
import '../utils/formatters.dart';
import '../utils/theme.dart';
import '../widgets/video_card.dart';
import 'player_screen.dart';

class ChannelScreen extends StatefulWidget {
  final String channelId;
  final String channelName;

  const ChannelScreen({
    super.key,
    required this.channelId,
    required this.channelName,
  });

  @override
  State<ChannelScreen> createState() => _ChannelScreenState();
}

class _ChannelScreenState extends State<ChannelScreen> with SingleTickerProviderStateMixin {
  final PipedApiService _api = PipedApiService();
  late TabController _tabController;

  ChannelDetails? _channelDetails;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadChannel();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadChannel() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final details = await _api.getChannelDetails(widget.channelId);
      if (!mounted) return;
      setState(() {
        _channelDetails = details;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final subProvider = context.watch<SubscriptionProvider>();
    final isSubbed = subProvider.isSubscribed(widget.channelId);

    final avatarUrl = _channelDetails?.avatarUrl;
    final bannerUrl = _channelDetails?.bannerUrl;
    final name = _channelDetails?.name ?? widget.channelName;
    final subs = _channelDetails?.subscriberCount;
    final videos = _channelDetails?.latestVideos ?? [];

    return Scaffold(
      backgroundColor: YouTubeTheme.ytBlack,
      appBar: AppBar(
        title: Text(
          name,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: YouTubeTheme.ytRed),
            )
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: Colors.grey),
                        const SizedBox(height: 12),
                        const Text(
                          'Could not load channel',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: YouTubeTheme.ytTextSecondary, fontSize: 12),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadChannel,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: YouTubeTheme.ytSurfaceLight,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : NestedScrollView(
                  headerSliverBuilder: (context, innerBoxIsScrolled) {
                    return [
                      SliverToBoxAdapter(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 1. Channel Banner
                            if (bannerUrl != null && bannerUrl.isNotEmpty)
                              AspectRatio(
                                aspectRatio: 16 / 4.5,
                                child: CachedNetworkImage(
                                  imageUrl: bannerUrl,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Container(color: YouTubeTheme.ytSurface),
                                  errorWidget: (context, url, error) => const SizedBox.shrink(),
                                ),
                              ),

                            // 2. Channel Avatar + Info Header
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 36,
                                        backgroundColor: YouTubeTheme.ytSurfaceLight,
                                        backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty)
                                            ? CachedNetworkImageProvider(avatarUrl)
                                            : null,
                                        child: (avatarUrl == null || avatarUrl.isEmpty)
                                            ? Text(
                                                name.isNotEmpty ? name[0].toUpperCase() : 'C',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 24,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              )
                                            : null,
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              name,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            if (subs != null) ...[
                                              const SizedBox(height: 4),
                                              Text(
                                                Formatters.formatSubscribers(subs),
                                                style: const TextStyle(
                                                  color: YouTubeTheme.ytTextSecondary,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),

                                  // Subscribe Button (Full Width YouTube Style)
                                  SizedBox(
                                    width: double.infinity,
                                    height: 38,
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: isSubbed ? YouTubeTheme.ytSurfaceLight : Colors.white,
                                        foregroundColor: isSubbed ? Colors.white : Colors.black,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                      ),
                                      onPressed: () {
                                        subProvider.toggleSubscription(
                                          channelId: widget.channelId,
                                          channelName: name,
                                          avatarUrl: avatarUrl ?? '',
                                          subscriberCount: subs?.toString(),
                                        );
                                      },
                                      child: Text(
                                        isSubbed ? 'Subscribed' : 'Subscribe',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // TabBar (Latest Videos / About)
                            TabBar(
                              controller: _tabController,
                              indicatorColor: Colors.white,
                              labelColor: Colors.white,
                              unselectedLabelColor: YouTubeTheme.ytTextSecondary,
                              indicatorWeight: 2,
                              tabs: const [
                                Tab(text: 'Latest Videos'),
                                Tab(text: 'About'),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ];
                  },
                  body: TabBarView(
                    controller: _tabController,
                    children: [
                      // 1. Latest Videos Tab
                      videos.isEmpty
                          ? const Center(
                              child: Text(
                                'No videos found on this channel',
                                style: TextStyle(color: YouTubeTheme.ytTextSecondary),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              itemCount: videos.length,
                              itemBuilder: (context, index) {
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
                                );
                              },
                            ),

                      // 2. About Tab
                      SingleChildScrollView(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Description',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _channelDetails?.description != null && _channelDetails!.description!.isNotEmpty
                                  ? _channelDetails!.description!
                                  : 'No description provided.',
                              style: const TextStyle(
                                color: YouTubeTheme.ytTextPrimary,
                                fontSize: 14,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
