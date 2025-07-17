import 'package:flutter/material.dart';
import '../../../domain/entities/case_detail.dart';
import '../base_info_section.dart';

/// Seção de Documentos Estratégicos para advogados contratantes
/// 
/// **Contexto:** Advogados individuais e escritórios contratantes
/// **Substituição:** DocumentsSection (experiência do cliente)
/// **Foco:** Documentos estratégicos, propostas, contratos e gestão de negócio
/// 
/// Conforme PLANO_DE_ACAO_CONTEXTUAL_VIEW.md:
/// - Substituir DocumentsSection para advogados contratantes
/// - Foco em oportunidade de negócio e documentos estratégicos
class StrategicDocumentsSection extends BaseInfoSection {
  @override
  final Map<String, dynamic>? contextualData;

  const StrategicDocumentsSection({
    required super.caseDetail,
    this.contextualData,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return buildSectionCard(
      title: 'Documentos Estratégicos',
      children: [
        _buildBusinessDocuments(context),
        const SizedBox(height: 16),
        _buildClientDocuments(context),
        const SizedBox(height: 16),
        _buildProposalDocuments(context),
        const SizedBox(height: 16),
        _buildDocumentMetrics(context),
        const SizedBox(height: 20),
        _buildStrategicActions(context),
      ],
    );
  }

  Widget _buildBusinessDocuments(BuildContext context) {
    final businessDocs = contextualData?['business_documents'] ?? [
      {
        'name': 'Proposta Comercial - v2.pdf',
        'type': 'proposal',
        'status': 'sent',
        'client_viewed': true,
        'last_action': 'Enviado ao cliente',
        'date': '15/01/2025',
        'value': 8500.0,
        'urgency': 'high',
      },
      {
        'name': 'Contrato de Prestação de Serviços.docx',
        'type': 'contract',
        'status': 'draft',
        'client_viewed': false,
        'last_action': 'Em elaboração',
        'date': '16/01/2025',
        'value': null,
        'urgency': 'medium',
      },
      {
        'name': 'Análise de Viabilidade.pdf',
        'type': 'analysis',
        'status': 'completed',
        'client_viewed': true,
        'last_action': 'Aprovado pelo cliente',
        'date': '14/01/2025',
        'value': null,
        'urgency': 'low',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Documentos de Negócio',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.green[700],
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: () => _createBusinessDoc(context),
              icon: const Icon(Icons.business_center, size: 16),
              label: const Text(
                'Nova Proposta',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        // Lista de documentos de negócio
        ...businessDocs.map<Widget>((doc) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _getDocumentPriorityColor(doc['urgency']).withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _getDocumentPriorityColor(doc['urgency']).withOpacity(0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header do documento
              Row(
                children: [
                  Icon(
                    _getBusinessDocIcon(doc['type']),
                    color: _getDocumentPriorityColor(doc['urgency']),
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          doc['name'],
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          doc['last_action'],
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
                        _getBusinessDocStatusText(doc['status']),
                        backgroundColor: _getBusinessDocStatusColor(doc['status']),
                        textColor: Colors.white,
                      ),
                      const SizedBox(height: 4),
                      if (doc['value'] != null)
                        Text(
                          formatCurrency(doc['value']),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Colors.green[600],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Status e informações
              Row(
                children: [
                  Icon(
                    doc['client_viewed'] ? Icons.visibility : Icons.visibility_off,
                    size: 16,
                    color: doc['client_viewed'] ? Colors.green : Colors.grey,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    doc['client_viewed'] ? 'Visualizado pelo cliente' : 'Não visualizado',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: doc['client_viewed'] ? Colors.green[600] : Colors.grey[600],
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    doc['date'],
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Ações do documento
              Row(
                children: [
                  TextButton.icon(
                    onPressed: () => _viewBusinessDoc(context, doc),
                    icon: const Icon(Icons.open_in_new, size: 14),
                    label: const Text('Visualizar', style: TextStyle(fontSize: 12)),
                  ),
                  TextButton.icon(
                    onPressed: () => _editBusinessDoc(context, doc),
                    icon: const Icon(Icons.edit, size: 14),
                    label: const Text('Editar', style: TextStyle(fontSize: 12)),
                  ),
                  if (doc['status'] == 'draft')
                    TextButton.icon(
                      onPressed: () => _sendToClient(context, doc),
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

  Widget _buildClientDocuments(BuildContext context) {
    final clientDocs = contextualData?['client_documents'] ?? [
      {
        'name': 'Contrato de Trabalho.pdf',
        'type': 'evidence',
        'uploaded_by': 'Cliente',
        'date': '13/01/2025',
        'size': '2.1 MB',
        'reviewed': true,
        'notes': 'Documento válido - proceder com análise',
      },
      {
        'name': 'Holerites_2024.zip',
        'type': 'evidence',
        'uploaded_by': 'Cliente',
        'date': '13/01/2025',
        'size': '5.8 MB',
        'reviewed': false,
        'notes': null,
      },
      {
        'name': 'Termo_Rescisao.pdf',
        'type': 'evidence',
        'uploaded_by': 'Assistente',
        'date': '14/01/2025',
        'size': '1.2 MB',
        'reviewed': true,
        'notes': 'Valores conferidos - OK',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Documentos do Cliente',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.blue[700],
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: () => _requestClientDocs(context),
              icon: const Icon(Icons.add_circle_outline, size: 16),
              label: const Text(
                'Solicitar Docs',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        // Lista de documentos do cliente
        ...clientDocs.map<Widget>((doc) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: doc['reviewed'] ? Colors.green[25] : Colors.orange[25],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: doc['reviewed'] ? Colors.green[200]! : Colors.orange[200]!,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header do documento
              Row(
                children: [
                  Icon(
                    Icons.description,
                    color: doc['reviewed'] ? Colors.green[600] : Colors.orange[600],
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      doc['name'],
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  buildStatusBadge(
                    doc['reviewed'] ? 'Revisado' : 'Pendente',
                    backgroundColor: doc['reviewed'] ? Colors.green : Colors.orange,
                    textColor: Colors.white,
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // Informações do documento
              Row(
                children: [
                  Icon(Icons.person_outline, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    doc['uploaded_by'],
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    doc['date'],
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.storage, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    doc['size'],
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              
              if (doc['notes'] != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.note, size: 14, color: Colors.blue[600]),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          doc['notes'],
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.blue[700],
                          ),
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
                    onPressed: () => _downloadClientDoc(context, doc),
                    icon: const Icon(Icons.download, size: 14),
                    label: const Text('Download', style: TextStyle(fontSize: 12)),
                  ),
                  if (!doc['reviewed'])
                    TextButton.icon(
                      onPressed: () => _reviewClientDoc(context, doc),
                      icon: const Icon(Icons.rate_review, size: 14),
                      label: const Text('Revisar', style: TextStyle(fontSize: 12)),
                    ),
                  TextButton.icon(
                    onPressed: () => _addNoteToDoc(context, doc),
                    icon: const Icon(Icons.note_add, size: 14),
                    label: const Text('Nota', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ],
          ),
        )).toList(),
      ],
    );
  }

  Widget _buildProposalDocuments(BuildContext context) {
    final proposalStats = contextualData?['proposal_stats'] ?? {
      'total_proposals': 3,
      'accepted': 1,
      'pending': 1,
      'rejected': 1,
      'total_value': 25000.0,
      'acceptance_rate': 33.3,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Desempenho de Propostas',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.purple[700],
          ),
        ),
        const SizedBox(height: 12),
        
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.purple[50]!,
                Colors.blue[50]!,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.purple[100]!),
          ),
          child: Column(
            children: [
              // Estatísticas principais
              Row(
                children: [
                  Expanded(
                    child: _buildProposalStat(
                      context,
                      'Total Propostas',
                      '${proposalStats['total_proposals']}',
                      Icons.description,
                      Colors.blue,
                    ),
                  ),
                  Expanded(
                    child: _buildProposalStat(
                      context,
                      'Taxa Aceitação',
                      '${proposalStats['acceptance_rate'].toStringAsFixed(1)}%',
                      Icons.trending_up,
                      Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildProposalStat(
                      context,
                      'Valor Total',
                      formatCurrency(proposalStats['total_value']),
                      Icons.attach_money,
                      Colors.green,
                    ),
                  ),
                  Expanded(
                    child: _buildProposalStat(
                      context,
                      'Pendentes',
                      '${proposalStats['pending']}',
                      Icons.schedule,
                      Colors.orange,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Gráfico de status das propostas
              Row(
                children: [
                  Expanded(
                    flex: proposalStats['accepted'],
                    child: Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  if (proposalStats['pending'] > 0) ...[
                    const SizedBox(width: 4),
                    Expanded(
                      flex: proposalStats['pending'],
                      child: Container(
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ],
                  if (proposalStats['rejected'] > 0) ...[
                    const SizedBox(width: 4),
                    Expanded(
                      flex: proposalStats['rejected'],
                      child: Container(
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              
              const SizedBox(height: 8),
              
              // Legenda
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildLegendItem('Aceitas', Colors.green, proposalStats['accepted']),
                  _buildLegendItem('Pendentes', Colors.orange, proposalStats['pending']),
                  _buildLegendItem('Rejeitadas', Colors.red, proposalStats['rejected']),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProposalStat(
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
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
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

  Widget _buildLegendItem(String label, Color color, int count) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '$label ($count)',
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildDocumentMetrics(BuildContext context) {
    final metrics = contextualData?['document_metrics'] ?? {
      'total_documents': 12,
      'client_documents': 6,
      'business_documents': 4,
      'pending_reviews': 2,
      'storage_used': '45.6 MB',
      'response_time': '2.3 horas',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Métricas de Documentos',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.indigo[700],
          ),
        ),
        const SizedBox(height: 12),
        
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.indigo[25],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.indigo[100]!),
          ),
          child: Column(
            children: [
              buildKPIsList([
                KPIItem(
                  icon: '📄',
                  label: 'Total Documentos',
                  value: '${metrics['total_documents']}',
                ),
                KPIItem(
                  icon: '⏱️',
                  label: 'Tempo Resposta',
                  value: metrics['response_time'],
                ),
                KPIItem(
                  icon: '💾',
                  label: 'Armazenamento',
                  value: metrics['storage_used'],
                ),
              ]),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStrategicActions(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: buildActionButton(
                context: context,
                label: 'Nova Proposta',
                icon: Icons.business_center,
                onPressed: () => _createProposal(context),
                backgroundColor: Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: buildActionButton(
                context: context,
                label: 'Solicitar Docs',
                icon: Icons.request_page,
                onPressed: () => _requestClientDocs(context),
                backgroundColor: Colors.blue,
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
                label: 'Relatório',
                icon: Icons.analytics,
                onPressed: () => _generateReport(context),
                backgroundColor: Colors.purple,
                isSecondary: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: buildActionButton(
                context: context,
                label: 'Templates',
                icon: Icons.library_books,
                onPressed: () => _browseTemplates(context),
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
  Color _getDocumentPriorityColor(String urgency) {
    switch (urgency) {
      case 'high': return Colors.red;
      case 'medium': return Colors.orange;
      case 'low': return Colors.green;
      default: return Colors.blue;
    }
  }

  IconData _getBusinessDocIcon(String type) {
    switch (type) {
      case 'proposal': return Icons.business_center;
      case 'contract': return Icons.article;
      case 'analysis': return Icons.analytics;
      default: return Icons.description;
    }
  }

  Color _getBusinessDocStatusColor(String status) {
    switch (status) {
      case 'sent': return Colors.blue;
      case 'approved': return Colors.green;
      case 'rejected': return Colors.red;
      case 'draft': return Colors.orange;
      default: return Colors.grey;
    }
  }

  String _getBusinessDocStatusText(String status) {
    switch (status) {
      case 'sent': return 'Enviado';
      case 'approved': return 'Aprovado';
      case 'rejected': return 'Rejeitado';
      case 'draft': return 'Rascunho';
      default: return 'Desconhecido';
    }
  }

  // Action methods
  void _createBusinessDoc(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Criar Documento de Negócio',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.business_center),
              title: const Text('Proposta Comercial'),
              subtitle: const Text('Template profissional de proposta'),
              onTap: () {
                Navigator.of(context).pop();
                _createFromTemplate(context, 'proposal');
              },
            ),
            ListTile(
              leading: const Icon(Icons.article),
              title: const Text('Contrato'),
              subtitle: const Text('Contrato de prestação de serviços'),
              onTap: () {
                Navigator.of(context).pop();
                _createFromTemplate(context, 'contract');
              },
            ),
            ListTile(
              leading: const Icon(Icons.analytics),
              title: const Text('Análise de Viabilidade'),
              subtitle: const Text('Documento de análise estratégica'),
              onTap: () {
                Navigator.of(context).pop();
                _createFromTemplate(context, 'analysis');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _createFromTemplate(BuildContext context, String type) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Criando documento: $type'),
        backgroundColor: Colors.green,
      ),
    );
    // TODO: Implementar criação de documento
  }

  void _viewBusinessDoc(BuildContext context, Map<String, dynamic> doc) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Visualizando: ${doc['name']}'),
        backgroundColor: Colors.blue,
      ),
    );
    // TODO: Implementar visualização
  }

  void _editBusinessDoc(BuildContext context, Map<String, dynamic> doc) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Editando: ${doc['name']}'),
        backgroundColor: Colors.orange,
      ),
    );
    // TODO: Implementar edição
  }

  void _sendToClient(BuildContext context, Map<String, dynamic> doc) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enviar para Cliente'),
        content: Text('Deseja enviar "${doc['name']}" para o cliente?'),
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

  void _downloadClientDoc(BuildContext context, Map<String, dynamic> doc) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Baixando: ${doc['name']}'),
        backgroundColor: Colors.blue,
      ),
    );
    // TODO: Implementar download
  }

  void _reviewClientDoc(BuildContext context, Map<String, dynamic> doc) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Revisar ${doc['name']}'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Adicionar nota de revisão',
                border: OutlineInputBorder(),
                hintText: 'Ex: Documento válido, proceder com análise...',
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
                SnackBar(
                  content: Text('Documento revisado: ${doc['name']}'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Salvar Revisão'),
          ),
        ],
      ),
    );
  }

  void _addNoteToDoc(BuildContext context, Map<String, dynamic> doc) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Nota - ${doc['name']}'),
        content: const TextField(
          maxLines: 3,
          decoration: InputDecoration(
            labelText: 'Adicionar nota',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  void _requestClientDocs(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Solicitar Documentos ao Cliente',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.work),
              title: const Text('Documentos Trabalhistas'),
              subtitle: const Text('CTPS, contratos, holerites, etc.'),
              onTap: () {
                Navigator.of(context).pop();
                _sendDocRequest(context, 'Trabalhistas');
              },
            ),
            ListTile(
              leading: const Icon(Icons.account_balance),
              title: const Text('Documentos Bancários'),
              subtitle: const Text('Extratos, comprovantes, etc.'),
              onTap: () {
                Navigator.of(context).pop();
                _sendDocRequest(context, 'Bancários');
              },
            ),
            ListTile(
              leading: const Icon(Icons.description),
              title: const Text('Outros Documentos'),
              subtitle: const Text('Especificar documentos necessários'),
              onTap: () {
                Navigator.of(context).pop();
                _sendDocRequest(context, 'Outros');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _sendDocRequest(BuildContext context, String type) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Solicitação enviada: Documentos $type'),
        backgroundColor: Colors.blue,
      ),
    );
    // TODO: Implementar solicitação de documentos
  }

  void _createProposal(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Abrindo criador de propostas...'),
        backgroundColor: Colors.green,
      ),
    );
    // TODO: Implementar criação de proposta
  }

  void _generateReport(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Gerando relatório de documentos...'),
        backgroundColor: Colors.purple,
      ),
    );
    // TODO: Implementar geração de relatório
  }

  void _browseTemplates(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Abrindo biblioteca de templates...'),
        backgroundColor: Colors.indigo,
      ),
    );
    // TODO: Implementar navegação de templates
  }
} 
import '../../../domain/entities/case_detail.dart';
import '../base_info_section.dart';

/// Seção de Documentos Estratégicos para advogados contratantes
/// 
/// **Contexto:** Advogados individuais e escritórios contratantes
/// **Substituição:** DocumentsSection (experiência do cliente)
/// **Foco:** Documentos estratégicos, propostas, contratos e gestão de negócio
/// 
/// Conforme PLANO_DE_ACAO_CONTEXTUAL_VIEW.md:
/// - Substituir DocumentsSection para advogados contratantes
/// - Foco em oportunidade de negócio e documentos estratégicos
class StrategicDocumentsSection extends BaseInfoSection {
  @override
  final Map<String, dynamic>? contextualData;

  const StrategicDocumentsSection({
    required super.caseDetail,
    this.contextualData,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return buildSectionCard(
      title: 'Documentos Estratégicos',
      children: [
        _buildBusinessDocuments(context),
        const SizedBox(height: 16),
        _buildClientDocuments(context),
        const SizedBox(height: 16),
        _buildProposalDocuments(context),
        const SizedBox(height: 16),
        _buildDocumentMetrics(context),
        const SizedBox(height: 20),
        _buildStrategicActions(context),
      ],
    );
  }

  Widget _buildBusinessDocuments(BuildContext context) {
    final businessDocs = contextualData?['business_documents'] ?? [
      {
        'name': 'Proposta Comercial - v2.pdf',
        'type': 'proposal',
        'status': 'sent',
        'client_viewed': true,
        'last_action': 'Enviado ao cliente',
        'date': '15/01/2025',
        'value': 8500.0,
        'urgency': 'high',
      },
      {
        'name': 'Contrato de Prestação de Serviços.docx',
        'type': 'contract',
        'status': 'draft',
        'client_viewed': false,
        'last_action': 'Em elaboração',
        'date': '16/01/2025',
        'value': null,
        'urgency': 'medium',
      },
      {
        'name': 'Análise de Viabilidade.pdf',
        'type': 'analysis',
        'status': 'completed',
        'client_viewed': true,
        'last_action': 'Aprovado pelo cliente',
        'date': '14/01/2025',
        'value': null,
        'urgency': 'low',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Documentos de Negócio',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.green[700],
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: () => _createBusinessDoc(context),
              icon: const Icon(Icons.business_center, size: 16),
              label: const Text(
                'Nova Proposta',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        // Lista de documentos de negócio
        ...businessDocs.map<Widget>((doc) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _getDocumentPriorityColor(doc['urgency']).withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _getDocumentPriorityColor(doc['urgency']).withOpacity(0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header do documento
              Row(
                children: [
                  Icon(
                    _getBusinessDocIcon(doc['type']),
                    color: _getDocumentPriorityColor(doc['urgency']),
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          doc['name'],
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          doc['last_action'],
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
                        _getBusinessDocStatusText(doc['status']),
                        backgroundColor: _getBusinessDocStatusColor(doc['status']),
                        textColor: Colors.white,
                      ),
                      const SizedBox(height: 4),
                      if (doc['value'] != null)
                        Text(
                          formatCurrency(doc['value']),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Colors.green[600],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Status e informações
              Row(
                children: [
                  Icon(
                    doc['client_viewed'] ? Icons.visibility : Icons.visibility_off,
                    size: 16,
                    color: doc['client_viewed'] ? Colors.green : Colors.grey,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    doc['client_viewed'] ? 'Visualizado pelo cliente' : 'Não visualizado',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: doc['client_viewed'] ? Colors.green[600] : Colors.grey[600],
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    doc['date'],
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Ações do documento
              Row(
                children: [
                  TextButton.icon(
                    onPressed: () => _viewBusinessDoc(context, doc),
                    icon: const Icon(Icons.open_in_new, size: 14),
                    label: const Text('Visualizar', style: TextStyle(fontSize: 12)),
                  ),
                  TextButton.icon(
                    onPressed: () => _editBusinessDoc(context, doc),
                    icon: const Icon(Icons.edit, size: 14),
                    label: const Text('Editar', style: TextStyle(fontSize: 12)),
                  ),
                  if (doc['status'] == 'draft')
                    TextButton.icon(
                      onPressed: () => _sendToClient(context, doc),
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

  Widget _buildClientDocuments(BuildContext context) {
    final clientDocs = contextualData?['client_documents'] ?? [
      {
        'name': 'Contrato de Trabalho.pdf',
        'type': 'evidence',
        'uploaded_by': 'Cliente',
        'date': '13/01/2025',
        'size': '2.1 MB',
        'reviewed': true,
        'notes': 'Documento válido - proceder com análise',
      },
      {
        'name': 'Holerites_2024.zip',
        'type': 'evidence',
        'uploaded_by': 'Cliente',
        'date': '13/01/2025',
        'size': '5.8 MB',
        'reviewed': false,
        'notes': null,
      },
      {
        'name': 'Termo_Rescisao.pdf',
        'type': 'evidence',
        'uploaded_by': 'Assistente',
        'date': '14/01/2025',
        'size': '1.2 MB',
        'reviewed': true,
        'notes': 'Valores conferidos - OK',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Documentos do Cliente',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.blue[700],
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: () => _requestClientDocs(context),
              icon: const Icon(Icons.add_circle_outline, size: 16),
              label: const Text(
                'Solicitar Docs',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        // Lista de documentos do cliente
        ...clientDocs.map<Widget>((doc) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: doc['reviewed'] ? Colors.green[25] : Colors.orange[25],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: doc['reviewed'] ? Colors.green[200]! : Colors.orange[200]!,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header do documento
              Row(
                children: [
                  Icon(
                    Icons.description,
                    color: doc['reviewed'] ? Colors.green[600] : Colors.orange[600],
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      doc['name'],
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  buildStatusBadge(
                    doc['reviewed'] ? 'Revisado' : 'Pendente',
                    backgroundColor: doc['reviewed'] ? Colors.green : Colors.orange,
                    textColor: Colors.white,
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // Informações do documento
              Row(
                children: [
                  Icon(Icons.person_outline, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    doc['uploaded_by'],
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    doc['date'],
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.storage, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    doc['size'],
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              
              if (doc['notes'] != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.note, size: 14, color: Colors.blue[600]),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          doc['notes'],
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.blue[700],
                          ),
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
                    onPressed: () => _downloadClientDoc(context, doc),
                    icon: const Icon(Icons.download, size: 14),
                    label: const Text('Download', style: TextStyle(fontSize: 12)),
                  ),
                  if (!doc['reviewed'])
                    TextButton.icon(
                      onPressed: () => _reviewClientDoc(context, doc),
                      icon: const Icon(Icons.rate_review, size: 14),
                      label: const Text('Revisar', style: TextStyle(fontSize: 12)),
                    ),
                  TextButton.icon(
                    onPressed: () => _addNoteToDoc(context, doc),
                    icon: const Icon(Icons.note_add, size: 14),
                    label: const Text('Nota', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ],
          ),
        )).toList(),
      ],
    );
  }

  Widget _buildProposalDocuments(BuildContext context) {
    final proposalStats = contextualData?['proposal_stats'] ?? {
      'total_proposals': 3,
      'accepted': 1,
      'pending': 1,
      'rejected': 1,
      'total_value': 25000.0,
      'acceptance_rate': 33.3,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Desempenho de Propostas',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.purple[700],
          ),
        ),
        const SizedBox(height: 12),
        
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.purple[50]!,
                Colors.blue[50]!,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.purple[100]!),
          ),
          child: Column(
            children: [
              // Estatísticas principais
              Row(
                children: [
                  Expanded(
                    child: _buildProposalStat(
                      context,
                      'Total Propostas',
                      '${proposalStats['total_proposals']}',
                      Icons.description,
                      Colors.blue,
                    ),
                  ),
                  Expanded(
                    child: _buildProposalStat(
                      context,
                      'Taxa Aceitação',
                      '${proposalStats['acceptance_rate'].toStringAsFixed(1)}%',
                      Icons.trending_up,
                      Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildProposalStat(
                      context,
                      'Valor Total',
                      formatCurrency(proposalStats['total_value']),
                      Icons.attach_money,
                      Colors.green,
                    ),
                  ),
                  Expanded(
                    child: _buildProposalStat(
                      context,
                      'Pendentes',
                      '${proposalStats['pending']}',
                      Icons.schedule,
                      Colors.orange,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Gráfico de status das propostas
              Row(
                children: [
                  Expanded(
                    flex: proposalStats['accepted'],
                    child: Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  if (proposalStats['pending'] > 0) ...[
                    const SizedBox(width: 4),
                    Expanded(
                      flex: proposalStats['pending'],
                      child: Container(
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ],
                  if (proposalStats['rejected'] > 0) ...[
                    const SizedBox(width: 4),
                    Expanded(
                      flex: proposalStats['rejected'],
                      child: Container(
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              
              const SizedBox(height: 8),
              
              // Legenda
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildLegendItem('Aceitas', Colors.green, proposalStats['accepted']),
                  _buildLegendItem('Pendentes', Colors.orange, proposalStats['pending']),
                  _buildLegendItem('Rejeitadas', Colors.red, proposalStats['rejected']),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProposalStat(
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
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
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

  Widget _buildLegendItem(String label, Color color, int count) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '$label ($count)',
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildDocumentMetrics(BuildContext context) {
    final metrics = contextualData?['document_metrics'] ?? {
      'total_documents': 12,
      'client_documents': 6,
      'business_documents': 4,
      'pending_reviews': 2,
      'storage_used': '45.6 MB',
      'response_time': '2.3 horas',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Métricas de Documentos',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.indigo[700],
          ),
        ),
        const SizedBox(height: 12),
        
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.indigo[25],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.indigo[100]!),
          ),
          child: Column(
            children: [
              buildKPIsList([
                KPIItem(
                  icon: '📄',
                  label: 'Total Documentos',
                  value: '${metrics['total_documents']}',
                ),
                KPIItem(
                  icon: '⏱️',
                  label: 'Tempo Resposta',
                  value: metrics['response_time'],
                ),
                KPIItem(
                  icon: '💾',
                  label: 'Armazenamento',
                  value: metrics['storage_used'],
                ),
              ]),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStrategicActions(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: buildActionButton(
                context: context,
                label: 'Nova Proposta',
                icon: Icons.business_center,
                onPressed: () => _createProposal(context),
                backgroundColor: Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: buildActionButton(
                context: context,
                label: 'Solicitar Docs',
                icon: Icons.request_page,
                onPressed: () => _requestClientDocs(context),
                backgroundColor: Colors.blue,
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
                label: 'Relatório',
                icon: Icons.analytics,
                onPressed: () => _generateReport(context),
                backgroundColor: Colors.purple,
                isSecondary: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: buildActionButton(
                context: context,
                label: 'Templates',
                icon: Icons.library_books,
                onPressed: () => _browseTemplates(context),
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
  Color _getDocumentPriorityColor(String urgency) {
    switch (urgency) {
      case 'high': return Colors.red;
      case 'medium': return Colors.orange;
      case 'low': return Colors.green;
      default: return Colors.blue;
    }
  }

  IconData _getBusinessDocIcon(String type) {
    switch (type) {
      case 'proposal': return Icons.business_center;
      case 'contract': return Icons.article;
      case 'analysis': return Icons.analytics;
      default: return Icons.description;
    }
  }

  Color _getBusinessDocStatusColor(String status) {
    switch (status) {
      case 'sent': return Colors.blue;
      case 'approved': return Colors.green;
      case 'rejected': return Colors.red;
      case 'draft': return Colors.orange;
      default: return Colors.grey;
    }
  }

  String _getBusinessDocStatusText(String status) {
    switch (status) {
      case 'sent': return 'Enviado';
      case 'approved': return 'Aprovado';
      case 'rejected': return 'Rejeitado';
      case 'draft': return 'Rascunho';
      default: return 'Desconhecido';
    }
  }

  // Action methods
  void _createBusinessDoc(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Criar Documento de Negócio',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.business_center),
              title: const Text('Proposta Comercial'),
              subtitle: const Text('Template profissional de proposta'),
              onTap: () {
                Navigator.of(context).pop();
                _createFromTemplate(context, 'proposal');
              },
            ),
            ListTile(
              leading: const Icon(Icons.article),
              title: const Text('Contrato'),
              subtitle: const Text('Contrato de prestação de serviços'),
              onTap: () {
                Navigator.of(context).pop();
                _createFromTemplate(context, 'contract');
              },
            ),
            ListTile(
              leading: const Icon(Icons.analytics),
              title: const Text('Análise de Viabilidade'),
              subtitle: const Text('Documento de análise estratégica'),
              onTap: () {
                Navigator.of(context).pop();
                _createFromTemplate(context, 'analysis');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _createFromTemplate(BuildContext context, String type) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Criando documento: $type'),
        backgroundColor: Colors.green,
      ),
    );
    // TODO: Implementar criação de documento
  }

  void _viewBusinessDoc(BuildContext context, Map<String, dynamic> doc) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Visualizando: ${doc['name']}'),
        backgroundColor: Colors.blue,
      ),
    );
    // TODO: Implementar visualização
  }

  void _editBusinessDoc(BuildContext context, Map<String, dynamic> doc) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Editando: ${doc['name']}'),
        backgroundColor: Colors.orange,
      ),
    );
    // TODO: Implementar edição
  }

  void _sendToClient(BuildContext context, Map<String, dynamic> doc) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enviar para Cliente'),
        content: Text('Deseja enviar "${doc['name']}" para o cliente?'),
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

  void _downloadClientDoc(BuildContext context, Map<String, dynamic> doc) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Baixando: ${doc['name']}'),
        backgroundColor: Colors.blue,
      ),
    );
    // TODO: Implementar download
  }

  void _reviewClientDoc(BuildContext context, Map<String, dynamic> doc) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Revisar ${doc['name']}'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Adicionar nota de revisão',
                border: OutlineInputBorder(),
                hintText: 'Ex: Documento válido, proceder com análise...',
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
                SnackBar(
                  content: Text('Documento revisado: ${doc['name']}'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Salvar Revisão'),
          ),
        ],
      ),
    );
  }

  void _addNoteToDoc(BuildContext context, Map<String, dynamic> doc) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Nota - ${doc['name']}'),
        content: const TextField(
          maxLines: 3,
          decoration: InputDecoration(
            labelText: 'Adicionar nota',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  void _requestClientDocs(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Solicitar Documentos ao Cliente',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.work),
              title: const Text('Documentos Trabalhistas'),
              subtitle: const Text('CTPS, contratos, holerites, etc.'),
              onTap: () {
                Navigator.of(context).pop();
                _sendDocRequest(context, 'Trabalhistas');
              },
            ),
            ListTile(
              leading: const Icon(Icons.account_balance),
              title: const Text('Documentos Bancários'),
              subtitle: const Text('Extratos, comprovantes, etc.'),
              onTap: () {
                Navigator.of(context).pop();
                _sendDocRequest(context, 'Bancários');
              },
            ),
            ListTile(
              leading: const Icon(Icons.description),
              title: const Text('Outros Documentos'),
              subtitle: const Text('Especificar documentos necessários'),
              onTap: () {
                Navigator.of(context).pop();
                _sendDocRequest(context, 'Outros');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _sendDocRequest(BuildContext context, String type) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Solicitação enviada: Documentos $type'),
        backgroundColor: Colors.blue,
      ),
    );
    // TODO: Implementar solicitação de documentos
  }

  void _createProposal(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Abrindo criador de propostas...'),
        backgroundColor: Colors.green,
      ),
    );
    // TODO: Implementar criação de proposta
  }

  void _generateReport(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Gerando relatório de documentos...'),
        backgroundColor: Colors.purple,
      ),
    );
    // TODO: Implementar geração de relatório
  }

  void _browseTemplates(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Abrindo biblioteca de templates...'),
        backgroundColor: Colors.indigo,
      ),
    );
    // TODO: Implementar navegação de templates
  }
} 