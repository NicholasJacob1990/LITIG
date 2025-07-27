import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../../shared/utils/app_colors.dart';
import '../../../domain/entities/match_analysis.dart';

/// Seção de análise de match para advogados
/// Contraparte da PreAnalysisSection que o cliente vê
/// Explica por que este caso chegou até o advogado e estratégia recomendada
class LawyerMatchAnalysisSection extends StatelessWidget {
  final MatchAnalysis analysis;
  final String lawyerRole;
  final VoidCallback? onViewStrategy;

  const LawyerMatchAnalysisSection({
    super.key,
    required this.analysis,
    required this.lawyerRole,
    this.onViewStrategy,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(theme),
            const SizedBox(height: 16),
            _buildMatchScore(theme),
            const SizedBox(height: 16),
            _buildMatchExplanation(theme),
            const SizedBox(height: 16),
            _buildStrengthsAndConsiderations(theme),
            const SizedBox(height: 16),
            _buildSpecificAnalysis(theme),
            const SizedBox(height: 16),
            _buildRecommendation(theme),
            const SizedBox(height: 20),
            _buildActionButton(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(ThemeData theme) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.info.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            LucideIcons.brain,
            color: AppColors.info,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Análise de Match',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                _getSubtitle(),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
        _buildMatchBadge(theme),
      ],
    );
  }

  String _getSubtitle() {
    switch (lawyerRole) {
      case 'lawyer_firm_member':
        return 'Por que foi delegado para você';
      case 'lawyer_platform_associate':
        return 'Algoritmo de match da plataforma';
      case 'lawyer_individual':
      case 'lawyer_office':
        return 'Análise de adequação comercial';
      default:
        return 'Análise de adequação ao caso';
    }
  }

  Widget _buildMatchBadge(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: analysis.matchColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: analysis.matchColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Text(
        analysis.matchLevel,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: analysis.matchColor,
        ),
      ),
    );
  }

  Widget _buildMatchScore(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: analysis.matchColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: analysis.matchColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Score visual
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: analysis.matchColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Center(
              child: Text(
                '${analysis.matchScore.toInt()}%',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: analysis.matchColor,
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
                  'Score de Adequação',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: analysis.matchColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Baseado em experiência, disponibilidade e especialização',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchExplanation(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                LucideIcons.lightbulb,
                size: 16,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              const SizedBox(width: 8),
              Text(
                'Por que este caso chegou até você?',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            analysis.matchReason,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStrengthsAndConsiderations(ThemeData theme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Pontos fortes
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.green.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      LucideIcons.checkCircle,
                      size: 16,
                      color: Colors.green,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Pontos Fortes',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...analysis.strengths.take(3).map((strength) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        LucideIcons.dot,
                        size: 12,
                        color: Colors.green,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          strength,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Pontos de atenção
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.orange.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      LucideIcons.alertCircle,
                      size: 16,
                      color: Colors.orange,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Atenção',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...analysis.considerations.take(3).map((consideration) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        LucideIcons.dot,
                        size: 12,
                        color: Colors.orange,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          consideration,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSpecificAnalysis(ThemeData theme) {
    switch (lawyerRole) {
      case 'lawyer_firm_member':
        return _buildInternalAnalysis(theme);
      case 'lawyer_platform_associate':
        return _buildAlgorithmAnalysis(theme);
      case 'lawyer_individual':
      case 'lawyer_office':
        return _buildBusinessAnalysis(theme);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildInternalAnalysis(ThemeData theme) {
    final internal = analysis as InternalMatchAnalysis;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primaryBlue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primaryBlue.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                LucideIcons.users,
                size: 16,
                color: AppColors.primaryBlue,
              ),
              const SizedBox(width: 8),
              Text(
                'Contexto de Delegação',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildInfoRow(theme, 'Delegado por', internal.delegatedBy),
          _buildInfoRow(theme, 'Objetivos', internal.learningObjectives),
          if (internal.supervisorNotes.isNotEmpty)
            _buildInfoRow(theme, 'Orientações', internal.supervisorNotes),
        ],
      ),
    );
  }

  Widget _buildAlgorithmAnalysis(ThemeData theme) {
    final algorithm = analysis as AlgorithmMatchAnalysis;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primaryPurple.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primaryPurple.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                LucideIcons.cpu,
                size: 16,
                color: AppColors.primaryPurple,
              ),
              const SizedBox(width: 8),
              Text(
                'Análise do Algoritmo',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryPurple,
                ),
              ),
              const Spacer(),
              Text(
                'Score: ${algorithm.algorithmScore.toInt()}%',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryPurple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            algorithm.matchExplanation,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          if (algorithm.competitors.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildInfoRow(theme, 'Concorrentes', algorithm.competitors.take(2).join(', ')),
          ],
          _buildInfoRow(theme, 'Conversão esperada', '${algorithm.conversionRate.toInt()}%'),
        ],
      ),
    );
  }

  Widget _buildBusinessAnalysis(ThemeData theme) {
    final business = analysis as BusinessMatchAnalysis;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.success.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                LucideIcons.trendingUp,
                size: 16,
                color: AppColors.success,
              ),
              const SizedBox(width: 8),
              Text(
                'Análise Comercial',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.success,
                ),
              ),
              const Spacer(),
              Text(
                'Fit: ${business.businessFit.toInt()}%',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildInfoRow(theme, 'Origem', _getCaseSourceLabel(business.caseSource)),
          _buildInfoRow(theme, 'Custo aquisição', business.acquisitionCost),
          _buildInfoRow(theme, 'Score lucratividade', '${business.profitabilityScore.toInt()}%'),
          if (business.upsellOpportunities.isNotEmpty)
            _buildInfoRow(theme, 'Oportunidades', business.upsellOpportunities.take(2).join(', ')),
        ],
      ),
    );
  }

  Widget _buildInfoRow(ThemeData theme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendation(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.warning.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                LucideIcons.target,
                size: 16,
                color: AppColors.warning,
              ),
              const SizedBox(width: 8),
              Text(
                'Estratégia Recomendada',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.warning,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            analysis.recommendation,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(ThemeData theme) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onViewStrategy ?? () => _showStrategy(),
        icon: const Icon(LucideIcons.compass, size: 18),
        label: const Text('Ver Estratégia Detalhada'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryBlue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  String _getCaseSourceLabel(String source) {
    switch (source) {
      case 'algorithm':
        return 'Via Algoritmo';
      case 'direct_capture':
        return 'Captação Direta';
      case 'partnership':
        return 'Parceria';
      case 'referral':
        return 'Indicação';
      default:
        return source;
    }
  }

  void _showStrategy() {
    // TODO: Implementar modal ou navegação para estratégia detalhada
  }
} 