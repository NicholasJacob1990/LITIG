import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class LawyerMatchCard extends StatelessWidget {
  final Map<String, dynamic> lawyer;
  final VoidCallback onSelect;
  final VoidCallback onExplain;

  const LawyerMatchCard({
    super.key,
    required this.lawyer,
    required this.onSelect,
    required this.onExplain,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final score = (lawyer['fair'] as num? ?? 0.0) * 100;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundImage: lawyer['avatar_url'] != null ? NetworkImage(lawyer['avatar_url']) : null,
                  child: lawyer['avatar_url'] == null ? const Icon(LucideIcons.user, size: 30) : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lawyer['nome'] ?? 'Advogado',
                        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        lawyer['primary_area'] ?? 'Especialista',
                        style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.primary),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${score.toStringAsFixed(0)}%',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Compatibilidade',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
            const Divider(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildInfoChip(
                  context,
                  icon: LucideIcons.star,
                  label: '${lawyer['rating']?.toStringAsFixed(1) ?? 'N/A'} Avaliação',
                ),
                _buildInfoChip(
                  context,
                  icon: LucideIcons.mapPin,
                  label: lawyer['distance_km'] != null ? '${(lawyer['distance_km'] as num).toStringAsFixed(1)} km' : 'N/A',
                ),
                _buildInfoChip(
                  context,
                  icon: lawyer['is_available'] ? LucideIcons.checkCircle : LucideIcons.xCircle,
                  label: lawyer['is_available'] ? 'Disponível' : 'Indisponível',
                  iconColor: lawyer['is_available'] ? Colors.green : Colors.red,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onExplain,
                    icon: const Icon(LucideIcons.helpCircle, size: 16),
                    label: const Text('Por que este advogado?'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onSelect,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Selecionar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(BuildContext context, {required IconData icon, required String label, Color? iconColor}) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 16, color: iconColor ?? theme.textTheme.bodySmall?.color),
        const SizedBox(width: 4),
        Text(label, style: theme.textTheme.bodySmall),
      ],
    );
  }
} 