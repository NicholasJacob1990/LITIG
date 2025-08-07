import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';
import 'dart:convert';
import '../../domain/entities/case_detail.dart';
import '../../../../shared/utils/app_colors.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/services/ocr_service.dart';
import '../../../../features/documents/presentation/screens/document_scanner_screen.dart';
import 'package:permission_handler/permission_handler.dart';

class CaseDocumentsScreen extends StatefulWidget {
  final String caseId;
  
  const CaseDocumentsScreen({super.key, required this.caseId});

  @override
  State<CaseDocumentsScreen> createState() => _CaseDocumentsScreenState();
}

class _CaseDocumentsScreenState extends State<CaseDocumentsScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  
  // Dados simulados - em produção viriam do BLoC
  final List<CaseDocument> clientDocuments = [
    CaseDocument(
      id: '1',
      name: 'Relatório da Consulta',
      type: 'pdf',
      url: '',
      uploadedAt: DateTime(2024, 1, 16),
      uploadedBy: 'advogado',
      sizeBytes: 2400000,
      isRequired: false,
    ),
    CaseDocument(
      id: '2',
      name: 'Modelo de Petição',
      type: 'docx',
      url: '',
      uploadedAt: DateTime(2024, 1, 17),
      uploadedBy: 'advogado',
      sizeBytes: 1100000,
      isRequired: true,
    ),
    CaseDocument(
      id: '3',
      name: 'Checklist de Documentos',
      type: 'pdf',
      url: '',
      uploadedAt: DateTime(2024, 1, 16),
      uploadedBy: 'advogado',
      sizeBytes: 800000,
      isRequired: false,
    ),
    CaseDocument(
      id: '4',
      name: 'Contrato de Trabalho',
      type: 'pdf',
      url: '',
      uploadedAt: DateTime(2024, 1, 15),
      uploadedBy: 'cliente',
      sizeBytes: 1500000,
      isRequired: true,
    ),
    CaseDocument(
      id: '5',
      name: 'Comprovante de Pagamento',
      type: 'jpg',
      url: '',
      uploadedAt: DateTime(2024, 1, 14),
      uploadedBy: 'cliente',
      sizeBytes: 600000,
      isRequired: false,
    ),
  ];
  
  final List<CaseDocument> processDocuments = [
    CaseDocument(
      id: '6',
      name: 'Petição Inicial',
      type: 'pdf',
      url: '',
      uploadedAt: DateTime(2024, 1, 18),
      uploadedBy: 'advogado',
      sizeBytes: 1800000,
      isRequired: false,
    ),
    CaseDocument(
      id: '7',
      name: 'Comprovante de Protocolo',
      type: 'pdf',
      url: '',
      uploadedAt: DateTime(2024, 1, 18),
      uploadedBy: 'advogado',
      sizeBytes: 500000,
      isRequired: false,
    ),
    CaseDocument(
      id: '8',
      name: 'Despacho do Juiz',
      type: 'pdf',
      url: '',
      uploadedAt: DateTime(2024, 1, 17),
      uploadedBy: 'sistema',
      sizeBytes: 300000,
      isRequired: false,
    ),
    CaseDocument(
      id: '9',
      name: 'Ata de Audiência',
      type: 'pdf',
      url: '',
      uploadedAt: DateTime(2024, 1, 16),
      uploadedBy: 'sistema',
      sizeBytes: 1200000,
      isRequired: false,
    ),
  ];

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
    return Scaffold(
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
          PopupMenuButton<String>(
            icon: const Icon(Icons.add),
            onSelected: (value) {
              switch (value) {
                case 'upload':
                  _showUploadDialog();
                  break;
                case 'scan':
                  _navigateToScanner();
                  break;
                case 'camera':
                  _captureWithCamera();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'upload',
                child: Row(
                  children: [
                    Icon(Icons.upload_file, size: 20),
                    SizedBox(width: 8),
                    Text('Upload de Arquivo'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'scan',
                child: Row(
                  children: [
                    Icon(Icons.document_scanner, size: 20),
                    SizedBox(width: 8),
                    Text('Scanner Inteligente'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'camera',
                child: Row(
                  children: [
                    Icon(Icons.camera_alt, size: 20),
                    SizedBox(width: 8),
                    Text('Capturar com Câmera'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDocumentsList(clientDocuments, canUpload: true),
          _buildDocumentsList(processDocuments, canUpload: false),
        ],
      ),
    );
  }

  Widget _buildDocumentsList(List<CaseDocument> documents, {required bool canUpload}) {
    // Agrupar documentos por categoria (simulado)
    final groupedDocs = <String, List<CaseDocument>>{};
    for (final doc in documents) {
      final category = _getDocumentCategory(doc);
      groupedDocs.putIfAbsent(category, () => []).add(doc);
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (canUpload) ...[
          _buildUploadArea(),
          if (_isUploading) _buildUploadProgress(),
          const SizedBox(height: 24),
        ],
        
        // Mostrar documentos agrupados por categoria
        ...groupedDocs.entries.map((entry) => [
          _buildCategoryHeader(entry.key, entry.value.length),
          const SizedBox(height: 8),
          ...entry.value.map((doc) => _buildDocumentCard(doc, canUpload)),
          const SizedBox(height: 16),
        ]).expand((widgets) => widgets),
      ],
    );
  }

  Widget _buildUploadArea() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.primaryBlue, style: BorderStyle.solid),
        borderRadius: BorderRadius.circular(12),
        color: AppColors.primaryBlue.withValues(alpha: 0.05),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.cloud_upload_outlined,
            size: 48,
            color: AppColors.primaryBlue,
          ),
          const SizedBox(height: 12),
          const Text(
            'Arraste arquivos aqui ou clique para fazer upload',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.primaryBlue,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'PDF, DOC, DOCX, JPG, PNG (máx. 10MB)',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.lightText2,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: _pickFiles,
                icon: const Icon(Icons.folder_open),
                label: const Text('Selecionar Arquivos'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: Colors.white,
                ),
              ),
              OutlinedButton.icon(
                onPressed: _navigateToScanner,
                icon: const Icon(Icons.document_scanner),
                label: const Text('Scanner OCR'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primaryBlue,
                  side: const BorderSide(color: AppColors.primaryBlue),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryHeader(String category, int count) {
    return Row(
      children: [
        Icon(
          _getCategoryIcon(category),
          size: 20,
          color: AppColors.primaryBlue,
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
            color: AppColors.lightBorder,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '$count',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDocumentCard(CaseDocument doc, bool canDelete) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Ícone do tipo de arquivo
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _getFileTypeColor(doc.type).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getFileTypeIcon(doc.type),
                color: _getFileTypeColor(doc.type),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            
            // Informações do documento
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          doc.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      if (doc.isRequired)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Obrigatório',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.orange[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_formatFileSize(doc.sizeBytes)}  •  ${_formatDate(doc.uploadedAt)}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.lightText2,
                    ),
                  ),
                  Text(
                    'Enviado por: ${_getUploaderLabel(doc.uploadedBy)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.lightText2,
                    ),
                  ),
                ],
              ),
            ),
            
            // Botões de ação
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: () => _previewDocument(doc.name),
                  icon: const Icon(Icons.visibility_outlined),
                  tooltip: 'Visualizar',
                ),
                IconButton(
                  onPressed: () => _downloadDocument(doc.name),
                  icon: const Icon(Icons.download_outlined),
                  tooltip: 'Download',
                ),
                if (canDelete)
                  IconButton(
                    onPressed: () => _deleteDocument(doc.name),
                    icon: const Icon(Icons.delete_outline),
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

  String _getDocumentCategory(CaseDocument doc) {
    // Lógica simples para categorizar documentos
    if (doc.name.toLowerCase().contains('petição')) return 'Petições';
    if (doc.name.toLowerCase().contains('contrato')) return 'Documentos Pessoais';
    if (doc.name.toLowerCase().contains('comprovante')) return 'Comprovantes';
    if (doc.name.toLowerCase().contains('relatório')) return 'Consulta';
    if (doc.name.toLowerCase().contains('checklist')) return 'Administrativo';
    if (doc.name.toLowerCase().contains('protocolo')) return 'Protocolo';
    if (doc.name.toLowerCase().contains('despacho')) return 'Decisões';
    if (doc.name.toLowerCase().contains('audiência')) return 'Audiências';
    return 'Outros';
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Consulta':
        return Icons.chat_outlined;
      case 'Petições':
        return Icons.gavel;
      case 'Administrativo':
        return Icons.folder_outlined;
      case 'Documentos Pessoais':
        return Icons.person_outline;
      case 'Comprovantes':
        return Icons.receipt_outlined;
      case 'Protocolo':
        return Icons.assignment_outlined;
      case 'Decisões':
        return Icons.balance;
      case 'Audiências':
        return Icons.mic_outlined;
      default:
        return Icons.insert_drive_file;
    }
  }

  IconData _getFileTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'docx':
      case 'doc':
        return Icons.description;
      case 'jpg':
      case 'jpeg':
      case 'png':
        return Icons.image;
      default:
        return Icons.insert_drive_file;
    }
  }

  Color _getFileTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'pdf':
        return Colors.red;
      case 'docx':
      case 'doc':
        return Colors.blue;
      case 'jpg':
      case 'jpeg':
      case 'png':
        return Colors.green;
      default:
        return AppColors.lightText2;
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _getUploaderLabel(String uploader) {
    switch (uploader.toLowerCase()) {
      case 'cliente':
        return 'Cliente';
      case 'advogado':
        return 'Advogado';
      case 'sistema':
        return 'Sistema';
      default:
        return uploader;
    }
  }

  void _showUploadDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Upload de Documentos'),
        content: const Text('Selecione os arquivos que deseja enviar para este caso.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _pickFiles();
            },
            child: const Text('Selecionar Arquivos'),
          ),
        ],
      ),
    );
  }

  void _pickFiles() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'],
        withData: true,
      );

      if (result != null) {
        for (final file in result.files) {
          if (file.bytes != null) {
            await _uploadFile(
              fileName: file.name,
              fileBytes: file.bytes!,
              fileExtension: file.extension ?? '',
            );
          }
        }
      }
    } catch (e) {
      AppLogger.error('Erro ao selecionar arquivos: $e');
      _showErrorMessage('Erro ao selecionar arquivos');
    }
  }

  void _previewDocument(String docName) async {
    try {
      AppLogger.info('Previewing: $docName');
      setState(() => _isUploading = true);
      
      // Simular carregamento do documento
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.visibility, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    docName,
                    style: const TextStyle(fontSize: 16),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              height: 300,
              child: Column(
                children: [
                  Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.description, size: 48, color: Colors.grey),
                          SizedBox(height: 8),
                          Text(
                            'Preview do documento\nserá implementado aqui',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _downloadDocument(docName);
                        },
                        icon: const Icon(Icons.download, size: 16),
                        label: const Text('Download'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, size: 16),
                        label: const Text('Fechar'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      }
    } catch (e) {
      AppLogger.error('Erro no preview: $e');
      _showErrorMessage('Erro ao abrir preview');
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _downloadDocument(String docName) async {
    try {
      setState(() {
        _isUploading = true;
        _uploadProgress = 0.0;
      });
      
      AppLogger.info('Downloading: $docName');
      
      // Simular progresso de download
      for (double i = 0; i <= 100; i += 10) {
        await Future.delayed(const Duration(milliseconds: 100));
        if (mounted) {
          setState(() => _uploadProgress = i / 100);
        }
      }
      
      // Simular salvamento do arquivo
      await Future.delayed(const Duration(milliseconds: 300));
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text('$docName baixado com sucesso')),
              ],
            ),
            backgroundColor: AppColors.green,
            action: SnackBarAction(
              label: 'Abrir',
              textColor: Colors.white,
              onPressed: () {
                // TODO: Implementar abertura do arquivo
              },
            ),
          ),
        );
      }
    } catch (e) {
      AppLogger.error('Erro no download: $e');
      _showErrorMessage('Erro ao baixar documento');
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _uploadProgress = 0.0;
        });
      }
    }
  }

  void _deleteDocument(String docName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir Documento'),
        content: Text('Tem certeza que deseja excluir "$docName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implementar exclusão real
              AppLogger.info('Deleting: $docName');
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$docName foi excluído'),
                  backgroundColor: AppColors.red,
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

  // Novos métodos implementados
  void _navigateToScanner() async {
    try {
      final result = await Navigator.push<ExtractedDocumentData>(
        context,
        MaterialPageRoute(
          builder: (context) => DocumentScannerScreen(
            caseId: widget.caseId,
            onDocumentProcessed: (data) {
              AppLogger.info('Documento processado via scanner: ${data.documentType}');
            },
          ),
        ),
      );
      
      if (result != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Documento digitalizado e salvo com sucesso!'),
            backgroundColor: AppColors.green,
          ),
        );
      }
    } catch (e) {
      AppLogger.error('Erro ao navegar para o scanner: $e');
      _showErrorMessage('Erro ao abrir scanner');
    }
  }

  void _captureWithCamera() async {
    try {
      if (await Permission.camera.request().isGranted) {
        // TODO: Implementar captura rápida com câmera
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Captura com câmera será implementada em breve'),
            backgroundColor: AppColors.primaryBlue,
          ),
        );
      } else {
        _showErrorMessage('Permissão de câmera necessária');
      }
    } catch (e) {
      AppLogger.error('Erro na captura com câmera: $e');
      _showErrorMessage('Erro ao acessar câmera');
    }
  }

  Future<void> _uploadFile({
    required String fileName,
    required Uint8List fileBytes,
    required String fileExtension,
  }) async {
    try {
      setState(() {
        _isUploading = true;
        _uploadProgress = 0.0;
      });
      
      AppLogger.info('Iniciando upload: $fileName (${fileBytes.length} bytes)');
      
      // Validar tamanho do arquivo (máx 10MB)
      if (fileBytes.length > 10 * 1024 * 1024) {
        throw Exception('Arquivo muito grande (máx. 10MB)');
      }
      
      // Validar extensão
      final allowedExtensions = ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'];
      if (!allowedExtensions.contains(fileExtension.toLowerCase())) {
        throw Exception('Tipo de arquivo não suportado');
      }
      
      // Simular progresso de upload
      for (double i = 0; i <= 80; i += 10) {
        await Future.delayed(const Duration(milliseconds: 200));
        if (mounted) {
          setState(() => _uploadProgress = i / 100);
        }
      }
      
      // Preparar dados para upload
      final fileBase64 = base64Encode(fileBytes);
      final uploadData = {
        'case_id': widget.caseId,
        'file_name': fileName,
        'file_extension': fileExtension,
        'file_data': fileBase64,
        'file_size': fileBytes.length,
        'uploaded_by': 'client', // ou 'lawyer' dependendo do contexto
        'is_required': false,
        'category': _categorizeByFileName(fileName),
      };
      
      // Finalizar progresso
      setState(() => _uploadProgress = 1.0);
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Simular resposta da API
      final response = {
        'success': true,
        'document_id': 'doc_${DateTime.now().millisecondsSinceEpoch}',
        'message': 'Documento enviado com sucesso',
      };
      
      AppLogger.success('Upload concluído: ${response['document_id']}');
      
      // Atualizar lista de documentos (simulado)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text('$fileName enviado com sucesso!')),
            ],
          ),
          backgroundColor: AppColors.green,
        ),
      );
      
    } catch (e) {
      AppLogger.error('Erro no upload: $e');
      _showErrorMessage('Erro ao enviar arquivo: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _uploadProgress = 0.0;
        });
      }
    }
  }

  String _categorizeByFileName(String fileName) {
    final name = fileName.toLowerCase();
    if (name.contains('contrato')) return 'contracts';
    if (name.contains('comprovante')) return 'receipts';
    if (name.contains('rg') || name.contains('cpf')) return 'documents';
    if (name.contains('procuração')) return 'legal';
    return 'others';
  }

  Widget _buildUploadProgress() {
    if (!_isUploading) return const SizedBox.shrink();
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryBlue.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primaryBlue.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  value: _uploadProgress,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                _uploadProgress < 1.0 
                    ? 'Enviando arquivo... ${(_uploadProgress * 100).toInt()}%'
                    : 'Processando...',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: _uploadProgress,
            backgroundColor: Colors.grey.shade200,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
          ),
        ],
      ),
    );
  }

  void _showErrorMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
} 