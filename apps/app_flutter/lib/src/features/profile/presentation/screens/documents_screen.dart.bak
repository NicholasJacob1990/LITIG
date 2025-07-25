import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/client_profile.dart';
import '../bloc/profile_bloc.dart';
import '../bloc/profile_event.dart';
import '../bloc/profile_state.dart';
import '../widgets/document_widgets.dart';
import '../../../../shared/widgets/skeleton_loader.dart';

class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({super.key});

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<ProfileBloc>().add(const LoadProfile('current_user'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Documentos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddDocumentDialog,
          ),
        ],
      ),
      body: BlocConsumer<ProfileBloc, ProfileState>(
        listener: (context, state) {
          if (state is ProfileError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is ProfileLoading) {
            return const DocumentsSkeletonLoader();
          }
          
          if (state is ProfileLoaded) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  DocumentsStatusCard(
                    totalDocuments: state.profile.documents.length,
                    verifiedDocuments: state.profile.documents.where((d) => d.status == DocumentStatus.verified).length,
                    pendingDocuments: state.profile.documents.where((d) => d.status == DocumentStatus.pending).length,
                    expiredDocuments: state.profile.documents.where((d) => d.status == DocumentStatus.expired).length,
                  ),
                  
                  const SizedBox(height: 24),
                  
                  RequiredDocumentsSection(
                    clientType: state.profile.type,
                    documents: state.profile.documents,
                    onUploadDocument: _uploadDocument,
                  ),
                  
                  const SizedBox(height: 24),
                  
                  if (state.profile.documents.isNotEmpty) 
                    DocumentsList(
                      documents: state.profile.documents,
                      onViewDocument: _viewDocument,
                      onDeleteDocument: _deleteDocument,
                      onReplaceDocument: _replaceDocument,
                    )
                  else
                    const EmptyDocumentsWidget(),
                ],
              ),
            );
          }
          
          return const DocumentsErrorWidget();
        },
      ),
    );
  }
  
  void _showAddDocumentDialog() {
    final profileState = context.read<ProfileBloc>().state;
    if (profileState is ProfileLoaded) {
      showDialog(
        context: context,
        builder: (context) => AddDocumentDialog(
          clientType: profileState.profile.type,
          onDocumentAdded: (document) => _uploadDocument(document.type),
        ),
      );
    }
  }

  void _uploadDocument(DocumentType type) {
    // TODO: Implementar lógica de upload
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Funcionalidade de upload será implementada'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _viewDocument(Document document) {
    showDialog(
      context: context,
      builder: (context) => DocumentViewDialog(document: document),
    );
  }

  void _deleteDocument(Document document) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir Documento'),
        content: Text('Tem certeza que deseja excluir o documento "${document.originalFileName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Implementar exclusão
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Documento excluído com sucesso'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }

  void _replaceDocument(Document document) {
    // TODO: Implementar substituição de documento
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Funcionalidade de substituição será implementada'),
        backgroundColor: Colors.blue,
      ),
    );
  }
}

class DocumentsStatusCard extends StatelessWidget {
  final int totalDocuments;
  final int verifiedDocuments;
  final int pendingDocuments;
  final int expiredDocuments;
  
