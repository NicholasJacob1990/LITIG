import 'package:flutter/material.dart';
import '../base_info_section.dart';

/// Seção de Oportunidade de Negócio para Advogados Contratantes
/// 
/// Substitui ConsultationInfoSection quando o advogado é contratante,
/// focando no potencial de receita e gestão do negócio.
class BusinessOpportunitySection extends BaseInfoSection {
  const BusinessOpportunitySection({
    required super.caseDetail,
    super.contextualData,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final estimatedValue = getContextualValue<double>('estimated_value') ?? 8500.0;
    final complexityScore = getContextualValue<int>('complexity_score') ?? 7;
    final successProbability = getContextualValue<double>('success_probability') ?? 0.85;
    final clientProfile = getContextualValue<String>('client_profile') ?? 'Empresarial';
    final competitorCount = getContextualValue<int>('competitor_count') ?? 3;
    
    return buildSectionCard(
      title: 'Oportunidade de Negócio',
      titleSuffix: buildStatusBadge(
        _getOpportunityRating(),
        backgroundColor: _getOpportunityColor(context),
        textColor: Colors.white,
        icon: Icons.trending_up,
      ),
      children: [
        // Header da oportunidade
        buildSectionHeader(
          title: 'Potencial Financeiro',
          icon: Icons.monetization_on,
          subtitle: 'Análise de viabilidade e rentabilidade',
        ),
        
        // Métricas principais
        buildKPIsList([
          KPIItem(
            icon: '💰',
            label: 'Valor Estimado',
            value: formatCurrency(estimatedValue),
          ),
          KPIItem(
            icon: '📊',
            label: 'Complexidade',
            value: '$complexityScore/10',
          ),
          KPIItem(
            icon: '🎯',
            label: 'Prob. Sucesso',
            value: formatPercentage(successProbability),
          ),
        ]),
        
        buildDivider(),
        
        // Informações do cliente
        buildSectionHeader(
          title: 'Perfil do Cliente',
          icon: Icons.person_outline,
        ),
        
        buildInfoRow(
          Icons.business,
          'Tipo de Cliente',
          clientProfile,
          trailing: buildStatusBadge(_getClientTier(clientProfile)),
        ),
        
        buildInfoRow(
          Icons.account_balance_wallet,
          'Orçamento Disponível',
          _getClientBudgetRange(),
          iconColor: Colors.green,
        ),
        
        buildInfoRow(
          Icons.history,
          'Histórico Conosco',
          _getClientHistory(),
        ),
        
        buildInfoRow(
          Icons.schedule,
          'Urgência',
          _getUrgencyLevel(),
          iconColor: _getUrgencyColor(context),
        ),
        
        buildDivider(),
        
        // Análise competitiva
        buildSectionHeader(
          title: 'Cenário Competitivo',
          icon: Icons.trending_up,
        ),
        
        buildInfoRow(
          Icons.people,
          'Concorrentes',
          '$competitorCount outros escritórios',
          trailing: competitorCount <= 2 
            ? buildStatusBadge('Baixa Concorrência', backgroundColor: Colors.green.shade100)
            : buildStatusBadge('Alta Concorrência', backgroundColor: Colors.red.shade100),
        ),
        
        buildInfoRow(
          Icons.timer,
          'Tempo para Resposta',
          _getResponseTime(),
          iconColor: _getResponseTimeColor(context),
        ),
        
        buildInfoRow(
          Icons.star,
          'Vantagem Competitiva',
          _getCompetitiveAdvantage(),
        ),
        
        buildDivider(),
        
        // Projeção financeira
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primaryContainer.withOpacity(0.1),
                Theme.of(context).colorScheme.primaryContainer.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.calculate,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Projeção Financeira',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildFinancialMetric(
                      context,
                      'Receita Bruta',
                      formatCurrency(estimatedValue),
                      Colors.green,
                    ),
                  ),
                  Expanded(
                    child: _buildFinancialMetric(
                      context,
                      'Margem Estimada',
                      '${_calculateMargin()}%',
                      Colors.blue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildFinancialMetric(
                      context,
                      'ROI Esperado',
                      '${_calculateROI()}%',
                      Colors.purple,
                    ),
                  ),
                  Expanded(
                    child: _buildFinancialMetric(
                      context,
                      'Prazo Recebimento',
                      _getPaymentTerm(),
                      Colors.orange,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        buildDivider(),
        
        // Ações estratégicas
        buildSectionHeader(
          title: 'Ações Estratégicas',
          icon: Icons.strategy,
        ),
        
        Row(
          children: [
            Expanded(
              child: buildActionButton(
                label: 'Aceitar Proposta',
                icon: Icons.check_circle,
                onPressed: () => _acceptProposal(context),
                backgroundColor: Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: buildActionButton(
                label: 'Negociar Valor',
                icon: Icons.handshake,
                isOutlined: true,
                onPressed: () => _negotiateValue(context),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 12),
        
        Row(
          children: [
            Expanded(
              child: buildActionButton(
                label: 'Consultar Equipe',
                icon: Icons.group,
                isOutlined: true,
                onPressed: () => _consultTeam(context),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: buildActionButton(
                label: 'Solicitar Info',
                icon: Icons.info,
                isOutlined: true,
                onPressed: () => _requestMoreInfo(context),
              ),
            ),
          ],
        ),
        
        // Insights de IA
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.psychology,
                size: 20,
                color: Colors.blue.shade700,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Insight da IA',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getAIInsight(),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==================== MÉTODOS PRIVADOS ====================

  Widget _buildFinancialMetric(BuildContext context, String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  String _getOpportunityRating() {
    final estimatedValue = getContextualValue<double>('estimated_value', 8500.0);
    final successProbability = getContextualValue<double>('success_probability', 0.85);
    
    final score = (estimatedValue / 1000) * successProbability;
    
    if (score >= 7) return 'Excelente';
    if (score >= 5) return 'Boa';
    if (score >= 3) return 'Regular';
    return 'Baixa';
  }

  Color _getOpportunityColor(BuildContext context) {
    final rating = _getOpportunityRating();
    switch (rating) {
      case 'Excelente': return Colors.green;
      case 'Boa': return Colors.blue;
      case 'Regular': return Colors.orange;
      default: return Colors.red;
    }
  }

  String _getClientTier(String clientProfile) {
    switch (clientProfile.toLowerCase()) {
      case 'empresarial': return 'Tier A';
      case 'pessoa física': return 'Tier B';
      case 'startup': return 'Tier C';
      default: return 'Standard';
    }
  }

  String _getClientBudgetRange() {
    final estimatedValue = getContextualValue<double>('estimated_value', 8500.0);
    const rangeMultiplier = 1.3;
    final maxBudget = estimatedValue * rangeMultiplier;
    return '${formatCurrency(estimatedValue)} - ${formatCurrency(maxBudget)}';
  }

  String _getClientHistory() {
    final isNewClient = getContextualValue<bool>('is_new_client', false);
    final previousCases = getContextualValue<int>('previous_cases', 0);
    
    if (isNewClient) return 'Cliente novo';
    if (previousCases == 0) return 'Sem histórico';
    if (previousCases == 1) return '1 caso anterior';
    return '$previousCases casos anteriores';
  }

  String _getUrgencyLevel() {
    final urgency = getContextualValue<int>('urgency_level', 5);
    if (urgency >= 8) return 'Muito urgente';
    if (urgency >= 6) return 'Urgente';
    if (urgency >= 4) return 'Normal';
    return 'Não urgente';
  }

  Color _getUrgencyColor(BuildContext context) {
    final urgency = getContextualValue<int>('urgency_level', 5);
    if (urgency >= 8) return Colors.red;
    if (urgency >= 6) return Colors.orange;
    return Theme.of(context).colorScheme.primary;
  }

  String _getResponseTime() {
    final hours = getContextualValue<int>('response_time_hours', 24);
    if (hours <= 2) return '$hours horas (Urgente)';
    if (hours <= 24) return '$hours horas';
    final days = (hours / 24).ceil();
    return '$days ${days == 1 ? 'dia' : 'dias'}';
  }

  Color _getResponseTimeColor(BuildContext context) {
    final hours = getContextualValue<int>('response_time_hours', 24);
    if (hours <= 2) return Colors.red;
    if (hours <= 12) return Colors.orange;
    return Theme.of(context).colorScheme.primary;
  }

  String _getCompetitiveAdvantage() {
    final advantages = [
      'Especialização na área',
      'Proximidade geográfica',
      'Preço competitivo',
      'Histórico de sucesso',
      'Equipe especializada'
    ];
    
    final index = getContextualValue<int>('advantage_index', 0) % advantages.length;
    return advantages[index];
  }

  int _calculateMargin() {
    final complexity = getContextualValue<int>('complexity_score', 7);
    return (30 - complexity * 2).clamp(15, 45);
  }

  int _calculateROI() {
    final margin = _calculateMargin();
    final successProbability = getContextualValue<double>('success_probability', 0.85);
    return (margin * successProbability).round();
  }

  String _getPaymentTerm() {
    final terms = ['30 dias', '45 dias', '60 dias'];
    final index = getContextualValue<int>('payment_term_index', 0) % terms.length;
    return terms[index];
  }

  String _getAIInsight() {
    final insights = [
      'Este caso tem alta compatibilidade com seu perfil. Recomendo aceitar rapidamente.',
      'Cliente com potencial para casos recorrentes. Invista no relacionamento.',
      'Concorrência baixa nesta especialização. Ótima oportunidade de posicionamento.',
      'Valor está acima da média de mercado. Cliente parece valorizar qualidade.',
    ];
    
    final index = getContextualValue<int>('insight_index', 0) % insights.length;
    return insights[index];
  }

  // ==================== AÇÕES DE CALLBACK ====================

  void _acceptProposal(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Aceitar Proposta'),
        content: const Text('Confirma que deseja aceitar esta proposta de caso?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Proposta aceita! Cliente será notificado.')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Aceitar'),
          ),
        ],
      ),
    );
  }

  void _negotiateValue(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Negociar Valor'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Valor proposto',
                prefixText: 'R\$ ',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Justificativa',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Contraproposta enviada!')),
              );
            },
            child: const Text('Enviar Proposta'),
          ),
        ],
      ),
    );
  }

  void _consultTeam(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Consultar Equipe',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.group),
              title: const Text('Compartilhar com sócios'),
              onTap: () {
                Navigator.of(context).pop();
                // TODO: Implementar compartilhamento
              },
            ),
            ListTile(
              leading: const Icon(Icons.poll),
              title: const Text('Criar votação'),
              onTap: () {
                Navigator.of(context).pop();
                // TODO: Implementar votação
              },
            ),
            ListTile(
              leading: const Icon(Icons.schedule),
              title: const Text('Agendar reunião'),
              onTap: () {
                Navigator.of(context).pop();
                // TODO: Implementar agendamento
              },
            ),
          ],
        ),
      ),
    );
  }

  void _requestMoreInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Solicitar Informações'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Que informações adicionais você precisa?',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Descreva as informações necessárias',
              ),
              maxLines: 4,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Solicitação enviada ao cliente!')),
              );
            },
            child: const Text('Solicitar'),
          ),
        ],
      ),
    );
  }
} 

