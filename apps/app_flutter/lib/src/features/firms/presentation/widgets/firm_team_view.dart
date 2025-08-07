import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../domain/entities/enriched_firm.dart';
import '../../../lawyers/domain/entities/enriched_lawyer.dart';

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
          if (enrichedFirm.partners.isNotEmpty) ...[
            _buildPartnersSection(context),
            const SizedBox(height: 24),
          ],
          if (enrichedFirm.associates.isNotEmpty) ...[
            _buildAssociatesSection(context),
            const SizedBox(height: 24),
          ],
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
                  '${enrichedFirm.totalLawyers}',
                  Colors.blue,
                ),
                _buildTeamMetricCard(
                  'Sócios',
                  '${enrichedFirm.partnersCount}',
                  Colors.purple,
                ),
                _buildTeamMetricCard(
                  'Associados',
                  '${enrichedFirm.associatesCount}',
                  Colors.green,
                ),
                _buildTeamMetricCard(
                  'Especialistas',
                  '${enrichedFirm.specialistsCount}',
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

  Widget _buildPartnersSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  LucideIcons.crown,
                  size: 20,
                  color: Colors.amber,
                ),
                const SizedBox(width: 8),
                Text(
                  'Sócios do Escritório',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (enrichedFirm.partners.length > 3)
                  TextButton(
                    onPressed: () => _viewAllPartners(context),
                    child: const Text('Ver Todos'),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            ...enrichedFirm.partners.take(3).map((partner) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _buildLawyerListTile(context, partner, true),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildAssociatesSection(BuildContext context) {
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
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Advogados Associados',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (enrichedFirm.associates.length > 3)
                  TextButton(
                    onPressed: () => _viewAllAssociates(context),
                    child: const Text('Ver Todos'),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            ...enrichedFirm.associates.take(3).map((associate) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _buildLawyerListTile(context, associate, false),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildLawyerListTile(BuildContext context, EnrichedLawyer lawyer, bool isPartner) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Stack(
        children: [
          CircleAvatar(
            backgroundImage: lawyer.avatarUrl.isNotEmpty ? NetworkImage(lawyer.avatarUrl) : null,
            child: lawyer.avatarUrl.isEmpty ? const Icon(LucideIcons.user) : null,
            radius: 24,
            onBackgroundImageError: (exception, stackTrace) {},
            child: lawyer.avatarUrl.isEmpty
                ? const Icon(LucideIcons.user, size: 20)
                : null,
          ),
          if (isPartner)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: Colors.amber,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(
                  LucideIcons.crown,
                  size: 8,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
      title: Text(
        lawyer.nome,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (lawyer.especialidades.isNotEmpty)
            Text(lawyer.especialidades.first),
          Row(
            children: [
              if (lawyer.linkedinProfile != null) ...[
                const Icon(Icons.star, size: 16, color: Colors.amber),
                Text(' ${(lawyer.fair * 10).toStringAsFixed(1)}'),
                const SizedBox(width: 16),
              ],
              Text('Match: ${(lawyer.fair * 100).toInt()}%'),
            ],
          ),
        ],
      ),
      trailing: OutlinedButton(
        onPressed: () => _viewLawyerProfile(context, lawyer.id),
        child: const Text('Ver Perfil'),
      ),
    );
  }

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
            if (enrichedFirm.specialistsByArea.isEmpty)
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
              ...enrichedFirm.specialistsByArea.entries.map((entry) => Padding(
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
              '${(enrichedFirm.stats.successRate * 100).toInt()}%',
              LucideIcons.trendingUp,
              Colors.green,
            ),
            const SizedBox(height: 12),
            _buildAchievementItem(
              'Avaliação Média',
              '${enrichedFirm.stats.averageRating.toStringAsFixed(1)} ⭐',
              LucideIcons.star,
              Colors.amber,
            ),
            const SizedBox(height: 12),
            _buildAchievementItem(
              'Tempo Médio de Resposta',
              '${enrichedFirm.stats.averageResponseTime.toInt()}h',
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

  void _viewAllPartners(BuildContext context) {
    // TODO: Implementar visualização de todos os sócios
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Visualização completa de sócios em desenvolvimento'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _viewAllAssociates(BuildContext context) {
    // TODO: Implementar visualização de todos os associados
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Visualização completa de associados em desenvolvimento'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _viewLawyerProfile(BuildContext context, String lawyerId) {
    context.push('/lawyer/$lawyerId/profile');
  }
} 