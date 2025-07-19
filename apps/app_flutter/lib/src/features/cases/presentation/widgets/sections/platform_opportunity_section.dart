import 'package:flutter/material.dart';
import '../base_info_section.dart';

/// Seção de Oportunidade da Plataforma para Super Associados
/// 
/// Substitui LawyerResponsibleSection quando o super associado
/// recebe casos diretamente do algoritmo da plataforma.
class PlatformOpportunitySection extends BaseInfoSection {
  const PlatformOpportunitySection({
    required super.caseDetail,
    super.contextualData,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final matchScore = getContextualValue<double>('match_score') ?? 0.94;
    final slaHours = getContextualValue<int>('sla_hours') ?? 2;
    final conversionRate = getContextualValue<double>('conversion_rate') ?? 85.0;
    final platformRanking = getContextualValue<int>('platform_ranking') ?? 5;
    
    return buildSectionCard(
      title: 'Oportunidade da Plataforma',
      titleSuffix: buildStatusBadge(
        _getPlatformTier(),
        backgroundColor: _getPlatformTierColor(),
        textColor: Colors.white,
        icon: Icons.star,
      ),
      children: [
        // Header do match
        buildSectionHeader(
          title: 'Match do Algoritmo',
          icon: Icons.psychology,
          subtitle: 'Análise de compatibilidade automatizada',
        ),
        
        // Métricas do match
        buildKPIsList([
          KPIItem(
            icon: '🎯',
            label: 'Score Match',
            value: '${(matchScore * 100).toInt()}%',
          ),
          KPIItem(
            icon: '⚡',
            label: 'SLA Response',
            value: '${slaHours}h',
          ),
          KPIItem(
            icon: '📈',
            label: 'Taxa Conversão',
            value: '${conversionRate.toInt()}%',
          ),
        ]),
        
        buildDivider(),
        
        // Análise do match
        buildSectionHeader(
          title: 'Análise de Compatibilidade',
          icon: Icons.analytics,
        ),
        
        buildInfoRow(
          Icons.verified,
          'Razão do Match',
          getContextualValue<String>('ai_reason') ?? 'Alta especialização na área',
        ),
        
        buildInfoRow(
          Icons.location_on,
          'Proximidade Geográfica',
          _getDistance(),
          iconColor: _getDistanceColor(context),
        ),
        
        buildInfoRow(
          Icons.school,
          'Especialização Requerida',
          _getRequiredSpecialization(),
        ),
        
        buildInfoRow(
          Icons.trending_up,
          'Histórico de Sucesso',
          _getSuccessHistory(),
          trailing: buildStatusBadge(
            _getSuccessRating(),
            backgroundColor: _getSuccessColor(),
          ),
        ),
        
        buildDivider(),
        
        // Performance na plataforma
        buildSectionHeader(
          title: 'Sua Performance na Plataforma',
          icon: Icons.leaderboard,
        ),
        
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
                         gradient: LinearGradient(
               colors: [
                 Colors.blue.shade50,
                 Colors.blue.shade100,
               ],
             ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildPerformanceMetric(
                      context,
                      'Ranking Geral',
                      '#$platformRanking',
                      Icons.emoji_events,
                      Colors.amber,
                    ),
                  ),
                  Expanded(
                    child: _buildPerformanceMetric(
                      context,
                      'Casos Este Mês',
                      '${_getCasesThisMonth()}',
                      Icons.folder,
                      Colors.blue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildPerformanceMetric(
                      context,
                      'Avaliação Média',
                      '${_getAverageRating()}/5',
                      Icons.star,
                      Colors.orange,
                    ),
                  ),
                  Expanded(
                    child: _buildPerformanceMetric(
                      context,
                      'Tempo Resposta',
                      _getAverageResponseTime(),
                      Icons.schedule,
                      Colors.green,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        buildDivider(),
        
        // Cliente e expectativas
        buildSectionHeader(
          title: 'Expectativas do Cliente',
          icon: Icons.person_outline,
        ),
        
        buildInfoRow(
          Icons.business,
          'Tipo de Cliente',
          _getClientType(),
          trailing: buildStatusBadge(_getClientTier()),
        ),
        
        buildInfoRow(
          Icons.account_balance_wallet,
          'Budget Disponível',
          _getClientBudget(),
          iconColor: Colors.green,
        ),
        
        buildInfoRow(
          Icons.schedule,
          'Expectativa de Prazo',
          _getExpectedDeadline(),
          iconColor: _getDeadlineUrgencyColor(context),
        ),
        
                 buildInfoRow(
           Icons.high_quality,
           'Nível de Qualidade Esperado',
           _getQualityExpectation(),
         ),
        
        buildDivider(),
        
        // Ações da plataforma
        buildSectionHeader(
          title: 'Ações da Plataforma',
          icon: Icons.flash_on,
        ),
        
        Row(
          children: [
            Expanded(
              child: buildActionButton(
                label: 'Aceitar Match',
                icon: Icons.thumb_up,
                onPressed: () => _acceptMatch(context),
                backgroundColor: Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: buildActionButton(
                label: 'Solicitar Ajustes',
                icon: Icons.tune,
                isOutlined: true,
                onPressed: () => _requestAdjustments(context),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 12),
        
        Row(
          children: [
            Expanded(
              child: buildActionButton(
                label: 'Ver Perfil Cliente',
                icon: Icons.person,
                isOutlined: true,
                onPressed: () => _viewClientProfile(context),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: buildActionButton(
                label: 'Recusar Match',
                icon: Icons.thumb_down,
                isOutlined: true,
                onPressed: () => _rejectMatch(context),
                foregroundColor: Colors.red,
              ),
            ),
          ],
        ),
        
        // Insights da plataforma
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.purple.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.purple.shade200),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.auto_awesome,
                size: 20,
                color: Colors.purple.shade700,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Insight da Plataforma',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: Colors.purple.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getPlatformInsight(),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.purple.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        // Dica de otimização
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.amber.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.amber.shade200),
          ),
          child: Row(
            children: [
              Icon(
                Icons.lightbulb,
                size: 16,
                color: Colors.amber.shade700,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _getOptimizationTip(),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.amber.shade700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==================== MÉTODOS PRIVADOS ====================

  Widget _buildPerformanceMetric(
    BuildContext context, 
    String label, 
    String value, 
    IconData icon, 
    Color color
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  String _getPlatformTier() {
    final ranking = getContextualValue<int>('platform_ranking', 5) ?? 5;
    if (ranking <= 10) return 'Elite';
    if (ranking <= 50) return 'Gold';
    if (ranking <= 100) return 'Silver';
    return 'Bronze';
  }

  Color _getPlatformTierColor() {
    final tier = _getPlatformTier();
    switch (tier) {
      case 'Elite': return Colors.purple;
      case 'Gold': return Colors.amber;
      case 'Silver': return Colors.grey;
      default: return Colors.brown;
    }
  }

  String _getDistance() {
    final distance = getContextualValue<double>('distance', 15.5) ?? 15.5;
    return '${distance.toStringAsFixed(1)} km';
  }

  Color _getDistanceColor(BuildContext context) {
    final distance = getContextualValue<double>('distance', 15.5) ?? 15.5;
    if (distance <= 10) return Colors.green;
    if (distance <= 25) return Colors.orange;
    return Colors.red;
  }

  String _getRequiredSpecialization() {
    final specializations = [
      'Direito Trabalhista',
      'Direito Empresarial',
      'Direito Tributário',
      'Direito Civil',
      'Direito Criminal'
    ];
    final index = (getContextualValue<int>('specialization_index', 0) ?? 0) % specializations.length;
    return specializations[index];
  }

  String _getSuccessHistory() {
    final successRate = getContextualValue<double>('success_rate', 92.0) ?? 92.0;
    final totalCases = getContextualValue<int>('total_cases', 47) ?? 47;
    return '$totalCases casos (${successRate.toInt()}% sucesso)';
  }

  String _getSuccessRating() {
    final successRate = getContextualValue<double>('success_rate', 92.0) ?? 92.0;
    if (successRate >= 95) return 'Excelente';
    if (successRate >= 85) return 'Muito Bom';
    if (successRate >= 75) return 'Bom';
    return 'Regular';
  }

  Color _getSuccessColor() {
    final rating = _getSuccessRating();
    switch (rating) {
      case 'Excelente': return Colors.green.shade100;
      case 'Muito Bom': return Colors.blue.shade100;
      case 'Bom': return Colors.orange.shade100;
      default: return Colors.red.shade100;
    }
  }

  int _getCasesThisMonth() {
    return getContextualValue<int>('cases_this_month', 8) ?? 8;
  }

  double _getAverageRating() {
    return getContextualValue<double>('average_rating', 4.7) ?? 4.7;
  }

  String _getAverageResponseTime() {
    final hours = getContextualValue<int>('avg_response_hours', 1) ?? 1;
    if (hours < 1) return '< 1h';
    return '${hours}h';
  }

  String _getClientType() {
    final types = ['Pessoa Física', 'Pequena Empresa', 'Média Empresa', 'Grande Empresa'];
    final index = (getContextualValue<int>('client_type_index', 1) ?? 1) % types.length;
    return types[index];
  }

  String _getClientTier() {
    final clientType = _getClientType();
    switch (clientType) {
      case 'Grande Empresa': return 'Premium';
      case 'Média Empresa': return 'Business';
      case 'Pequena Empresa': return 'Standard';
      default: return 'Basic';
    }
  }

  String _getClientBudget() {
    final budget = getContextualValue<double>('client_budget', 5000.0) ?? 5000.0;
    return formatCurrency(budget);
  }

  String _getExpectedDeadline() {
    final days = getContextualValue<int>('expected_deadline_days', 14) ?? 14;
    return '$days dias úteis';
  }

  Color _getDeadlineUrgencyColor(BuildContext context) {
    final days = getContextualValue<int>('expected_deadline_days', 14) ?? 14;
    if (days <= 7) return Colors.red;
    if (days <= 14) return Colors.orange;
    return Theme.of(context).colorScheme.primary;
  }

  String _getQualityExpectation() {
    final expectations = ['Básico', 'Padrão', 'Alto', 'Premium'];
    final index = (getContextualValue<int>('quality_index', 2) ?? 2) % expectations.length;
    return expectations[index];
  }

  String _getPlatformInsight() {
    final insights = [
      'Este match tem 94% de compatibilidade. Cliente valoriza resposta rápida.',
      'Seu perfil é ideal para este tipo de caso. Histórico de sucesso similar.',
      'Cliente tem potencial para casos recorrentes. Invista no relacionamento.',
      'Este caso pode melhorar seu ranking na plataforma significativamente.',
    ];
    final index = (getContextualValue<int>('insight_index', 0) ?? 0) % insights.length;
    return insights[index];
  }

  String _getOptimizationTip() {
    final tips = [
      'Responda em até 1h para manter seu SLA e melhorar o ranking.',
      'Atualize seu perfil com esta nova especialização após concluir.',
      'Este cliente pode gerar reviews positivas. Foque na qualidade.',
      'Considere ajustar seus preços baseado neste tipo de cliente.',
    ];
    final index = (getContextualValue<int>('tip_index', 0) ?? 0) % tips.length;
    return tips[index];
  }

  // ==================== AÇÕES DE CALLBACK ====================

  void _acceptMatch(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Aceitar Match'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Confirma que deseja aceitar este match da plataforma?'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, color: Colors.green.shade700, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Você tem 2h para entrar em contato com o cliente.',
                      style: TextStyle(
                        color: Colors.green.shade700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
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
                const SnackBar(content: Text('Match aceito! Cliente foi notificado.')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Aceitar Match'),
          ),
        ],
      ),
    );
  }

  void _requestAdjustments(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Solicitar Ajustes'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Que ajustes você gostaria de solicitar?'),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Valor proposto',
                prefixText: 'R\$ ',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Prazo sugerido (dias)',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Observações',
              ),
              maxLines: 2,
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
                const SnackBar(content: Text('Solicitação de ajustes enviada!')),
              );
            },
            child: const Text('Enviar'),
          ),
        ],
      ),
    );
  }

  void _viewClientProfile(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                'Perfil do Cliente',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    ListTile(
                      leading: const Icon(Icons.business),
                      title: const Text('Tipo'),
                      subtitle: Text(_getClientType()),
                    ),
                    const ListTile(
                      leading: Icon(Icons.location_on),
                      title: Text('Localização'),
                      subtitle: Text('São Paulo, SP'),
                    ),
                    const ListTile(
                      leading: Icon(Icons.history),
                      title: Text('Histórico na Plataforma'),
                      subtitle: Text('3 casos anteriores'),
                    ),
                    const ListTile(
                      leading: Icon(Icons.star),
                      title: Text('Avaliação como Cliente'),
                      subtitle: Text('4.6/5 (baseado em 3 avaliações)'),
                    ),
                    const ListTile(
                      leading: Icon(Icons.schedule),
                      title: Text('Tempo Médio de Resposta'),
                      subtitle: Text('3.2 horas'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _rejectMatch(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Recusar Match'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Por que você está recusando este match?'),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Motivo',
              ),
              items: const [
                DropdownMenuItem(value: 'agenda', child: Text('Agenda lotada')),
                DropdownMenuItem(value: 'especialidade', child: Text('Fora da especialidade')),
                DropdownMenuItem(value: 'valor', child: Text('Valor inadequado')),
                DropdownMenuItem(value: 'prazo', child: Text('Prazo muito apertado')),
                DropdownMenuItem(value: 'outros', child: Text('Outros')),
              ],
              onChanged: (value) {},
            ),
            const SizedBox(height: 12),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Observações (opcional)',
              ),
              maxLines: 2,
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
                const SnackBar(content: Text('Match recusado. Motivo registrado.')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Recusar'),
          ),
        ],
      ),
    );
  }
} 