/// Seção de Oportunidade de Negócio para Advogados Contratantes
/// 
/// Substitui ConsultationInfoSection quando o advogado é contratante,
/// focando no potencial de receita e gestão do negócio.
class BusinessOpportunitySection extends BaseInfoSection {
  const BusinessOpportunitySection({
    required super.caseDetail,
    super.contextualData,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final estimatedValue = getContextualValue<double>('estimated_value') ?? 8500.0;
    final complexityScore = getContextualValue<int>('complexity_score') ?? 7;
    final successProbability = getContextualValue<double>('success_probability') ?? 0.85;
    final clientProfile = getContextualValue<String>('client_profile') ?? 'Empresarial';
    final competitorCount = getContextualValue<int>('competitor_count') ?? 3;
    
    return buildSectionCard(
      title: 'Oportunidade de Negócio',
      titleSuffix: buildStatusBadge(
        _getOpportunityRating(),
        backgroundColor: _getOpportunityColor(context),
        textColor: Colors.white,
        icon: Icons.trending_up,
      ),
      children: [
        // Header da oportunidade
        buildSectionHeader(
          title: 'Potencial Financeiro',
          icon: Icons.monetization_on,
          subtitle: 'Análise de viabilidade e rentabilidade',
        ),
        
        // Métricas principais
        buildKPIsList([
          KPIItem(
            icon: '💰',
            label: 'Valor Estimado',
            value: formatCurrency(estimatedValue),
          ),
          KPIItem(
            icon: '📊',
            label: 'Complexidade',
            value: '$complexityScore/10',
          ),
          KPIItem(
            icon: '🎯',
            label: 'Prob. Sucesso',
            value: formatPercentage(successProbability),
          ),
        ]),
        
        buildDivider(),
        
        // Informações do cliente
        buildSectionHeader(
          title: 'Perfil do Cliente',
          icon: Icons.person_outline,
        ),
        
        buildInfoRow(
          Icons.business,
          'Tipo de Cliente',
          clientProfile,
          trailing: buildStatusBadge(_getClientTier(clientProfile)),
        ),
        
        buildInfoRow(
          Icons.account_balance_wallet,
          'Orçamento Disponível',
          _getClientBudgetRange(),
          iconColor: Colors.green,
        ),
        
        buildInfoRow(
          Icons.history,
          'Histórico Conosco',
          _getClientHistory(),
        ),
        
        buildInfoRow(
          Icons.schedule,
          'Urgência',
          _getUrgencyLevel(),
          iconColor: _getUrgencyColor(context),
        ),
        
        buildDivider(),
        
        // Análise competitiva
        buildSectionHeader(
          title: 'Cenário Competitivo',
          icon: Icons.trending_up,
        ),
        
        buildInfoRow(
          Icons.people,
          'Concorrentes',
          '$competitorCount outros escritórios',
          trailing: competitorCount <= 2 
            ? buildStatusBadge('Baixa Concorrência', backgroundColor: Colors.green.shade100)
            : buildStatusBadge('Alta Concorrência', backgroundColor: Colors.red.shade100),
        ),
        
        buildInfoRow(
          Icons.timer,
          'Tempo para Resposta',
          _getResponseTime(),
          iconColor: _getResponseTimeColor(context),
        ),
        
        buildInfoRow(
          Icons.star,
          'Vantagem Competitiva',
          _getCompetitiveAdvantage(),
        ),
        
        buildDivider(),
        
        // Projeção financeira
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primaryContainer.withOpacity(0.1),
                Theme.of(context).colorScheme.primaryContainer.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.calculate,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Projeção Financeira',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildFinancialMetric(
                      context,
                      'Receita Bruta',
                      formatCurrency(estimatedValue),
                      Colors.green,
                    ),
                  ),
                  Expanded(
                    child: _buildFinancialMetric(
                      context,
                      'Margem Estimada',
                      '${_calculateMargin()}%',
                      Colors.blue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildFinancialMetric(
                      context,
                      'ROI Esperado',
                      '${_calculateROI()}%',
                      Colors.purple,
                    ),
                  ),
                  Expanded(
                    child: _buildFinancialMetric(
                      context,
                      'Prazo Recebimento',
                      _getPaymentTerm(),
                      Colors.orange,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        buildDivider(),
        
        // Ações estratégicas
        buildSectionHeader(
          title: 'Ações Estratégicas',
          icon: Icons.strategy,
        ),
        
        Row(
          children: [
            Expanded(
              child: buildActionButton(
                label: 'Aceitar Proposta',
                icon: Icons.check_circle,
                onPressed: () => _acceptProposal(context),
                backgroundColor: Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: buildActionButton(
                label: 'Negociar Valor',
                icon: Icons.handshake,
                isOutlined: true,
                onPressed: () => _negotiateValue(context),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 12),
        
        Row(
          children: [
            Expanded(
              child: buildActionButton(
                label: 'Consultar Equipe',
                icon: Icons.group,
                isOutlined: true,
                onPressed: () => _consultTeam(context),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: buildActionButton(
                label: 'Solicitar Info',
                icon: Icons.info,
                isOutlined: true,
                onPressed: () => _requestMoreInfo(context),
              ),
            ),
          ],
        ),
        
        // Insights de IA
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.psychology,
                size: 20,
                color: Colors.blue.shade700,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Insight da IA',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getAIInsight(),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==================== MÉTODOS PRIVADOS ====================

  Widget _buildFinancialMetric(BuildContext context, String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  String _getOpportunityRating() {
    final estimatedValue = getContextualValue<double>('estimated_value', 8500.0);
    final successProbability = getContextualValue<double>('success_probability', 0.85);
    
    final score = (estimatedValue / 1000) * successProbability;
    
    if (score >= 7) return 'Excelente';
    if (score >= 5) return 'Boa';
    if (score >= 3) return 'Regular';
    return 'Baixa';
  }

  Color _getOpportunityColor(BuildContext context) {
    final rating = _getOpportunityRating();
    switch (rating) {
      case 'Excelente': return Colors.green;
      case 'Boa': return Colors.blue;
      case 'Regular': return Colors.orange;
      default: return Colors.red;
    }
  }

  String _getClientTier(String clientProfile) {
    switch (clientProfile.toLowerCase()) {
      case 'empresarial': return 'Tier A';
      case 'pessoa física': return 'Tier B';
      case 'startup': return 'Tier C';
      default: return 'Standard';
    }
  }

  String _getClientBudgetRange() {
    final estimatedValue = getContextualValue<double>('estimated_value', 8500.0);
    const rangeMultiplier = 1.3;
    final maxBudget = estimatedValue * rangeMultiplier;
    return '${formatCurrency(estimatedValue)} - ${formatCurrency(maxBudget)}';
  }

  String _getClientHistory() {
    final isNewClient = getContextualValue<bool>('is_new_client', false);
    final previousCases = getContextualValue<int>('previous_cases', 0);
    
    if (isNewClient) return 'Cliente novo';
    if (previousCases == 0) return 'Sem histórico';
    if (previousCases == 1) return '1 caso anterior';
    return '$previousCases casos anteriores';
  }

  String _getUrgencyLevel() {
    final urgency = getContextualValue<int>('urgency_level', 5);
    if (urgency >= 8) return 'Muito urgente';
    if (urgency >= 6) return 'Urgente';
    if (urgency >= 4) return 'Normal';
    return 'Não urgente';
  }

  Color _getUrgencyColor(BuildContext context) {
    final urgency = getContextualValue<int>('urgency_level', 5);
    if (urgency >= 8) return Colors.red;
    if (urgency >= 6) return Colors.orange;
    return Theme.of(context).colorScheme.primary;
  }

  String _getResponseTime() {
    final hours = getContextualValue<int>('response_time_hours', 24);
    if (hours <= 2) return '$hours horas (Urgente)';
    if (hours <= 24) return '$hours horas';
    final days = (hours / 24).ceil();
    return '$days ${days == 1 ? 'dia' : 'dias'}';
  }

  Color _getResponseTimeColor(BuildContext context) {
    final hours = getContextualValue<int>('response_time_hours', 24);
    if (hours <= 2) return Colors.red;
    if (hours <= 12) return Colors.orange;
    return Theme.of(context).colorScheme.primary;
  }

  String _getCompetitiveAdvantage() {
    final advantages = [
      'Especialização na área',
      'Proximidade geográfica',
      'Preço competitivo',
      'Histórico de sucesso',
      'Equipe especializada'
    ];
    
    final index = getContextualValue<int>('advantage_index', 0) % advantages.length;
    return advantages[index];
  }

  int _calculateMargin() {
    final complexity = getContextualValue<int>('complexity_score', 7);
    return (30 - complexity * 2).clamp(15, 45);
  }

  int _calculateROI() {
    final margin = _calculateMargin();
    final successProbability = getContextualValue<double>('success_probability', 0.85);
    return (margin * successProbability).round();
  }

  String _getPaymentTerm() {
    final terms = ['30 dias', '45 dias', '60 dias'];
    final index = getContextualValue<int>('payment_term_index', 0) % terms.length;
    return terms[index];
  }

  String _getAIInsight() {
    final insights = [
      'Este caso tem alta compatibilidade com seu perfil. Recomendo aceitar rapidamente.',
      'Cliente com potencial para casos recorrentes. Invista no relacionamento.',
      'Concorrência baixa nesta especialização. Ótima oportunidade de posicionamento.',
      'Valor está acima da média de mercado. Cliente parece valorizar qualidade.',
    ];
    
    final index = getContextualValue<int>('insight_index', 0) % insights.length;
    return insights[index];
  }

  // ==================== AÇÕES DE CALLBACK ====================

  void _acceptProposal(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Aceitar Proposta'),
        content: const Text('Confirma que deseja aceitar esta proposta de caso?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Proposta aceita! Cliente será notificado.')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Aceitar'),
          ),
        ],
      ),
    );
  }

  void _negotiateValue(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Negociar Valor'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Valor proposto',
                prefixText: 'R\$ ',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Justificativa',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Contraproposta enviada!')),
              );
            },
            child: const Text('Enviar Proposta'),
          ),
        ],
      ),
    );
  }

  void _consultTeam(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Consultar Equipe',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.group),
              title: const Text('Compartilhar com sócios'),
              onTap: () {
                Navigator.of(context).pop();
                // TODO: Implementar compartilhamento
              },
            ),
            ListTile(
              leading: const Icon(Icons.poll),
              title: const Text('Criar votação'),
              onTap: () {
                Navigator.of(context).pop();
                // TODO: Implementar votação
              },
            ),
            ListTile(
              leading: const Icon(Icons.schedule),
              title: const Text('Agendar reunião'),
              onTap: () {
                Navigator.of(context).pop();
                // TODO: Implementar agendamento
              },
            ),
          ],
        ),
      ),
    );
  }

  void _requestMoreInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Solicitar Informações'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Que informações adicionais você precisa?',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Descreva as informações necessárias',
              ),
              maxLines: 4,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Solicitação enviada ao cliente!')),
              );
            },
            child: const Text('Solicitar'),
          ),
        ],
      ),
    );
  }
} 