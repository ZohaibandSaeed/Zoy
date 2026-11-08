import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/search_provider.dart';
import '../providers/subscription_provider.dart';
import '../utils/formatters.dart';
import '../utils/theme.dart';
import '../widgets/shimmer_loader.dart';
import '../widgets/video_card.dart';
import 'channel_screen.dart';
import 'player_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _performSearch() {
    final query = _searchController.text.trim();
    if (query.isNotEmpty) {
      _focusNode.unfocus();
      context.read<SearchProvider>().search(query);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: YouTubeTheme.ytBlack,
      appBar: AppBar(
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Container(
          height: 40,
          margin: const EdgeInsets.only(right: 12),
          decoration: BoxDecoration(
            color: YouTubeTheme.ytSurface,
            borderRadius: BorderRadius.circular(20),
          ),
          child: TextField(
            controller: _searchController,
            focusNode: _focusNode,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _performSearch(),
            decoration: InputDecoration(
              hintText: 'Search zoy',
              hintStyle: const TextStyle(color: YouTubeTheme.ytTextSecondary, fontSize: 14),
              prefixIcon: const Icon(Icons.search, color: YouTubeTheme.ytTextSecondary, size: 20),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: Colors.white70, size: 18),
                      onPressed: () {
                        setState(() {
                          _searchController.clear();
                        });
                        context.read<SearchProvider>().clear();
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
            onChanged: (val) {
              setState(() {});
            },
          ),
        ),
      ),
      body: Consumer<SearchProvider>(
        builder: (context, searchProvider, _) {
          return Column(
            children: [
              // Filter chips bar
              Container(
                height: 44,
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                child: Row(
                  children: [
                    _filterChip('all', 'All', searchProvider),
                    const SizedBox(width: 8),
                    _filterChip('videos', 'Videos', searchProvider),
                    const SizedBox(width: 8),
                    _filterChip('channels', 'Channels', searchProvider),
                  ],
                ),
              ),

              // Results or Shimmer
              Expanded(
                child: searchProvider.isLoading
                    ? ListView.builder(
                        itemCount: 5,
                        itemBuilder: (context, index) => const VideoCardSkeleton(),
                      )
                    : searchProvider.errorMessage != null
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Text(
                                searchProvider.errorMessage!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: YouTubeTheme.ytTextSecondary),
                              ),
                            ),
                          )
                        : (searchProvider.videos.isEmpty && searchProvider.channels.isEmpty)
                            ? const Center(
                                child: Text(
                                  'Search for videos, creators, or topics',
                                  style: TextStyle(color: YouTubeTheme.ytTextSecondary),
                                ),
                              )
                            : ListView(
                                children: [
                                  // Channels row if any
                                  if (searchProvider.channels.isNotEmpty) ...[
                                    ...searchProvider.channels.map((ch) => _buildChannelItem(context, ch)),
                                    const Divider(color: YouTubeTheme.ytBorder, height: 16),
                                  ],

                                  // Videos list
                                  ...searchProvider.videos.map(
                                    (v) => VideoCard(
                                      video: v,
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => PlayerScreen(videoId: v.id, initialVideo: v),
                                          ),
                                        );
                                      },
                                      onChannelTap: (chId, chName) {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => ChannelScreen(channelId: chId, channelName: chName),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _filterChip(String filterKey, String label, SearchProvider provider) {
    final isSelected = provider.activeFilter == filterKey;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? YouTubeTheme.ytPillActiveText : YouTubeTheme.ytTextPrimary,
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      selectedColor: YouTubeTheme.ytPillActiveBg,
      backgroundColor: YouTubeTheme.ytPillBg,
      showCheckmark: false,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      side: BorderSide.none,
      onSelected: (_) {
        provider.setFilter(filterKey, _searchController.text.trim());
      },
    );
  }

  Widget _buildChannelItem(BuildContext context, Map<String, dynamic> ch) {
    final id = ch['id'] as String;
    final name = ch['name'] as String;
    final avatar = ch['avatar'] as String;
    final subs = ch['subscribers'] as int?;

    final subProvider = context.watch<SubscriptionProvider>();
    final isSubbed = subProvider.isSubscribed(id);

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChannelScreen(channelId: id, channelName: name),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: YouTubeTheme.ytSurfaceLight,
              backgroundImage: avatar.isNotEmpty ? CachedNetworkImageProvider(avatar) : null,
              child: avatar.isEmpty ? Text(name.isNotEmpty ? name[0].toUpperCase() : 'C') : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  if (subs != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      Formatters.formatSubscribers(subs),
                      style: const TextStyle(color: YouTubeTheme.ytTextSecondary, fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isSubbed ? YouTubeTheme.ytSurfaceLight : Colors.white,
                foregroundColor: isSubbed ? Colors.white : Colors.black,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              ),
              onPressed: () {
                subProvider.toggleSubscription(
                  channelId: id,
                  channelName: name,
                  avatarUrl: avatar,
                  subscriberCount: subs?.toString(),
                );
              },
              child: Text(
                isSubbed ? 'Subscribed' : 'Subscribe',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
