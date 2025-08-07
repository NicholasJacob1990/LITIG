import 'package:flutter/material.dart';
import '../base_info_section.dart';

/// Seção de Rentabilidade para advogados contratantes
/// 
/// **Contexto:** Advogados individuais e escritórios contratantes
/// **Substituição:** ProcessStatusSection (experiência do cliente)
/// **Foco:** Métricas financeiras, ROI, análise de rentabilidade e gestão de custos
/// 
/// Conforme PLANO_DE_ACAO_CONTEXTUAL_VIEW.md:
/// - Substituir ProcessStatusSection para advogados contratantes
/// - Foco em oportunidade de negócio e análise financeira
class ProfitabilitySection extends BaseInfoSection {
  @override
  final Map<String, dynamic>? contextualData;

  const ProfitabilitySection({
    required super.caseDetail,
    this.contextualData,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return buildSectionCard(
      context,
      title: 'Análise de Rentabilidade',
      children: [
        _buildFinancialOverview(context),
        const SizedBox(height: 16),
        _buildCostBreakdown(context),
        const SizedBox(height: 16),
        _buildROIAnalysis(context),
        const SizedBox(height: 16),
        _buildProfitabilityTrends(context),
        const SizedBox(height: 16),
        _buildRiskAssessment(context),
        const SizedBox(height: 20),
        _buildFinancialActions(context),
      ],
    );
  }

  Widget _buildFinancialOverview(BuildContext context) {
    final financial = contextualData?['financial_overview'] ?? {
      'estimated_revenue': 8500.0,
      'estimated_costs': 3200.0,
      'estimated_profit': 5300.0,
      'profit_margin': 62.4,
      'expected_roi': 165.6,
      'payment_terms': '30 dias',
      'billing_model': 'Valor fixo + sucesso',
    };

    final profitMargin = financial['profit_margin'];
    final roi = financial['expected_roi'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Resumo Financeiro',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.green[700],
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getProfitabilityColor(profitMargin),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _getProfitabilityIcon(profitMargin),
                    color: Colors.white,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _getProfitabilityStatus(profitMargin),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.green[50]!,
                Colors.teal[50]!,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.green[100]!),
          ),
          child: Column(
            children: [
              // Indicadores principais
              Row(
                children: [
                  Expanded(
                    child: _buildFinancialIndicator(
                      context,
                      'Receita Estimada',
                      formatCurrency(financial['estimated_revenue']),
                      Icons.trending_up,
                      Colors.green,
                      subtitle: financial['billing_model'],
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 60,
                    color: Colors.green[200],
                  ),
                  Expanded(
                    child: _buildFinancialIndicator(
                      context,
                      'Lucro Líquido',
                      formatCurrency(financial['estimated_profit']),
                      Icons.attach_money,
                      Colors.teal,
                      subtitle: '${profitMargin.toStringAsFixed(1)}% margem',
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              // ROI e métricas secundárias
              Row(
                children: [
                  Expanded(
                    child: _buildFinancialIndicator(
                      context,
                      'ROI Esperado',
                      '+${roi.toStringAsFixed(1)}%',
                      Icons.rocket_launch,
                      Colors.purple,
                      subtitle: 'Sobre investimento',
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 60,
                    color: Colors.green[200],
                  ),
                  Expanded(
                    child: _buildFinancialIndicator(
                      context,
                      'Prazo Pagamento',
                      financial['payment_terms'],
                      Icons.schedule,
                      Colors.blue,
                      subtitle: 'Acordo comercial',
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

  Widget _buildFinancialIndicator(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color, {
    String? subtitle,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
          textAlign: TextAlign.center,
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
        if (subtitle != null)
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
              fontSize: 11,
            ),
            textAlign: TextAlign.center,
          ),
      ],
    );
  }

  Widget _buildCostBreakdown(BuildContext context) {
    final costs = contextualData?['cost_breakdown'] ?? [
      {
        'category': 'Horas de Trabalho',
        'estimated_amount': 2400.0,
        'actual_amount': 1800.0,
        'percentage': 56.3,
        'details': '24h × R\$ 100/h',
        'status': 'under_budget',
      },
      {
        'category': 'Custas Processuais',
        'estimated_amount': 500.0,
        'actual_amount': 450.0,
        'percentage': 14.1,
        'details': 'Taxas e protocolos',
        'status': 'under_budget',
      },
      {
        'category': 'Pesquisa e Documentação',
        'estimated_amount': 200.0,
        'actual_amount': 250.0,
        'percentage': 7.8,
        'details': 'Bases jurídicas + certidões',
        'status': 'over_budget',
      },
      {
        'category': 'Deslocamento',
        'estimated_amount': 100.0,
        'actual_amount': 80.0,
        'percentage': 2.5,
        'details': 'Audiências e reuniões',
        'status': 'under_budget',
      },
    ];

    final totalEstimated = costs.fold<double>(0, (double sum, cost) => sum + (cost['estimated_amount'] as num));
    final totalActual = costs.fold<double>(0, (double sum, cost) => sum + (cost['actual_amount'] as num));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Detalhamento de Custos',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.orange[700],
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: () => _viewDetailedCosts(context),
              icon: const Icon(Icons.analytics, size: 16),
              label: const Text(
                'Análise Detalhada',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        // Resumo de custos
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.orange[25],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.orange[100]!),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Estimado',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      formatCurrency(totalEstimated),
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange[700],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward, color: Colors.grey[600]),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Atual',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      formatCurrency(totalActual),
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: totalActual <= totalEstimated ? Colors.green[700] : Colors.red[700],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: totalActual <= totalEstimated ? Colors.green : Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  totalActual <= totalEstimated ? 'Dentro do Orçamento' : 'Acima do Orçamento',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Lista detalhada de custos
        ...costs.map<Widget>((cost) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _getCostStatusColor(cost['status']).withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _getCostStatusColor(cost['status']).withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header do custo
              Row(
                children: [
                  Expanded(
                    child: Text(
                      cost['category'],
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  buildStatusBadge(
        context,
                    _getCostStatusText(cost['status']),
                    backgroundColor: _getCostStatusColor(cost['status']),
                    textColor: Colors.white,
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // Valores e detalhes
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cost['details'],
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              'Estimado: ${formatCurrency(cost['estimated_amount'])}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Text(
                              'Atual: ${formatCurrency(cost['actual_amount'])}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: _getCostStatusColor(cost['status']),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${cost['percentage'].toStringAsFixed(1)}%',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: _getCostStatusColor(cost['status']),
                    ),
                  ),
                ],
              ),
            ],
          ),
        )).toList(),
      ],
    );
  }

  Widget _buildROIAnalysis(BuildContext context) {
    final roiData = contextualData?['roi_analysis'] ?? {
      'investment': 3200.0,
      'expected_return': 8500.0,
      'roi_percentage': 165.6,
      'payback_period': 15, // dias
      'break_even_point': 3200.0,
      'risk_level': 'low',
      'confidence_level': 85.0,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Análise de ROI',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.purple[700],
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getRiskColor(roiData['risk_level']),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _getRiskIcon(roiData['risk_level']),
                    color: Colors.white,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Risco ${_getRiskText(roiData['risk_level'])}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.purple[50]!,
                Colors.indigo[50]!,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.purple[100]!),
          ),
          child: Column(
            children: [
              // ROI principal
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.purple[600],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.trending_up, color: Colors.white, size: 32),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ROI Esperado',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            '+${roiData['roi_percentage'].toStringAsFixed(1)}%',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Confiança',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white70,
                          ),
                        ),
                        Text(
                          '${roiData['confidence_level']}%',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Métricas secundárias
              Row(
                children: [
                  Expanded(
                    child: _buildROIMetric(
                      context,
                      'Investimento',
                      formatCurrency(roiData['investment']),
                      Icons.savings,
                      Colors.orange,
                    ),
                  ),
                  Expanded(
                    child: _buildROIMetric(
                      context,
                      'Retorno Esperado',
                      formatCurrency(roiData['expected_return']),
                      Icons.monetization_on,
                      Colors.green,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              Row(
                children: [
                  Expanded(
                    child: _buildROIMetric(
                      context,
                      'Payback',
                      '${roiData['payback_period']} dias',
                      Icons.schedule,
                      Colors.blue,
                    ),
                  ),
                  Expanded(
                    child: _buildROIMetric(
                      context,
                      'Break-even',
                      formatCurrency(roiData['break_even_point']),
                      Icons.balance,
                      Colors.indigo,
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

  Widget _buildROIMetric(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey[700],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildProfitabilityTrends(BuildContext context) {
    final trends = contextualData?['profitability_trends'] ?? {
      'monthly_average': 4200.0,
      'quarterly_growth': 15.3,
      'case_efficiency': 92.0,
      'client_retention': 88.0,
      'avg_case_value': 6800.0,
      'cost_reduction': -8.5,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tendências de Rentabilidade',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.blue[700],
          ),
        ),
        const SizedBox(height: 12),
        
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue[25],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue[100]!),
          ),
          child: Column(
            children: [
              // Primeira linha de métricas
              Row(
                children: [
                  Expanded(
                    child: _buildTrendMetric(
                      context,
                      'Média Mensal',
                      formatCurrency(trends['monthly_average']),
                      trends['quarterly_growth'],
                      Icons.trending_up,
                    ),
                  ),
                  Expanded(
                    child: _buildTrendMetric(
                      context,
                      'Eficiência',
                      '${trends['case_efficiency']}%',
                      2.1, // Melhoria fictícia
                      Icons.speed,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Segunda linha de métricas
              Row(
                children: [
                  Expanded(
                    child: _buildTrendMetric(
                      context,
                      'Retenção',
                      '${trends['client_retention']}%',
                      3.2, // Melhoria fictícia
                      Icons.favorite,
                    ),
                  ),
                  Expanded(
                    child: _buildTrendMetric(
                      context,
                      'Valor Médio',
                      formatCurrency(trends['avg_case_value']),
                      trends['cost_reduction'],
                      Icons.attach_money,
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

  Widget _buildTrendMetric(
    BuildContext context,
    String label,
    String value,
    double trend,
    IconData icon,
  ) {
    final isPositive = trend >= 0;
    final trendColor = isPositive ? Colors.green : Colors.red;
    final trendIcon = isPositive ? Icons.arrow_upward : Icons.arrow_downward;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.blue[600], size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.blue[700],
            ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(trendIcon, size: 12, color: trendColor),
              const SizedBox(width: 2),
              Text(
                '${trend.abs().toStringAsFixed(1)}%',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: trendColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRiskAssessment(BuildContext context) {
    final risks = contextualData?['risk_assessment'] ?? [
      {
        'category': 'Pagamento',
        'level': 'low',
        'probability': 15.0,
        'impact': 'medium',
        'mitigation': 'Contrato com garantias',
        'description': 'Cliente com histórico positivo',
      },
      {
        'category': 'Complexidade',
        'level': 'medium',
        'probability': 35.0,
        'impact': 'high',
        'mitigation': 'Consultoria especializada',
        'description': 'Caso pode requerer expertise adicional',
      },
      {
        'category': 'Prazo',
        'level': 'low',
        'probability': 20.0,
        'impact': 'low',
        'mitigation': 'Cronograma realista',
        'description': 'Prazos bem definidos e factíveis',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Avaliação de Riscos',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.red[700],
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: () => _viewRiskMatrix(context),
              icon: const Icon(Icons.warning, size: 16),
              label: const Text(
                'Matriz Completa',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        // Lista de riscos
        ...risks.map<Widget>((risk) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _getRiskLevelColor(risk['level']).withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _getRiskLevelColor(risk['level']).withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header do risco
              Row(
                children: [
                  Icon(
                    _getRiskCategoryIcon(risk['category']),
                    color: _getRiskLevelColor(risk['level']),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Risco de ${risk['category']}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  buildStatusBadge(
        context,
                    _getRiskLevelText(risk['level']),
                    backgroundColor: _getRiskLevelColor(risk['level']),
                    textColor: Colors.white,
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // Descrição e probabilidade
              Text(
                risk['description'],
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[700],
                ),
              ),
              
              const SizedBox(height: 8),
              
              // Probabilidade e impacto
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(Icons.percent, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          'Probabilidade: ${risk['probability']}%',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      Icon(Icons.warning_amber_outlined, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        'Impacto: ${_getImpactText(risk['impact'])}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // Mitigação
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    Icon(Icons.shield, size: 14, color: Colors.blue[600]),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Mitigação: ${risk['mitigation']}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.blue[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        )).toList(),
      ],
    );
  }

  Widget _buildFinancialActions(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: buildActionButton(context,
                label: 'Ajustar Proposta',
                icon: Icons.edit,
                onPressed: () => _adjustProposal(context),
                backgroundColor: Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: buildActionButton(context,
                label: 'Relatório Financeiro',
                icon: Icons.assessment,
                onPressed: () => _generateFinancialReport(context),
                backgroundColor: Colors.green,
                isOutlined: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: buildActionButton(context,
                label: 'Simular Cenários',
                icon: Icons.calculate,
                onPressed: () => _runScenarioSimulation(context),
                backgroundColor: Colors.purple,
                isOutlined: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: buildActionButton(context,
                label: 'Alertas',
                icon: Icons.notifications,
                onPressed: () => _configureAlerts(context),
                backgroundColor: Colors.orange,
                isOutlined: true,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Helper methods
  Color _getProfitabilityColor(double margin) {
    if (margin >= 50) return Colors.green;
    if (margin >= 30) return Colors.blue;
    if (margin >= 15) return Colors.orange;
    return Colors.red;
  }

  IconData _getProfitabilityIcon(double margin) {
    if (margin >= 50) return Icons.trending_up;
    if (margin >= 30) return Icons.trending_flat;
    return Icons.trending_down;
  }

  String _getProfitabilityStatus(double margin) {
    if (margin >= 50) return 'Excelente';
    if (margin >= 30) return 'Boa';
    if (margin >= 15) return 'Regular';
    return 'Baixa';
  }

  Color _getCostStatusColor(String status) {
    switch (status) {
      case 'under_budget': return Colors.green;
      case 'on_budget': return Colors.blue;
      case 'over_budget': return Colors.red;
      default: return Colors.grey;
    }
  }

  String _getCostStatusText(String status) {
    switch (status) {
      case 'under_budget': return 'Abaixo';
      case 'on_budget': return 'No Orçamento';
      case 'over_budget': return 'Acima';
      default: return 'Indefinido';
    }
  }

  Color _getRiskColor(String level) {
    switch (level) {
      case 'low': return Colors.green;
      case 'medium': return Colors.orange;
      case 'high': return Colors.red;
      default: return Colors.grey;
    }
  }

  IconData _getRiskIcon(String level) {
    switch (level) {
      case 'low': return Icons.check_circle;
      case 'medium': return Icons.warning;
      case 'high': return Icons.error;
      default: return Icons.help;
    }
  }

  String _getRiskText(String level) {
    switch (level) {
      case 'low': return 'Baixo';
      case 'medium': return 'Médio';
      case 'high': return 'Alto';
      default: return 'Indefinido';
    }
  }

  Color _getRiskLevelColor(String level) {
    switch (level) {
      case 'low': return Colors.green;
      case 'medium': return Colors.orange;
      case 'high': return Colors.red;
      default: return Colors.grey;
    }
  }

  String _getRiskLevelText(String level) {
    switch (level) {
      case 'low': return 'Baixo';
      case 'medium': return 'Médio';
      case 'high': return 'Alto';
      default: return 'Indefinido';
    }
  }

  IconData _getRiskCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'pagamento': return Icons.payment;
      case 'complexidade': return Icons.psychology;
      case 'prazo': return Icons.schedule;
      case 'cliente': return Icons.person;
      default: return Icons.warning;
    }
  }

  String _getImpactText(String impact) {
    switch (impact) {
      case 'low': return 'Baixo';
      case 'medium': return 'Médio';
      case 'high': return 'Alto';
      default: return 'Indefinido';
    }
  }

  // Action methods
  void _viewDetailedCosts(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Abrindo análise detalhada de custos...'),
        backgroundColor: Colors.orange,
      ),
    );
    // TODO: Implementar análise detalhada
  }

  void _viewRiskMatrix(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Matriz de Riscos'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.check_circle, color: Colors.green),
              title: Text('Baixo Risco'),
              subtitle: Text('Probabilidade < 25% • Impacto baixo/médio'),
            ),
            ListTile(
              leading: Icon(Icons.warning, color: Colors.orange),
              title: Text('Médio Risco'),
              subtitle: Text('Probabilidade 25-50% • Impacto médio/alto'),
            ),
            ListTile(
              leading: Icon(Icons.error, color: Colors.red),
              title: Text('Alto Risco'),
              subtitle: Text('Probabilidade > 50% • Impacto alto'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  void _adjustProposal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Ajustar Proposta Comercial',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.attach_money),
              title: const Text('Ajustar Valores'),
              subtitle: const Text('Modificar valores e condições'),
              onTap: () {
                Navigator.of(context).pop();
                _adjustValues(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.schedule),
              title: const Text('Alterar Prazos'),
              subtitle: const Text('Rever cronograma e entregas'),
              onTap: () {
                Navigator.of(context).pop();
                _adjustTimeline(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.build),
              title: const Text('Modificar Escopo'),
              subtitle: const Text('Ajustar serviços incluídos'),
              onTap: () {
                Navigator.of(context).pop();
                _adjustScope(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _adjustValues(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Abrindo editor de valores...'),
        backgroundColor: Colors.green,
      ),
    );
    // TODO: Implementar ajuste de valores
  }

  void _adjustTimeline(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Abrindo editor de cronograma...'),
        backgroundColor: Colors.blue,
      ),
    );
    // TODO: Implementar ajuste de cronograma
  }

  void _adjustScope(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Abrindo editor de escopo...'),
        backgroundColor: Colors.purple,
      ),
    );
    // TODO: Implementar ajuste de escopo
  }

  void _generateFinancialReport(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const AlertDialog(
        title: Text('Gerar Relatório Financeiro'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Compilando dados financeiros...'),
          ],
        ),
      ),
    );
    
    // Simular geração
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Relatório financeiro gerado com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
    });
  }

  void _runScenarioSimulation(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Abrindo simulador de cenários...'),
        backgroundColor: Colors.purple,
      ),
    );
    // TODO: Implementar simulação
  }

  void _configureAlerts(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Configurar Alertas Financeiros',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Estouro de Orçamento'),
              subtitle: const Text('Alerta quando custos excedem 95%'),
              value: true,
              onChanged: (value) {},
            ),
            SwitchListTile(
              title: const Text('Margem Baixa'),
              subtitle: const Text('Alerta quando margem < 20%'),
              value: false,
              onChanged: (value) {},
            ),
            SwitchListTile(
              title: const Text('ROI Abaixo do Esperado'),
              subtitle: const Text('Alerta quando ROI < 100%'),
              value: true,
              onChanged: (value) {},
            ),
          ],
        ),
      ),
    );
  }
} 

/// Seção de Rentabilidade para advogados contratantes
/// 
/// **Contexto:** Advogados individuais e escritórios contratantes
/// **Substituição:** ProcessStatusSection (experiência do cliente)
/// **Foco:** Métricas financeiras, ROI, análise de rentabilidade e gestão de custos
/// 
/// Conforme PLANO_DE_ACAO_CONTEXTUAL_VIEW.md:
/// - Substituir ProcessStatusSection para advogados contratantes
/// - Foco em oportunidade de negócio e análise financeira
