import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../domain/entities/business_context.dart';
import '../../../../../shared/utils/app_colors.dart';

/// Seção de contexto comercial do caso na visão do advogado
/// Fornece análise financeira, de risco e estratégica
/// Equivalente à PreAnalysisSection que o cliente vê
class BusinessContextSection extends StatelessWidget {
  final BusinessContext businessContext;
  final VoidCallback? onViewDetails;

  const BusinessContextSection({
    super.key,
    required this.businessContext,
    this.onViewDetails,
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
          color: theme.colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.1),
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
            _buildFinancialOverview(theme),
            const SizedBox(height: 16),
            _buildComplexityAnalysis(theme),
            const SizedBox(height: 16),
            _buildRiskAnalysis(theme),
            const SizedBox(height: 16),
            _buildOpportunityAnalysis(theme),
            if ((businessContext.clientUrgency - businessContext.realUrgency).abs() > 20) ...[
              const SizedBox(height: 16),
              _buildUrgencyAlert(theme),
            ],
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
            color: AppColors.success.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            LucideIcons.trendingUp,
            color: AppColors.success,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Análise Comercial',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Viabilidade e potencial do caso',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
        _buildViabilityIndicator(theme),
      ],
    );
  }

  Widget _buildViabilityIndicator(ThemeData theme) {
    final isViable = businessContext.isProfitable;
    final color = isViable ? Colors.green : Colors.orange;
    final text = isViable ? 'Viável' : 'Avaliar';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildFinancialOverview(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                LucideIcons.dollarSign,
                size: 16,
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
              const SizedBox(width: 8),
              Text(
                'Projeção Financeira',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildFinancialMetric(
                theme,
                label: 'Valor Estimado',
                value: 'R\$ ${businessContext.estimatedValue.toStringAsFixed(2)}',
                icon: LucideIcons.banknote,
                color: Colors.green,
              ),
              const SizedBox(width: 12),
              _buildFinancialMetric(
                theme,
                label: 'ROI Projetado',
                value: '${businessContext.roiProjection.toStringAsFixed(1)}%',
                icon: LucideIcons.trendingUp,
                color: _getROIColor(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildFinancialMetric(
                theme,
                label: 'Duração',
                value: businessContext.estimatedDurationFormatted,
                icon: LucideIcons.clock,
                color: Colors.blue,
              ),
              const SizedBox(width: 12),
              _buildFinancialMetric(
                theme,
                label: 'Horas Est.',
                value: '${businessContext.expectedHours.toInt()}h',
                icon: LucideIcons.timer,
                color: Colors.purple,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialMetric(
    ThemeData theme, {
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: theme.colorScheme.outline.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 14, color: color),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComplexityAnalysis(ThemeData theme) {
    final complexityColor = _getComplexityColor();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: complexityColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: complexityColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                LucideIcons.layers,
                size: 16,
                color: complexityColor,
              ),
              const SizedBox(width: 8),
              Text(
                'Análise de Complexidade',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: complexityColor,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: complexityColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  businessContext.complexityLevel,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: complexityColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Dificuldade: ${businessContext.difficultyLevel.toUpperCase()}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          if (businessContext.complexityFactors.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Fatores: ${businessContext.complexityFactors.take(3).join(', ')}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRiskAnalysis(ThemeData theme) {
    final riskColor = _getRiskColor();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: riskColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: riskColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                LucideIcons.shield,
                size: 16,
                color: riskColor,
              ),
              const SizedBox(width: 8),
              Text(
                'Análise de Risco',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: riskColor,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: riskColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  businessContext.riskProfile.riskLevel,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: riskColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildRiskMetric(
                theme,
                'Jurídico',
                businessContext.riskProfile.legalRisk,
                Colors.red,
              ),
              const SizedBox(width: 8),
              _buildRiskMetric(
                theme,
                'Financeiro',
                businessContext.riskProfile.financialRisk,
                Colors.orange,
              ),
              const SizedBox(width: 8),
              _buildRiskMetric(
                theme,
                'Cliente',
                businessContext.riskProfile.clientRisk,
                Colors.blue,
              ),
            ],
          ),
          if (businessContext.riskProfile.riskSummary.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              businessContext.riskProfile.riskSummary,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRiskMetric(ThemeData theme, String label, double value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            '${value.toInt()}%',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOpportunityAnalysis(ThemeData theme) {
    final hasOpportunities = businessContext.expansionPotential >= 50 || 
                              businessContext.upsellOpportunities.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primaryPurple.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primaryPurple.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                LucideIcons.zap,
                size: 16,
                color: AppColors.primaryPurple,
              ),
              const SizedBox(width: 8),
              Text(
                'Potencial de Expansão',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryPurple,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primaryPurple.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${businessContext.expansionPotential.toInt()}%',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryPurple,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                hasOpportunities ? LucideIcons.checkCircle : LucideIcons.alertCircle,
                size: 14,
                color: hasOpportunities ? Colors.green : Colors.orange,
              ),
              const SizedBox(width: 4),
              Text(
                hasOpportunities ? 'Alto potencial identificado' : 'Potencial limitado',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
          if (businessContext.upsellOpportunities.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Oportunidades: ${businessContext.upsellOpportunities.take(2).join(', ')}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildUrgencyAlert(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.amber.withOpacity(0.4),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            LucideIcons.alertTriangle,
            color: Colors.amber.shade700,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Alerta de Urgência',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.amber.shade700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Há divergência entre urgência declarada (${businessContext.clientUrgency.toInt()}%) e real (${businessContext.realUrgency.toInt()}%)',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.8),
                  ),
                ),
              ],
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
        onPressed: onViewDetails ?? () => _showDetails(),
        icon: const Icon(LucideIcons.pieChart, size: 18),
        label: const Text('Ver Análise Completa'),
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

  Color _getROIColor() {
    if (businessContext.roiProjection >= 30) return Colors.green;
    if (businessContext.roiProjection >= 15) return Colors.orange;
    return Colors.red;
  }

  Color _getComplexityColor() {
    if (businessContext.complexityScore <= 25) return Colors.green;
    if (businessContext.complexityScore <= 50) return Colors.blue;
    if (businessContext.complexityScore <= 75) return Colors.orange;
    return Colors.red;
  }

  Color _getRiskColor() {
    final overall = businessContext.riskProfile.overallRisk;
    if (overall <= 30) return Colors.green;
    if (overall <= 60) return Colors.orange;
    return Colors.red;
  }

  void _showDetails() {
    // TODO: Implementar modal ou navegação para análise detalhada
  }
} 
