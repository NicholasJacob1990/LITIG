import 'package:flutter/material.dart';
import '../base_info_section.dart';

/// Seção de Documentos da Plataforma para super associados
/// 
/// **Contexto:** Super associados (lawyer_platform_associate)
/// **Substituição:** DocumentsSection (experiência do cliente)
/// **Foco:** Documentos da plataforma, compliance, qualidade e entregáveis
/// 
/// Conforme PLANO_DE_ACAO_CONTEXTUAL_VIEW.md:
/// - Substituir DocumentsSection para super associados
/// - Foco em performance na plataforma e qualidade dos entregáveis
class PlatformDocumentsSection extends BaseInfoSection {
  @override
  final Map<String, dynamic>? contextualData;

  const PlatformDocumentsSection({
    required super.caseDetail,
    this.contextualData,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return buildSectionCard(
      title: 'Documentos da Plataforma',
      children: [
        _buildQualityDocuments(context),
        const SizedBox(height: 16),
        _buildComplianceDocuments(context),
        const SizedBox(height: 16),
        _buildDeliverables(context),
        const SizedBox(height: 16),
        _buildPlatformMetrics(context),
        const SizedBox(height: 20),
        _buildPlatformActions(context),
      ],
    );
  }

  Widget _buildQualityDocuments(BuildContext context) {
    final qualityDocs = contextualData?['quality_documents'] ?? [
      {
        'name': 'Checklist de Qualidade.pdf',
        'type': 'checklist',
        'status': 'completed',
        'completion_rate': 95.0,
        'last_review': '16/01/2025 09:30',
        'reviewer': 'Sistema da Plataforma',
        'score': 4.8,
        'required': true,
      },
      {
        'name': 'Relatório de Progresso.docx',
        'type': 'progress',
        'status': 'in_progress',
        'completion_rate': 75.0,
        'last_review': '15/01/2025 16:45',
        'reviewer': 'Você',
        'score': null,
        'required': true,
      },
      {
        'name': 'Documentação Técnica.pdf',
        'type': 'technical',
        'status': 'pending',
        'completion_rate': 0.0,
        'last_review': null,
        'reviewer': null,
        'score': null,
        'required': false,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Documentos de Qualidade',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.blue[700],
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: () => _runQualityCheck(context),
              icon: const Icon(Icons.verified, size: 16),
              label: const Text(
                'Verificar Qualidade',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        // Lista de documentos de qualidade
        ...qualityDocs.map<Widget>((doc) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _getQualityDocColor(doc['status']).withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _getQualityDocColor(doc['status']).withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header do documento
              Row(
                children: [
                  Icon(
                    _getQualityDocIcon(doc['type']),
                    color: _getQualityDocColor(doc['status']),
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                doc['name'],
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            if (doc['required'])
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red[100],
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  'OBRIGATÓRIO',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.red[700],
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            buildStatusBadge(
                              _getQualityStatusText(doc['status']),
                              backgroundColor: _getQualityDocColor(doc['status']),
                              textColor: Colors.white,
                            ),
                            if (doc['score'] != null) ...[
                              const SizedBox(width: 8),
                              Row(
                                children: [
                                  Icon(
                                    Icons.star,
                                    color: Colors.amber[600],
                                    size: 16,
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    '${doc['score']}',
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
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Barra de progresso
              Row(
                children: [
                  Text(
                    'Progresso:',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: LinearProgressIndicator(
                      value: doc['completion_rate'] / 100.0,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _getQualityDocColor(doc['status']),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${doc['completion_rate'].toInt()}%',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: _getQualityDocColor(doc['status']),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Informações de revisão
              if (doc['last_review'] != null) ...[
                Row(
                  children: [
                    Icon(Icons.schedule, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      'Última revisão: ${doc['last_review']}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    if (doc['reviewer'] != null) ...[
                      const SizedBox(width: 12),
                      Icon(Icons.person, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        'por ${doc['reviewer']}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
              ],
              
              // Ações do documento
              Row(
                children: [
                  TextButton.icon(
                    onPressed: () => _editQualityDoc(context, doc),
                    icon: const Icon(Icons.edit, size: 14),
                    label: const Text('Editar', style: TextStyle(fontSize: 12)),
                  ),
                  TextButton.icon(
                    onPressed: () => _viewQualityDoc(context, doc),
                    icon: const Icon(Icons.visibility, size: 14),
                    label: const Text('Visualizar', style: TextStyle(fontSize: 12)),
                  ),
                  if (doc['status'] != 'completed')
                    TextButton.icon(
                      onPressed: () => _submitForReview(context, doc),
                      icon: const Icon(Icons.send, size: 14),
                      label: const Text('Enviar', style: TextStyle(fontSize: 12)),
                    ),
                ],
              ),
            ],
          ),
        )).toList(),
      ],
    );
  }

  Widget _buildComplianceDocuments(BuildContext context) {
    final complianceDocs = contextualData?['compliance_documents'] ?? [
      {
        'name': 'Termo de Conformidade.pdf',
        'type': 'compliance_term',
        'status': 'approved',
        'expires_in': 45,
        'mandatory': true,
        'category': 'Ético',
      },
      {
        'name': 'Certificado de Competência.pdf',
        'type': 'certification',
        'status': 'valid',
        'expires_in': 120,
        'mandatory': true,
        'category': 'Técnico',
      },
      {
        'name': 'Declaração de Conflito de Interesses.docx',
        'type': 'declaration',
        'status': 'pending',
        'expires_in': null,
        'mandatory': false,
        'category': 'Ético',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Documentos de Compliance',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.green[700],
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: () => _viewComplianceStatus(context),
              icon: const Icon(Icons.security, size: 16),
              label: const Text(
                'Status Geral',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        // Lista de documentos de compliance
        ...complianceDocs.map<Widget>((doc) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _getComplianceColor(doc['status']).withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _getComplianceColor(doc['status']).withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header do documento
              Row(
                children: [
                  Icon(
                    _getComplianceIcon(doc['type']),
                    color: _getComplianceColor(doc['status']),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          doc['name'],
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Categoria: ${doc['category']}',
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
                        _getComplianceStatusText(doc['status']),
                        backgroundColor: _getComplianceColor(doc['status']),
                        textColor: Colors.white,
                      ),
                      if (doc['mandatory'])
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'OBRIGATÓRIO',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Colors.red[700],
                              fontSize: 10,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              
              if (doc['expires_in'] != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getExpirationColor(doc['expires_in']).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.schedule,
                        size: 14,
                        color: _getExpirationColor(doc['expires_in']),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Expira em ${doc['expires_in']} dias',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: _getExpirationColor(doc['expires_in']),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              
              const SizedBox(height: 8),
              
              // Ações do documento
              Row(
                children: [
                  TextButton.icon(
                    onPressed: () => _viewComplianceDoc(context, doc),
                    icon: const Icon(Icons.visibility, size: 14),
                    label: const Text('Visualizar', style: TextStyle(fontSize: 12)),
                  ),
                  if (doc['status'] == 'pending')
                    TextButton.icon(
                      onPressed: () => _updateComplianceDoc(context, doc),
                      icon: const Icon(Icons.upload, size: 14),
                      label: const Text('Atualizar', style: TextStyle(fontSize: 12)),
                    ),
                  if (doc['expires_in'] != null && doc['expires_in'] <= 30)
                    TextButton.icon(
                      onPressed: () => _renewComplianceDoc(context, doc),
                      icon: const Icon(Icons.refresh, size: 14),
                      label: const Text('Renovar', style: TextStyle(fontSize: 12)),
                    ),
                ],
              ),
            ],
          ),
        )).toList(),
      ],
    );
  }

  Widget _buildDeliverables(BuildContext context) {
    final deliverables = contextualData?['deliverables'] ?? [
      {
        'name': 'Relatório de Análise Inicial',
        'type': 'report',
        'due_date': '18/01/2025',
        'status': 'in_progress',
        'priority': 'high',
        'client_facing': true,
        'estimated_hours': 8,
        'completed_hours': 3,
      },
      {
        'name': 'Petição Inicial Revisada',
        'type': 'petition',
        'due_date': '20/01/2025',
        'status': 'pending',
        'priority': 'high',
        'client_facing': true,
        'estimated_hours': 12,
        'completed_hours': 0,
      },
      {
        'name': 'Documentação de Processo',
        'type': 'documentation',
        'due_date': '22/01/2025',
        'status': 'pending',
        'priority': 'medium',
        'client_facing': false,
        'estimated_hours': 4,
        'completed_hours': 0,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Entregáveis',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.purple[700],
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: () => _viewDeliveryTimeline(context),
              icon: const Icon(Icons.timeline, size: 16),
              label: const Text(
                'Timeline',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        // Lista de entregáveis
        ...deliverables.map<Widget>((deliverable) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _getDeliverablePriorityColor(deliverable['priority']).withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _getDeliverablePriorityColor(deliverable['priority']).withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header do entregável
              Row(
                children: [
                  Icon(
                    _getDeliverableIcon(deliverable['type']),
                    color: _getDeliverablePriorityColor(deliverable['priority']),
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          deliverable['name'],
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            buildStatusBadge(
                              _getDeliverableStatusText(deliverable['status']),
                              backgroundColor: _getDeliverableStatusColor(deliverable['status']),
                              textColor: Colors.white,
                            ),
                            const SizedBox(width: 8),
                            buildStatusBadge(
                              deliverable['priority'].toUpperCase(),
                              backgroundColor: _getDeliverablePriorityColor(deliverable['priority']),
                              textColor: Colors.white,
                            ),
                            if (deliverable['client_facing']) ...[
                              const SizedBox(width: 8),
                              buildStatusBadge(
                                'CLIENTE',
                                backgroundColor: Colors.blue,
                                textColor: Colors.white,
                                icon: Icons.visibility,
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Informações do entregável
              Row(
                children: [
                  Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    'Prazo: ${deliverable['due_date']}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${deliverable['completed_hours']}h / ${deliverable['estimated_hours']}h',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // Barra de progresso por horas
              LinearProgressIndicator(
                value: deliverable['completed_hours'] / deliverable['estimated_hours'],
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(
                  _getDeliverablePriorityColor(deliverable['priority']),
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Ações do entregável
              Row(
                children: [
                  TextButton.icon(
                    onPressed: () => _workOnDeliverable(context, deliverable),
                    icon: const Icon(Icons.play_arrow, size: 14),
                    label: const Text('Trabalhar', style: TextStyle(fontSize: 12)),
                  ),
                  TextButton.icon(
                    onPressed: () => _viewDeliverableDetails(context, deliverable),
                    icon: const Icon(Icons.info, size: 14),
                    label: const Text('Detalhes', style: TextStyle(fontSize: 12)),
                  ),
                  if (deliverable['status'] == 'in_progress')
                    TextButton.icon(
                      onPressed: () => _submitDeliverable(context, deliverable),
                      icon: const Icon(Icons.send, size: 14),
                      label: const Text('Enviar', style: TextStyle(fontSize: 12)),
                    ),
                ],
              ),
            ],
          ),
        )).toList(),
      ],
    );
  }

  Widget _buildPlatformMetrics(BuildContext context) {
    final metrics = contextualData?['platform_metrics'] ?? {
      'quality_score': 4.7,
      'delivery_rate': 95.0,
      'client_satisfaction': 4.8,
      'platform_ranking': 8,
      'total_deliverables': 15,
      'completed_on_time': 14,
      'avg_quality_score': 4.6,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Métricas da Plataforma',
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
                Colors.purple[50]!,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.indigo[100]!),
          ),
          child: Column(
            children: [
              // Métricas principais
              buildKPIsList([
                KPIItem(
                  icon: '⭐',
                  label: 'Score Qualidade',
                  value: '${metrics['quality_score']}',
                ),
                KPIItem(
                  icon: '🎯',
                  label: 'Taxa Entrega',
                  value: '${metrics['delivery_rate']}%',
                ),
                KPIItem(
                  icon: '😊',
                  label: 'Satisfação',
                  value: '${metrics['client_satisfaction']}',
                ),
              ]),
              
              const SizedBox(height: 16),
              
              // Ranking na plataforma
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.emoji_events, color: Colors.amber[600], size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ranking na Plataforma',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'Posição #${metrics['platform_ranking']} entre Super Associados',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '#${metrics['platform_ranking']}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.amber[600],
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

  Widget _buildPlatformActions(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: buildActionButton(
                context: context,
                label: 'Enviar Entregável',
                icon: Icons.send,
                onPressed: () => _submitMainDeliverable(context),
                backgroundColor: Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: buildActionButton(
                context: context,
                label: 'Verificar Qualidade',
                icon: Icons.verified,
                onPressed: () => _runQualityCheck(context),
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
                label: 'Templates',
                icon: Icons.library_books,
                onPressed: () => _browseTemplates(context),
                backgroundColor: Colors.purple,
                isSecondary: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: buildActionButton(
                context: context,
                label: 'Suporte',
                icon: Icons.help_center,
                onPressed: () => _contactPlatformSupport(context),
                backgroundColor: Colors.indigo,
                isSecondary: true,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Helper methods
  Color _getQualityDocColor(String status) {
    switch (status) {
      case 'completed': return Colors.green;
      case 'in_progress': return Colors.blue;
      case 'pending': return Colors.orange;
      default: return Colors.grey;
    }
  }

  String _getQualityStatusText(String status) {
    switch (status) {
      case 'completed': return 'Completo';
      case 'in_progress': return 'Em Progresso';
      case 'pending': return 'Pendente';
      default: return 'Desconhecido';
    }
  }

  IconData _getQualityDocIcon(String type) {
    switch (type) {
      case 'checklist': return Icons.checklist;
      case 'progress': return Icons.trending_up;
      case 'technical': return Icons.engineering;
      default: return Icons.description;
    }
  }

  Color _getComplianceColor(String status) {
    switch (status) {
      case 'approved': case 'valid': return Colors.green;
      case 'pending': return Colors.orange;
      case 'expired': case 'rejected': return Colors.red;
      default: return Colors.grey;
    }
  }

  String _getComplianceStatusText(String status) {
    switch (status) {
      case 'approved': return 'Aprovado';
      case 'valid': return 'Válido';
      case 'pending': return 'Pendente';
      case 'expired': return 'Expirado';
      case 'rejected': return 'Rejeitado';
      default: return 'Desconhecido';
    }
  }

  IconData _getComplianceIcon(String type) {
    switch (type) {
      case 'compliance_term': return Icons.security;
      case 'certification': return Icons.verified;
      case 'declaration': return Icons.assignment;
      default: return Icons.description;
    }
  }

  Color _getExpirationColor(int daysUntilExpiration) {
    if (daysUntilExpiration <= 7) return Colors.red;
    if (daysUntilExpiration <= 30) return Colors.orange;
    return Colors.green;
  }

  Color _getDeliverablePriorityColor(String priority) {
    switch (priority) {
      case 'high': return Colors.red;
      case 'medium': return Colors.orange;
      case 'low': return Colors.green;
      default: return Colors.blue;
    }
  }

  Color _getDeliverableStatusColor(String status) {
    switch (status) {
      case 'completed': return Colors.green;
      case 'in_progress': return Colors.blue;
      case 'pending': return Colors.orange;
      case 'overdue': return Colors.red;
      default: return Colors.grey;
    }
  }

  String _getDeliverableStatusText(String status) {
    switch (status) {
      case 'completed': return 'Completo';
      case 'in_progress': return 'Em Progresso';
      case 'pending': return 'Pendente';
      case 'overdue': return 'Atrasado';
      default: return 'Desconhecido';
    }
  }

  IconData _getDeliverableIcon(String type) {
    switch (type) {
      case 'report': return Icons.assessment;
      case 'petition': return Icons.description;
      case 'documentation': return Icons.folder;
      default: return Icons.assignment;
    }
  }

  // Action methods
  void _runQualityCheck(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const AlertDialog(
        title: Text('Verificação de Qualidade'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Executando verificação automática...'),
          ],
        ),
      ),
    );
    
    // Simular verificação
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Verificação concluída: Score 4.8/5.0'),
          backgroundColor: Colors.green,
        ),
      );
    });
  }

  void _editQualityDoc(BuildContext context, Map<String, dynamic> doc) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Editando: ${doc['name']}'),
        backgroundColor: Colors.blue,
      ),
    );
    // TODO: Implementar edição
  }

  void _viewQualityDoc(BuildContext context, Map<String, dynamic> doc) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Visualizando: ${doc['name']}'),
        backgroundColor: Colors.blue,
      ),
    );
    // TODO: Implementar visualização
  }

  void _submitForReview(BuildContext context, Map<String, dynamic> doc) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enviar para Revisão'),
        content: Text('Confirma o envio de "${doc['name']}" para revisão da plataforma?'),
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
                  content: Text('Documento enviado: ${doc['name']}'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Enviar'),
          ),
        ],
      ),
    );
  }

  void _viewComplianceStatus(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Status de Compliance'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.check_circle, color: Colors.green),
              title: Text('Documentos Obrigatórios'),
              subtitle: Text('2/2 completos'),
            ),
            ListTile(
              leading: Icon(Icons.warning, color: Colors.orange),
              title: Text('Documentos Expirando'),
              subtitle: Text('1 documento expira em 45 dias'),
            ),
            ListTile(
              leading: Icon(Icons.info, color: Colors.blue),
              title: Text('Status Geral'),
              subtitle: Text('Conforme - Aprovado para trabalhar'),
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

  void _viewComplianceDoc(BuildContext context, Map<String, dynamic> doc) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Visualizando: ${doc['name']}'),
        backgroundColor: Colors.green,
      ),
    );
    // TODO: Implementar visualização
  }

  void _updateComplianceDoc(BuildContext context, Map<String, dynamic> doc) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Atualizando: ${doc['name']}'),
        backgroundColor: Colors.orange,
      ),
    );
    // TODO: Implementar atualização
  }

  void _renewComplianceDoc(BuildContext context, Map<String, dynamic> doc) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Renovando: ${doc['name']}'),
        backgroundColor: Colors.blue,
      ),
    );
    // TODO: Implementar renovação
  }

  void _viewDeliveryTimeline(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Abrindo timeline de entregáveis...'),
        backgroundColor: Colors.purple,
      ),
    );
    // TODO: Implementar timeline
  }

  void _workOnDeliverable(BuildContext context, Map<String, dynamic> deliverable) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Iniciando trabalho: ${deliverable['name']}'),
        backgroundColor: Colors.blue,
      ),
    );
    // TODO: Implementar início de trabalho
  }

  void _viewDeliverableDetails(BuildContext context, Map<String, dynamic> deliverable) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(deliverable['name']),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tipo: ${deliverable['type']}'),
            Text('Prazo: ${deliverable['due_date']}'),
            Text('Prioridade: ${deliverable['priority']}'),
            Text('Cliente vê: ${deliverable['client_facing'] ? 'Sim' : 'Não'}'),
            Text('Progresso: ${deliverable['completed_hours']}h / ${deliverable['estimated_hours']}h'),
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

  void _submitDeliverable(BuildContext context, Map<String, dynamic> deliverable) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enviar Entregável'),
        content: Text('Confirma o envio de "${deliverable['name']}"?'),
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
                  content: Text('Entregável enviado: ${deliverable['name']}'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Enviar'),
          ),
        ],
      ),
    );
  }

  void _submitMainDeliverable(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Abrindo submissão de entregável principal...'),
        backgroundColor: Colors.blue,
      ),
    );
    // TODO: Implementar submissão principal
  }

  void _browseTemplates(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Abrindo biblioteca de templates da plataforma...'),
        backgroundColor: Colors.purple,
      ),
    );
    // TODO: Implementar templates
  }

  void _contactPlatformSupport(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Suporte da Plataforma',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.chat),
              title: const Text('Chat de Suporte'),
              subtitle: const Text('Suporte em tempo real'),
              onTap: () {
                Navigator.of(context).pop();
                // TODO: Implementar chat
              },
            ),
            ListTile(
              leading: const Icon(Icons.help_center),
              title: const Text('Central de Ajuda'),
              subtitle: const Text('Documentação e tutoriais'),
              onTap: () {
                Navigator.of(context).pop();
                // TODO: Implementar central de ajuda
              },
            ),
            ListTile(
              leading: const Icon(Icons.feedback),
              title: const Text('Enviar Feedback'),
              subtitle: const Text('Sugerir melhorias'),
              onTap: () {
                Navigator.of(context).pop();
                // TODO: Implementar feedback
              },
            ),
          ],
        ),
      ),
    );
  }
} 

