import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../domain/entities/case_detail.dart';
import '../../../../shared/utils/app_colors.dart';

class DocumentsSection extends StatelessWidget {
  final List<CaseDocument>? documents;
  final String? caseId;
  
  const DocumentsSection({
    super.key,
    this.documents,
    this.caseId,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    
    if (documents == null || documents!.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Documentos',
                  style: t.titleMedium!.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),
              Center(
                child: Column(
                  children: [
                    Icon(Icons.folder_outlined, size: 48, color: Colors.grey[400]),
                    const SizedBox(height: 8),
                    Text(
                      'Nenhum documento disponível',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    final previewDocs = documents!.take(3).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Documentos',
                    style: t.titleMedium!.copyWith(fontWeight: FontWeight.w600)),
                Text('${documents!.length} arquivo${documents!.length != 1 ? 's' : ''}',
                    style: t.bodySmall!.copyWith(color: AppColors.lightText2)),
              ],
            ),
            const SizedBox(height: 12),
            
            // Preview dos documentos (máximo 3)
            ...previewDocs.map((doc) => _docPreviewCard(
              doc,
              () => _downloadDocument(doc),
              () => _previewDocument(doc),
            )),
            
            if (documents!.length > 3) ...[
              const SizedBox(height: 12),
              
              // Botão para ver todos os documentos
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => context.push('/cases/${caseId ?? 'unknown'}/documents'),
                  icon: const Icon(Icons.folder_open),
                  label: Text('Ver todos os ${documents!.length} documentos'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _docPreviewCard(
    CaseDocument document,
    VoidCallback onDownload,
    VoidCallback onPreview,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.lightBorder),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          // Ícone do tipo de arquivo
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _getFileTypeColor(document.type).withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              _getFileTypeIcon(document.type),
              color: _getFileTypeColor(document.type),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          
          // Informações do documento
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        document.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (document.isRequired)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Obrigatório',
                          style: TextStyle(
                            fontSize: 8,
                            color: Colors.orange[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${_formatFileSize(document.sizeBytes)}  •  ${_formatDate(document.uploadedAt)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.lightText2,
                  ),
                ),
                Text(
                  'Enviado por: ${_getUploaderLabel(document.uploadedBy)}',
                  style: TextStyle(
                    fontSize: 11,
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
                onPressed: onPreview,
                icon: const Icon(Icons.visibility_outlined),
                iconSize: 20,
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
              IconButton(
                onPressed: onDownload,
                icon: const Icon(Icons.download_outlined),
                iconSize: 20,
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            ],
          ),
        ],
      ),
    );
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
      default:
        return uploader;
    }
  }

  void _downloadDocument(CaseDocument document) {
    // TODO: Implementar download
    print('Downloading: ${document.name}');
  }

  void _previewDocument(CaseDocument document) {
    // TODO: Implementar preview
    print('Previewing: ${document.name}');
  }
} 