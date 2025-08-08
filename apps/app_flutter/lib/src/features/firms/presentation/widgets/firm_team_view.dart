import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../domain/entities/enriched_firm.dart';

class FirmTeamView extends StatelessWidget {
  final String firmId;
  final EnrichedFirm enrichedFirm;

  const FirmTeamView({
    super.key,
    required this.firmId,
    required this.enrichedFirm,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTeamOverview(context),
          const SizedBox(height: 24),
          _buildSpecialistsByArea(context),
          const SizedBox(height: 24),
          _buildTeamAchievements(context),
        ],
      ),
    );
  }

  Widget _buildTeamOverview(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  LucideIcons.users,
                  size: 24,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Visão Geral da Equipe',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 2.5,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: [
                _buildTeamMetricCard(
                  'Total de Advogados',
                  '${enrichedFirm.teamData.totalLawyers}',
                  Colors.blue,
                ),
                _buildTeamMetricCard(
                  'Sócios',
                  '${enrichedFirm.teamData.partnersCount}',
                  Colors.purple,
                ),
                _buildTeamMetricCard(
                  'Associados',
                  '${enrichedFirm.teamData.associatesCount}',
                  Colors.green,
                ),
                _buildTeamMetricCard(
                  'Especialistas',
                  '${enrichedFirm.teamData.specialistsCount}',
                  Colors.orange,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamMetricCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Seções de sócios e associados removidas temporariamente por ausência desses
  // dados na entidade atual. Reintroduzir quando a API expuser estas listas.

  Widget _buildSpecialistsByArea(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Especialistas por Área',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (enrichedFirm.teamData.stats.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Icon(
                        LucideIcons.users,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Informações de especialização em breve',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...enrichedFirm.teamData.stats.entries.map((entry) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _getAreaColor(entry.key).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _getAreaIcon(entry.key),
                        color: _getAreaColor(entry.key),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.key,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            '${entry.value} especialistas',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getAreaColor(entry.key).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${entry.value}',
                        style: TextStyle(
                          color: _getAreaColor(entry.key),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamAchievements(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  LucideIcons.trophy,
                  size: 20,
                  color: Colors.amber,
                ),
                const SizedBox(width: 8),
                Text(
                  'Conquistas da Equipe',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildAchievementItem(
              'Taxa de Sucesso da Equipe',
              '${(enrichedFirm.caseSuccessRate * 100).toInt()}%',
              LucideIcons.trendingUp,
              Colors.green,
            ),
            const SizedBox(height: 12),
            _buildAchievementItem(
              'Avaliação Média',
              '${enrichedFirm.rating.toStringAsFixed(1)} ⭐',
              LucideIcons.star,
              Colors.amber,
            ),
            const SizedBox(height: 12),
            _buildAchievementItem(
              'Tempo Médio de Resposta',
              '${enrichedFirm.averageResponseTime.inHours}h',
              LucideIcons.clock,
              Colors.blue,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievementItem(String title, String value, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getAreaColor(String area) {
    switch (area.toLowerCase()) {
      case 'direito civil':
        return Colors.blue;
      case 'direito penal':
        return Colors.red;
      case 'direito trabalhista':
        return Colors.green;
      case 'direito empresarial':
        return Colors.purple;
      case 'direito tributário':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getAreaIcon(String area) {
    switch (area.toLowerCase()) {
      case 'direito civil':
        return LucideIcons.home;
      case 'direito penal':
        return LucideIcons.gavel;
      case 'direito trabalhista':
        return LucideIcons.users;
      case 'direito empresarial':
        return LucideIcons.building;
      case 'direito tributário':
        return LucideIcons.calculator;
      default:
        return LucideIcons.briefcase;
    }
  }

  // Secções detalhadas e navegação de perfis serão reintroduzidas quando a API expuser listas de membros.
} 