  const DocumentsStatusCard({
    super.key,
    required this.totalDocuments,
    required this.verifiedDocuments,
    required this.pendingDocuments,
    required this.expiredDocuments,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Status dos Documentos', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: _StatusIndicator(
                    icon: Icons.folder,
                    label: 'Total',
                    count: totalDocuments,
                    color: Colors.blue,
                  ),
                ),
                Expanded(
                  child: _StatusIndicator(
                    icon: Icons.check_circle,
                    label: 'Verificados',
                    count: verifiedDocuments,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(
                  child: _StatusIndicator(
                    icon: Icons.schedule,
                    label: 'Pendentes',
                    count: pendingDocuments,
                    color: Colors.orange,
                  ),
                ),
                Expanded(
                  child: _StatusIndicator(
                    icon: Icons.warning,
                    label: 'Expirados',
                    count: expiredDocuments,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusIndicator extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;
  final Color color;
  
  const _StatusIndicator({
    required this.icon,
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            '$count',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class RequiredDocumentsSection extends StatelessWidget {
  final ClientType clientType;
  final List<Document> documents;
  final Function(DocumentType) onUploadDocument;
  
  const RequiredDocumentsSection({
    super.key,
    required this.clientType,
    required this.documents,
    required this.onUploadDocument,
  });

  @override
  Widget build(BuildContext context) {
    final requiredDocs = _getRequiredDocuments();
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Documentos Obrigatórios', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            
            ...requiredDocs.map((docType) {
              final document = documents.where((d) => d.type == docType).firstOrNull;
              
              return RequiredDocumentItem(
                documentType: docType,
                document: document,
                onUpload: () => onUploadDocument(docType),
              );
            }),
          ],
        ),
      ),
    );
  }
  
  List<DocumentType> _getRequiredDocuments() {
    switch (clientType) {
      case ClientType.individual:
        return [
          DocumentType.cpf,
          DocumentType.rg,
          DocumentType.addressProof,
        ];
      case ClientType.corporate:
        return [
          DocumentType.cnpj,
          DocumentType.articlesOfIncorporation,
          DocumentType.addressProof,
        ];
    }
  }
}

class RequiredDocumentItem extends StatelessWidget {
  final DocumentType documentType;
  final Document? document;
  final VoidCallback onUpload;
  
  const RequiredDocumentItem({
    super.key,
    required this.documentType,
    this.document,
    required this.onUpload,
  });

  @override
  Widget build(BuildContext context) {
    final hasDocument = document != null;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(
          color: _getBorderColor(),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _getStatusColor().withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              _getStatusIcon(),
              color: _getStatusColor(),
            ),
          ),
          
          const SizedBox(width: 12),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getDocumentName(),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  _getStatusText(),
                  style: TextStyle(
                    color: _getStatusColor(),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (document?.expirationDate != null) ...[ 
                  const SizedBox(height: 4),
                  Text(
                    'Vence em: ${DateFormat('dd/MM/yyyy').format(document!.expirationDate!)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: _isExpiringSoon() ? Colors.orange : Colors.grey[600],
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          if (!hasDocument)
            ElevatedButton.icon(
              icon: const Icon(Icons.upload),
              label: const Text('Enviar'),
              onPressed: onUpload,
            )
          else
            PopupMenuButton<String>(
              onSelected: (action) => _handleAction(action, context),
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'view', child: Text('Visualizar')),
                const PopupMenuItem(value: 'replace', child: Text('Substituir')),
                if (document?.status == DocumentStatus.rejected)
                  const PopupMenuItem(value: 'resubmit', child: Text('Reenviar')),
              ],
            ),
        ],
      ),
    );
  }

  Color _getBorderColor() {
    if (document == null) return Colors.grey[300]!;
    switch (document!.status) {
      case DocumentStatus.verified:
        return Colors.green;
      case DocumentStatus.pending:
        return Colors.orange;
      case DocumentStatus.rejected:
        return Colors.red;
      case DocumentStatus.expired:
        return Colors.red;
      case DocumentStatus.archived:
        return Colors.grey;
    }
  }

