import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ClusterTrendBadge extends StatelessWidget {
  final String? clusterId;
  final String? clusterLabel;
  final double? momentumScore;
  final bool isEmergent;
  final VoidCallback? onTap;

  const ClusterTrendBadge({
    super.key,
    this.clusterId,
    this.clusterLabel,
    this.momentumScore,
    this.isEmergent = false,
    this.onTap,
  });

  bool get _shouldShow => clusterId != null && (isEmergent || (momentumScore ?? 0) > 0.7);

  @override
  Widget build(BuildContext context) {
    if (!_shouldShow) return const SizedBox.shrink();

    final badgeColor = _getBadgeColor();
    final badgeText = _getBadgeText();
    final badgeIcon = _getBadgeIcon();

    Widget badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: badgeColor.withOpacity(0.3),
            offset: const Offset(0, 2),
            blurRadius: 4,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(badgeIcon, size: 12, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            badgeText,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );

    if (onTap != null) {
      badge = GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap!();
        },
        child: badge,
      );
    }

    return Tooltip(
      message: clusterLabel ?? 'Nicho em tendência',
      child: badge,
    );
  }

  Color _getBadgeColor() {
    if (isEmergent) return const Color(0xFFFF6B35); // Laranja vibrante
    if ((momentumScore ?? 0) > 0.8) return const Color(0xFF10B981); // Verde
    return const Color(0xFF3B82F6); // Azul
  }

  String _getBadgeText() {
    if (isEmergent) return 'NOVO';
    if ((momentumScore ?? 0) > 0.8) return 'EM ALTA';
    return 'TRENDING';
  }

  IconData _getBadgeIcon() {
    if (isEmergent) return Icons.new_releases;
    return Icons.trending_up;
  }
} 