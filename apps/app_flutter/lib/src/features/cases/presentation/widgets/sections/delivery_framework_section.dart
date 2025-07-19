import 'package:flutter/material.dart';
import '../base_info_section.dart';

/// Seção de Framework de Entrega para super associados
/// 
/// **Contexto:** Super associados (lawyer_platform_associate)
/// **Substituição:** NextStepsSection (experiência do cliente)
/// **Foco:** Metodologia de entrega, frameworks estruturados e expectativas da plataforma
/// 
/// Conforme PLANO_DE_ACAO_CONTEXTUAL_VIEW.md:
/// - Substituir NextStepsSection para super associados
/// - Foco em delivery framework e metodologias estruturadas
class DeliveryFrameworkSection extends BaseInfoSection {
  @override
  final Map<String, dynamic>? contextualData;

  const DeliveryFrameworkSection({
    required super.caseDetail,
    this.contextualData,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return buildSectionCard(
      title: 'Framework de Entrega',
      children: [
        _buildMethodologyOverview(context),
        const SizedBox(height: 16),
        _buildDeliveryPhases(context),
        const SizedBox(height: 16),
        _buildQualityGates(context),
        const SizedBox(height: 16),
        _buildClientTouchpoints(context),
        const SizedBox(height: 16),
        _buildPerformanceTargets(context),
        const SizedBox(height: 20),
        _buildFrameworkActions(context),
      ],
    );
  }

  Widget _buildMethodologyOverview(BuildContext context) {
    final methodology = contextualData?['methodology'] ?? {
      'name': 'Legal Excellence Framework',
      'version': '2.1',
      'certification_level': 'Gold',
      'success_rate': 94.5,
      'avg_delivery_time': 3.2,
      'client_satisfaction': 4.8,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Metodologia Aplicada',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.blue[700],
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getCertificationColor(methodology['certification_level']),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.verified,
                    color: Colors.white,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    methodology['certification_level'],
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
                Colors.blue[50]!,
                Colors.indigo[50]!,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue[100]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Nome e versão da metodologia
              Row(
                children: [
                  Icon(Icons.psychology, color: Colors.blue[600], size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          methodology['name'],
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[800],
                          ),
                        ),
                        Text(
                          'Versão ${methodology['version']} • Atualizada para 2025',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.blue[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Métricas da metodologia
              Row(
                children: [
                  Expanded(
                    child: _buildMethodologyMetric(
                      context,
                      'Taxa de Sucesso',
                      '${methodology['success_rate']}%',
                      Icons.trending_up,
                      Colors.green,
                    ),
                  ),
                  Expanded(
                    child: _buildMethodologyMetric(
                      context,
                      'Tempo Médio',
                      '${methodology['avg_delivery_time']} dias',
                      Icons.schedule,
                      Colors.orange,
                    ),
                  ),
                  Expanded(
                    child: _buildMethodologyMetric(
                      context,
                      'Satisfação',
                      '${methodology['client_satisfaction']}⭐',
                      Icons.sentiment_very_satisfied,
                      Colors.amber,
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

  Widget _buildMethodologyMetric(
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
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildDeliveryPhases(BuildContext context) {
    final phases = contextualData?['delivery_phases'] ?? [
      {
        'name': 'Análise & Diagnóstico',
        'duration': '1-2 dias',
        'status': 'completed',
        'progress': 100.0,
        'deliverables': ['Relatório de Análise', 'Diagnóstico Inicial'],
        'key_activities': ['Revisão documental', 'Análise de viabilidade', 'Identificação de riscos'],
      },
      {
        'name': 'Estratégia & Planejamento',
        'duration': '1 dia',
        'status': 'in_progress',
        'progress': 60.0,
        'deliverables': ['Plano de Ação', 'Timeline de Execução'],
        'key_activities': ['Definição de estratégia', 'Cronograma detalhado', 'Alocação de recursos'],
      },
      {
        'name': 'Execução & Implementação',
        'duration': '2-3 dias',
        'status': 'pending',
        'progress': 0.0,
        'deliverables': ['Petições/Documentos', 'Acompanhamento Processual'],
        'key_activities': ['Elaboração de peças', 'Protocolos', 'Monitoramento'],
      },
      {
        'name': 'Entrega & Transição',
        'duration': '0.5 dia',
        'status': 'pending',
        'progress': 0.0,
        'deliverables': ['Relatório Final', 'Documentação de Transferência'],
        'key_activities': ['Entrega final', 'Transição para cliente', 'Follow-up'],
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Fases de Entrega',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.green[700],
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: () => _viewDetailedTimeline(context),
              icon: const Icon(Icons.timeline, size: 16),
              label: const Text(
                'Ver Timeline',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        // Lista de fases
        ...phases.asMap().entries.map<Widget>((entry) {
          final index = entry.key;
          final phase = entry.value;
          final isLast = index == phases.length - 1;
          
          return Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _getPhaseStatusColor(phase['status']).withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _getPhaseStatusColor(phase['status']).withOpacity(0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header da fase
                    Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: _getPhaseStatusColor(phase['status']),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                phase['name'],
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                'Duração: ${phase['duration']}',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            buildStatusBadge(
                              _getPhaseStatusText(phase['status']),
                              backgroundColor: _getPhaseStatusColor(phase['status']),
                              textColor: Colors.white,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${phase['progress'].toInt()}%',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: _getPhaseStatusColor(phase['status']),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Barra de progresso
                    LinearProgressIndicator(
                      value: phase['progress'] / 100.0,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _getPhaseStatusColor(phase['status']),
                      ),
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Entregáveis
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Entregáveis:',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[700],
                                ),
                              ),
                              ...phase['deliverables'].map<Widget>((deliverable) => Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  '• $deliverable',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                                ),
                              )).toList(),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Atividades principais:',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[700],
                                ),
                              ),
                              ...phase['key_activities'].take(3).map<Widget>((activity) => Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  '• $activity',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                                ),
                              )).toList(),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Ações da fase
                    if (phase['status'] == 'in_progress') ...[
                      Row(
                        children: [
                          TextButton.icon(
                            onPressed: () => _continuePhase(context, phase),
                            icon: const Icon(Icons.play_arrow, size: 14),
                            label: const Text('Continuar', style: TextStyle(fontSize: 12)),
                          ),
                          TextButton.icon(
                            onPressed: () => _viewPhaseDetails(context, phase),
                            icon: const Icon(Icons.info, size: 14),
                            label: const Text('Detalhes', style: TextStyle(fontSize: 12)),
                          ),
                        ],
                      ),
                    ] else if (phase['status'] == 'pending') ...[
                      Row(
                        children: [
                          TextButton.icon(
                            onPressed: () => _startPhase(context, phase),
                            icon: const Icon(Icons.play_arrow, size: 14),
                            label: const Text('Iniciar', style: TextStyle(fontSize: 12)),
                          ),
                          TextButton.icon(
                            onPressed: () => _viewPhaseDetails(context, phase),
                            icon: const Icon(Icons.info, size: 14),
                            label: const Text('Preparar', style: TextStyle(fontSize: 12)),
                          ),
                        ],
                      ),
                    ] else if (phase['status'] == 'completed') ...[
                      Row(
                        children: [
                          TextButton.icon(
                            onPressed: () => _viewPhaseDeliverables(context, phase),
                            icon: const Icon(Icons.assignment_turned_in, size: 14),
                            label: const Text('Ver Entregáveis', style: TextStyle(fontSize: 12)),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              
              // Conectores entre fases
              if (!isLast) ...[
                const SizedBox(height: 8),
                Container(
                  width: 2,
                  height: 24,
                  color: Colors.grey[300],
                  margin: const EdgeInsets.only(left: 15),
                ),
                const SizedBox(height: 8),
              ],
            ],
          );
        }).toList(),
      ],
    );
  }

  Widget _buildQualityGates(BuildContext context) {
    final qualityGates = contextualData?['quality_gates'] ?? [
      {
        'name': 'Revisão de Análise',
        'phase': 'Análise & Diagnóstico',
        'criteria': ['Completude documental', 'Viabilidade jurídica', 'Identificação de riscos'],
        'status': 'passed',
        'score': 4.8,
        'reviewer': 'Sistema Automatizado',
      },
      {
        'name': 'Aprovação de Estratégia',
        'phase': 'Estratégia & Planejamento',
        'criteria': ['Clareza do plano', 'Viabilidade do cronograma', 'Alocação adequada'],
        'status': 'pending',
        'score': null,
        'reviewer': 'Supervisor de Qualidade',
      },
      {
        'name': 'Revisão de Execução',
        'phase': 'Execução & Implementação',
        'criteria': ['Qualidade das peças', 'Conformidade técnica', 'Prazo de entrega'],
        'status': 'not_reached',
        'score': null,
        'reviewer': 'Cliente + Sistema',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Portões de Qualidade',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.purple[700],
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: () => _viewQualityStandards(context),
              icon: const Icon(Icons.verified, size: 16),
              label: const Text(
                'Padrões',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        // Lista de quality gates
        ...qualityGates.map<Widget>((gate) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _getQualityGateColor(gate['status']).withOpacity(0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _getQualityGateColor(gate['status']).withOpacity(0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header do quality gate
              Row(
                children: [
                  Icon(
                    _getQualityGateIcon(gate['status']),
                    color: _getQualityGateColor(gate['status']),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          gate['name'],
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Fase: ${gate['phase']}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      buildStatusBadge(
                        _getQualityGateStatusText(gate['status']),
                        backgroundColor: _getQualityGateColor(gate['status']),
                        textColor: Colors.white,
                      ),
                      if (gate['score'] != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.star,
                              color: Colors.amber[600],
                              size: 14,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              '${gate['score']}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: Colors.amber[700],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // Critérios de qualidade
              Text(
                'Critérios avaliados:',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 4),
              ...gate['criteria'].map<Widget>((criteria) => Padding(
                padding: const EdgeInsets.only(left: 12, top: 2),
                child: Row(
                  children: [
                    Icon(
                      gate['status'] == 'passed' ? Icons.check_circle : Icons.radio_button_unchecked,
                      size: 12,
                      color: gate['status'] == 'passed' ? Colors.green : Colors.grey,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      criteria,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              )).toList(),
              
              const SizedBox(height: 8),
              
              // Revisor
              Row(
                children: [
                  Icon(Icons.person_outline, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    'Revisor: ${gate['reviewer']}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
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

  Widget _buildClientTouchpoints(BuildContext context) {
    final touchpoints = contextualData?['client_touchpoints'] ?? [
      {
        'name': 'Kickoff Meeting',
        'type': 'meeting',
        'status': 'completed',
        'date': '13/01/2025',
        'duration': '30 min',
        'participants': ['Cliente', 'Você', 'Supervisor'],
        'outcome': 'Expectativas alinhadas',
      },
      {
        'name': 'Progress Update',
        'type': 'report',
        'status': 'scheduled',
        'date': '17/01/2025',
        'duration': '15 min',
        'participants': ['Cliente', 'Você'],
        'outcome': 'Pendente',
      },
      {
        'name': 'Final Delivery',
        'type': 'presentation',
        'status': 'pending',
        'date': '20/01/2025',
        'duration': '45 min',
        'participants': ['Cliente', 'Você', 'Supervisor'],
        'outcome': 'Não realizado',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Pontos de Contato com Cliente',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.orange[700],
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: () => _scheduleClientMeeting(context),
              icon: const Icon(Icons.event, size: 16),
              label: const Text(
                'Agendar',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        // Lista de touchpoints
        ...touchpoints.map<Widget>((touchpoint) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _getTouchpointStatusColor(touchpoint['status']).withOpacity(0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _getTouchpointStatusColor(touchpoint['status']).withOpacity(0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(
                _getTouchpointTypeIcon(touchpoint['type']),
                color: _getTouchpointStatusColor(touchpoint['status']),
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      touchpoint['name'],
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${touchpoint['date']} • ${touchpoint['duration']}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      'Resultado: ${touchpoint['outcome']}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              buildStatusBadge(
                _getTouchpointStatusText(touchpoint['status']),
                backgroundColor: _getTouchpointStatusColor(touchpoint['status']),
                textColor: Colors.white,
              ),
            ],
          ),
        )).toList(),
      ],
    );
  }

  Widget _buildPerformanceTargets(BuildContext context) {
    final targets = contextualData?['performance_targets'] ?? {
      'delivery_time': {'target': 5, 'current': 3.2, 'unit': 'dias'},
      'quality_score': {'target': 4.5, 'current': 4.8, 'unit': '/5.0'},
      'client_satisfaction': {'target': 4.0, 'current': 4.8, 'unit': '/5.0'},
      'sla_compliance': {'target': 95, 'current': 98, 'unit': '%'},
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Metas de Performance',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.indigo[700],
          ),
        ),
        const SizedBox(height: 12),
        
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.indigo[50]!,
                Colors.blue[50]!,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.indigo[100]!),
          ),
          child: Column(
            children: targets.entries.map<Widget>((entry) {
              final targetName = entry.key;
              final data = entry.value;
              final current = data['current'];
              final target = data['target'];
              final unit = data['unit'];
              final isAchieved = current >= target;
              final percentage = (current / target * 100).clamp(0, 100);
              
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _getTargetDisplayName(targetName),
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Text(
                          '$current$unit',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isAchieved ? Colors.green[600] : Colors.orange[600],
                          ),
                        ),
                        Text(
                          ' / $target$unit',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: percentage / 100,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isAchieved ? Colors.green : Colors.orange,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          isAchieved ? Icons.check_circle : Icons.trending_up,
                          size: 14,
                          color: isAchieved ? Colors.green[600] : Colors.orange[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isAchieved ? 'Meta alcançada' : 'Em progresso',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: isAchieved ? Colors.green[600] : Colors.orange[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${percentage.toInt()}%',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildFrameworkActions(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: buildActionButton(
                context: context,
                label: 'Próxima Fase',
                icon: Icons.arrow_forward,
                onPressed: () => _proceedToNextPhase(context),
                backgroundColor: Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: buildActionButton(
                context: context,
                label: 'Revisar Qualidade',
                icon: Icons.verified,
                onPressed: () => _reviewQuality(context),
                backgroundColor: Colors.green,
                isSecondary: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: buildActionButton(
                context: context,
                label: 'Agendar Cliente',
                icon: Icons.event,
                onPressed: () => _scheduleClientMeeting(context),
                backgroundColor: Colors.orange,
                isSecondary: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: buildActionButton(
                context: context,
                label: 'Templates',
                icon: Icons.library_books,
                onPressed: () => _accessFrameworkTemplates(context),
                backgroundColor: Colors.purple,
                isSecondary: true,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Helper methods
  Color _getCertificationColor(String level) {
    switch (level.toLowerCase()) {
      case 'gold': return Colors.amber[600]!;
      case 'silver': return Colors.grey[600]!;
      case 'bronze': return Colors.brown[600]!;
      default: return Colors.blue[600]!;
    }
  }

  Color _getPhaseStatusColor(String status) {
    switch (status) {
      case 'completed': return Colors.green;
      case 'in_progress': return Colors.blue;
      case 'pending': return Colors.orange;
      default: return Colors.grey;
    }
  }

  String _getPhaseStatusText(String status) {
    switch (status) {
      case 'completed': return 'Concluído';
      case 'in_progress': return 'Em Progresso';
      case 'pending': return 'Pendente';
      default: return 'Desconhecido';
    }
  }

  Color _getQualityGateColor(String status) {
    switch (status) {
      case 'passed': return Colors.green;
      case 'pending': return Colors.orange;
      case 'failed': return Colors.red;
      case 'not_reached': return Colors.grey;
      default: return Colors.grey;
    }
  }

  IconData _getQualityGateIcon(String status) {
    switch (status) {
      case 'passed': return Icons.check_circle;
      case 'pending': return Icons.schedule;
      case 'failed': return Icons.error;
      case 'not_reached': return Icons.radio_button_unchecked;
      default: return Icons.help;
    }
  }

  String _getQualityGateStatusText(String status) {
    switch (status) {
      case 'passed': return 'Aprovado';
      case 'pending': return 'Pendente';
      case 'failed': return 'Reprovado';
      case 'not_reached': return 'Não Atingido';
      default: return 'Desconhecido';
    }
  }

  Color _getTouchpointStatusColor(String status) {
    switch (status) {
      case 'completed': return Colors.green;
      case 'scheduled': return Colors.blue;
      case 'pending': return Colors.orange;
      case 'cancelled': return Colors.red;
      default: return Colors.grey;
    }
  }

  IconData _getTouchpointTypeIcon(String type) {
    switch (type) {
      case 'meeting': return Icons.videocam;
      case 'report': return Icons.assessment;
      case 'presentation': return Icons.present_to_all;
      case 'call': return Icons.phone;
      default: return Icons.event;
    }
  }

  String _getTouchpointStatusText(String status) {
    switch (status) {
      case 'completed': return 'Realizado';
      case 'scheduled': return 'Agendado';
      case 'pending': return 'Pendente';
      case 'cancelled': return 'Cancelado';
      default: return 'Desconhecido';
    }
  }

  String _getTargetDisplayName(String targetName) {
    switch (targetName) {
      case 'delivery_time': return 'Tempo de Entrega';
      case 'quality_score': return 'Score de Qualidade';
      case 'client_satisfaction': return 'Satisfação do Cliente';
      case 'sla_compliance': return 'Compliance SLA';
      default: return targetName;
    }
  }

  // Action methods
  void _viewDetailedTimeline(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Abrindo timeline detalhada...'),
        backgroundColor: Colors.blue,
      ),
    );
    // TODO: Implementar timeline detalhada
  }

  void _continuePhase(BuildContext context, Map<String, dynamic> phase) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Continuando fase: ${phase['name']}'),
        backgroundColor: Colors.blue,
      ),
    );
    // TODO: Implementar continuação da fase
  }

  void _startPhase(BuildContext context, Map<String, dynamic> phase) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Iniciar ${phase['name']}'),
        content: Text('Confirma o início da fase "${phase['name']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Fase iniciada: ${phase['name']}'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Iniciar'),
          ),
        ],
      ),
    );
  }

  void _viewPhaseDetails(BuildContext context, Map<String, dynamic> phase) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(phase['name']),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Duração: ${phase['duration']}'),
              const SizedBox(height: 8),
              Text('Status: ${_getPhaseStatusText(phase['status'])}'),
              const SizedBox(height: 8),
              Text('Progresso: ${phase['progress'].toInt()}%'),
              const SizedBox(height: 12),
              const Text('Entregáveis:', style: TextStyle(fontWeight: FontWeight.bold)),
              ...phase['deliverables'].map<Widget>((d) => Text('• $d')).toList(),
              const SizedBox(height: 12),
              const Text('Atividades:', style: TextStyle(fontWeight: FontWeight.bold)),
              ...phase['key_activities'].map<Widget>((a) => Text('• $a')).toList(),
            ],
          ),
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

  void _viewPhaseDeliverables(BuildContext context, Map<String, dynamic> phase) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Visualizando entregáveis de: ${phase['name']}'),
        backgroundColor: Colors.green,
      ),
    );
    // TODO: Implementar visualização de entregáveis
  }

  void _viewQualityStandards(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Abrindo padrões de qualidade da plataforma...'),
        backgroundColor: Colors.purple,
      ),
    );
    // TODO: Implementar visualização de padrões
  }

  void _scheduleClientMeeting(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Agendar Reunião com Cliente',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.videocam),
              title: const Text('Reunião de Progresso'),
              subtitle: const Text('Atualização de status (15-30 min)'),
              onTap: () {
                Navigator.of(context).pop();
                _scheduleMeetingType(context, 'progress');
              },
            ),
            ListTile(
              leading: const Icon(Icons.present_to_all),
              title: const Text('Apresentação de Entrega'),
              subtitle: const Text('Apresentação de resultados (45 min)'),
              onTap: () {
                Navigator.of(context).pop();
                _scheduleMeetingType(context, 'delivery');
              },
            ),
            ListTile(
              leading: const Icon(Icons.help_center),
              title: const Text('Esclarecimento'),
              subtitle: const Text('Dúvidas e alinhamentos (15 min)'),
              onTap: () {
                Navigator.of(context).pop();
                _scheduleMeetingType(context, 'clarification');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _scheduleMeetingType(BuildContext context, String type) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Agendando reunião tipo: $type'),
        backgroundColor: Colors.orange,
      ),
    );
    // TODO: Implementar agendamento específico
  }

  void _proceedToNextPhase(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Avançando para próxima fase...'),
        backgroundColor: Colors.blue,
      ),
    );
    // TODO: Implementar avanço de fase
  }

  void _reviewQuality(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Executando revisão de qualidade...'),
        backgroundColor: Colors.green,
      ),
    );
    // TODO: Implementar revisão de qualidade
  }

  void _accessFrameworkTemplates(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Abrindo biblioteca de templates do framework...'),
        backgroundColor: Colors.purple,
      ),
    );
    // TODO: Implementar acesso aos templates
  }
} 

/// Seção de Framework de Entrega para super associados
/// 
/// **Contexto:** Super associados (lawyer_platform_associate)
/// **Substituição:** NextStepsSection (experiência do cliente)
/// **Foco:** Metodologia de entrega, frameworks estruturados e expectativas da plataforma
/// 
/// Conforme PLANO_DE_ACAO_CONTEXTUAL_VIEW.md:
/// - Substituir NextStepsSection para super associados
/// - Foco em delivery framework e metodologias estruturadas
class DeliveryFrameworkSection extends BaseInfoSection {
  @override
  final Map<String, dynamic>? contextualData;

  const DeliveryFrameworkSection({
    required super.caseDetail,
    this.contextualData,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return buildSectionCard(
      title: 'Framework de Entrega',
      children: [
        _buildMethodologyOverview(context),
        const SizedBox(height: 16),
        _buildDeliveryPhases(context),
        const SizedBox(height: 16),
        _buildQualityGates(context),
        const SizedBox(height: 16),
        _buildClientTouchpoints(context),
        const SizedBox(height: 16),
        _buildPerformanceTargets(context),
        const SizedBox(height: 20),
        _buildFrameworkActions(context),
      ],
    );
  }

  Widget _buildMethodologyOverview(BuildContext context) {
    final methodology = contextualData?['methodology'] ?? {
      'name': 'Legal Excellence Framework',
      'version': '2.1',
      'certification_level': 'Gold',
      'success_rate': 94.5,
      'avg_delivery_time': 3.2,
      'client_satisfaction': 4.8,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Metodologia Aplicada',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.blue[700],
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getCertificationColor(methodology['certification_level']),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.verified,
                    color: Colors.white,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    methodology['certification_level'],
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
                Colors.blue[50]!,
                Colors.indigo[50]!,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue[100]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Nome e versão da metodologia
              Row(
                children: [
                  Icon(Icons.psychology, color: Colors.blue[600], size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          methodology['name'],
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[800],
                          ),
                        ),
                        Text(
                          'Versão ${methodology['version']} • Atualizada para 2025',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.blue[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Métricas da metodologia
              Row(
                children: [
                  Expanded(
                    child: _buildMethodologyMetric(
                      context,
                      'Taxa de Sucesso',
                      '${methodology['success_rate']}%',
                      Icons.trending_up,
                      Colors.green,
                    ),
                  ),
                  Expanded(
                    child: _buildMethodologyMetric(
                      context,
                      'Tempo Médio',
                      '${methodology['avg_delivery_time']} dias',
                      Icons.schedule,
                      Colors.orange,
                    ),
                  ),
                  Expanded(
                    child: _buildMethodologyMetric(
                      context,
                      'Satisfação',
                      '${methodology['client_satisfaction']}⭐',
                      Icons.sentiment_very_satisfied,
                      Colors.amber,
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

  Widget _buildMethodologyMetric(
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
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildDeliveryPhases(BuildContext context) {
    final phases = contextualData?['delivery_phases'] ?? [
      {
        'name': 'Análise & Diagnóstico',
        'duration': '1-2 dias',
        'status': 'completed',
        'progress': 100.0,
        'deliverables': ['Relatório de Análise', 'Diagnóstico Inicial'],
        'key_activities': ['Revisão documental', 'Análise de viabilidade', 'Identificação de riscos'],
      },
      {
        'name': 'Estratégia & Planejamento',
        'duration': '1 dia',
        'status': 'in_progress',
        'progress': 60.0,
        'deliverables': ['Plano de Ação', 'Timeline de Execução'],
        'key_activities': ['Definição de estratégia', 'Cronograma detalhado', 'Alocação de recursos'],
      },
      {
        'name': 'Execução & Implementação',
        'duration': '2-3 dias',
        'status': 'pending',
        'progress': 0.0,
        'deliverables': ['Petições/Documentos', 'Acompanhamento Processual'],
        'key_activities': ['Elaboração de peças', 'Protocolos', 'Monitoramento'],
      },
      {
        'name': 'Entrega & Transição',
        'duration': '0.5 dia',
        'status': 'pending',
        'progress': 0.0,
        'deliverables': ['Relatório Final', 'Documentação de Transferência'],
        'key_activities': ['Entrega final', 'Transição para cliente', 'Follow-up'],
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Fases de Entrega',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.green[700],
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: () => _viewDetailedTimeline(context),
              icon: const Icon(Icons.timeline, size: 16),
              label: const Text(
                'Ver Timeline',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        // Lista de fases
        ...phases.asMap().entries.map<Widget>((entry) {
          final index = entry.key;
          final phase = entry.value;
          final isLast = index == phases.length - 1;
          
          return Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _getPhaseStatusColor(phase['status']).withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _getPhaseStatusColor(phase['status']).withOpacity(0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header da fase
                    Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: _getPhaseStatusColor(phase['status']),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                phase['name'],
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                'Duração: ${phase['duration']}',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            buildStatusBadge(
                              _getPhaseStatusText(phase['status']),
                              backgroundColor: _getPhaseStatusColor(phase['status']),
                              textColor: Colors.white,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${phase['progress'].toInt()}%',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: _getPhaseStatusColor(phase['status']),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Barra de progresso
                    LinearProgressIndicator(
                      value: phase['progress'] / 100.0,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _getPhaseStatusColor(phase['status']),
                      ),
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Entregáveis
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Entregáveis:',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[700],
                                ),
                              ),
                              ...phase['deliverables'].map<Widget>((deliverable) => Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  '• $deliverable',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                                ),
                              )).toList(),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Atividades principais:',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[700],
                                ),
                              ),
                              ...phase['key_activities'].take(3).map<Widget>((activity) => Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  '• $activity',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                                ),
                              )).toList(),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Ações da fase
                    if (phase['status'] == 'in_progress') ...[
                      Row(
                        children: [
                          TextButton.icon(
                            onPressed: () => _continuePhase(context, phase),
                            icon: const Icon(Icons.play_arrow, size: 14),
                            label: const Text('Continuar', style: TextStyle(fontSize: 12)),
                          ),
                          TextButton.icon(
                            onPressed: () => _viewPhaseDetails(context, phase),
                            icon: const Icon(Icons.info, size: 14),
                            label: const Text('Detalhes', style: TextStyle(fontSize: 12)),
                          ),
                        ],
                      ),
                    ] else if (phase['status'] == 'pending') ...[
                      Row(
                        children: [
                          TextButton.icon(
                            onPressed: () => _startPhase(context, phase),
                            icon: const Icon(Icons.play_arrow, size: 14),
                            label: const Text('Iniciar', style: TextStyle(fontSize: 12)),
                          ),
                          TextButton.icon(
                            onPressed: () => _viewPhaseDetails(context, phase),
                            icon: const Icon(Icons.info, size: 14),
                            label: const Text('Preparar', style: TextStyle(fontSize: 12)),
                          ),
                        ],
                      ),
                    ] else if (phase['status'] == 'completed') ...[
                      Row(
                        children: [
                          TextButton.icon(
                            onPressed: () => _viewPhaseDeliverables(context, phase),
                            icon: const Icon(Icons.assignment_turned_in, size: 14),
                            label: const Text('Ver Entregáveis', style: TextStyle(fontSize: 12)),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              
              // Conectores entre fases
              if (!isLast) ...[
                const SizedBox(height: 8),
                Container(
                  width: 2,
                  height: 24,
                  color: Colors.grey[300],
                  margin: const EdgeInsets.only(left: 15),
                ),
                const SizedBox(height: 8),
              ],
            ],
          );
        }).toList(),
      ],
    );
  }

  Widget _buildQualityGates(BuildContext context) {
    final qualityGates = contextualData?['quality_gates'] ?? [
      {
        'name': 'Revisão de Análise',
        'phase': 'Análise & Diagnóstico',
        'criteria': ['Completude documental', 'Viabilidade jurídica', 'Identificação de riscos'],
        'status': 'passed',
        'score': 4.8,
        'reviewer': 'Sistema Automatizado',
      },
      {
        'name': 'Aprovação de Estratégia',
        'phase': 'Estratégia & Planejamento',
        'criteria': ['Clareza do plano', 'Viabilidade do cronograma', 'Alocação adequada'],
        'status': 'pending',
        'score': null,
        'reviewer': 'Supervisor de Qualidade',
      },
      {
        'name': 'Revisão de Execução',
        'phase': 'Execução & Implementação',
        'criteria': ['Qualidade das peças', 'Conformidade técnica', 'Prazo de entrega'],
        'status': 'not_reached',
        'score': null,
        'reviewer': 'Cliente + Sistema',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Portões de Qualidade',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.purple[700],
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: () => _viewQualityStandards(context),
              icon: const Icon(Icons.verified, size: 16),
              label: const Text(
                'Padrões',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        // Lista de quality gates
        ...qualityGates.map<Widget>((gate) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _getQualityGateColor(gate['status']).withOpacity(0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _getQualityGateColor(gate['status']).withOpacity(0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header do quality gate
              Row(
                children: [
                  Icon(
                    _getQualityGateIcon(gate['status']),
                    color: _getQualityGateColor(gate['status']),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          gate['name'],
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Fase: ${gate['phase']}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      buildStatusBadge(
                        _getQualityGateStatusText(gate['status']),
                        backgroundColor: _getQualityGateColor(gate['status']),
                        textColor: Colors.white,
                      ),
                      if (gate['score'] != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.star,
                              color: Colors.amber[600],
                              size: 14,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              '${gate['score']}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: Colors.amber[700],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // Critérios de qualidade
              Text(
                'Critérios avaliados:',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 4),
              ...gate['criteria'].map<Widget>((criteria) => Padding(
                padding: const EdgeInsets.only(left: 12, top: 2),
                child: Row(
                  children: [
                    Icon(
                      gate['status'] == 'passed' ? Icons.check_circle : Icons.radio_button_unchecked,
                      size: 12,
                      color: gate['status'] == 'passed' ? Colors.green : Colors.grey,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      criteria,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              )).toList(),
              
              const SizedBox(height: 8),
              
              // Revisor
              Row(
                children: [
                  Icon(Icons.person_outline, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    'Revisor: ${gate['reviewer']}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
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

  Widget _buildClientTouchpoints(BuildContext context) {
    final touchpoints = contextualData?['client_touchpoints'] ?? [
      {
        'name': 'Kickoff Meeting',
        'type': 'meeting',
        'status': 'completed',
        'date': '13/01/2025',
        'duration': '30 min',
        'participants': ['Cliente', 'Você', 'Supervisor'],
        'outcome': 'Expectativas alinhadas',
      },
      {
        'name': 'Progress Update',
        'type': 'report',
        'status': 'scheduled',
        'date': '17/01/2025',
        'duration': '15 min',
        'participants': ['Cliente', 'Você'],
        'outcome': 'Pendente',
      },
      {
        'name': 'Final Delivery',
        'type': 'presentation',
        'status': 'pending',
        'date': '20/01/2025',
        'duration': '45 min',
        'participants': ['Cliente', 'Você', 'Supervisor'],
        'outcome': 'Não realizado',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Pontos de Contato com Cliente',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.orange[700],
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: () => _scheduleClientMeeting(context),
              icon: const Icon(Icons.event, size: 16),
              label: const Text(
                'Agendar',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        // Lista de touchpoints
        ...touchpoints.map<Widget>((touchpoint) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _getTouchpointStatusColor(touchpoint['status']).withOpacity(0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _getTouchpointStatusColor(touchpoint['status']).withOpacity(0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(
                _getTouchpointTypeIcon(touchpoint['type']),
                color: _getTouchpointStatusColor(touchpoint['status']),
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      touchpoint['name'],
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${touchpoint['date']} • ${touchpoint['duration']}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      'Resultado: ${touchpoint['outcome']}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              buildStatusBadge(
                _getTouchpointStatusText(touchpoint['status']),
                backgroundColor: _getTouchpointStatusColor(touchpoint['status']),
                textColor: Colors.white,
              ),
            ],
          ),
        )).toList(),
      ],
    );
  }

  Widget _buildPerformanceTargets(BuildContext context) {
    final targets = contextualData?['performance_targets'] ?? {
      'delivery_time': {'target': 5, 'current': 3.2, 'unit': 'dias'},
      'quality_score': {'target': 4.5, 'current': 4.8, 'unit': '/5.0'},
      'client_satisfaction': {'target': 4.0, 'current': 4.8, 'unit': '/5.0'},
      'sla_compliance': {'target': 95, 'current': 98, 'unit': '%'},
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Metas de Performance',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.indigo[700],
          ),
        ),
        const SizedBox(height: 12),
        
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.indigo[50]!,
                Colors.blue[50]!,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.indigo[100]!),
          ),
          child: Column(
            children: targets.entries.map<Widget>((entry) {
              final targetName = entry.key;
              final data = entry.value;
              final current = data['current'];
              final target = data['target'];
              final unit = data['unit'];
              final isAchieved = current >= target;
              final percentage = (current / target * 100).clamp(0, 100);
              
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _getTargetDisplayName(targetName),
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Text(
                          '$current$unit',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isAchieved ? Colors.green[600] : Colors.orange[600],
                          ),
                        ),
                        Text(
                          ' / $target$unit',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: percentage / 100,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isAchieved ? Colors.green : Colors.orange,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          isAchieved ? Icons.check_circle : Icons.trending_up,
                          size: 14,
                          color: isAchieved ? Colors.green[600] : Colors.orange[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isAchieved ? 'Meta alcançada' : 'Em progresso',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: isAchieved ? Colors.green[600] : Colors.orange[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${percentage.toInt()}%',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildFrameworkActions(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: buildActionButton(
                context: context,
                label: 'Próxima Fase',
                icon: Icons.arrow_forward,
                onPressed: () => _proceedToNextPhase(context),
                backgroundColor: Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: buildActionButton(
                context: context,
                label: 'Revisar Qualidade',
                icon: Icons.verified,
                onPressed: () => _reviewQuality(context),
                backgroundColor: Colors.green,
                isSecondary: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: buildActionButton(
                context: context,
                label: 'Agendar Cliente',
                icon: Icons.event,
                onPressed: () => _scheduleClientMeeting(context),
                backgroundColor: Colors.orange,
                isSecondary: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: buildActionButton(
                context: context,
                label: 'Templates',
                icon: Icons.library_books,
                onPressed: () => _accessFrameworkTemplates(context),
                backgroundColor: Colors.purple,
                isSecondary: true,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Helper methods
  Color _getCertificationColor(String level) {
    switch (level.toLowerCase()) {
      case 'gold': return Colors.amber[600]!;
      case 'silver': return Colors.grey[600]!;
      case 'bronze': return Colors.brown[600]!;
      default: return Colors.blue[600]!;
    }
  }

  Color _getPhaseStatusColor(String status) {
    switch (status) {
      case 'completed': return Colors.green;
      case 'in_progress': return Colors.blue;
      case 'pending': return Colors.orange;
      default: return Colors.grey;
    }
  }

  String _getPhaseStatusText(String status) {
    switch (status) {
      case 'completed': return 'Concluído';
      case 'in_progress': return 'Em Progresso';
      case 'pending': return 'Pendente';
      default: return 'Desconhecido';
    }
  }

  Color _getQualityGateColor(String status) {
    switch (status) {
      case 'passed': return Colors.green;
      case 'pending': return Colors.orange;
      case 'failed': return Colors.red;
      case 'not_reached': return Colors.grey;
      default: return Colors.grey;
    }
  }

  IconData _getQualityGateIcon(String status) {
    switch (status) {
      case 'passed': return Icons.check_circle;
      case 'pending': return Icons.schedule;
      case 'failed': return Icons.error;
      case 'not_reached': return Icons.radio_button_unchecked;
      default: return Icons.help;
    }
  }

  String _getQualityGateStatusText(String status) {
    switch (status) {
      case 'passed': return 'Aprovado';
      case 'pending': return 'Pendente';
      case 'failed': return 'Reprovado';
      case 'not_reached': return 'Não Atingido';
      default: return 'Desconhecido';
    }
  }

  Color _getTouchpointStatusColor(String status) {
    switch (status) {
      case 'completed': return Colors.green;
      case 'scheduled': return Colors.blue;
      case 'pending': return Colors.orange;
      case 'cancelled': return Colors.red;
      default: return Colors.grey;
    }
  }

  IconData _getTouchpointTypeIcon(String type) {
    switch (type) {
      case 'meeting': return Icons.videocam;
      case 'report': return Icons.assessment;
      case 'presentation': return Icons.present_to_all;
      case 'call': return Icons.phone;
      default: return Icons.event;
    }
  }

  String _getTouchpointStatusText(String status) {
    switch (status) {
      case 'completed': return 'Realizado';
      case 'scheduled': return 'Agendado';
      case 'pending': return 'Pendente';
      case 'cancelled': return 'Cancelado';
      default: return 'Desconhecido';
    }
  }

  String _getTargetDisplayName(String targetName) {
    switch (targetName) {
      case 'delivery_time': return 'Tempo de Entrega';
      case 'quality_score': return 'Score de Qualidade';
      case 'client_satisfaction': return 'Satisfação do Cliente';
      case 'sla_compliance': return 'Compliance SLA';
      default: return targetName;
    }
  }

  // Action methods
  void _viewDetailedTimeline(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Abrindo timeline detalhada...'),
        backgroundColor: Colors.blue,
      ),
    );
    // TODO: Implementar timeline detalhada
  }

  void _continuePhase(BuildContext context, Map<String, dynamic> phase) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Continuando fase: ${phase['name']}'),
        backgroundColor: Colors.blue,
      ),
    );
    // TODO: Implementar continuação da fase
  }

  void _startPhase(BuildContext context, Map<String, dynamic> phase) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Iniciar ${phase['name']}'),
        content: Text('Confirma o início da fase "${phase['name']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Fase iniciada: ${phase['name']}'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Iniciar'),
          ),
        ],
      ),
    );
  }

  void _viewPhaseDetails(BuildContext context, Map<String, dynamic> phase) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(phase['name']),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Duração: ${phase['duration']}'),
              const SizedBox(height: 8),
              Text('Status: ${_getPhaseStatusText(phase['status'])}'),
              const SizedBox(height: 8),
              Text('Progresso: ${phase['progress'].toInt()}%'),
              const SizedBox(height: 12),
              const Text('Entregáveis:', style: TextStyle(fontWeight: FontWeight.bold)),
              ...phase['deliverables'].map<Widget>((d) => Text('• $d')).toList(),
              const SizedBox(height: 12),
              const Text('Atividades:', style: TextStyle(fontWeight: FontWeight.bold)),
              ...phase['key_activities'].map<Widget>((a) => Text('• $a')).toList(),
            ],
          ),
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

  void _viewPhaseDeliverables(BuildContext context, Map<String, dynamic> phase) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Visualizando entregáveis de: ${phase['name']}'),
        backgroundColor: Colors.green,
      ),
    );
    // TODO: Implementar visualização de entregáveis
  }

  void _viewQualityStandards(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Abrindo padrões de qualidade da plataforma...'),
        backgroundColor: Colors.purple,
      ),
    );
    // TODO: Implementar visualização de padrões
  }

  void _scheduleClientMeeting(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Agendar Reunião com Cliente',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.videocam),
              title: const Text('Reunião de Progresso'),
              subtitle: const Text('Atualização de status (15-30 min)'),
              onTap: () {
                Navigator.of(context).pop();
                _scheduleMeetingType(context, 'progress');
              },
            ),
            ListTile(
              leading: const Icon(Icons.present_to_all),
              title: const Text('Apresentação de Entrega'),
              subtitle: const Text('Apresentação de resultados (45 min)'),
              onTap: () {
                Navigator.of(context).pop();
                _scheduleMeetingType(context, 'delivery');
              },
            ),
            ListTile(
              leading: const Icon(Icons.help_center),
              title: const Text('Esclarecimento'),
              subtitle: const Text('Dúvidas e alinhamentos (15 min)'),
              onTap: () {
                Navigator.of(context).pop();
                _scheduleMeetingType(context, 'clarification');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _scheduleMeetingType(BuildContext context, String type) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Agendando reunião tipo: $type'),
        backgroundColor: Colors.orange,
      ),
    );
    // TODO: Implementar agendamento específico
  }

  void _proceedToNextPhase(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Avançando para próxima fase...'),
        backgroundColor: Colors.blue,
      ),
    );
    // TODO: Implementar avanço de fase
  }

  void _reviewQuality(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Executando revisão de qualidade...'),
        backgroundColor: Colors.green,
      ),
    );
    // TODO: Implementar revisão de qualidade
  }

  void _accessFrameworkTemplates(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Abrindo biblioteca de templates do framework...'),
        backgroundColor: Colors.purple,
      ),
    );
    // TODO: Implementar acesso aos templates
  }
} 