/// Seção de Oportunidade da Plataforma para Super Associados
/// 
/// Substitui LawyerResponsibleSection quando o super associado
/// recebe casos diretamente do algoritmo da plataforma.
class PlatformOpportunitySection extends BaseInfoSection {
  const PlatformOpportunitySection({
    required super.caseDetail,
    super.contextualData,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final matchScore = getContextualValue<double>('match_score') ?? 0.94;
    final slaHours = getContextualValue<int>('sla_hours') ?? 2;
    final conversionRate = getContextualValue<double>('conversion_rate') ?? 85.0;
    final platformRanking = getContextualValue<int>('platform_ranking') ?? 5;
    
    return buildSectionCard(
      title: 'Oportunidade da Plataforma',
      titleSuffix: buildStatusBadge(
        _getPlatformTier(),
        backgroundColor: _getPlatformTierColor(),
        textColor: Colors.white,
        icon: Icons.star,
      ),
      children: [
        // Header do match
        buildSectionHeader(
          title: 'Match do Algoritmo',
          icon: Icons.psychology,
          subtitle: 'Análise de compatibilidade automatizada',
        ),
        
        // Métricas do match
        buildKPIsList([
          KPIItem(
            icon: '🎯',
            label: 'Score Match',
            value: '${(matchScore * 100).toInt()}%',
          ),
          KPIItem(
            icon: '⚡',
            label: 'SLA Response',
            value: '${slaHours}h',
          ),
          KPIItem(
            icon: '📈',
            label: 'Taxa Conversão',
            value: '${conversionRate.toInt()}%',
          ),
        ]),
        
        buildDivider(),
        
        // Análise do match
        buildSectionHeader(
          title: 'Análise de Compatibilidade',
          icon: Icons.analytics,
        ),
        
        buildInfoRow(
          Icons.verified,
          'Razão do Match',
          getContextualValue<String>('ai_reason') ?? 'Alta especialização na área',
        ),
        
        buildInfoRow(
          Icons.location_on,
          'Proximidade Geográfica',
          _getDistance(),
          iconColor: _getDistanceColor(context),
        ),
        
        buildInfoRow(
          Icons.school,
          'Especialização Requerida',
          _getRequiredSpecialization(),
        ),
        
        buildInfoRow(
          Icons.trending_up,
          'Histórico de Sucesso',
          _getSuccessHistory(),
          trailing: buildStatusBadge(
            _getSuccessRating(),
            backgroundColor: _getSuccessColor(),
          ),
        ),
        
        buildDivider(),
        
        // Performance na plataforma
        buildSectionHeader(
          title: 'Sua Performance na Plataforma',
          icon: Icons.leaderboard,
        ),
        
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
                         gradient: LinearGradient(
               colors: [
                 Colors.blue.shade50,
                 Colors.blue.shade100,
               ],
             ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildPerformanceMetric(
                      context,
                      'Ranking Geral',
                      '#$platformRanking',
                      Icons.emoji_events,
                      Colors.amber,
                    ),
                  ),
                  Expanded(
                    child: _buildPerformanceMetric(
                      context,
                      'Casos Este Mês',
                      '${_getCasesThisMonth()}',
                      Icons.folder,
                      Colors.blue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildPerformanceMetric(
                      context,
                      'Avaliação Média',
                      '${_getAverageRating()}/5',
                      Icons.star,
                      Colors.orange,
                    ),
                  ),
                  Expanded(
                    child: _buildPerformanceMetric(
                      context,
                      'Tempo Resposta',
                      _getAverageResponseTime(),
                      Icons.schedule,
                      Colors.green,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        buildDivider(),
        
        // Cliente e expectativas
        buildSectionHeader(
          title: 'Expectativas do Cliente',
          icon: Icons.person_outline,
        ),
        
        buildInfoRow(
          Icons.business,
          'Tipo de Cliente',
          _getClientType(),
          trailing: buildStatusBadge(_getClientTier()),
        ),
        
        buildInfoRow(
          Icons.account_balance_wallet,
          'Budget Disponível',
          _getClientBudget(),
          iconColor: Colors.green,
        ),
        
        buildInfoRow(
          Icons.schedule,
          'Expectativa de Prazo',
          _getExpectedDeadline(),
          iconColor: _getDeadlineUrgencyColor(context),
        ),
        
                 buildInfoRow(
           Icons.high_quality,
           'Nível de Qualidade Esperado',
           _getQualityExpectation(),
         ),
        
        buildDivider(),
        
        // Ações da plataforma
        buildSectionHeader(
          title: 'Ações da Plataforma',
          icon: Icons.flash_on,
        ),
        
        Row(
          children: [
            Expanded(
              child: buildActionButton(
                label: 'Aceitar Match',
                icon: Icons.thumb_up,
                onPressed: () => _acceptMatch(context),
                backgroundColor: Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: buildActionButton(
                label: 'Solicitar Ajustes',
                icon: Icons.tune,
                isOutlined: true,
                onPressed: () => _requestAdjustments(context),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 12),
        
        Row(
          children: [
            Expanded(
              child: buildActionButton(
                label: 'Ver Perfil Cliente',
                icon: Icons.person,
                isOutlined: true,
                onPressed: () => _viewClientProfile(context),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: buildActionButton(
                label: 'Recusar Match',
                icon: Icons.thumb_down,
                isOutlined: true,
                onPressed: () => _rejectMatch(context),
                foregroundColor: Colors.red,
              ),
            ),
          ],
        ),
        
        // Insights da plataforma
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.purple.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.purple.shade200),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.auto_awesome,
                size: 20,
                color: Colors.purple.shade700,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Insight da Plataforma',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: Colors.purple.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getPlatformInsight(),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.purple.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        // Dica de otimização
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.amber.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.amber.shade200),
          ),
          child: Row(
            children: [
              Icon(
                Icons.lightbulb,
                size: 16,
                color: Colors.amber.shade700,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _getOptimizationTip(),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.amber.shade700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==================== MÉTODOS PRIVADOS ====================

  Widget _buildPerformanceMetric(
    BuildContext context, 
    String label, 
    String value, 
    IconData icon, 
    Color color
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  String _getPlatformTier() {
    final ranking = getContextualValue<int>('platform_ranking', 5) ?? 5;
    if (ranking <= 10) return 'Elite';
    if (ranking <= 50) return 'Gold';
    if (ranking <= 100) return 'Silver';
    return 'Bronze';
  }

  Color _getPlatformTierColor() {
    final tier = _getPlatformTier();
    switch (tier) {
      case 'Elite': return Colors.purple;
      case 'Gold': return Colors.amber;
      case 'Silver': return Colors.grey;
      default: return Colors.brown;
    }
  }

  String _getDistance() {
    final distance = getContextualValue<double>('distance', 15.5) ?? 15.5;
    return '${distance.toStringAsFixed(1)} km';
  }

  Color _getDistanceColor(BuildContext context) {
    final distance = getContextualValue<double>('distance', 15.5) ?? 15.5;
    if (distance <= 10) return Colors.green;
    if (distance <= 25) return Colors.orange;
    return Colors.red;
  }

  String _getRequiredSpecialization() {
    final specializations = [
      'Direito Trabalhista',
      'Direito Empresarial',
      'Direito Tributário',
      'Direito Civil',
      'Direito Criminal'
    ];
    final index = (getContextualValue<int>('specialization_index', 0) ?? 0) % specializations.length;
    return specializations[index];
  }

  String _getSuccessHistory() {
    final successRate = getContextualValue<double>('success_rate', 92.0) ?? 92.0;
    final totalCases = getContextualValue<int>('total_cases', 47) ?? 47;
    return '$totalCases casos (${successRate.toInt()}% sucesso)';
  }

  String _getSuccessRating() {
    final successRate = getContextualValue<double>('success_rate', 92.0) ?? 92.0;
    if (successRate >= 95) return 'Excelente';
    if (successRate >= 85) return 'Muito Bom';
    if (successRate >= 75) return 'Bom';
    return 'Regular';
  }

  Color _getSuccessColor() {
    final rating = _getSuccessRating();
    switch (rating) {
      case 'Excelente': return Colors.green.shade100;
      case 'Muito Bom': return Colors.blue.shade100;
      case 'Bom': return Colors.orange.shade100;
      default: return Colors.red.shade100;
    }
  }

  int _getCasesThisMonth() {
    return getContextualValue<int>('cases_this_month', 8) ?? 8;
  }

  double _getAverageRating() {
    return getContextualValue<double>('average_rating', 4.7) ?? 4.7;
  }

  String _getAverageResponseTime() {
    final hours = getContextualValue<int>('avg_response_hours', 1) ?? 1;
    if (hours < 1) return '< 1h';
    return '${hours}h';
  }

  String _getClientType() {
    final types = ['Pessoa Física', 'Pequena Empresa', 'Média Empresa', 'Grande Empresa'];
    final index = (getContextualValue<int>('client_type_index', 1) ?? 1) % types.length;
    return types[index];
  }

  String _getClientTier() {
    final clientType = _getClientType();
    switch (clientType) {
      case 'Grande Empresa': return 'Premium';
      case 'Média Empresa': return 'Business';
      case 'Pequena Empresa': return 'Standard';
      default: return 'Basic';
    }
  }

  String _getClientBudget() {
    final budget = getContextualValue<double>('client_budget', 5000.0) ?? 5000.0;
    return formatCurrency(budget);
  }

  String _getExpectedDeadline() {
    final days = getContextualValue<int>('expected_deadline_days', 14) ?? 14;
    return '$days dias úteis';
  }

  Color _getDeadlineUrgencyColor(BuildContext context) {
    final days = getContextualValue<int>('expected_deadline_days', 14) ?? 14;
    if (days <= 7) return Colors.red;
    if (days <= 14) return Colors.orange;
    return Theme.of(context).colorScheme.primary;
  }

  String _getQualityExpectation() {
    final expectations = ['Básico', 'Padrão', 'Alto', 'Premium'];
    final index = (getContextualValue<int>('quality_index', 2) ?? 2) % expectations.length;
    return expectations[index];
  }

  String _getPlatformInsight() {
    final insights = [
      'Este match tem 94% de compatibilidade. Cliente valoriza resposta rápida.',
      'Seu perfil é ideal para este tipo de caso. Histórico de sucesso similar.',
      'Cliente tem potencial para casos recorrentes. Invista no relacionamento.',
      'Este caso pode melhorar seu ranking na plataforma significativamente.',
    ];
    final index = (getContextualValue<int>('insight_index', 0) ?? 0) % insights.length;
    return insights[index];
  }

  String _getOptimizationTip() {
    final tips = [
      'Responda em até 1h para manter seu SLA e melhorar o ranking.',
      'Atualize seu perfil com esta nova especialização após concluir.',
      'Este cliente pode gerar reviews positivas. Foque na qualidade.',
      'Considere ajustar seus preços baseado neste tipo de cliente.',
    ];
    final index = (getContextualValue<int>('tip_index', 0) ?? 0) % tips.length;
    return tips[index];
  }

  // ==================== AÇÕES DE CALLBACK ====================

  void _acceptMatch(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Aceitar Match'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Confirma que deseja aceitar este match da plataforma?'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, color: Colors.green.shade700, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Você tem 2h para entrar em contato com o cliente.',
                      style: TextStyle(
                        color: Colors.green.shade700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
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
                const SnackBar(content: Text('Match aceito! Cliente foi notificado.')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Aceitar Match'),
          ),
        ],
      ),
    );
  }

  void _requestAdjustments(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Solicitar Ajustes'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Que ajustes você gostaria de solicitar?'),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Valor proposto',
                prefixText: 'R\$ ',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Prazo sugerido (dias)',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Observações',
              ),
              maxLines: 2,
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
                const SnackBar(content: Text('Solicitação de ajustes enviada!')),
              );
            },
            child: const Text('Enviar'),
          ),
        ],
      ),
    );
  }

  void _viewClientProfile(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                'Perfil do Cliente',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    ListTile(
                      leading: const Icon(Icons.business),
                      title: const Text('Tipo'),
                      subtitle: Text(_getClientType()),
                    ),
                    const ListTile(
                      leading: Icon(Icons.location_on),
                      title: Text('Localização'),
                      subtitle: Text('São Paulo, SP'),
                    ),
                    const ListTile(
                      leading: Icon(Icons.history),
                      title: Text('Histórico na Plataforma'),
                      subtitle: Text('3 casos anteriores'),
                    ),
                    const ListTile(
                      leading: Icon(Icons.star),
                      title: Text('Avaliação como Cliente'),
                      subtitle: Text('4.6/5 (baseado em 3 avaliações)'),
                    ),
                    const ListTile(
                      leading: Icon(Icons.schedule),
                      title: Text('Tempo Médio de Resposta'),
                      subtitle: Text('3.2 horas'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _rejectMatch(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Recusar Match'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Por que você está recusando este match?'),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Motivo',
              ),
              items: const [
                DropdownMenuItem(value: 'agenda', child: Text('Agenda lotada')),
                DropdownMenuItem(value: 'especialidade', child: Text('Fora da especialidade')),
                DropdownMenuItem(value: 'valor', child: Text('Valor inadequado')),
                DropdownMenuItem(value: 'prazo', child: Text('Prazo muito apertado')),
                DropdownMenuItem(value: 'outros', child: Text('Outros')),
              ],
              onChanged: (value) {},
            ),
            const SizedBox(height: 12),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Observações (opcional)',
              ),
              maxLines: 2,
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
                const SnackBar(content: Text('Match recusado. Motivo registrado.')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Recusar'),
          ),
        ],
      ),
    );
  }
} 