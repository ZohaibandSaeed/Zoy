import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/subscription_provider.dart';
import '../services/storage_service.dart';
import '../utils/env_config.dart';
import '../utils/theme.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final subProvider = context.watch<SubscriptionProvider>();
    final likedCount = StorageService.getLikedVideoIds().length;

    return Scaffold(
      backgroundColor: YouTubeTheme.ytBlack,
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // 1. Premium Architecture Shield Banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  YouTubeTheme.ytSurface,
                  Colors.green.withValues(alpha: 0.12),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.verified_user_outlined, color: Colors.greenAccent, size: 28),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '100% Private & Untracked',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Built from scratch with zero telemetry, zero history logging, and zero cloud profiling.',
                        style: TextStyle(
                          color: YouTubeTheme.ytTextSecondary,
                          fontSize: 12,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 2. Core Privacy Shield Section
          const Text(
            'PRIVACY & SECURITY SHIELD',
            style: TextStyle(
              color: YouTubeTheme.ytTextSecondary,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 10),

          _buildTile(
            icon: Icons.history_toggle_off,
            title: 'Watch History',
            subtitle: 'Permanently Disabled (Zero Watch Data Kept)',
            trailing: const Icon(Icons.check_circle, color: Colors.greenAccent, size: 20),
          ),
          _buildTile(
            icon: Icons.search_off,
            title: 'Search Queries',
            subtitle: '100% Private (Never stored or transmitted)',
            trailing: const Icon(Icons.check_circle, color: Colors.greenAccent, size: 20),
          ),
          _buildTile(
            icon: Icons.shield,
            title: 'Ad & Tracker Shield',
            subtitle: 'Blocked natively by zoy Privacy Engine',
            trailing: const Icon(Icons.check_circle, color: Colors.greenAccent, size: 20),
          ),
          _buildTile(
            icon: Icons.person_off_outlined,
            title: 'Account & Identity',
            subtitle: 'Zero accounts required. Complete anonymity.',
            trailing: const Icon(Icons.check_circle, color: Colors.greenAccent, size: 20),
          ),
          const SizedBox(height: 24),

          // 3. Local Storage Section (100% On-Device)
          const Text(
            'ON-DEVICE DATA (100% LOCAL)',
            style: TextStyle(
              color: YouTubeTheme.ytTextSecondary,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 10),

          _buildTile(
            icon: Icons.subscriptions_outlined,
            title: 'Local Subscriptions',
            subtitle: '${subProvider.subscriptions.length} channels saved locally on this device',
          ),
          _buildTile(
            icon: Icons.thumb_up_alt_outlined,
            title: 'Liked Videos',
            subtitle: '$likedCount videos saved offline on device',
          ),
          _buildTile(
            icon: Icons.dns_outlined,
            title: 'Secure Privacy Gateway',
            subtitle: 'Decentralized encrypted streaming network',
          ),
          _buildTile(
            icon: Icons.language,
            title: 'Feed Region',
            subtitle: EnvConfig.defaultRegion == 'PK'
                ? 'Pakistan (PK) 🇵🇰'
                : EnvConfig.defaultRegion,
          ),
          const SizedBox(height: 32),

          // Developer Credit with Stylish Typography
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.12),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.code_rounded,
                    color: Colors.redAccent,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: 'developer: ',
                          style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 12,
                            letterSpacing: 1.2,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        TextSpan(
                          text: 'ZohaibandSaeed',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                            fontStyle: FontStyle.italic,
                            shadows: [
                              Shadow(
                                color: Colors.redAccent.withValues(alpha: 0.55),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),
        ],
      ),
    );
  }

  Widget _buildTile({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: YouTubeTheme.ytSurface,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.white70, size: 22),
        title: Text(
          title,
          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: YouTubeTheme.ytTextSecondary, fontSize: 12),
        ),
        trailing: trailing,
      ),
    );
  }
}
