import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart' as lucide;
import 'package:meu_app/src/features/lawyers/domain/entities/matched_lawyer.dart';
import 'package:meu_app/src/features/lawyers/presentation/widgets/lawyer_social_links.dart';

class LawyerMatchCard extends StatelessWidget {
  final MatchedLawyer lawyer;
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
    final score = lawyer.fair * 100;

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
                  backgroundImage: lawyer.avatarUrl != null ? CachedNetworkImageProvider(lawyer.avatarUrl) : null,
                  child: lawyer.avatarUrl == null ? const Icon(lucide.LucideIcons.user, size: 30) : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lawyer.nome,
                        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        lawyer.primaryArea,
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
            
            const Divider(height: 24),

            // Experiência e Prêmios
            _buildExperienceAndAwards(context),

            const Divider(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildInfoChip(
                  context,
                  icon: lucide.LucideIcons.star,
                  label: '${lawyer.rating?.toStringAsFixed(1) ?? 'N/A'} Avaliação',
                ),
                _buildInfoChip(
                  context,
                  icon: lucide.LucideIcons.mapPin,
                  label: '${lawyer.distanceKm.toStringAsFixed(1) ?? 'N/A'} km',
                ),
                _buildInfoChip(
                  context,
                  icon: lawyer.isAvailable ? lucide.LucideIcons.checkCircle : lucide.LucideIcons.xCircle,
                  label: lawyer.isAvailable ? 'Disponível' : 'Indisponível',
                  iconColor: lawyer.isAvailable ? Colors.green : Colors.red,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onExplain,
                    icon: const Icon(lucide.LucideIcons.helpCircle, size: 16),
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

  Widget _buildExperienceAndAwards(BuildContext context) {
    final theme = Theme.of(context);
    final experienceYears = lawyer.experienceYears;
    final awards = lawyer.awards;
    final professionalSummary = lawyer.professionalSummary;

    if ((experienceYears ?? 0) == 0 && (awards.isEmpty)) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if ((experienceYears ?? 0) > 0)
              Row(
                children: [
                  Icon(lucide.LucideIcons.briefcase, size: 16, color: theme.colorScheme.onSurface.withOpacity(0.7)),
                  const SizedBox(width: 8),
                  Text('$experienceYears anos de experiência', style: theme.textTheme.bodyMedium),
                ],
              ),
            if (professionalSummary != null && professionalSummary.isNotEmpty)
              TextButton(
                onPressed: () => _showCurriculumModal(context),
                child: const Text('Ver Perfil Completo'),
              ),
          ],
        ),
        if (awards.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: awards.take(3).map((award) => Chip(
              avatar: const Icon(lucide.LucideIcons.award, size: 14, color: Colors.amber),
              label: Text(award, style: theme.textTheme.labelSmall),
              backgroundColor: Colors.amber.withOpacity(0.1),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            )).toList(),
          ),
        ],
      ],
    );
  }

  void _showCurriculumModal(BuildContext context) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Perfil - ${lawyer.nome}', style: theme.textTheme.headlineSmall),
                      IconButton(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.close)),
                    ],
                  ),
                  const Divider(height: 24),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildModalSection(theme, title: 'Resumo Profissional', content: lawyer.professionalSummary),
                          _buildModalSection(theme, title: 'Experiência', content: '${lawyer.experienceYears ?? 0} anos'),
                          _buildModalSection(theme, title: 'Prêmios e Reconhecimentos', items: lawyer.awards),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildModalSection(ThemeData theme, {required String title, String? content, List<String>? items}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        if (content != null && content.isNotEmpty) Text(content, style: theme.textTheme.bodyLarge),
        if (items != null && items.isNotEmpty)
          ...items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text('• $item', style: theme.textTheme.bodyMedium),
          )),
        const SizedBox(height: 24),
      ],
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