  Color _getStatusColor() {
    if (document == null) return Colors.grey;
    switch (document!.status) {
      case DocumentStatus.verified:
        return Colors.green;
      case DocumentStatus.pending:
        return Colors.orange;
      case DocumentStatus.rejected:
        return Colors.red;
      case DocumentStatus.expired:
        return Colors.red;
      case DocumentStatus.archived:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon() {
    if (document == null) return Icons.cloud_upload;
    switch (document!.status) {
      case DocumentStatus.verified:
        return Icons.check_circle;
      case DocumentStatus.pending:
        return Icons.schedule;
      case DocumentStatus.rejected:
        return Icons.error;
      case DocumentStatus.expired:
        return Icons.warning;
      case DocumentStatus.archived:
        return Icons.archive;
    }
  }

  String _getDocumentName() {
    switch (documentType) {
      case DocumentType.cpf:
        return 'CPF';
      case DocumentType.rg:
        return 'RG';
      case DocumentType.cnpj:
        return 'CNPJ';
      case DocumentType.addressProof:
        return 'Comprovante de Endereço';
      case DocumentType.articlesOfIncorporation:
        return 'Contrato Social';
      default:
        return documentType.toString().split('.').last;
    }
  }

  String _getStatusText() {
    if (document == null) return 'Não enviado';
    switch (document!.status) {
      case DocumentStatus.verified:
        return 'Verificado';
      case DocumentStatus.pending:
        return 'Aguardando verificação';
      case DocumentStatus.rejected:
        return 'Rejeitado';
      case DocumentStatus.expired:
        return 'Expirado';
      case DocumentStatus.archived:
        return 'Arquivado';
    }
  }

  bool _isExpiringSoon() {
    if (document?.expirationDate == null) return false;
    final now = DateTime.now();
    final expirationDate = document!.expirationDate!;
    return expirationDate.difference(now).inDays <= 30;
  }

  void _handleAction(String action, BuildContext context) {
    switch (action) {
      case 'view':
        // TODO: Implementar visualização
        break;
      case 'replace':
        onUpload();
        break;
      case 'resubmit':
        onUpload();
        break;
    }
  }
}

class DocumentsList extends StatelessWidget {
  final List<Document> documents;
  final Function(Document) onViewDocument;
  final Function(Document) onDeleteDocument;
  final Function(Document) onReplaceDocument;
  
  const DocumentsList({
    super.key,
    required this.documents,
    required this.onViewDocument,
    required this.onDeleteDocument,
    required this.onReplaceDocument,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Todos os Documentos', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: documents.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final document = documents[index];
                return DocumentListItem(
                  document: document,
                  onView: () => onViewDocument(document),
                  onDelete: () => onDeleteDocument(document),
                  onReplace: () => onReplaceDocument(document),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class DocumentListItem extends StatelessWidget {
  final Document document;
  final VoidCallback onView;
  final VoidCallback onDelete;
  final VoidCallback onReplace;
  
  const DocumentListItem({
    super.key,
    required this.document,
    required this.onView,
    required this.onDelete,
    required this.onReplace,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(_getDocumentIcon()),
      title: Text(document.originalFileName),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Enviado em: ${DateFormat('dd/MM/yyyy HH:mm').format(document.uploadedAt)}'),
          Text('Tamanho: ${_formatFileSize(document.fileSize)}'),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StatusChip(status: document.status),
          PopupMenuButton<String>(
            onSelected: (action) => _handleAction(action),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'view', child: Text('Visualizar')),
              const PopupMenuItem(value: 'replace', child: Text('Substituir')),
              const PopupMenuItem(value: 'delete', child: Text('Excluir')),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getDocumentIcon() {
    if (document.mimeType.startsWith('image/')) {
      return Icons.image;
    } else if (document.mimeType == 'application/pdf') {
      return Icons.picture_as_pdf;
    } else {
      return Icons.description;
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  void _handleAction(String action) {
    switch (action) {
      case 'view':
        onView();
        break;
      case 'replace':
        onReplace();
        break;
      case 'delete':
        onDelete();
        break;
    }
  }
}

class _StatusChip extends StatelessWidget {
  final DocumentStatus status;
  
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(_getStatusText()),
      backgroundColor: _getStatusColor().withOpacity(0.1),
      labelStyle: TextStyle(color: _getStatusColor()),
      avatar: Icon(_getStatusIcon(), color: _getStatusColor(), size: 16),
    );
  }

  String _getStatusText() {
    switch (status) {
      case DocumentStatus.verified:
        return 'Verificado';
      case DocumentStatus.pending:
        return 'Pendente';
      case DocumentStatus.rejected:
        return 'Rejeitado';
      case DocumentStatus.expired:
        return 'Expirado';
      case DocumentStatus.archived:
        return 'Arquivado';
    }
  }

  Color _getStatusColor() {
    switch (status) {
      case DocumentStatus.verified:
        return Colors.green;
      case DocumentStatus.pending:
        return Colors.orange;
      case DocumentStatus.rejected:
        return Colors.red;
      case DocumentStatus.expired:
        return Colors.red;
      case DocumentStatus.archived:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon() {
    switch (status) {
      case DocumentStatus.verified:
        return Icons.check_circle;
      case DocumentStatus.pending:
        return Icons.schedule;
      case DocumentStatus.rejected:
        return Icons.error;
      case DocumentStatus.expired:
        return Icons.warning;
      case DocumentStatus.archived:
        return Icons.archive;
    }
  }
}

class EmptyDocumentsWidget extends StatelessWidget {
  const EmptyDocumentsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(
              Icons.folder_open,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Nenhum documento enviado',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text(
              'Comece enviando os documentos obrigatórios acima.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class DocumentsSkeletonLoader extends StatelessWidget {
  const DocumentsSkeletonLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          SkeletonLoader(height: 120, width: double.infinity),
          SizedBox(height: 24),
          SkeletonLoader(height: 300, width: double.infinity),
          SizedBox(height: 24),
          SkeletonLoader(height: 400, width: double.infinity),
        ],
      ),
    );
  }
}

class DocumentsErrorWidget extends StatelessWidget {
  const DocumentsErrorWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          Text(
            'Erro ao carregar documentos',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          const Text('Por favor, tente novamente mais tarde.'),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              context.read<ProfileBloc>().add(const LoadProfile('current_user'));
            },
            child: const Text('Tentar Novamente'),
          ),
        ],
      ),
    );
  }
}