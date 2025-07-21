import 'package:flutter/material.dart';
import '../base_info_section.dart';

/// Seção de Análise de Complexidade para advogados contratantes
/// 
/// **Contexto:** Advogados individuais e escritórios contratantes
/// **Substituição:** PreAnalysisSection (experiência do cliente)
/// **Foco:** Análise de complexidade, viabilidade financeira e estimativas técnicas
/// 
/// Conforme PLANO_DE_ACAO_CONTEXTUAL_VIEW.md:
/// - Substituir PreAnalysisSection para advogados contratantes
/// - Foco em oportunidade de negócio e análise de viabilidade
class CaseComplexitySection extends BaseInfoSection {
  @override
  final Map<String, dynamic>? contextualData;

  const CaseComplexitySection({
    required super.caseDetail,
    this.contextualData,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return buildSectionCard(
      context,
      title: 'Análise de Complexidade',
      children: [
        _buildComplexityAnalysis(context),
        const SizedBox(height: 16),
        _buildTechnicalRequirements(context),
        const SizedBox(height: 16),
        _buildFinancialViability(context),
        const SizedBox(height: 16),
        _buildRiskAssessment(context),
        const SizedBox(height: 20),
        _buildRecommendations(context),
      ],
    );
  }

  Widget _buildComplexityAnalysis(BuildContext context) {
    final complexityScore = contextualData?['complexity_score'] ?? 7;
    final estimatedHours = contextualData?['estimated_hours'] ?? 45;
    final specialtyRequired = contextualData?['specialty_required'] ?? 'Trabalhista + Tributário';
    final precedentExists = contextualData?['precedent_exists'] ?? true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Nível de Complexidade',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.orange[700],
          ),
        ),
        const SizedBox(height: 12),
        
