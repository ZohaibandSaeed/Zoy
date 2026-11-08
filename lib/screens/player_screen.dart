import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import '../models/comment_model.dart';
import '../models/stream_info.dart';
import '../models/video_model.dart';
import '../providers/feed_provider.dart';
import '../providers/subscription_provider.dart';
import '../services/piped_api_service.dart';
import '../services/storage_service.dart';
import '../utils/formatters.dart';
import '../utils/theme.dart';
import '../widgets/pill_button.dart';
import '../widgets/video_card.dart';
import '../widgets/web_player.dart';
import 'channel_screen.dart';

class PlayerScreen extends StatefulWidget {
  final String videoId;
  final VideoModel? initialVideo;

  const PlayerScreen({
    super.key,
    required this.videoId,
    this.initialVideo,
  });

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  final PipedApiService _api = PipedApiService();

  late String _currentVideoId;
  YoutubePlayerController? _ytController;
  StreamSubscription<YoutubeVideoState>? _ytVideoStateSub;
  StreamSubscription<YoutubePlayerValue>? _ytPlayerStateSub;
  double _mobilePosition = 0.0;
  bool _isMobileMuted = false;

  StreamInfo? _streamInfo;
  bool _isLoadingInfo = true;
  String? _errorMessage;
  bool _showControls = true;
  Timer? _hideControlsTimer;
  bool _isDescriptionExpanded = false;
  bool _isLiked = false;
  double _playbackSpeed = 1.0;
  String _selectedQuality = 'Auto (1080p)';
  bool _isLooping = false;
  bool _isCaptionsEnabled = true;
  double _dragValue = -1.0; // for smooth slider dragging

  // Comments & Related Videos state
  List<CommentModel> _comments = [];
  bool _isLoadingComments = true;
  List<VideoModel> _relatedVideos = [];
  bool _isLoadingRelated = true;

  double get _streamDuration {
    if (!kIsWeb && _ytController != null) {
      final d = _ytController!.metadata.duration.inSeconds.toDouble();
      if (d > 0) return d;
    }
    final dur = (widget.initialVideo?.duration ?? 0) > 0
        ? widget.initialVideo!.duration!.toDouble()
        : 120.0;
    return dur;
  }

  @override
  void initState() {
    super.initState();
    _currentVideoId = widget.videoId;
    _isLiked = StorageService.isVideoLiked(_currentVideoId);
    _startHideControlsTimer();
    _loadStreamData(_currentVideoId);
  }

  @override
  void dispose() {
    _hideControlsTimer?.cancel();
    _ytVideoStateSub?.cancel();
    _ytPlayerStateSub?.cancel();
    _ytController?.close();
    super.dispose();
  }

