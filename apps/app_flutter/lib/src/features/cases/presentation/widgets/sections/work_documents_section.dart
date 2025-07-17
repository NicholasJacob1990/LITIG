import 'package:flutter/material.dart';
import '../../../domain/entities/case_detail.dart';
import '../base_info_section.dart';

/// Seção de Documentos de Trabalho para advogados associados
/// 
/// **Contexto:** Advogados associados (lawyer_associated)
/// **Substituição:** DocumentsSection (experiência do cliente)
/// **Foco:** Documentos de trabalho, templates, versioning e colaboração
/// 
/// Conforme PLANO_DE_ACAO_CONTEXTUAL_VIEW.md:
/// - Substituir DocumentsSection para advogados associados
/// - Foco em produtividade e gestão de documentos de trabalho
class WorkDocumentsSection extends BaseInfoSection {
  @override
  final Map<String, dynamic>? contextualData;

  const WorkDocumentsSection({
    required super.caseDetail,
    this.contextualData,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return buildSectionCard(
      title: 'Documentos de Trabalho',
      children: [
        _buildActiveDocuments(context),
        const SizedBox(height: 16),
        _buildDocumentCategories(context),
        const SizedBox(height: 16),
        _buildRecentActivity(context),
        const SizedBox(height: 16),
        _buildCollaborationStatus(context),
        const SizedBox(height: 20),
        _buildDocumentActions(context),
      ],
    );
  }

  Widget _buildActiveDocuments(BuildContext context) {
    final activeDocuments = contextualData?['active_documents'] ?? [
      {
        'name': 'Petição Inicial - v3.docx',
        'type': 'petition',
        'status': 'in_progress',
        'last_modified': '16/01/2025 14:30',
        'owner': 'Você',
        'size': '2.3 MB',
        'comments_count': 3,
      },
      {
        'name': 'Análise Documental.pdf',
        'type': 'analysis',
        'status': 'completed',
        'last_modified': '15/01/2025 16:45',
        'owner': 'Você',
        'size': '1.8 MB',
        'comments_count': 0,
      },
      {
        'name': 'Pesquisa Jurisprudencial.docx',
        'type': 'research',
        'status': 'pending',
        'last_modified': '14/01/2025 10:15',
        'owner': 'Dr. Silva',
        'size': '850 KB',
        'comments_count': 1,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Documentos Ativos',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.blue[700],
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: () => _createNewDocument(context),
              icon: const Icon(Icons.add, size: 16),
              label: const Text(
                'Novo Documento',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        // Lista de documentos ativos
        ...activeDocuments.map<Widget>((doc) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _getDocumentStatusColor(doc['status']).withOpacity(0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _getDocumentStatusColor(doc['status']).withOpacity(0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header do documento
              Row(
                children: [
                  Icon(
                    _getDocumentTypeIcon(doc['type']),
                    color: _getDocumentStatusColor(doc['status']),
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
                    _getDocumentStatusText(doc['status']),
                    backgroundColor: _getDocumentStatusColor(doc['status']),
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
                    doc['owner'],
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    doc['last_modified'],
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
              
              if (doc['comments_count'] > 0) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.comment_outlined, size: 14, color: Colors.orange[600]),
                    const SizedBox(width: 4),
                    Text(
                      '${doc['comments_count']} comentário${doc['comments_count'] > 1 ? 's' : ''}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.orange[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
              
              const SizedBox(height: 8),
              
              // Ações do documento
              Row(
                children: [
                  TextButton.icon(
                    onPressed: () => _openDocument(context, doc),
                    icon: const Icon(Icons.open_in_new, size: 14),
                    label: const Text('Abrir', style: TextStyle(fontSize: 12)),
                  ),
                  TextButton.icon(
                    onPressed: () => _editDocument(context, doc),
                    icon: const Icon(Icons.edit, size: 14),
                    label: const Text('Editar', style: TextStyle(fontSize: 12)),
                  ),
                  if (doc['comments_count'] > 0)
                    TextButton.icon(
                      onPressed: () => _viewComments(context, doc),
                      icon: const Icon(Icons.comment, size: 14),
                      label: const Text('Comentários', style: TextStyle(fontSize: 12)),
                    ),
                ],
              ),
            ],
          ),
        )).toList(),
      ],
    );
  }

  Widget _buildDocumentCategories(BuildContext context) {
    final categories = [
      {
        'name': 'Petições',
        'count': 2,
        'icon': Icons.description,
        'color': Colors.blue,
      },
      {
        'name': 'Análises',
        'count': 3,
        'icon': Icons.analytics,
        'color': Colors.green,
      },
      {
        'name': 'Pesquisas',
        'count': 1,
        'icon': Icons.search,
        'color': Colors.orange,
      },
      {
        'name': 'Rascunhos',
        'count': 4,
        'icon': Icons.draft,
        'color': Colors.purple,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Categorias de Documentos',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.blue[700],
          ),
        ),
        const SizedBox(height: 12),
        
        // Grid de categorias
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 2.5,
          ),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final category = categories[index];
            return InkWell(
              onTap: () => _filterByCategory(context, category['name'] as String),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (category['color'] as Color).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: (category['color'] as Color).withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      category['icon'] as IconData,
                      color: category['color'] as Color,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            category['name'] as String,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '${category['count']} itens',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildRecentActivity(BuildContext context) {
    final recentActivity = contextualData?['recent_activity'] ?? [
      {
        'action': 'commented',
        'document': 'Petição Inicial - v3.docx',
        'user': 'Dr. Silva',
        'time': '2h atrás',
        'comment': 'Revisar parágrafo sobre danos morais',
      },
      {
        'action': 'uploaded',
        'document': 'Contrato_Trabalho_Digitalizado.pdf',
        'user': 'Cliente',
        'time': '4h atrás',
        'comment': null,
      },
      {
        'action': 'modified',
        'document': 'Análise Documental.pdf',
        'user': 'Você',
        'time': '1 dia atrás',
        'comment': null,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Atividade Recente',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.blue[700],
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: () => _viewAllActivity(context),
              icon: const Icon(Icons.history, size: 16),
              label: const Text(
                'Ver Tudo',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        // Lista de atividades recentes
        ...recentActivity.map<Widget>((activity) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: _getActivityColor(activity['action']).withOpacity(0.2),
                child: Icon(
                  _getActivityIcon(activity['action']),
                  color: _getActivityColor(activity['action']),
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        style: Theme.of(context).textTheme.bodySmall,
                        children: [
                          TextSpan(
                            text: activity['user'],
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          TextSpan(
                            text: ' ${_getActivityText(activity['action'])} ',
                          ),
                          TextSpan(
                            text: activity['document'],
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                    if (activity['comment'] != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        '"${activity['comment']}"',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                activity['time'],
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        )).toList(),
      ],
    );
  }

  Widget _buildCollaborationStatus(BuildContext context) {
    final collaborationData = contextualData?['collaboration'] ?? {
      'total_documents': 8,
      'shared_documents': 5,
      'pending_reviews': 2,
      'active_collaborators': 3,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Status de Colaboração',
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
              // Métricas de colaboração
              Row(
                children: [
                  Expanded(
                    child: _buildCollaborationMetric(
                      context,
                      'Total',
                      '${collaborationData['total_documents']}',
                      Icons.description,
                      Colors.blue,
                    ),
                  ),
                  Expanded(
                    child: _buildCollaborationMetric(
                      context,
                      'Compartilhados',
                      '${collaborationData['shared_documents']}',
                      Icons.share,
                      Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildCollaborationMetric(
                      context,
                      'Revisões Pendentes',
                      '${collaborationData['pending_reviews']}',
                      Icons.rate_review,
                      Colors.orange,
                    ),
                  ),
                  Expanded(
                    child: _buildCollaborationMetric(
                      context,
                      'Colaboradores',
                      '${collaborationData['active_collaborators']}',
                      Icons.people,
                      Colors.purple,
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

  Widget _buildCollaborationMetric(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
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

  Widget _buildDocumentActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: buildActionButton(
            context: context,
            label: 'Upload Documento',
            icon: Icons.upload_file,
            onPressed: () => _uploadDocument(context),
            backgroundColor: Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: buildActionButton(
            context: context,
            label: 'Templates',
            icon: Icons.library_books,
            onPressed: () => _browseTemplates(context),
            backgroundColor: Colors.green,
            isSecondary: true,
          ),
        ),
      ],
    );
  }

  // Helper methods
  Color _getDocumentStatusColor(String status) {
    switch (status) {
      case 'completed': return Colors.green;
      case 'in_progress': return Colors.blue;
      case 'pending': return Colors.orange;
      case 'draft': return Colors.purple;
      default: return Colors.grey;
    }
  }

  String _getDocumentStatusText(String status) {
    switch (status) {
      case 'completed': return 'Concluído';
      case 'in_progress': return 'Em Progresso';
      case 'pending': return 'Pendente';
      case 'draft': return 'Rascunho';
      default: return 'Desconhecido';
    }
  }

  IconData _getDocumentTypeIcon(String type) {
    switch (type) {
      case 'petition': return Icons.description;
      case 'analysis': return Icons.analytics;
      case 'research': return Icons.search;
      case 'contract': return Icons.article;
      default: return Icons.description;
    }
  }

  Color _getActivityColor(String action) {
    switch (action) {
      case 'commented': return Colors.orange;
      case 'uploaded': return Colors.blue;
      case 'modified': return Colors.green;
      case 'deleted': return Colors.red;
      default: return Colors.grey;
    }
  }

  IconData _getActivityIcon(String action) {
    switch (action) {
      case 'commented': return Icons.comment;
      case 'uploaded': return Icons.upload;
      case 'modified': return Icons.edit;
      case 'deleted': return Icons.delete;
      default: return Icons.info;
    }
  }

  String _getActivityText(String action) {
    switch (action) {
      case 'commented': return 'comentou em';
      case 'uploaded': return 'enviou';
      case 'modified': return 'modificou';
      case 'deleted': return 'deletou';
      default: return 'interagiu com';
    }
  }

  // Action methods
  void _createNewDocument(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Criar Novo Documento',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.description),
              title: const Text('Petição'),
              subtitle: const Text('Template para petições iniciais'),
              onTap: () {
                Navigator.of(context).pop();
                _createFromTemplate(context, 'petition');
              },
            ),
            ListTile(
              leading: const Icon(Icons.analytics),
              title: const Text('Análise'),
              subtitle: const Text('Documento de análise jurídica'),
              onTap: () {
                Navigator.of(context).pop();
                _createFromTemplate(context, 'analysis');
              },
            ),
            ListTile(
              leading: const Icon(Icons.article),
              title: const Text('Documento em branco'),
              subtitle: const Text('Começar do zero'),
              onTap: () {
                Navigator.of(context).pop();
                _createFromTemplate(context, 'blank');
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
        content: Text('Criando documento do tipo: $type'),
        backgroundColor: Colors.blue,
      ),
    );
    // TODO: Implementar criação de documento
  }

  void _openDocument(BuildContext context, Map<String, dynamic> doc) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Abrindo: ${doc['name']}'),
        backgroundColor: Colors.blue,
      ),
    );
    // TODO: Implementar abertura de documento
  }

  void _editDocument(BuildContext context, Map<String, dynamic> doc) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Editando: ${doc['name']}'),
        backgroundColor: Colors.green,
      ),
    );
    // TODO: Implementar edição de documento
  }

  void _viewComments(BuildContext context, Map<String, dynamic> doc) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Comentários - ${doc['name']}'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: CircleAvatar(child: Text('DS')),
              title: Text('Dr. Silva'),
              subtitle: Text('Revisar parágrafo sobre danos morais'),
            ),
            ListTile(
              leading: CircleAvatar(child: Text('MO')),
              title: Text('Maria Oliveira'),
              subtitle: Text('Formatação está perfeita!'),
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

  void _filterByCategory(BuildContext context, String category) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Filtrando por categoria: $category'),
        backgroundColor: Colors.orange,
      ),
    );
    // TODO: Implementar filtro por categoria
  }

  void _viewAllActivity(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Abrindo histórico completo de atividades...'),
        backgroundColor: Colors.purple,
      ),
    );
    // TODO: Implementar visualização completa de atividades
  }

  void _uploadDocument(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Abrindo seletor de arquivos...'),
        backgroundColor: Colors.blue,
      ),
    );
    // TODO: Implementar upload de documento
  }

  void _browseTemplates(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Abrindo biblioteca de templates...'),
        backgroundColor: Colors.green,
      ),
    );
    // TODO: Implementar navegação de templates
  }
} 
import '../../../domain/entities/case_detail.dart';
import '../base_info_section.dart';

