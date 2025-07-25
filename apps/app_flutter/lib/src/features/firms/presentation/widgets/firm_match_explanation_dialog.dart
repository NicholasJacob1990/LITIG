import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../domain/entities/law_firm.dart';

class FirmMatchExplanationDialog extends StatelessWidget {
  final LawFirm firm;
  final VoidCallback? onViewFullProfile;

  const FirmMatchExplanationDialog({
    super.key,
    required this.firm,
    this.onViewFullProfile,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 650),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(context),
            const SizedBox(height: 20),
            _buildFirmCompatibilityScore(context),
            const SizedBox(height: 20),
            _buildFirmStrengths(context),
            const SizedBox(height: 20),
            _buildTeamCompatibility(context),
            const SizedBox(height: 20),
            _buildMatchFactors(context),
            const SizedBox(height: 24),
            _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            LucideIcons.building,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Por que ${firm.name} foi recomendado?',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Análise da compatibilidade do escritório',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(LucideIcons.x),
        ),
      ],
    );
  }

  Widget _buildFirmCompatibilityScore(BuildContext context) {
    final compatibility = firm.kpis?.overallScore ?? 0.0;
    final percentage = (compatibility * 10).toInt(); // Converter para escala 0-100
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _getScoreColor(compatibility).withValues(alpha: 0.1),
            _getScoreColor(compatibility).withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _getScoreColor(compatibility).withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: _getScoreColor(compatibility),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Center(
              child: Text(
                '$percentage%',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Compatibilidade do Escritório',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _getFirmCompatibilityText(compatibility),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFirmStrengths(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pontos Fortes do Escritório',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        _buildStrengthItem(
          'Tamanho da Equipe',
          firm.teamSize > 0 ? firm.teamSize / 100.0 : 0.5,
          LucideIcons.users,
          '${firm.teamSize} profissionais qualificados',
        ),
        _buildStrengthItem(
          'Reputação',
          firm.kpis?.reputationScore != null ? firm.kpis!.reputationScore / 100.0 : 0.7,
          LucideIcons.star,
          'Excelente reputação no mercado',
        ),
        _buildStrengthItem(
          'Especialização',
          0.9,
          LucideIcons.target,
          'Altamente especializado na área',
        ),
        if (firm.hasLocation)
          _buildStrengthItem(
            'Localização',
            0.85,
            LucideIcons.mapPin,
            'Localização estratégica',
          ),
      ],
    );
  }

  Widget _buildStrengthItem(String title, double score, IconData icon, String description) {
    final color = _getScoreColor(score);
    final percentage = (score * 100).toInt();
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
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
                Row(
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '$percentage%',
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamCompatibility(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(LucideIcons.users, size: 20, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Compatibilidade da Equipe',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Este escritório possui profissionais com o perfil ideal para seu caso:',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            if (firm.kpis?.topAreas != null && firm.kpis!.topAreas.isNotEmpty)
              ...firm.kpis!.topAreas.take(3).map((area) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, size: 16, color: Colors.green),
                    const SizedBox(width: 8),
                    Text('Especialistas em $area'),
                  ],
                ),
              ))
            else
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, size: 16, color: Colors.green),
                    const SizedBox(width: 8),
                    Text('Equipe altamente qualificada'),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMatchFactors(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(LucideIcons.brain, size: 20, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Fatores de Recomendação',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildFactorItem('Histórico de Casos', 'Casos similares resolvidos com sucesso'),
            _buildFactorItem('Experiência da Equipe', 'Profissionais especializados na área'),
            _buildFactorItem('Avaliações', 'Excelentes avaliações de clientes anteriores'),
            if (firm.hasLocation)
              _buildFactorItem('Proximidade', 'Localização conveniente para atendimento'),
          ],
        ),
      ),
    );
  }

  Widget _buildFactorItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4,
            height: 4,
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onViewFullProfile,
            icon: const Icon(LucideIcons.building),
            label: const Text('Ver Perfil Completo'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Implementar contratação do escritório
            },
            icon: const Icon(LucideIcons.handshake),
            label: const Text('Contratar'),
          ),
        ),
      ],
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 0.8) return Colors.green;
    if (score >= 0.6) return Colors.orange;
    return Colors.red;
  }

  String _getFirmCompatibilityText(double score) {
    if (score >= 8.0) return 'Excelente compatibilidade com suas necessidades';
    if (score >= 6.0) return 'Boa compatibilidade com seu caso';
    if (score >= 4.0) return 'Compatibilidade moderada';
    return 'Compatibilidade básica';
  }
} 