import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_picker/file_picker.dart';
import 'package:meu_app/src/shared/utils/app_colors.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:meu_app/src/features/cases/domain/entities/case_document.dart';
import 'package:meu_app/src/features/cases/presentation/bloc/case_documents_bloc.dart';
import 'package:meu_app/injection_container.dart';

class CaseDocumentsScreen extends StatefulWidget {
  final String caseId;
  
  const CaseDocumentsScreen({super.key, required this.caseId});

  @override
  State<CaseDocumentsScreen> createState() => _CaseDocumentsScreenState();
}

class _CaseDocumentsScreenState extends State<CaseDocumentsScreen> with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return BlocProvider(
      create: (context) => getIt<CaseDocumentsBloc>()..add(LoadCaseDocuments(widget.caseId)),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Documentos do Caso'),
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: AppColors.primaryGradient,
            ),
          ),
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Meus Documentos'),
              Tab(text: 'Documentos do Processo'),
            ],
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
          ),
          actions: [
            BlocBuilder<CaseDocumentsBloc, CaseDocumentsState>(
              builder: (context, state) {
                return IconButton(
                  icon: const Icon(LucideIcons.uploadCloud),
                  onPressed: state is DocumentUploading ? null : () => _showUploadDialog(context),
                );
              },
            ),
          ],
        ),
        body: BlocConsumer<CaseDocumentsBloc, CaseDocumentsState>(
          listener: (context, state) {
            if (state is DocumentUploadSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Documento "${state.document.name}" enviado com sucesso!'),
                  backgroundColor: AppColors.success,
                ),
              );
            } else if (state is DocumentUploadError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Erro no upload: ${state.message}'),
                  backgroundColor: AppColors.error,
                ),
              );
            } else if (state is CaseDocumentsError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Erro: ${state.message}'),
                  backgroundColor: AppColors.error,
                ),
              );
            }
          },
          builder: (context, state) {
            if (state is CaseDocumentsLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            
            if (state is CaseDocumentsError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(LucideIcons.alertCircle, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text('Erro ao carregar documentos'),
                    const SizedBox(height: 8),
                    Text(state.message, style: const TextStyle(color: Colors.grey)),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => context.read<CaseDocumentsBloc>().add(LoadCaseDocuments(widget.caseId)),
                      child: const Text('Tentar Novamente'),
                    ),
                  ],
                ),
              );
            }
            
            if (state is CaseDocumentsLoaded) {
              // Separar documentos por categoria (mockado para demonstração)
              final clientDocuments = state.documents.where((doc) => 
                doc.category == 'Consulta' || 
                doc.category == 'Administrativo' || 
                doc.category == 'Documentos Pessoais' || 
                doc.category == 'Comprovantes'
              ).toList();
              
              final processDocuments = state.documents.where((doc) => 
                doc.category == 'Petições' || 
                doc.category == 'Protocolo' || 
                doc.category == 'Decisões' || 
                doc.category == 'Audiências'
              ).toList();
              
              return TabBarView(
                controller: _tabController,
                children: [
                  _buildDocumentsList(context, clientDocuments, canUpload: true),
                  _buildDocumentsList(context, processDocuments, canUpload: false),
                ],
              );
            }
            
            // Estado inicial ou outros estados não cobertos
            return TabBarView(
              controller: _tabController,
              children: [
                _buildEmptyState(context, true),
                _buildEmptyState(context, false),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool canUpload) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(LucideIcons.fileX, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('Nenhum documento encontrado'),
          if (canUpload) ...[
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _showUploadDialog(context),
              icon: const Icon(LucideIcons.plus),
              label: const Text('Adicionar Documento'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDocumentsList(BuildContext context, List<CaseDocument> documents, {required bool canUpload}) {
    if (documents.isEmpty) {
      return _buildEmptyState(context, canUpload);
    }

    final groupedDocs = <String, List<CaseDocument>>{};
    for (final doc in documents) {
      final category = doc.category;
      groupedDocs.putIfAbsent(category, () => []).add(doc);
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (canUpload) ...[
          _buildUploadArea(context),
          const SizedBox(height: 24),
        ],
        
        if (groupedDocs.isEmpty) ...[
          _buildEmptyState(context, canUpload),
        ] else ...[
          ...groupedDocs.entries.map((entry) => [
            _buildCategoryHeader(entry.key, entry.value.length),
            const SizedBox(height: 8),
            ...entry.value.map((doc) => _buildDocumentCard(context, doc, canUpload)),
            const SizedBox(height: 16),
          ]).expand((widgets) => widgets),
        ],
      ],
    );
  }

  Widget _buildUploadArea(BuildContext context) {
    final theme = Theme.of(context);
    
    return BlocBuilder<CaseDocumentsBloc, CaseDocumentsState>(
      builder: (context, state) {
        final isUploading = state is DocumentUploading;
        
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            border: Border.all(
              color: isUploading ? Colors.grey : theme.colorScheme.primary, 
              style: BorderStyle.solid
            ),
            borderRadius: BorderRadius.circular(12),
            color: (isUploading ? Colors.grey : theme.colorScheme.primary).withOpacity(0.05),
          ),
          child: Column(
            children: [
              if (isUploading) ...[
                const CircularProgressIndicator(),
                const SizedBox(height: 12),
                Text(
                  'Enviando documento...',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
              ] else ...[
                Icon(
                  LucideIcons.upload,
                  size: 48,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 12),
                Text(
                  'Arraste arquivos aqui ou clique para fazer upload',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.primary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'PDF, DOC, DOCX, JPG, PNG (máx. 10MB)',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => _pickFiles(context),
                  icon: const Icon(LucideIcons.plus),
                  label: const Text('Selecionar Arquivos'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildCategoryHeader(String category, int count) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(
          _getCategoryIcon(category),
          size: 20,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(width: 8),
        Text(
          category,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: theme.colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '$count',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.onSecondaryContainer,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDocumentCard(BuildContext context, CaseDocument doc, bool canDelete) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _getFileTypeColor(doc.type).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getFileTypeIcon(doc.type),
                color: _getFileTypeColor(doc.type),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    doc.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${doc.size}  •  ${doc.date}',
                    style: TextStyle(
                      fontSize: 14,
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: () => _previewDocument(doc.name),
                  icon: const Icon(LucideIcons.eye),
                  tooltip: 'Visualizar',
                ),
                IconButton(
                  onPressed: () => _downloadDocument(doc.name),
                  icon: const Icon(LucideIcons.download),
                  tooltip: 'Download',
                ),
                if (canDelete)
                  IconButton(
                    onPressed: () => _deleteDocument(context, doc),
                    icon: const Icon(LucideIcons.trash2),
                    tooltip: 'Excluir',
                    color: Colors.red,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Consulta': return LucideIcons.messagesSquare;
      case 'Petições': return LucideIcons.gavel;
      case 'Administrativo': return LucideIcons.folderArchive;
      case 'Documentos Pessoais': return LucideIcons.user;
      case 'Comprovantes': return LucideIcons.receipt;
      case 'Protocolo': return LucideIcons.stamp;
      case 'Decisões': return LucideIcons.scale;
      case 'Audiências': return LucideIcons.mic;
      default: return LucideIcons.file;
    }
  }

  IconData _getFileTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'pdf': return LucideIcons.fileType2;
      case 'docx': case 'doc': return LucideIcons.fileText;
      case 'jpg': case 'jpeg': case 'png': return LucideIcons.image;
      default: return LucideIcons.file;
    }
  }

  Color _getFileTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'pdf': return Colors.red;
      case 'docx': case 'doc': return Colors.blue;
      case 'jpg': case 'jpeg': case 'png': return Colors.green;
      default: return AppColors.lightText2;
    }
  }

  void _showUploadDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Upload de Documentos'),
        content: const Text('Selecione os arquivos que deseja enviar para este caso.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _pickFiles(context);
            },
            child: const Text('Selecionar Arquivos'),
          ),
        ],
      ),
    );
  }

  void _pickFiles(BuildContext context) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: false, // Por enquanto, um arquivo por vez
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'],
      );

      if (result != null && result.files.single.bytes != null) {
        final file = result.files.single;
        final bytes = file.bytes!;
        
        // Por enquanto, definir categoria padrão
        const category = 'Administrativo';
        
        context.read<CaseDocumentsBloc>().add(UploadDocument(
          caseId: widget.caseId,
          fileName: file.name,
          fileBytes: bytes,
          category: category,
        ));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erro ao selecionar arquivos'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _previewDocument(String docName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(docName),
        content: const Text('Preview do documento será implementado aqui.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  void _downloadDocument(String docName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Baixando: $docName'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _deleteDocument(BuildContext context, CaseDocument doc) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Excluir Documento'),
        content: Text('Tem certeza que deseja excluir "${doc.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              // Por enquanto usar o nome como ID
              context.read<CaseDocumentsBloc>().add(DeleteDocument(
                caseId: widget.caseId,
                documentId: doc.name, // Temporário - usar nome como ID
                documentName: doc.name,
              ));
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }
} 