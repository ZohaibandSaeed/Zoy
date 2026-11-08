import 'package:flutter/material.dart';
import '../utils/theme.dart';

class PillButton extends StatelessWidget {
  final IconData? icon;
  final String label;
  final VoidCallback onTap;
  final bool isActive;
  final Color? activeColor;

  const PillButton({
    super.key,
    this.icon,
    required this.label,
    required this.onTap,
    this.isActive = false,
    this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isActive
          ? (activeColor ?? YouTubeTheme.ytPillActiveBg)
          : YouTubeTheme.ytPillBg,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 18,
                  color: isActive
                      ? YouTubeTheme.ytPillActiveText
                      : YouTubeTheme.ytTextPrimary,
                ),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  color: isActive
                      ? YouTubeTheme.ytPillActiveText
                      : YouTubeTheme.ytTextPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

