class WebPlayerInfo {
  final double currentTime;
  final double duration;
  final bool isPlaying;
  final int volume;
  final bool isMuted;

  const WebPlayerInfo({
    this.currentTime = 0.0,
    this.duration = 0.0,
    this.isPlaying = true,
    this.volume = 100,
    this.isMuted = false,
  });

  WebPlayerInfo copyWith({
    double? currentTime,
    double? duration,
    bool? isPlaying,
    int? volume,
    bool? isMuted,
  }) {
    return WebPlayerInfo(
      currentTime: currentTime ?? this.currentTime,
      duration: duration ?? this.duration,
      isPlaying: isPlaying ?? this.isPlaying,
      volume: volume ?? this.volume,
      isMuted: isMuted ?? this.isMuted,
    );
  }
}