/// Seção de Documentos de Trabalho para advogados associados
/// 
/// **Contexto:** Advogados associados (lawyer_associated)
/// **Substituição:** DocumentsSection (experiência do cliente)
/// **Foco:** Documentos de trabalho, templates, versioning e colaboração
/// 
/// Conforme PLANO_DE_ACAO_CONTEXTUAL_VIEW.md:
/// - Substituir DocumentsSection para advogados associados
/// - Foco em produtividade e gestão de documentos de trabalho
class WorkDocumentsSection extends BaseInfoSection {
  @override
  final Map<String, dynamic>? contextualData;

  const WorkDocumentsSection({
    required super.caseDetail,
    this.contextualData,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return buildSectionCard(
      title: 'Documentos de Trabalho',
      children: [
        _buildActiveDocuments(context),
        const SizedBox(height: 16),
        _buildDocumentCategories(context),
        const SizedBox(height: 16),
        _buildRecentActivity(context),
        const SizedBox(height: 16),
        _buildCollaborationStatus(context),
        const SizedBox(height: 20),
        _buildDocumentActions(context),
      ],
    );
  }

  Widget _buildActiveDocuments(BuildContext context) {
    final activeDocuments = contextualData?['active_documents'] ?? [
      {
        'name': 'Petição Inicial - v3.docx',
        'type': 'petition',
        'status': 'in_progress',
        'last_modified': '16/01/2025 14:30',
        'owner': 'Você',
        'size': '2.3 MB',
        'comments_count': 3,
      },
      {
        'name': 'Análise Documental.pdf',
        'type': 'analysis',
        'status': 'completed',
        'last_modified': '15/01/2025 16:45',
        'owner': 'Você',
        'size': '1.8 MB',
        'comments_count': 0,
      },
      {
        'name': 'Pesquisa Jurisprudencial.docx',
        'type': 'research',
        'status': 'pending',
        'last_modified': '14/01/2025 10:15',
        'owner': 'Dr. Silva',
        'size': '850 KB',
        'comments_count': 1,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Documentos Ativos',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.blue[700],
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: () => _createNewDocument(context),
              icon: const Icon(Icons.add, size: 16),
              label: const Text(
                'Novo Documento',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        // Lista de documentos ativos
        ...activeDocuments.map<Widget>((doc) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _getDocumentStatusColor(doc['status']).withOpacity(0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _getDocumentStatusColor(doc['status']).withOpacity(0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header do documento
              Row(
                children: [
                  Icon(
                    _getDocumentTypeIcon(doc['type']),
                    color: _getDocumentStatusColor(doc['status']),
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
                    _getDocumentStatusText(doc['status']),
                    backgroundColor: _getDocumentStatusColor(doc['status']),
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
                    doc['owner'],
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    doc['last_modified'],
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
              
              if (doc['comments_count'] > 0) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.comment_outlined, size: 14, color: Colors.orange[600]),
                    const SizedBox(width: 4),
                    Text(
                      '${doc['comments_count']} comentário${doc['comments_count'] > 1 ? 's' : ''}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.orange[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
              
              const SizedBox(height: 8),
              
              // Ações do documento
              Row(
                children: [
                  TextButton.icon(
                    onPressed: () => _openDocument(context, doc),
                    icon: const Icon(Icons.open_in_new, size: 14),
                    label: const Text('Abrir', style: TextStyle(fontSize: 12)),
                  ),
                  TextButton.icon(
                    onPressed: () => _editDocument(context, doc),
                    icon: const Icon(Icons.edit, size: 14),
                    label: const Text('Editar', style: TextStyle(fontSize: 12)),
                  ),
                  if (doc['comments_count'] > 0)
                    TextButton.icon(
                      onPressed: () => _viewComments(context, doc),
                      icon: const Icon(Icons.comment, size: 14),
                      label: const Text('Comentários', style: TextStyle(fontSize: 12)),
                    ),
                ],
              ),
            ],
          ),
        )).toList(),
      ],
    );
  }

  Widget _buildDocumentCategories(BuildContext context) {
    final categories = [
      {
        'name': 'Petições',
        'count': 2,
        'icon': Icons.description,
        'color': Colors.blue,
      },
      {
        'name': 'Análises',
        'count': 3,
        'icon': Icons.analytics,
        'color': Colors.green,
      },
      {
        'name': 'Pesquisas',
        'count': 1,
        'icon': Icons.search,
        'color': Colors.orange,
      },
      {
        'name': 'Rascunhos',
        'count': 4,
        'icon': Icons.draft,
        'color': Colors.purple,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Categorias de Documentos',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.blue[700],
          ),
        ),
        const SizedBox(height: 12),
        
        // Grid de categorias
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 2.5,
          ),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final category = categories[index];
            return InkWell(
              onTap: () => _filterByCategory(context, category['name'] as String),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (category['color'] as Color).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: (category['color'] as Color).withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      category['icon'] as IconData,
                      color: category['color'] as Color,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            category['name'] as String,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '${category['count']} itens',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildRecentActivity(BuildContext context) {
    final recentActivity = contextualData?['recent_activity'] ?? [
      {
        'action': 'commented',
        'document': 'Petição Inicial - v3.docx',
        'user': 'Dr. Silva',
        'time': '2h atrás',
        'comment': 'Revisar parágrafo sobre danos morais',
      },
      {
        'action': 'uploaded',
        'document': 'Contrato_Trabalho_Digitalizado.pdf',
        'user': 'Cliente',
        'time': '4h atrás',
        'comment': null,
      },
      {
        'action': 'modified',
        'document': 'Análise Documental.pdf',
        'user': 'Você',
        'time': '1 dia atrás',
        'comment': null,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Atividade Recente',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.blue[700],
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: () => _viewAllActivity(context),
              icon: const Icon(Icons.history, size: 16),
              label: const Text(
                'Ver Tudo',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        // Lista de atividades recentes
        ...recentActivity.map<Widget>((activity) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: _getActivityColor(activity['action']).withOpacity(0.2),
                child: Icon(
                  _getActivityIcon(activity['action']),
                  color: _getActivityColor(activity['action']),
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        style: Theme.of(context).textTheme.bodySmall,
                        children: [
                          TextSpan(
                            text: activity['user'],
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          TextSpan(
                            text: ' ${_getActivityText(activity['action'])} ',
                          ),
                          TextSpan(
                            text: activity['document'],
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                    if (activity['comment'] != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        '"${activity['comment']}"',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                activity['time'],
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        )).toList(),
      ],
    );
  }

  Widget _buildCollaborationStatus(BuildContext context) {
    final collaborationData = contextualData?['collaboration'] ?? {
      'total_documents': 8,
      'shared_documents': 5,
      'pending_reviews': 2,
      'active_collaborators': 3,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Status de Colaboração',
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
              // Métricas de colaboração
              Row(
                children: [
                  Expanded(
                    child: _buildCollaborationMetric(
                      context,
                      'Total',
                      '${collaborationData['total_documents']}',
                      Icons.description,
                      Colors.blue,
                    ),
                  ),
                  Expanded(
                    child: _buildCollaborationMetric(
                      context,
                      'Compartilhados',
                      '${collaborationData['shared_documents']}',
                      Icons.share,
                      Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildCollaborationMetric(
                      context,
                      'Revisões Pendentes',
                      '${collaborationData['pending_reviews']}',
                      Icons.rate_review,
                      Colors.orange,
                    ),
                  ),
                  Expanded(
                    child: _buildCollaborationMetric(
                      context,
                      'Colaboradores',
                      '${collaborationData['active_collaborators']}',
                      Icons.people,
                      Colors.purple,
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

  Widget _buildCollaborationMetric(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
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

  Widget _buildDocumentActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: buildActionButton(
            context: context,
            label: 'Upload Documento',
            icon: Icons.upload_file,
            onPressed: () => _uploadDocument(context),
            backgroundColor: Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: buildActionButton(
            context: context,
            label: 'Templates',
            icon: Icons.library_books,
            onPressed: () => _browseTemplates(context),
            backgroundColor: Colors.green,
            isSecondary: true,
          ),
        ),
      ],
    );
  }

  // Helper methods
  Color _getDocumentStatusColor(String status) {
    switch (status) {
      case 'completed': return Colors.green;
      case 'in_progress': return Colors.blue;
      case 'pending': return Colors.orange;
      case 'draft': return Colors.purple;
      default: return Colors.grey;
    }
  }

  String _getDocumentStatusText(String status) {
    switch (status) {
      case 'completed': return 'Concluído';
      case 'in_progress': return 'Em Progresso';
      case 'pending': return 'Pendente';
      case 'draft': return 'Rascunho';
      default: return 'Desconhecido';
    }
  }

  IconData _getDocumentTypeIcon(String type) {
    switch (type) {
      case 'petition': return Icons.description;
      case 'analysis': return Icons.analytics;
      case 'research': return Icons.search;
      case 'contract': return Icons.article;
      default: return Icons.description;
    }
  }

  Color _getActivityColor(String action) {
    switch (action) {
      case 'commented': return Colors.orange;
      case 'uploaded': return Colors.blue;
      case 'modified': return Colors.green;
      case 'deleted': return Colors.red;
      default: return Colors.grey;
    }
  }

  IconData _getActivityIcon(String action) {
    switch (action) {
      case 'commented': return Icons.comment;
      case 'uploaded': return Icons.upload;
      case 'modified': return Icons.edit;
      case 'deleted': return Icons.delete;
      default: return Icons.info;
    }
  }

  String _getActivityText(String action) {
    switch (action) {
      case 'commented': return 'comentou em';
      case 'uploaded': return 'enviou';
      case 'modified': return 'modificou';
      case 'deleted': return 'deletou';
      default: return 'interagiu com';
    }
  }

  // Action methods
  void _createNewDocument(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Criar Novo Documento',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.description),
              title: const Text('Petição'),
              subtitle: const Text('Template para petições iniciais'),
              onTap: () {
                Navigator.of(context).pop();
                _createFromTemplate(context, 'petition');
              },
            ),
            ListTile(
              leading: const Icon(Icons.analytics),
              title: const Text('Análise'),
              subtitle: const Text('Documento de análise jurídica'),
              onTap: () {
                Navigator.of(context).pop();
                _createFromTemplate(context, 'analysis');
              },
            ),
            ListTile(
              leading: const Icon(Icons.article),
              title: const Text('Documento em branco'),
              subtitle: const Text('Começar do zero'),
              onTap: () {
                Navigator.of(context).pop();
                _createFromTemplate(context, 'blank');
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
        content: Text('Criando documento do tipo: $type'),
        backgroundColor: Colors.blue,
      ),
    );
    // TODO: Implementar criação de documento
  }

  void _openDocument(BuildContext context, Map<String, dynamic> doc) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Abrindo: ${doc['name']}'),
        backgroundColor: Colors.blue,
      ),
    );
    // TODO: Implementar abertura de documento
  }

  void _editDocument(BuildContext context, Map<String, dynamic> doc) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Editando: ${doc['name']}'),
        backgroundColor: Colors.green,
      ),
    );
    // TODO: Implementar edição de documento
  }

  void _viewComments(BuildContext context, Map<String, dynamic> doc) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Comentários - ${doc['name']}'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: CircleAvatar(child: Text('DS')),
              title: Text('Dr. Silva'),
              subtitle: Text('Revisar parágrafo sobre danos morais'),
            ),
            ListTile(
              leading: CircleAvatar(child: Text('MO')),
              title: Text('Maria Oliveira'),
              subtitle: Text('Formatação está perfeita!'),
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

  void _filterByCategory(BuildContext context, String category) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Filtrando por categoria: $category'),
        backgroundColor: Colors.orange,
      ),
    );
    // TODO: Implementar filtro por categoria
  }

  void _viewAllActivity(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Abrindo histórico completo de atividades...'),
        backgroundColor: Colors.purple,
      ),
    );
    // TODO: Implementar visualização completa de atividades
  }

  void _uploadDocument(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Abrindo seletor de arquivos...'),
        backgroundColor: Colors.blue,
      ),
    );
    // TODO: Implementar upload de documento
  }

  void _browseTemplates(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Abrindo biblioteca de templates...'),
        backgroundColor: Colors.green,
      ),
    );
    // TODO: Implementar navegação de templates
  }
} 