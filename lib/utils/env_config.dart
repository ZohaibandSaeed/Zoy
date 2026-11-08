import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'constants.dart';

class EnvConfig {
  static Future<void> init() async {
    try {
      await dotenv.load(fileName: ".env");
    } catch (e) {
      // Fallback gracefully if .env is missing or invalid
      // ignore: avoid_print
      print('Warning: .env file not found or failed to load. Using defaults.');
    }
  }

  static String get appName {
    if (!dotenv.isInitialized) return AppConstants.appName;
    return dotenv.env['APP_NAME'] ?? AppConstants.appName;
  }

  static String get defaultRegion {
    if (!dotenv.isInitialized) return AppConstants.defaultRegion;
    return dotenv.env['DEFAULT_REGION'] ?? AppConstants.defaultRegion;
  }

  static String get primaryPipedUrl {
    if (!dotenv.isInitialized) return AppConstants.pipedInstances[0];
    return dotenv.env['PIPED_PRIMARY_API_URL']?.trim().isNotEmpty == true
        ? dotenv.env['PIPED_PRIMARY_API_URL']!.trim()
        : AppConstants.pipedInstances[0];
  }

  static List<String> get allPipedInstances {
    if (!dotenv.isInitialized) return AppConstants.pipedInstances;
    final list = <String>[];
    final custom = dotenv.env['CUSTOM_API_INSTANCE_URL']?.trim();
    if (custom != null && custom.isNotEmpty) {
      list.add(custom);
    }

    final primary = dotenv.env['PIPED_PRIMARY_API_URL']?.trim();
    if (primary != null && primary.isNotEmpty && !list.contains(primary)) {
      list.add(primary);
    }

    final fb1 = dotenv.env['PIPED_FALLBACK_API_URL_1']?.trim();
    if (fb1 != null && fb1.isNotEmpty && !list.contains(fb1)) {
      list.add(fb1);
    }

    final fb2 = dotenv.env['PIPED_FALLBACK_API_URL_2']?.trim();
    if (fb2 != null && fb2.isNotEmpty && !list.contains(fb2)) {
      list.add(fb2);
    }

    // Default fallbacks from constants
    for (final instance in AppConstants.pipedInstances) {
      if (!list.contains(instance)) {
        list.add(instance);
      }
    }
    return list;
  }

  static String? get youtubeApiKey {
    if (!dotenv.isInitialized) return null;
    final key = dotenv.env['YOUTUBE_DATA_API_KEY']?.trim();
    if (key != null && key.isNotEmpty && key != 'your_youtube_api_key_here') {
      return key;
    }
    return null;
  }
}

