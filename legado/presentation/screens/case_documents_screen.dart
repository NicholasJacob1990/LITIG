import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../shared/utils/app_colors.dart';

class CaseDocumentsScreen extends StatefulWidget {
  final String caseId;
  
  const CaseDocumentsScreen({super.key, required this.caseId});

  @override
  State<CaseDocumentsScreen> createState() => _CaseDocumentsScreenState();
}

class _CaseDocumentsScreenState extends State<CaseDocumentsScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  
  // Dados simulados
  final List<Map<String, String>> clientDocuments = [
    {'name': 'Relatório da Consulta', 'size': '2.3 MB', 'date': '16/01/2024', 'type': 'pdf', 'category': 'Consulta'},
    {'name': 'Modelo de Petição', 'size': '1.1 MB', 'date': '17/01/2024', 'type': 'docx', 'category': 'Petições'},
    {'name': 'Checklist de Documentos', 'size': '0.8 MB', 'date': '16/01/2024', 'type': 'pdf', 'category': 'Administrativo'},
    {'name': 'Contrato de Trabalho', 'size': '1.5 MB', 'date': '15/01/2024', 'type': 'pdf', 'category': 'Documentos Pessoais'},
    {'name': 'Comprovante de Pagamento', 'size': '0.6 MB', 'date': '14/01/2024', 'type': 'jpg', 'category': 'Comprovantes'},
  ];
  
  final List<Map<String, String>> processDocuments = [
    {'name': 'Petição Inicial', 'size': '1.8 MB', 'date': '18/01/2024', 'type': 'pdf', 'category': 'Petições'},
    {'name': 'Comprovante de Protocolo', 'size': '0.5 MB', 'date': '18/01/2024', 'type': 'pdf', 'category': 'Protocolo'},
    {'name': 'Despacho do Juiz', 'size': '0.3 MB', 'date': '17/01/2024', 'type': 'pdf', 'category': 'Decisões'},
    {'name': 'Ata de Audiência', 'size': '1.2 MB', 'date': '16/01/2024', 'type': 'pdf', 'category': 'Audiências'},
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
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.primaryGradientTop,
                AppColors.primaryGradientBot,
              ],
            ),
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
          IconButton(
            icon: const Icon(Icons.upload_file),
            onPressed: _showUploadDialog,
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

  Widget _buildDocumentsList(List<Map<String, String>> documents, {required bool canUpload}) {
    // Agrupar documentos por categoria
    final groupedDocs = <String, List<Map<String, String>>>{};
    for (final doc in documents) {
      final category = doc['category']!;
      groupedDocs.putIfAbsent(category, () => []).add(doc);
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (canUpload) ...[
          _buildUploadArea(),
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
        color: AppColors.primaryBlue.withOpacity(0.05),
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
          ElevatedButton.icon(
            onPressed: _pickFiles,
            icon: const Icon(Icons.add),
            label: const Text('Selecionar Arquivos'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: Colors.white,
            ),
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

  Widget _buildDocumentCard(Map<String, String> doc, bool canDelete) {
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
                color: _getFileTypeColor(doc['type']!).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getFileTypeIcon(doc['type']!),
                color: _getFileTypeColor(doc['type']!),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            
            // Informações do documento
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    doc['name']!,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${doc['size']}  •  ${doc['date']}',
                    style: const TextStyle(
                      fontSize: 14,
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
                  onPressed: () => _previewDocument(doc['name']!),
                  icon: const Icon(Icons.visibility_outlined),
                  tooltip: 'Visualizar',
                ),
                IconButton(
                  onPressed: () => _downloadDocument(doc['name']!),
                  icon: const Icon(Icons.download_outlined),
                  tooltip: 'Download',
                ),
                if (canDelete)
                  IconButton(
                    onPressed: () => _deleteDocument(doc['name']!),
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
      );

      if (result != null) {
        // TODO: Implementar upload real
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${result.files.length} arquivo(s) selecionado(s) para upload'),
            backgroundColor: AppColors.green,
          ),
        );
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
    // TODO: Implementar preview real
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
    // TODO: Implementar download real
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Baixando: $docName'),
        backgroundColor: AppColors.green,
      ),
    );
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
} 