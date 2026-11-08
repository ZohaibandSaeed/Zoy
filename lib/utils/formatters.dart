class Formatters {
  // Format views: 1500 -> 1.5K, 2300000 -> 2.3M
  static String formatViews(int? views) {
    if (views == null || views < 0) return '0 views';
    if (views < 1000) {
      return '$views views';
    } else if (views < 1000000) {
      double num = views / 1000;
      return '${num.toStringAsFixed(num < 10 ? 1 : 0)}K views';
    } else if (views < 1000000000) {
      double num = views / 1000000;
      return '${num.toStringAsFixed(num < 10 ? 1 : 0)}M views';
    } else {
      double num = views / 1000000000;
      return '${num.toStringAsFixed(1)}B views';
    }
  }

  // Format subscribers: 1200000 -> 1.2M subscribers
  static String formatSubscribers(int? subs) {
    if (subs == null || subs <= 0) return 'No subscribers';
    if (subs < 1000) {
      return '$subs subscribers';
    } else if (subs < 1000000) {
      double num = subs / 1000;
      return '${num.toStringAsFixed(num < 10 ? 1 : 0)}K subscribers';
    } else {
      double num = subs / 1000000;
      return '${num.toStringAsFixed(num < 10 ? 1 : 0)}M subscribers';
    }
  }

  // Format duration seconds to mm:ss or hh:mm:ss
  static String formatDuration(int? seconds) {
    if (seconds == null || seconds <= 0) return '0:00';
    final duration = Duration(seconds: seconds);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final secs = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    } else {
      return '$minutes:${secs.toString().padLeft(2, '0')}';
    }
  }

  // Format upload date or text
  static String formatUploadDate(String? text, [int? timestamp]) {
    if (text != null && text.isNotEmpty) {
      return text;
    }
    if (timestamp != null && timestamp > 0) {
      final date = DateTime.fromMillisecondsSinceEpoch(
        timestamp > 1000000000000 ? timestamp : timestamp * 1000,
      );
      final diff = DateTime.now().difference(date);
      if (diff.inDays > 365) {
        final years = (diff.inDays / 365).floor();
        return '$years year${years > 1 ? 's' : ''} ago';
      } else if (diff.inDays > 30) {
        final months = (diff.inDays / 30).floor();
        return '$months month${months > 1 ? 's' : ''} ago';
      } else if (diff.inDays > 0) {
        return '${diff.inDays} day${diff.inDays > 1 ? 's' : ''} ago';
      } else if (diff.inHours > 0) {
        return '${diff.inHours} hour${diff.inHours > 1 ? 's' : ''} ago';
      } else if (diff.inMinutes > 0) {
        return '${diff.inMinutes} minute${diff.inMinutes > 1 ? 's' : ''} ago';
      } else {
        return 'Just now';
      }
    }
    return '';
  }
}

