import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/utils/app_colors.dart';

class DocumentsSection extends StatelessWidget {
  const DocumentsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    
    // Lista de documentos (simulando dados)
    final previewDocs = [
      {'name': 'Relatório da Consulta', 'size': '2.3 MB', 'date': '16/01/2024', 'type': 'pdf'},
      {'name': 'Modelo de Petição', 'size': '1.1 MB', 'date': '17/01/2024', 'type': 'docx'},
      {'name': 'Checklist de Documentos', 'size': '0.8 MB', 'date': '16/01/2024', 'type': 'pdf'},
    ];

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
                Text('${previewDocs.length}+ arquivos',
                    style: t.bodySmall!.copyWith(color: AppColors.lightText2)),
              ],
            ),
            const SizedBox(height: 12),
            
            // Preview dos documentos (máximo 3)
            ...previewDocs.map((doc) => _docPreviewCard(
              doc['name']!,
              doc['size']!,
              doc['date']!,
              doc['type']!,
              () => _downloadDocument(doc['name']!),
              () => _previewDocument(doc['name']!),
            )),
            
            const SizedBox(height: 12),
            
            // Botão para ver todos os documentos
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => context.push('/cases/case-123/documents'),
                icon: const Icon(Icons.folder_open),
                label: const Text('Ver todos os documentos'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _docPreviewCard(
    String name, 
    String size, 
    String date, 
    String type,
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
              color: _getFileTypeColor(type).withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              _getFileTypeIcon(type),
              color: _getFileTypeColor(type),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          
          // Informações do documento
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '$size  •  $date',
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

  void _downloadDocument(String docName) {
    // TODO: Implementar download
    print('Downloading: $docName');
  }

  void _previewDocument(String docName) {
    // TODO: Implementar preview
    print('Previewing: $docName');
  }
} 