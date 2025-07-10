import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:meu_app/src/features/lawyers/domain/entities/matched_lawyer.dart';

class LawyerMatchCard extends StatelessWidget {
  final MatchedLawyer lawyer;
  final VoidCallback? onSelect;
  final VoidCallback? onExplain;

  const LawyerMatchCard({
    super.key,
    required this.lawyer,
    this.onSelect,
    this.onExplain,
  });

  Color _getMatchColor(double score) {
    if (score >= 0.8) return Colors.green.shade400;
    if (score >= 0.6) return Colors.amber.shade400;
    return Colors.red.shade400;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final matchColor = _getMatchColor(lawyer.score);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundImage: CachedNetworkImageProvider(lawyer.avatarUrl),
                  backgroundColor: theme.colorScheme.surface,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(lawyer.nome, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(lawyer.expertiseAreas.join(', '), style: theme.textTheme.bodyMedium),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: matchColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: matchColor, width: 1),
                  ),
                  child: Text(
                    '${(lawyer.score * 100).toInt()}%',
                    style: theme.textTheme.titleSmall?.copyWith(color: matchColor, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                if (lawyer.rating != null)
                  _buildInfoChip(context, icon: LucideIcons.star, text: '${lawyer.rating}', color: Colors.amber),
                _buildInfoChip(context, icon: LucideIcons.mapPin, text: '${lawyer.distanceKm} km'),
                if (lawyer.estimatedResponseTimeHours != null)
                  _buildInfoChip(context, icon: LucideIcons.timer, text: '${lawyer.estimatedResponseTimeHours}h resp.'),
              ],
            ),
            if (onSelect != null || onExplain != null) ...[
              const Divider(height: 32),
              Row(
                children: [
                  if (onExplain != null)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: onExplain,
                        child: const Text('Explicar Match'),
                      ),
                    ),
                  if (onExplain != null && onSelect != null) const SizedBox(width: 12),
                  if (onSelect != null)
                    Expanded(
                      child: ElevatedButton(
                        onPressed: onSelect,
                        child: const Text('Selecionar'),
                      ),
                    ),
                ],
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(BuildContext context, {required IconData icon, required String text, Color? color}) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 16, color: color ?? theme.colorScheme.onSurface.withOpacity(0.7)),
        const SizedBox(width: 6),
        Text(text, style: theme.textTheme.bodyMedium),
      ],
    );
  }
} 