        // Score de complexidade visual
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _getComplexityColor(complexityScore).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _getComplexityColor(complexityScore).withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(
                    _getComplexityIcon(complexityScore),
                    color: _getComplexityColor(complexityScore),
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Complexidade: $complexityScore/10',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: _getComplexityColor(complexityScore),
                          ),
                        ),
                        Text(
                          _getComplexityLabel(complexityScore),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getComplexityColor(complexityScore),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      '${estimatedHours}h',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Barra de complexidade
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: complexityScore / 10,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _getComplexityColor(complexityScore),
                  ),
                  minHeight: 8,
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 12),
        
        // Informações técnicas
        Row(
          children: [
            Expanded(
              child: buildInfoRow(
                context,
                Icons.psychology_outlined,
                'Especialização',
                specialtyRequired,
              ),
            ),
          ],
        ),
        
        buildInfoRow(
          context,
          precedentExists ? Icons.check_circle_outline : Icons.warning_outlined,
          'Precedentes',
          precedentExists ? 'Jurisprudência favorável' : 'Caso inovador',
          iconColor: precedentExists ? Colors.green : Colors.orange,
        ),
      ],
    );
  }

  Widget _buildTechnicalRequirements(BuildContext context) {
    final documentsNeeded = contextualData?['documents_needed'] ?? [
      'Contrato de Trabalho',
      'Holerites dos últimos 12 meses',
      'CTPS digitalizada',
      'Termo de rescisão'
    ];
    final expertsNeeded = contextualData?['experts_needed'] ?? [];
    final researchTime = contextualData?['research_time'] ?? 8;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Requisitos Técnicos',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.orange[700],
          ),
        ),
        const SizedBox(height: 12),
        
        // Documentos necessários
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue[25],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue[100]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.description_outlined, color: Colors.blue[600], size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Documentos Necessários',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.blue[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...documentsNeeded.map<Widget>((doc) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '• $doc',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              )).toList(),
            ],
          ),
        ),
        
        const SizedBox(height: 12),
        
        // Requisitos de pesquisa e expertise
        Row(
          children: [
            Expanded(
              child: buildInfoRow(
                context,
                Icons.search_outlined,
                'Pesquisa prévia',
                '${researchTime}h estimadas',
              ),
            ),
            if (expertsNeeded.isNotEmpty)
              Expanded(
                child: buildInfoRow(
                  context,
                  Icons.people_outline,
                  'Consultores',
                  '${expertsNeeded.length} especialistas',
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildFinancialViability(BuildContext context) {
    final estimatedValue = contextualData?['estimated_value'] ?? 8500.0;
    final hourlyRate = contextualData?['hourly_rate'] ?? 180.0;
    final estimatedHours = contextualData?['estimated_hours'] ?? 45;
    final profitMargin = ((estimatedValue - (hourlyRate * estimatedHours)) / estimatedValue * 100);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Viabilidade Financeira',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.orange[700],
          ),
        ),
        const SizedBox(height: 12),
        
        Row(
          children: [
            Expanded(
              child: _buildFinancialKPI(
                context,
                'Valor Estimado',
                'R\$ ${estimatedValue.toStringAsFixed(0)}',
                Icons.monetization_on_outlined,
                Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildFinancialKPI(
                context,
                'Custo Interno',
                'R\$ ${(hourlyRate * estimatedHours).toStringAsFixed(0)}',
                Icons.calculate_outlined,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildFinancialKPI(
                context,
                'Margem',
                '${profitMargin.toStringAsFixed(1)}%',
                Icons.trending_up_outlined,
                _getProfitMarginColor(profitMargin),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 12),
        
        // Análise de rentabilidade
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _getProfitMarginColor(profitMargin).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _getProfitMarginColor(profitMargin).withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(
                _getProfitMarginIcon(profitMargin),
                color: _getProfitMarginColor(profitMargin),
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _getProfitMarginLabel(profitMargin),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: _getProfitMarginColor(profitMargin),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFinancialKPI(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRiskAssessment(BuildContext context) {
    final riskLevel = contextualData?['risk_level'] ?? 'Médio';
    final successProbability = contextualData?['success_probability'] ?? 0.75;
    final mainRisks = contextualData?['main_risks'] ?? [
      'Jurisprudência em mudança',
      'Documentação incompleta',
      'Valor da causa pode ser questionado'
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Avaliação de Riscos',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.orange[700],
          ),
        ),
        const SizedBox(height: 12),
        
        Row(
          children: [
            Expanded(
              child: buildInfoRow(
                context,
                Icons.shield_outlined,
                'Nível de Risco',
                riskLevel,
                iconColor: _getRiskColor(riskLevel),
              ),
            ),
            Expanded(
              child: buildInfoRow(
                context,
                Icons.percent_outlined,
                'Prob. Sucesso',
                '${(successProbability * 100).toStringAsFixed(0)}%',
                iconColor: _getSuccessProbabilityColor(successProbability),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 12),
        
        // Lista de riscos principais
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.red[25],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.red[100]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.warning_outlined, color: Colors.red[600], size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Principais Riscos',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.red[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...mainRisks.map<Widget>((risk) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '• $risk',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              )).toList(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendations(BuildContext context) {
    final shouldAccept = contextualData?['should_accept'] ?? true;
    final recommendation = contextualData?['recommendation'] ?? 
        'Caso viável com boa margem de lucro. Recomendado aceitar.';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recomendação da IA',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.orange[700],
          ),
        ),
        const SizedBox(height: 12),
        
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: shouldAccept ? Colors.green[25] : Colors.orange[25],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: shouldAccept ? Colors.green[100]! : Colors.orange[100]!,
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(
                    shouldAccept ? Icons.check_circle_outline : Icons.warning_outlined,
                    color: shouldAccept ? Colors.green[600] : Colors.orange[600],
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      shouldAccept ? 'RECOMENDADO ACEITAR' : 'AVALIAR COM CUIDADO',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: shouldAccept ? Colors.green[600] : Colors.orange[600],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                recommendation,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: buildActionButton(context,
                      label: shouldAccept ? 'Aceitar Caso' : 'Solicitar Mais Info',
                      icon: shouldAccept ? Icons.check : Icons.info_outline,
                      onPressed: () => _handleRecommendation(context, shouldAccept),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: buildActionButton(context,
                      label: 'Consultar Equipe',
                      icon: Icons.people_outline,
                      onPressed: () => _consultTeam(context),
                      isOutlined: true,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Métodos de ação
  void _handleRecommendation(BuildContext context, bool shouldAccept) {
    if (shouldAccept) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Processando aceitação do caso...'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Solicitando informações adicionais...'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _consultTeam(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Consultar Equipe'),
        content: const Text(
          'Deseja enviar esta análise para discussão com a equipe técnica?\n\n'
          'A equipe receberá todas as informações de complexidade e viabilidade.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Análise enviada para a equipe técnica'),
                  backgroundColor: Colors.blue,
                ),
              );
            },
            child: const Text('Enviar'),
          ),
        ],
      ),
    );
  }

  // Métodos de apoio para cores e ícones
  Color _getComplexityColor(int score) {
    if (score <= 3) return Colors.green;
    if (score <= 6) return Colors.orange;
    return Colors.red;
  }

  IconData _getComplexityIcon(int score) {
    if (score <= 3) return Icons.sentiment_satisfied_outlined;
    if (score <= 6) return Icons.sentiment_neutral_outlined;
    return Icons.sentiment_dissatisfied_outlined;
  }

  String _getComplexityLabel(int score) {
    if (score <= 3) return 'Complexidade Baixa';
    if (score <= 6) return 'Complexidade Média';
    return 'Complexidade Alta';
  }

  Color _getProfitMarginColor(double margin) {
    if (margin >= 25) return Colors.green;
    if (margin >= 15) return Colors.orange;
    return Colors.red;
  }

  IconData _getProfitMarginIcon(double margin) {
    if (margin >= 25) return Icons.trending_up;
    if (margin >= 15) return Icons.trending_flat;
    return Icons.trending_down;
  }

  String _getProfitMarginLabel(double margin) {
    if (margin >= 25) return 'Margem excelente - Caso muito rentável';
    if (margin >= 15) return 'Margem adequada - Rentabilidade moderada';
    return 'Margem baixa - Avaliar viabilidade';
  }

  Color _getRiskColor(String riskLevel) {
    switch (riskLevel.toLowerCase()) {
      case 'baixo': return Colors.green;
      case 'médio': return Colors.orange;
      case 'alto': return Colors.red;
      default: return Colors.orange;
    }
  }

  Color _getSuccessProbabilityColor(double probability) {
    if (probability >= 0.8) return Colors.green;
    if (probability >= 0.6) return Colors.orange;
    return Colors.red;
  }
}