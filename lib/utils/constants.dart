class AppConstants {
  static const String appName = 'zoy';
  
  // High-reliability verified privacy endpoints for home trending, search & comments
  static const List<String> pipedInstances = [
    'https://pipedapi.ducks.party',
    'https://api.piped.private.coffee',
  ];

  // Invidious API Fallback Instances (empty - all active operations handled by zeeTube Privacy Engine)
  static const List<String> invidiousInstances = [];

  static const String defaultRegion = 'PK';
  
  // Storage keys (ONLY for local subscriptions - ZERO history)
  static const String keySubscriptions = 'zeetube_local_subscriptions';
  static const String keyLikedVideoIds = 'zeetube_liked_video_ids';
  static const String keyPreferredInstance = 'zeetube_preferred_instance';
}