/// Seção de Documentos da Plataforma para super associados
/// 
/// **Contexto:** Super associados (lawyer_platform_associate)
/// **Substituição:** DocumentsSection (experiência do cliente)
/// **Foco:** Documentos da plataforma, compliance, qualidade e entregáveis
/// 
/// Conforme PLANO_DE_ACAO_CONTEXTUAL_VIEW.md:
/// - Substituir DocumentsSection para super associados
/// - Foco em performance na plataforma e qualidade dos entregáveis
class PlatformDocumentsSection extends BaseInfoSection {
  @override
  final Map<String, dynamic>? contextualData;

  const PlatformDocumentsSection({
    required super.caseDetail,
    this.contextualData,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return buildSectionCard(
      title: 'Documentos da Plataforma',
      children: [
        _buildQualityDocuments(context),
        const SizedBox(height: 16),
        _buildComplianceDocuments(context),
        const SizedBox(height: 16),
        _buildDeliverables(context),
        const SizedBox(height: 16),
        _buildPlatformMetrics(context),
        const SizedBox(height: 20),
        _buildPlatformActions(context),
      ],
    );
  }

  Widget _buildQualityDocuments(BuildContext context) {
    final qualityDocs = contextualData?['quality_documents'] ?? [
      {
        'name': 'Checklist de Qualidade.pdf',
        'type': 'checklist',
        'status': 'completed',
        'completion_rate': 95.0,
        'last_review': '16/01/2025 09:30',
        'reviewer': 'Sistema da Plataforma',
        'score': 4.8,
        'required': true,
      },
      {
        'name': 'Relatório de Progresso.docx',
        'type': 'progress',
        'status': 'in_progress',
        'completion_rate': 75.0,
        'last_review': '15/01/2025 16:45',
        'reviewer': 'Você',
        'score': null,
        'required': true,
      },
      {
        'name': 'Documentação Técnica.pdf',
        'type': 'technical',
        'status': 'pending',
        'completion_rate': 0.0,
        'last_review': null,
        'reviewer': null,
        'score': null,
        'required': false,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Documentos de Qualidade',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.blue[700],
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: () => _runQualityCheck(context),
              icon: const Icon(Icons.verified, size: 16),
              label: const Text(
                'Verificar Qualidade',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        // Lista de documentos de qualidade
        ...qualityDocs.map<Widget>((doc) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _getQualityDocColor(doc['status']).withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _getQualityDocColor(doc['status']).withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header do documento
              Row(
                children: [
                  Icon(
                    _getQualityDocIcon(doc['type']),
                    color: _getQualityDocColor(doc['status']),
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                doc['name'],
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            if (doc['required'])
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red[100],
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  'OBRIGATÓRIO',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.red[700],
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            buildStatusBadge(
                              _getQualityStatusText(doc['status']),
                              backgroundColor: _getQualityDocColor(doc['status']),
                              textColor: Colors.white,
                            ),
                            if (doc['score'] != null) ...[
                              const SizedBox(width: 8),
                              Row(
                                children: [
                                  Icon(
                                    Icons.star,
                                    color: Colors.amber[600],
                                    size: 16,
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    '${doc['score']}',
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
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Barra de progresso
              Row(
                children: [
                  Text(
                    'Progresso:',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: LinearProgressIndicator(
                      value: doc['completion_rate'] / 100.0,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _getQualityDocColor(doc['status']),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${doc['completion_rate'].toInt()}%',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: _getQualityDocColor(doc['status']),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Informações de revisão
              if (doc['last_review'] != null) ...[
                Row(
                  children: [
                    Icon(Icons.schedule, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      'Última revisão: ${doc['last_review']}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    if (doc['reviewer'] != null) ...[
                      const SizedBox(width: 12),
                      Icon(Icons.person, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        'por ${doc['reviewer']}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
              ],
              
              // Ações do documento
              Row(
                children: [
                  TextButton.icon(
                    onPressed: () => _editQualityDoc(context, doc),
                    icon: const Icon(Icons.edit, size: 14),
                    label: const Text('Editar', style: TextStyle(fontSize: 12)),
                  ),
                  TextButton.icon(
                    onPressed: () => _viewQualityDoc(context, doc),
                    icon: const Icon(Icons.visibility, size: 14),
                    label: const Text('Visualizar', style: TextStyle(fontSize: 12)),
                  ),
                  if (doc['status'] != 'completed')
                    TextButton.icon(
                      onPressed: () => _submitForReview(context, doc),
                      icon: const Icon(Icons.send, size: 14),
                      label: const Text('Enviar', style: TextStyle(fontSize: 12)),
                    ),
                ],
              ),
            ],
          ),
        )).toList(),
      ],
    );
  }

  Widget _buildComplianceDocuments(BuildContext context) {
    final complianceDocs = contextualData?['compliance_documents'] ?? [
      {
        'name': 'Termo de Conformidade.pdf',
        'type': 'compliance_term',
        'status': 'approved',
        'expires_in': 45,
        'mandatory': true,
        'category': 'Ético',
      },
      {
        'name': 'Certificado de Competência.pdf',
        'type': 'certification',
        'status': 'valid',
        'expires_in': 120,
        'mandatory': true,
        'category': 'Técnico',
      },
      {
        'name': 'Declaração de Conflito de Interesses.docx',
        'type': 'declaration',
        'status': 'pending',
        'expires_in': null,
        'mandatory': false,
        'category': 'Ético',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Documentos de Compliance',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.green[700],
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: () => _viewComplianceStatus(context),
              icon: const Icon(Icons.security, size: 16),
              label: const Text(
                'Status Geral',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        // Lista de documentos de compliance
        ...complianceDocs.map<Widget>((doc) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _getComplianceColor(doc['status']).withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _getComplianceColor(doc['status']).withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header do documento
              Row(
                children: [
                  Icon(
                    _getComplianceIcon(doc['type']),
                    color: _getComplianceColor(doc['status']),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          doc['name'],
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Categoria: ${doc['category']}',
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
                        _getComplianceStatusText(doc['status']),
                        backgroundColor: _getComplianceColor(doc['status']),
                        textColor: Colors.white,
                      ),
                      if (doc['mandatory'])
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'OBRIGATÓRIO',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Colors.red[700],
                              fontSize: 10,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              
              if (doc['expires_in'] != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getExpirationColor(doc['expires_in']).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.schedule,
                        size: 14,
                        color: _getExpirationColor(doc['expires_in']),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Expira em ${doc['expires_in']} dias',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: _getExpirationColor(doc['expires_in']),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              
              const SizedBox(height: 8),
              
              // Ações do documento
              Row(
                children: [
                  TextButton.icon(
                    onPressed: () => _viewComplianceDoc(context, doc),
                    icon: const Icon(Icons.visibility, size: 14),
                    label: const Text('Visualizar', style: TextStyle(fontSize: 12)),
                  ),
                  if (doc['status'] == 'pending')
                    TextButton.icon(
                      onPressed: () => _updateComplianceDoc(context, doc),
                      icon: const Icon(Icons.upload, size: 14),
                      label: const Text('Atualizar', style: TextStyle(fontSize: 12)),
                    ),
                  if (doc['expires_in'] != null && doc['expires_in'] <= 30)
                    TextButton.icon(
                      onPressed: () => _renewComplianceDoc(context, doc),
                      icon: const Icon(Icons.refresh, size: 14),
                      label: const Text('Renovar', style: TextStyle(fontSize: 12)),
                    ),
                ],
              ),
            ],
          ),
        )).toList(),
      ],
    );
  }

  Widget _buildDeliverables(BuildContext context) {
    final deliverables = contextualData?['deliverables'] ?? [
      {
        'name': 'Relatório de Análise Inicial',
        'type': 'report',
        'due_date': '18/01/2025',
        'status': 'in_progress',
        'priority': 'high',
        'client_facing': true,
        'estimated_hours': 8,
        'completed_hours': 3,
      },
      {
        'name': 'Petição Inicial Revisada',
        'type': 'petition',
        'due_date': '20/01/2025',
        'status': 'pending',
        'priority': 'high',
        'client_facing': true,
        'estimated_hours': 12,
        'completed_hours': 0,
      },
      {
        'name': 'Documentação de Processo',
        'type': 'documentation',
        'due_date': '22/01/2025',
        'status': 'pending',
        'priority': 'medium',
        'client_facing': false,
        'estimated_hours': 4,
        'completed_hours': 0,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Entregáveis',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.purple[700],
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: () => _viewDeliveryTimeline(context),
              icon: const Icon(Icons.timeline, size: 16),
              label: const Text(
                'Timeline',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        // Lista de entregáveis
        ...deliverables.map<Widget>((deliverable) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _getDeliverablePriorityColor(deliverable['priority']).withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _getDeliverablePriorityColor(deliverable['priority']).withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header do entregável
              Row(
                children: [
                  Icon(
                    _getDeliverableIcon(deliverable['type']),
                    color: _getDeliverablePriorityColor(deliverable['priority']),
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          deliverable['name'],
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            buildStatusBadge(
                              _getDeliverableStatusText(deliverable['status']),
                              backgroundColor: _getDeliverableStatusColor(deliverable['status']),
                              textColor: Colors.white,
                            ),
                            const SizedBox(width: 8),
                            buildStatusBadge(
                              deliverable['priority'].toUpperCase(),
                              backgroundColor: _getDeliverablePriorityColor(deliverable['priority']),
                              textColor: Colors.white,
                            ),
                            if (deliverable['client_facing']) ...[
                              const SizedBox(width: 8),
                              buildStatusBadge(
                                'CLIENTE',
                                backgroundColor: Colors.blue,
                                textColor: Colors.white,
                                icon: Icons.visibility,
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Informações do entregável
              Row(
                children: [
                  Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    'Prazo: ${deliverable['due_date']}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${deliverable['completed_hours']}h / ${deliverable['estimated_hours']}h',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // Barra de progresso por horas
              LinearProgressIndicator(
                value: deliverable['completed_hours'] / deliverable['estimated_hours'],
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(
                  _getDeliverablePriorityColor(deliverable['priority']),
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Ações do entregável
              Row(
                children: [
                  TextButton.icon(
                    onPressed: () => _workOnDeliverable(context, deliverable),
                    icon: const Icon(Icons.play_arrow, size: 14),
                    label: const Text('Trabalhar', style: TextStyle(fontSize: 12)),
                  ),
                  TextButton.icon(
                    onPressed: () => _viewDeliverableDetails(context, deliverable),
                    icon: const Icon(Icons.info, size: 14),
                    label: const Text('Detalhes', style: TextStyle(fontSize: 12)),
                  ),
                  if (deliverable['status'] == 'in_progress')
                    TextButton.icon(
                      onPressed: () => _submitDeliverable(context, deliverable),
                      icon: const Icon(Icons.send, size: 14),
                      label: const Text('Enviar', style: TextStyle(fontSize: 12)),
                    ),
                ],
              ),
            ],
          ),
        )).toList(),
      ],
    );
  }

  Widget _buildPlatformMetrics(BuildContext context) {
    final metrics = contextualData?['platform_metrics'] ?? {
      'quality_score': 4.7,
      'delivery_rate': 95.0,
      'client_satisfaction': 4.8,
      'platform_ranking': 8,
      'total_deliverables': 15,
      'completed_on_time': 14,
      'avg_quality_score': 4.6,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Métricas da Plataforma',
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
                Colors.purple[50]!,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.indigo[100]!),
          ),
          child: Column(
            children: [
              // Métricas principais
              buildKPIsList([
                KPIItem(
                  icon: '⭐',
                  label: 'Score Qualidade',
                  value: '${metrics['quality_score']}',
                ),
                KPIItem(
                  icon: '🎯',
                  label: 'Taxa Entrega',
                  value: '${metrics['delivery_rate']}%',
                ),
                KPIItem(
                  icon: '😊',
                  label: 'Satisfação',
                  value: '${metrics['client_satisfaction']}',
                ),
              ]),
              
              const SizedBox(height: 16),
              
              // Ranking na plataforma
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.emoji_events, color: Colors.amber[600], size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ranking na Plataforma',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'Posição #${metrics['platform_ranking']} entre Super Associados',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '#${metrics['platform_ranking']}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.amber[600],
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

  Widget _buildPlatformActions(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: buildActionButton(
                context: context,
                label: 'Enviar Entregável',
                icon: Icons.send,
                onPressed: () => _submitMainDeliverable(context),
                backgroundColor: Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: buildActionButton(
                context: context,
                label: 'Verificar Qualidade',
                icon: Icons.verified,
                onPressed: () => _runQualityCheck(context),
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
                label: 'Templates',
                icon: Icons.library_books,
                onPressed: () => _browseTemplates(context),
                backgroundColor: Colors.purple,
                isSecondary: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: buildActionButton(
                context: context,
                label: 'Suporte',
                icon: Icons.help_center,
                onPressed: () => _contactPlatformSupport(context),
                backgroundColor: Colors.indigo,
                isSecondary: true,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Helper methods
  Color _getQualityDocColor(String status) {
    switch (status) {
      case 'completed': return Colors.green;
      case 'in_progress': return Colors.blue;
      case 'pending': return Colors.orange;
      default: return Colors.grey;
    }
  }

  String _getQualityStatusText(String status) {
    switch (status) {
      case 'completed': return 'Completo';
      case 'in_progress': return 'Em Progresso';
      case 'pending': return 'Pendente';
      default: return 'Desconhecido';
    }
  }

  IconData _getQualityDocIcon(String type) {
    switch (type) {
      case 'checklist': return Icons.checklist;
      case 'progress': return Icons.trending_up;
      case 'technical': return Icons.engineering;
      default: return Icons.description;
    }
  }

  Color _getComplianceColor(String status) {
    switch (status) {
      case 'approved': case 'valid': return Colors.green;
      case 'pending': return Colors.orange;
      case 'expired': case 'rejected': return Colors.red;
      default: return Colors.grey;
    }
  }

  String _getComplianceStatusText(String status) {
    switch (status) {
      case 'approved': return 'Aprovado';
      case 'valid': return 'Válido';
      case 'pending': return 'Pendente';
      case 'expired': return 'Expirado';
      case 'rejected': return 'Rejeitado';
      default: return 'Desconhecido';
    }
  }

  IconData _getComplianceIcon(String type) {
    switch (type) {
      case 'compliance_term': return Icons.security;
      case 'certification': return Icons.verified;
      case 'declaration': return Icons.assignment;
      default: return Icons.description;
    }
  }

  Color _getExpirationColor(int daysUntilExpiration) {
    if (daysUntilExpiration <= 7) return Colors.red;
    if (daysUntilExpiration <= 30) return Colors.orange;
    return Colors.green;
  }

  Color _getDeliverablePriorityColor(String priority) {
    switch (priority) {
      case 'high': return Colors.red;
      case 'medium': return Colors.orange;
      case 'low': return Colors.green;
      default: return Colors.blue;
    }
  }

  Color _getDeliverableStatusColor(String status) {
    switch (status) {
      case 'completed': return Colors.green;
      case 'in_progress': return Colors.blue;
      case 'pending': return Colors.orange;
      case 'overdue': return Colors.red;
      default: return Colors.grey;
    }
  }

  String _getDeliverableStatusText(String status) {
    switch (status) {
      case 'completed': return 'Completo';
      case 'in_progress': return 'Em Progresso';
      case 'pending': return 'Pendente';
      case 'overdue': return 'Atrasado';
      default: return 'Desconhecido';
    }
  }

  IconData _getDeliverableIcon(String type) {
    switch (type) {
      case 'report': return Icons.assessment;
      case 'petition': return Icons.description;
      case 'documentation': return Icons.folder;
      default: return Icons.assignment;
    }
  }

  // Action methods
  void _runQualityCheck(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const AlertDialog(
        title: Text('Verificação de Qualidade'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Executando verificação automática...'),
          ],
        ),
      ),
    );
    
    // Simular verificação
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Verificação concluída: Score 4.8/5.0'),
          backgroundColor: Colors.green,
        ),
      );
    });
  }

  void _editQualityDoc(BuildContext context, Map<String, dynamic> doc) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Editando: ${doc['name']}'),
        backgroundColor: Colors.blue,
      ),
    );
    // TODO: Implementar edição
  }

  void _viewQualityDoc(BuildContext context, Map<String, dynamic> doc) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Visualizando: ${doc['name']}'),
        backgroundColor: Colors.blue,
      ),
    );
    // TODO: Implementar visualização
  }

  void _submitForReview(BuildContext context, Map<String, dynamic> doc) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enviar para Revisão'),
        content: Text('Confirma o envio de "${doc['name']}" para revisão da plataforma?'),
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
                  content: Text('Documento enviado: ${doc['name']}'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Enviar'),
          ),
        ],
      ),
    );
  }

  void _viewComplianceStatus(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Status de Compliance'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.check_circle, color: Colors.green),
              title: Text('Documentos Obrigatórios'),
              subtitle: Text('2/2 completos'),
            ),
            ListTile(
              leading: Icon(Icons.warning, color: Colors.orange),
              title: Text('Documentos Expirando'),
              subtitle: Text('1 documento expira em 45 dias'),
            ),
            ListTile(
              leading: Icon(Icons.info, color: Colors.blue),
              title: Text('Status Geral'),
              subtitle: Text('Conforme - Aprovado para trabalhar'),
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

  void _viewComplianceDoc(BuildContext context, Map<String, dynamic> doc) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Visualizando: ${doc['name']}'),
        backgroundColor: Colors.green,
      ),
    );
    // TODO: Implementar visualização
  }

  void _updateComplianceDoc(BuildContext context, Map<String, dynamic> doc) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Atualizando: ${doc['name']}'),
        backgroundColor: Colors.orange,
      ),
    );
    // TODO: Implementar atualização
  }

  void _renewComplianceDoc(BuildContext context, Map<String, dynamic> doc) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Renovando: ${doc['name']}'),
        backgroundColor: Colors.blue,
      ),
    );
    // TODO: Implementar renovação
  }

  void _viewDeliveryTimeline(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Abrindo timeline de entregáveis...'),
        backgroundColor: Colors.purple,
      ),
    );
    // TODO: Implementar timeline
  }

  void _workOnDeliverable(BuildContext context, Map<String, dynamic> deliverable) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Iniciando trabalho: ${deliverable['name']}'),
        backgroundColor: Colors.blue,
      ),
    );
    // TODO: Implementar início de trabalho
  }

  void _viewDeliverableDetails(BuildContext context, Map<String, dynamic> deliverable) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(deliverable['name']),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tipo: ${deliverable['type']}'),
            Text('Prazo: ${deliverable['due_date']}'),
            Text('Prioridade: ${deliverable['priority']}'),
            Text('Cliente vê: ${deliverable['client_facing'] ? 'Sim' : 'Não'}'),
            Text('Progresso: ${deliverable['completed_hours']}h / ${deliverable['estimated_hours']}h'),
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

  void _submitDeliverable(BuildContext context, Map<String, dynamic> deliverable) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enviar Entregável'),
        content: Text('Confirma o envio de "${deliverable['name']}"?'),
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
                  content: Text('Entregável enviado: ${deliverable['name']}'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Enviar'),
          ),
        ],
      ),
    );
  }

  void _submitMainDeliverable(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Abrindo submissão de entregável principal...'),
        backgroundColor: Colors.blue,
      ),
    );
    // TODO: Implementar submissão principal
  }

  void _browseTemplates(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Abrindo biblioteca de templates da plataforma...'),
        backgroundColor: Colors.purple,
      ),
    );
    // TODO: Implementar templates
  }

  void _contactPlatformSupport(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Suporte da Plataforma',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.chat),
              title: const Text('Chat de Suporte'),
              subtitle: const Text('Suporte em tempo real'),
              onTap: () {
                Navigator.of(context).pop();
                // TODO: Implementar chat
              },
            ),
            ListTile(
              leading: const Icon(Icons.help_center),
              title: const Text('Central de Ajuda'),
              subtitle: const Text('Documentação e tutoriais'),
              onTap: () {
                Navigator.of(context).pop();
                // TODO: Implementar central de ajuda
              },
            ),
            ListTile(
              leading: const Icon(Icons.feedback),
              title: const Text('Enviar Feedback'),
              subtitle: const Text('Sugerir melhorias'),
              onTap: () {
                Navigator.of(context).pop();
                // TODO: Implementar feedback
              },
            ),
          ],
        ),
      ),
    );
  }
} 