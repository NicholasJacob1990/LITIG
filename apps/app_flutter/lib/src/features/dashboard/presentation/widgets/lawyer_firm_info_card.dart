import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart' as lucide;
import 'package:meu_app/src/features/firms/domain/entities/law_firm.dart';

class LawyerFirmInfoCard extends StatelessWidget {
  final LawFirm firm;
  final bool hasActiveCases;
  final int totalCases;

  const LawyerFirmInfoCard({
    super.key,
    required this.firm,
    this.hasActiveCases = false,
    this.totalCases = 0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final kpis = firm.kpis;
    
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: () => context.push('/firm/${firm.id}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header com nome e ação
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      lucide.LucideIcons.building,
                      color: theme.colorScheme.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          firm.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (firm.hasLocation) ...[
                          const SizedBox(height: 2),
                          Text(
                            'Localização: ${firm.mainLat?.toStringAsFixed(4)}, ${firm.mainLon?.toStringAsFixed(4)}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(lucide.LucideIcons.externalLink),
                    onPressed: () => context.push('/firm/${firm.id}'),
                    tooltip: 'Ver detalhes do escritório',
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Estatísticas básicas
              Row(
                children: [
                  _buildStatItem(
                    context,
                    icon: lucide.LucideIcons.users,
                    label: 'Advogados',
                    value: '${firm.teamSize ?? 0}',
                  ),
                  const SizedBox(width: 24),
                  _buildStatItem(
                    context,
                    icon: lucide.LucideIcons.briefcase,
                    label: 'Meus Casos',
                    value: '$totalCases',
                  ),
                  const SizedBox(width: 24),
                  _buildStatItem(
                    context,
                    icon: lucide.LucideIcons.activity,
                    label: 'Status',
                    value: hasActiveCases ? 'Ativo' : 'Inativo',
                    valueColor: hasActiveCases ? Colors.green : Colors.orange,
                  ),
                ],
              ),
              
              if (kpis != null) ...[
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 12),
                
                // KPIs do escritório
                Text(
                  'Performance do Escritório',
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                
                Row(
                  children: [
                    Expanded(
                      child: _buildKpiItem(
                        context,
                        label: 'Taxa de Sucesso',
                        value: '${(kpis.successRate * 100).toStringAsFixed(1)}%',
                        color: _getSuccessRateColor(kpis.successRate),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildKpiItem(
                        context,
                        label: 'NPS',
                        value: (kpis.nps * 100).toStringAsFixed(0),
                        color: _getNpsColor(kpis.nps),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                Row(
                  children: [
                    Expanded(
                      child: _buildKpiItem(
                        context,
                        label: 'Reputação',
                        value: (kpis.reputationScore * 100).toStringAsFixed(0),
                        color: _getReputationColor(kpis.reputationScore),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildKpiItem(
                        context,
                        label: 'Diversidade',
                        value: (kpis.diversityIndex * 100).toStringAsFixed(0),
                        color: _getDiversityColor(kpis.diversityIndex),
                      ),
                    ),
                  ],
                ),
              ],
              
              const SizedBox(height: 16),
              
              // Ações rápidas
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => context.push('/firm/${firm.id}'),
                      icon: const Icon(lucide.LucideIcons.eye, size: 16),
                      label: const Text('Ver Detalhes'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => context.push('/firm/${firm.id}/lawyers'),
                      icon: const Icon(lucide.LucideIcons.users, size: 16),
                      label: const Text('Colegas'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    final theme = Theme.of(context);
    
    return Column(
      children: [
        Icon(
          icon,
          size: 16,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: valueColor ?? theme.colorScheme.onSurface,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildKpiItem(
    BuildContext context, {
    required String label,
    required String value,
    required Color color,
  }) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Color _getSuccessRateColor(double rate) {
    if (rate >= 0.8) return Colors.green;
    if (rate >= 0.6) return Colors.orange;
    return Colors.red;
  }

  Color _getNpsColor(double nps) {
    if (nps >= 0.7) return Colors.green;
    if (nps >= 0.5) return Colors.orange;
    return Colors.red;
  }

  Color _getReputationColor(double reputation) {
    if (reputation >= 0.8) return Colors.blue;
    if (reputation >= 0.6) return Colors.orange;
    return Colors.red;
  }

  Color _getDiversityColor(double diversity) {
    if (diversity >= 0.7) return Colors.purple;
    if (diversity >= 0.5) return Colors.orange;
    return Colors.red;
  }
} 