  void _startHideControlsTimer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 4), () {
      if (mounted && _showControls && _dragValue < 0) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  void _toggleControlsVisibility() {
    setState(() {
      _showControls = !_showControls;
    });
    if (_showControls) {
      _startHideControlsTimer();
    }
  }

  Future<void> _loadStreamData(String videoId) async {
    setState(() {
      _isLoadingInfo = widget.initialVideo == null;
      _errorMessage = null;
      _currentVideoId = videoId;
      _isLiked = StorageService.isVideoLiked(videoId);
      _comments = [];
      _relatedVideos = [];
      _isLoadingComments = true;
      _isLoadingRelated = true;
      _mobilePosition = 0.0;
      _dragValue = -1.0;
      if (widget.initialVideo != null) {
        _streamInfo = StreamInfo(
          id: widget.initialVideo!.id,
          title: widget.initialVideo!.title,
          description: widget.initialVideo!.description ??
              'Uploaded by ${widget.initialVideo!.uploaderName}. Streamed privately on zoy.',
          uploadDate: widget.initialVideo!.uploadedDate ?? 'Recently',
          views: widget.initialVideo!.views,
          uploader: widget.initialVideo!.uploaderName,
          uploaderId: widget.initialVideo!.uploaderId,
          uploaderAvatar: widget.initialVideo!.uploaderAvatar,
          videoStreams: [],
          audioStreams: [],
          relatedStreams: [],
        );
      }
      if (kIsWeb) {
        final initDur = (widget.initialVideo?.duration ?? 0) > 0
            ? widget.initialVideo!.duration!.toDouble()
            : 0.0;
        getPlatformPlayerNotifier().value = getPlatformPlayerNotifier().value.copyWith(
          currentTime: 0.0,
          duration: initDur > 0 ? initDur : null,
          isPlaying: true,
        );
      }
    });

    if (!kIsWeb) {
      _ytVideoStateSub?.cancel();
      _ytPlayerStateSub?.cancel();
      await _ytController?.close();
      _ytController = null;

      final controller = YoutubePlayerController.fromVideoId(
        videoId: videoId,
        autoPlay: true,
        params: const YoutubePlayerParams(
          showControls: false,
          showFullscreenButton: false,
          mute: false,
          enableCaption: true,
          strictRelatedVideos: true,
        ),
      );

      _ytController = controller;

      _ytVideoStateSub = controller.videoStateStream.listen((state) {
        if (mounted && _dragValue < 0) {
          setState(() {
            _mobilePosition = state.position.inSeconds.toDouble();
          });
        }
      });

      _ytPlayerStateSub = controller.stream.listen((val) {
        if (mounted) {
          setState(() {});
        }
      });
    }

    // Asynchronously fetch comments and related videos
    _loadComments(videoId);
    _loadRelated(videoId, widget.initialVideo?.title ?? 'Trending Video');

    try {
      final info = await _api.getStreamInfo(videoId);
      if (!mounted) return;

      setState(() {
        _streamInfo = info;
        _isLoadingInfo = false;
      });

      // If stream info returned related streams, use them
      if (info.relatedStreams.isNotEmpty) {
        setState(() {
          _relatedVideos = info.relatedStreams;
          _isLoadingRelated = false;
        });
      } else {
        _loadRelated(videoId, info.title);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingInfo = false;
      });
    }
  }

  Future<void> _loadComments(String videoId) async {
    try {
      final list = await _api.getComments(videoId);
      if (mounted) {
        setState(() {
          _comments = list;
          _isLoadingComments = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingComments = false);
    }
  }

  Future<void> _loadRelated(String videoId, String title) async {
    try {
      final list = await _api.getRelatedVideos(videoId, title);
      if (mounted && list.isNotEmpty) {
        setState(() {
          _relatedVideos = list;
          _isLoadingRelated = false;
        });
        return;
      }
    } catch (_) {}

    // Fallback to current feed / trending videos if search returns empty
    if (mounted) {
      try {
        final feedVideos = context.read<FeedProvider>().videos;
        if (feedVideos.isNotEmpty) {
          final fallbackList = feedVideos.where((v) => v.id != videoId).toList();
          if (fallbackList.isNotEmpty) {
            setState(() {
              _relatedVideos = fallbackList;
              _isLoadingRelated = false;
            });
            return;
          }
        }
      } catch (_) {}

      try {
        final trending = await _api.getTrending();
        if (mounted && trending.isNotEmpty) {
          final fallbackList = trending.where((v) => v.id != videoId).toList();
          if (fallbackList.isNotEmpty) {
            setState(() {
              _relatedVideos = fallbackList;
              _isLoadingRelated = false;
            });
            return;
          }
        }
      } catch (_) {}

      setState(() => _isLoadingRelated = false);
    }
  }

  void _handleSeekRelative(int seconds) {
    _startHideControlsTimer();
    if (kIsWeb) {
      sendWebSeek(_currentVideoId, seconds);
    } else if (_ytController != null) {
      final cur = _mobilePosition;
      final dur = _streamDuration;
      final target = (cur + seconds).clamp(0.0, dur);
      _ytController!.seekTo(seconds: target, allowSeekAhead: true);
      setState(() {
        _mobilePosition = target;
      });
    }
  }

  void _handleSeekTo(double seconds) {
    if (kIsWeb) {
      sendWebSeekTo(_currentVideoId, seconds);
    } else if (_ytController != null) {
      _ytController!.seekTo(seconds: seconds, allowSeekAhead: true);
      setState(() {
        _mobilePosition = seconds;
      });
    }
    _startHideControlsTimer();
  }

  void _handlePlayPause() {
    _startHideControlsTimer();
    if (kIsWeb) {
      sendWebPlayPause(_currentVideoId);
    } else if (_ytController != null) {
      if (_ytController!.value.playerState == PlayerState.playing) {
        _ytController!.pauseVideo();
      } else {
        _ytController!.playVideo();
      }
      setState(() {});
    }
  }

  void _handleSpeed(double speed) {
    setState(() {
      _playbackSpeed = speed;
    });
    if (kIsWeb) {
      sendWebSpeed(_currentVideoId, speed);
    } else {
      _ytController?.setPlaybackRate(speed);
    }
  }

  void _handleToggleMute(bool isCurrentlyMuted) {
    if (kIsWeb) {
      sendWebToggleMute(_currentVideoId);
    } else if (_ytController != null) {
      if (isCurrentlyMuted) {
        _ytController!.unMute();
        setState(() => _isMobileMuted = false);
      } else {
        _ytController!.mute();
        setState(() => _isMobileMuted = true);
      }
    }
  }

  void _handleFullscreen() {
    if (kIsWeb) {
      sendWebFullscreen(_currentVideoId);
    } else if (_ytController != null) {
      _ytController!.toggleFullScreen();
    }
  }

  void _handleToggleCaptions([bool? explicitValue]) {
    _startHideControlsTimer();
    final nextVal = explicitValue ?? !_isCaptionsEnabled;
    setState(() {
      _isCaptionsEnabled = nextVal;
    });
    if (kIsWeb) {
      sendWebToggleCaptions(_currentVideoId, nextVal);
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          nextVal ? 'Captions (CC) turned on' : 'Captions (CC) turned off',
        ),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _showSettingsSheet(BuildContext context) {
    _hideControlsTimer?.cancel();
    showModalBottomSheet(
      context: context,
      backgroundColor: YouTubeTheme.ytSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: StatefulBuilder(
            builder: (context, setSheetState) {
              return Column(
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
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Video Settings',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const Divider(color: YouTubeTheme.ytBorder),

                  // Captions (CC / Subtitles)
                  ListTile(
                    leading: Icon(
                      _isCaptionsEnabled ? Icons.closed_caption : Icons.closed_caption_outlined,
                      color: _isCaptionsEnabled ? YouTubeTheme.ytRed : Colors.white70,
                    ),
                    title: const Text('Captions (Subtitles)', style: TextStyle(color: Colors.white)),
                    subtitle: Text(
                      _isCaptionsEnabled ? 'Auto-generated / Available' : 'Off',
                      style: const TextStyle(color: YouTubeTheme.ytTextSecondary, fontSize: 12),
                    ),
                    trailing: Switch(
                      value: _isCaptionsEnabled,
                      activeThumbColor: YouTubeTheme.ytRed,
                      onChanged: (val) {
                        setSheetState(() => _isCaptionsEnabled = val);
                        _handleToggleCaptions(val);
                      },
                    ),
                    onTap: () {
                      final next = !_isCaptionsEnabled;
                      setSheetState(() => _isCaptionsEnabled = next);
                      _handleToggleCaptions(next);
                    },
                  ),

                  // Quality selector
                  ListTile(
                    leading: const Icon(Icons.high_quality, color: Colors.white70),
                    title: const Text('Quality', style: TextStyle(color: Colors.white)),
                    subtitle: Text(
                      _selectedQuality,
                      style: const TextStyle(color: YouTubeTheme.ytTextSecondary, fontSize: 12),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white54),
                    onTap: () {
                      Navigator.pop(ctx);
                      _showQualitySheet(context);
                    },
                  ),

                  // Playback speed
                  ListTile(
                    leading: const Icon(Icons.speed, color: Colors.white70),
                    title: const Text('Playback Speed', style: TextStyle(color: Colors.white)),
                    subtitle: Text(
                      _playbackSpeed == 1.0 ? 'Normal' : '${_playbackSpeed}x',
                      style: const TextStyle(color: YouTubeTheme.ytTextSecondary, fontSize: 12),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white54),
                    onTap: () {
                      Navigator.pop(ctx);
                      _showSpeedSheet(context);
                    },
                  ),

                  // Loop Video
                  SwitchListTile(
                    secondary: const Icon(Icons.loop, color: Colors.white70),
                    title: const Text('Loop Video', style: TextStyle(color: Colors.white)),
                    value: _isLooping,
                    activeThumbColor: YouTubeTheme.ytRed,
                    onChanged: (val) {
                      setSheetState(() => _isLooping = val);
                      setState(() => _isLooping = val);
                      _ytController?.setLoop(loopPlaylists: val);
                    },
                  ),
                  const SizedBox(height: 12),
                ],
              );
            },
          ),
        );
      },
    ).then((_) => _startHideControlsTimer());
  }

  void _showQualitySheet(BuildContext context) {
    final qualities = ['Auto (1080p)', '1080p', '720p', '480p', '360p'];
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
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('Select Quality', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              ...qualities.map((q) => ListTile(
                    title: Text(q, style: const TextStyle(color: Colors.white)),
                    trailing: _selectedQuality == q ? const Icon(Icons.check, color: YouTubeTheme.ytRed) : null,
                    onTap: () {
                      setState(() => _selectedQuality = q);
                      Navigator.pop(ctx);
                    },
                  )),
            ],
          ),
        );
      },
    );
  }

  void _showSpeedSheet(BuildContext context) {
    final speeds = [0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0];
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
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('Playback Speed', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              ...speeds.map((s) => ListTile(
                    title: Text(s == 1.0 ? 'Normal (1.0x)' : '${s}x', style: const TextStyle(color: Colors.white)),
                    trailing: _playbackSpeed == s ? const Icon(Icons.check, color: YouTubeTheme.ytRed) : null,
                    onTap: () {
                      _handleSpeed(s);
                      Navigator.pop(ctx);
                    },
                  )),
            ],
          ),
        );
      },
    );
  }

  // Full YouTube Comments BottomSheet
  void _showCommentsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: YouTubeTheme.ytSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                // Drag handle
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[600],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // Top Header Row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      const Text(
                        'Comments',
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _comments.isNotEmpty ? '${_comments.length}' : '',
                        style: const TextStyle(color: YouTubeTheme.ytTextSecondary, fontSize: 15),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                ),
                const Divider(color: YouTubeTheme.ytBorder, height: 1),

                // Comments List
                Expanded(
                  child: _isLoadingComments
                      ? const Center(child: CircularProgressIndicator(color: YouTubeTheme.ytRed))
                      : _comments.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.comment_outlined, color: Colors.white54, size: 36),
                                  const SizedBox(height: 8),
                                  const Text('No comments available or restricted.',
                                      style: TextStyle(color: YouTubeTheme.ytTextSecondary, fontSize: 13)),
                                  const SizedBox(height: 8),
                                  TextButton.icon(
                                    style: TextButton.styleFrom(foregroundColor: Colors.white),
                                    icon: const Icon(Icons.refresh, size: 16),
                                    label: const Text('Retry'),
                                    onPressed: () {
                                      Navigator.pop(ctx);
                                      _loadComments(_currentVideoId);
                                    },
                                  ),
                                ],
                              ),
                            )
                          : ListView.separated(
                              controller: scrollController,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              itemCount: _comments.length,
                              separatorBuilder: (context, index) => const SizedBox(height: 16),
                              itemBuilder: (context, index) {
                                final c = _comments[index];
                                return Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CircleAvatar(
                                      radius: 16,
                                      backgroundColor: YouTubeTheme.ytSurfaceLight,
                                      backgroundImage: (c.authorAvatar != null && c.authorAvatar!.isNotEmpty)
                                          ? CachedNetworkImageProvider(c.authorAvatar!)
                                          : null,
                                      child: (c.authorAvatar == null || c.authorAvatar!.isEmpty)
                                          ? Text(c.author.isNotEmpty ? c.author[0].toUpperCase() : 'U',
                                              style: const TextStyle(color: Colors.white, fontSize: 12))
                                          : null,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Text(
                                                c.author,
                                                style: const TextStyle(
                                                    color: YouTubeTheme.ytTextSecondary,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w500),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                c.time,
                                                style: const TextStyle(color: Colors.grey, fontSize: 11),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            c.text,
                                            style: const TextStyle(
                                                color: YouTubeTheme.ytTextPrimary, fontSize: 13, height: 1.3),
                                          ),
                                          const SizedBox(height: 6),
                                          Row(
                                            children: [
                                              const Icon(Icons.thumb_up_alt_outlined, size: 14, color: Colors.grey),
                                              if (c.likes > 0) ...[
                                                const SizedBox(width: 4),
                                                Text(
                                                  '${c.likes}',
                                                  style: const TextStyle(color: Colors.grey, fontSize: 11),
                                                ),
                                              ],
                                              const SizedBox(width: 16),
                                              const Icon(Icons.thumb_down_alt_outlined, size: 14, color: Colors.grey),
                                              if (c.isHearted) ...[
                                                const SizedBox(width: 12),
                                                const Icon(Icons.favorite, size: 14, color: YouTubeTheme.ytRed),
                                              ],
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = _streamInfo?.title ?? widget.initialVideo?.title ?? 'Loading video...';
    final uploaderName = _streamInfo?.uploader ?? widget.initialVideo?.uploaderName ?? 'Creator';
    final uploaderId = _streamInfo?.uploaderId ?? widget.initialVideo?.uploaderId;
    final uploaderAvatar = _streamInfo?.uploaderAvatar ?? widget.initialVideo?.uploaderAvatar;
    final views = _streamInfo?.views ?? widget.initialVideo?.views;
    final uploadDate = _streamInfo?.uploadDate ?? widget.initialVideo?.uploadedDate;
    final subscribers = _streamInfo?.uploaderSubscriberCount;

    final subProvider = context.watch<SubscriptionProvider>();
    final isSubbed = uploaderId != null && subProvider.isSubscribed(uploaderId);

    return Scaffold(
      backgroundColor: YouTubeTheme.ytBlack,
      body: SafeArea(
        child: Column(
          children: [
            // 1. YouTube Video Player Area (16:9) with interactive Red Line Scrubber Overlay
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Container(
                color: Colors.black,
                child: MouseRegion(
                  onHover: (_) {
                    if (!_showControls) {
                      setState(() => _showControls = true);
                    }
                    _startHideControlsTimer();
                  },
                  onEnter: (_) {
                    if (!_showControls) {
                      setState(() => _showControls = true);
                    }
                    _startHideControlsTimer();
                  },
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Base Player (Web IFrame or Mobile YoutubePlayer)
                      if (kIsWeb)
                        getPlatformWebPlayer(_currentVideoId)
                      else if (_ytController != null)
                        YoutubePlayer(
                          controller: _ytController!,
                          aspectRatio: 16 / 9,
                          controlsBuilder: (context, isFullscreen) {
                            return Stack(
                              fit: StackFit.expand,
                              children: [
                                // Gesture Layer for tap-to-toggle overlay
                                Positioned.fill(
                                  child: GestureDetector(
                                    behavior: HitTestBehavior.translucent,
                                    onTap: _toggleControlsVisibility,
                                  ),
                                ),

                                // Thin Red Progress Line when overlay is hidden (Official YouTube UI)
                                if (!_showControls)
                                  Positioned(
                                    left: 0,
                                    right: 0,
                                    bottom: 0,
                                    child: LinearProgressIndicator(
                                      value: (_mobilePosition / _streamDuration).clamp(0.0, 1.0),
                                      backgroundColor: Colors.transparent,
                                      valueColor: const AlwaysStoppedAnimation<Color>(YouTubeTheme.ytRed),
                                      minHeight: 2.5,
                                    ),
                                  ),

                                // 1:1 Modern YouTube Player Controls Overlay
                                if (_showControls)
                                  _buildYouTubeOverlay(
                                    currentTime: _dragValue >= 0 ? _dragValue : _mobilePosition,
                                    duration: _streamDuration,
                                    isPlaying: _ytController?.value.playerState == PlayerState.playing,
                                    isMuted: _isMobileMuted,
                                    isFullscreen: isFullscreen,
                                  ),
                              ],
                            );
                          },
                        )
                      else if (_isLoadingInfo)
                        const Center(
                          child: CircularProgressIndicator(color: YouTubeTheme.ytRed, strokeWidth: 2.5),
                        )
                      else if (_errorMessage != null)
                        Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.error_outline, color: YouTubeTheme.ytRed, size: 26),
                              const SizedBox(height: 4),
                              Text(
                                _errorMessage!,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Colors.white70, fontSize: 11),
                              ),
                              TextButton.icon(
                                style: TextButton.styleFrom(foregroundColor: Colors.white),
                                icon: const Icon(Icons.refresh, size: 14),
                                label: const Text('Retry'),
                                onPressed: () => _loadStreamData(_currentVideoId),
                              ),
                            ],
                          ),
                        )
                      else
                        const Center(
                          child: CircularProgressIndicator(color: YouTubeTheme.ytRed, strokeWidth: 2.5),
                        ),

                      // Overlay for Web only
                      if (kIsWeb) ...[
                        // Gesture Layer for tap-to-toggle overlay on Web
                        Positioned.fill(
                          child: GestureDetector(
                            behavior: HitTestBehavior.translucent,
                            onTap: _toggleControlsVisibility,
                          ),
                        ),

                        // Thin Red Progress Line when overlay is hidden on Web
                        if (!_showControls)
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 0,
                            child: ValueListenableBuilder<WebPlayerInfo>(
                              valueListenable: getPlatformPlayerNotifier(),
                              builder: (context, webInfo, _) {
                                final dur = webInfo.duration > 0
                                    ? webInfo.duration
                                    : (widget.initialVideo?.duration?.toDouble() ?? 120.0);
                                final frac = (webInfo.currentTime / dur).clamp(0.0, 1.0);
                                return LinearProgressIndicator(
                                  value: frac,
                                  backgroundColor: Colors.transparent,
                                  valueColor: const AlwaysStoppedAnimation<Color>(YouTubeTheme.ytRed),
                                  minHeight: 2.5,
                                );
                              },
                            ),
                          ),

                        // 1:1 Modern YouTube Player Controls Overlay on Web
                        if (_showControls)
                          ValueListenableBuilder<WebPlayerInfo>(
                            valueListenable: getPlatformPlayerNotifier(),
                            builder: (context, webInfo, _) {
                              final curSeconds = _dragValue >= 0 ? _dragValue : webInfo.currentTime;
                              final durSeconds = webInfo.duration > 0
                                  ? webInfo.duration
                                  : (widget.initialVideo?.duration?.toDouble() ?? 120.0);
                              final isPlaying = webInfo.isPlaying;
                              final isMuted = webInfo.isMuted;

                              return _buildYouTubeOverlay(
                                currentTime: curSeconds,
                                duration: durSeconds,
                                isPlaying: isPlaying,
                                isMuted: isMuted,
                              );
                            },
                          ),
                      ],
                    ],
                  ),
                ),
              ),
            ),

            // 2. Video Info & Actions Scrollable Feed
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                children: [
                  // Title
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Metadata subtitle
                  Text(
                    '${Formatters.formatViews(views)} • ${Formatters.formatUploadDate(uploadDate)}',
                    style: const TextStyle(color: YouTubeTheme.ytTextSecondary, fontSize: 12),
                  ),
                  const SizedBox(height: 12),

                  // Channel Bar Row
                  Row(
                    children: [
                      // Avatar
                      GestureDetector(
                        onTap: () {
                          if (uploaderId != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ChannelScreen(channelId: uploaderId, channelName: uploaderName),
                              ),
                            );
                          }
                        },
                        child: CircleAvatar(
                          radius: 18,
                          backgroundColor: YouTubeTheme.ytSurfaceLight,
                          backgroundImage: (uploaderAvatar != null && uploaderAvatar.isNotEmpty)
                              ? CachedNetworkImageProvider(uploaderAvatar)
                              : null,
                          child: (uploaderAvatar == null || uploaderAvatar.isEmpty)
                              ? Text(uploaderName.isNotEmpty ? uploaderName[0].toUpperCase() : 'Y')
                              : null,
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Channel name & subs
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            if (uploaderId != null) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ChannelScreen(channelId: uploaderId, channelName: uploaderName),
                                ),
                              );
                            }
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                uploaderName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              if (subscribers != null)
                                Text(
                                  Formatters.formatSubscribers(subscribers),
                                  style: const TextStyle(
                                    color: YouTubeTheme.ytTextSecondary,
                                    fontSize: 11,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),

                      // YouTube Subscribe Button (Red / Gray toggle)
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isSubbed ? YouTubeTheme.ytSurfaceLight : Colors.white,
                          foregroundColor: isSubbed ? Colors.white : Colors.black,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        onPressed: () {
                          if (uploaderId != null) {
                            subProvider.toggleSubscription(
                              channelId: uploaderId,
                              channelName: uploaderName,
                              avatarUrl: uploaderAvatar ?? '',
                              subscriberCount: subscribers?.toString(),
                            );
                          }
                        },
                        child: Text(
                          isSubbed ? 'Subscribed' : 'Subscribe',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // YouTube Action Pills Bar (Like, Share, Copy)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        // Like Button
                        PillButton(
                          icon: _isLiked ? Icons.thumb_up : Icons.thumb_up_alt_outlined,
                          label: _isLiked ? 'Liked' : 'Like',
                          isActive: _isLiked,
                          activeColor: Colors.white,
                          onTap: () async {
                            final nowLiked = await StorageService.toggleLikeVideo(_currentVideoId);
                            setState(() {
                              _isLiked = nowLiked;
                            });
                          },
                        ),
                        const SizedBox(width: 8),

                        // Native Share Button
                        PillButton(
                          icon: Icons.share_outlined,
                          label: 'Share',
                          onTap: () {
                            SharePlus.instance.share(
                              ShareParams(
                                text: '$title\nhttps://youtu.be/$_currentVideoId',
                                subject: title,
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 8),

                        // Copy Link Button
                        PillButton(
                          icon: Icons.copy,
                          label: 'Copy link',
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: 'https://youtu.be/$_currentVideoId'));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('YouTube video link copied!'),
                                duration: Duration(seconds: 1),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 1. YouTube Expandable Description Box
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _isDescriptionExpanded = !_isDescriptionExpanded;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: YouTubeTheme.ytSurface,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                Formatters.formatViews(views),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                Formatters.formatUploadDate(uploadDate),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _streamInfo?.description != null && _streamInfo!.description.isNotEmpty
                                ? _streamInfo!.description
                                : 'No description provided for this video.',
                            maxLines: _isDescriptionExpanded ? null : 3,
                            overflow: _isDescriptionExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
                            style: const TextStyle(color: YouTubeTheme.ytTextPrimary, fontSize: 12, height: 1.4),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _isDescriptionExpanded ? 'Show less' : '...more',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 2. YouTube Comments Preview Card (Tap opens full comments sheet)
                  GestureDetector(
                    onTap: () => _showCommentsSheet(context),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: YouTubeTheme.ytSurface,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text(
                                'Comments',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _comments.isNotEmpty ? '${_comments.length}' : '',
                                style: const TextStyle(color: YouTubeTheme.ytTextSecondary, fontSize: 12),
                              ),
                              const Spacer(),
                              const Icon(Icons.unfold_more, size: 16, color: Colors.white70),
                            ],
                          ),
                          if (_comments.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 12,
                                  backgroundColor: YouTubeTheme.ytSurfaceLight,
                                  backgroundImage: (_comments.first.authorAvatar != null &&
                                          _comments.first.authorAvatar!.isNotEmpty)
                                      ? CachedNetworkImageProvider(_comments.first.authorAvatar!)
                                      : null,
                                  child: (_comments.first.authorAvatar == null ||
                                          _comments.first.authorAvatar!.isEmpty)
                                      ? Text(_comments.first.author[0].toUpperCase(),
                                          style: const TextStyle(fontSize: 10, color: Colors.white))
                                      : null,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _comments.first.text,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(color: YouTubeTheme.ytTextPrimary, fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                          ] else if (_isLoadingComments) ...[
                            const SizedBox(height: 4),
                            const Text('Loading comments...', style: TextStyle(color: Colors.grey, fontSize: 11)),
                          ] else ...[
                            const SizedBox(height: 4),
                            const Text('Tap to view comments', style: TextStyle(color: Colors.grey, fontSize: 11)),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 3. Up Next / Related Videos Heading
                  const Text(
                    'Up Next',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Up next videos list (Guaranteed loaded)
                  if (_isLoadingRelated && _relatedVideos.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24.0),
                        child: CircularProgressIndicator(color: YouTubeTheme.ytRed, strokeWidth: 2),
                      ),
                    )
                  else if (_relatedVideos.isNotEmpty)
                    ..._relatedVideos.map(
                      (v) => VideoCard(
                        video: v,
                        onTap: () {
                          _loadStreamData(v.id);
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
                    )
                  else
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                      child: Text(
                        'No related videos found.',
                        style: TextStyle(color: YouTubeTheme.ytTextSecondary, fontSize: 12),
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

  // ---------------------------------------------------------------------------
  // YouTube 1:1 Complete Overlay (Red line scrubber, Volume, Settings, 10s skip)
  // ---------------------------------------------------------------------------
  Widget _buildYouTubeOverlay({
    required double currentTime,
    required double duration,
    required bool isPlaying,
    required bool isMuted,
    bool isFullscreen = false,
  }) {
    final maxDur = duration > 0 ? duration : 1.0;
    final curPos = currentTime.clamp(0.0, maxDur);

    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 1. Top Bar: Down Arrow, Spacer, Volume button, Settings Gear
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 24),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  tooltip: 'Minimize',
                  onPressed: () => Navigator.pop(context),
                ),
                const Spacer(),

                // CC (Captions / Subtitles) toggle
                IconButton(
                  icon: Icon(
                    _isCaptionsEnabled ? Icons.closed_caption : Icons.closed_caption_outlined,
                    color: _isCaptionsEnabled ? YouTubeTheme.ytRed : Colors.white,
                    size: 21,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  tooltip: _isCaptionsEnabled ? 'Turn off captions (CC)' : 'Turn on captions (CC)',
                  onPressed: _handleToggleCaptions,
                ),

                // Volume / Mute button
                IconButton(
                  icon: Icon(
                    isMuted ? Icons.volume_off : Icons.volume_up,
                    color: Colors.white,
                    size: 20,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  tooltip: isMuted ? 'Unmute' : 'Mute',
                  onPressed: () => _handleToggleMute(isMuted),
                ),

                // Settings Gear (Quality, Speed, Loop)
                IconButton(
                  icon: const Icon(Icons.settings_outlined, color: Colors.white, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  tooltip: 'Settings',
                  onPressed: () => _showSettingsSheet(context),
                ),
              ],
            ),
          ),

          // 2. Center Action Buttons: [ 10s Rewind ] [ Play / Pause ] [ 10s Forward ]
          Expanded(
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Rewind 10s
                      IconButton(
                        icon: const Icon(Icons.replay_10, color: Colors.white, size: 32),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                        tooltip: 'Rewind 10s',
                        onPressed: () => _handleSeekRelative(-10),
                      ),
                      const SizedBox(width: 20),

                      // Play / Pause Circle
                      IconButton(
                        icon: Icon(
                          isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                          color: Colors.white,
                          size: 50,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 54, minHeight: 54),
                        tooltip: isPlaying ? 'Pause' : 'Play',
                        onPressed: _handlePlayPause,
                      ),
                      const SizedBox(width: 20),

                      // Forward 10s
                      IconButton(
                        icon: const Icon(Icons.forward_10, color: Colors.white, size: 32),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                        tooltip: 'Forward 10s',
                        onPressed: () => _handleSeekRelative(10),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 3. Bottom Row: Draggable Red Line Scrubber + Timestamp + Fullscreen
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 8, 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Red Timeline Scrubber Line (Draggable Bar)
                SizedBox(
                  height: 18,
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 3.0,
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 5.5,
                        elevation: 1,
                      ),
                      overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
                      activeTrackColor: YouTubeTheme.ytRed,
                      inactiveTrackColor: Colors.white30,
                      thumbColor: YouTubeTheme.ytRed,
                      overlayColor: YouTubeTheme.ytRed.withValues(alpha: 0.3),
                    ),
                    child: Slider(
                      value: curPos,
                      min: 0.0,
                      max: maxDur,
                      onChanged: (val) {
                        setState(() {
                          _dragValue = val;
                        });
                      },
                      onChangeEnd: (val) {
                        _handleSeekTo(val);
                        setState(() {
                          _dragValue = -1.0;
                        });
                      },
                    ),
                  ),
                ),

                // Timestamps and Fullscreen button
                Row(
                  children: [
                    Text(
                      '${Formatters.formatDuration(curPos.toInt())} / ${Formatters.formatDuration(maxDur.toInt())}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: Icon(
                        isFullscreen ? Icons.fullscreen_exit : Icons.fullscreen,
                        color: Colors.white,
                        size: 20,
                      ),
                      tooltip: isFullscreen ? 'Exit Fullscreen' : 'Fullscreen',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                      onPressed: _handleFullscreen,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
