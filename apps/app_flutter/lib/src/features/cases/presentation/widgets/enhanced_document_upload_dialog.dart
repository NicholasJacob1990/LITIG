// Enhanced document upload dialog with intelligent categorization
// Uses the new document types and categories system

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../core/enums/document_enums.dart';
import '../../../../core/services/document_type_mapper.dart';

class EnhancedDocumentUploadDialog extends StatefulWidget {
  final String caseId;
  final String? caseArea;
  final String? caseSubarea;
  final List<String> existingDocumentTypes;
  final Function(List<DocumentUploadData>) onDocumentsSelected;

  const EnhancedDocumentUploadDialog({
    super.key,
    required this.caseId,
    this.caseArea,
    this.caseSubarea,
    required this.existingDocumentTypes,
    required this.onDocumentsSelected,
  });

  @override
  State<EnhancedDocumentUploadDialog> createState() => _EnhancedDocumentUploadDialogState();
}

class _EnhancedDocumentUploadDialogState extends State<EnhancedDocumentUploadDialog>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final List<DocumentUploadData> _selectedDocuments = [];
  DocumentCategory? _selectedCategory;
  List<DocumentTypeSuggestion> _suggestions = [];
  final bool _showSuggestions = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadSuggestions();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadSuggestions() {
    if (widget.caseArea != null) {
      _suggestions = DocumentTypeMapper.suggestTypesForCase(
        caseArea: widget.caseArea!,
        caseSubarea: widget.caseSubarea,
        existingDocumentTypes: widget.existingDocumentTypes,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildUploadTab(),
                  _buildSuggestionsTab(),
                ],
              ),
            ),
            _buildActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.cloud_upload, color: Colors.white),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Upload de Documentos',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: Colors.white),
              ),
            ],
          ),
          if (widget.caseArea != null) ...[
            const SizedBox(height: 4),
            Text(
              'Área: ${widget.caseArea}${widget.caseSubarea != null ? ' - ${widget.caseSubarea}' : ''}',
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
          const SizedBox(height: 16),
          TabBar(
            controller: _tabController,
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(
                icon: const Icon(Icons.upload_file),
                text: 'Upload (${_selectedDocuments.length})',
              ),
              Tab(
                icon: const Icon(Icons.lightbulb_outline),
                text: 'Sugestões (${_suggestions.length})',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUploadTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCategorySelector(),
          const SizedBox(height: 16),
          _buildUploadArea(),
          const SizedBox(height: 16),
          if (_selectedDocuments.isNotEmpty) ...[
            Text(
              'Documentos Selecionados (${_selectedDocuments.length})',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Expanded(child: _buildDocumentsList()),
          ] else
            const Expanded(
              child: Center(
                child: Text(
                  'Nenhum documento selecionado',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSuggestionsTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Documentos Recomendados',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          if (_suggestions.isEmpty)
            const Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle, size: 64, color: Colors.green),
                    SizedBox(height: 16),
                    Text(
                      'Todos os documentos recomendados já foram enviados!',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(child: _buildSuggestionsList()),
        ],
      ),
    );
  }

  Widget _buildCategorySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Categoria',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: DocumentCategory.values.map((category) {
            final isSelected = _selectedCategory == category;
            return FilterChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(category.icon, size: 16, color: isSelected ? Colors.white : category.color),
                  const SizedBox(width: 4),
                  Text(category.label),
                ],
              ),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedCategory = selected ? category : null;
                });
              },
              selectedColor: category.color,
              backgroundColor: category.color.withOpacity(0.1),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildUploadArea() {
    return GestureDetector(
      onTap: _pickFiles,
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(context).primaryColor,
            style: BorderStyle.solid,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12),
          color: Theme.of(context).primaryColor.withOpacity(0.05),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_upload_outlined,
              size: 48,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(height: 8),
            Text(
              'Clique para selecionar arquivos',
              style: TextStyle(
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'PDF, DOC, DOCX, JPG, PNG (máx. 10MB cada)',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentsList() {
    return ListView.builder(
      itemCount: _selectedDocuments.length,
      itemBuilder: (context, index) {
        final doc = _selectedDocuments[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: doc.type.category.color,
              child: Icon(doc.type.specificIcon, color: Colors.white, size: 20),
            ),
            title: Text(doc.fileName),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tipo: ${doc.type.displayName}'),
                if (doc.autoDetected)
                  Row(
                    children: [
                      const Icon(Icons.auto_awesome, size: 14, color: Colors.orange),
                      const SizedBox(width: 4),
                      Text(
                        'Detectado automaticamente',
                        style: TextStyle(color: Colors.orange[700], fontSize: 12),
                      ),
                    ],
                  ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButton<DocumentType>(
                  value: doc.type,
                  onChanged: (newType) {
                    if (newType != null) {
                      setState(() {
                        _selectedDocuments[index] = doc.copyWith(
                          type: newType,
                          autoDetected: false,
                        );
                      });
                    }
                  },
                  items: _getAvailableTypes().map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(type.displayName),
                    );
                  }).toList(),
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _selectedDocuments.removeAt(index);
                    });
                  },
                  icon: const Icon(Icons.delete, color: Colors.red),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSuggestionsList() {
    return ListView.builder(
      itemCount: _suggestions.length,
      itemBuilder: (context, index) {
        final suggestion = _suggestions[index];
        final priorityColor = _getPriorityColor(suggestion.priority);
        
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: suggestion.type.category.color,
              child: Icon(suggestion.type.specificIcon, color: Colors.white, size: 20),
            ),
            title: Row(
              children: [
                Expanded(child: Text(suggestion.type.displayName)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: priorityColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getPriorityLabel(suggestion.priority),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            subtitle: Text(suggestion.reason),
            trailing: IconButton(
              onPressed: () => _addSuggestedDocument(suggestion.type),
              icon: const Icon(Icons.add),
              tooltip: 'Adicionar à lista de upload',
            ),
          ),
        );
      },
    );
  }

  Widget _buildActions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: _selectedDocuments.isEmpty ? null : _confirmUpload,
              child: Text('Upload (${_selectedDocuments.length})'),
            ),
          ),
        ],
      ),
    );
  }

  List<DocumentType> _getAvailableTypes() {
    if (_selectedCategory != null) {
      return DocumentType.getTypesByCategory(_selectedCategory!);
    }
    return DocumentType.values;
  }

  Color _getPriorityColor(SuggestionPriority priority) {
    switch (priority) {
      case SuggestionPriority.required:
        return Colors.red;
      case SuggestionPriority.recommended:
        return Colors.orange;
      case SuggestionPriority.optional:
        return Colors.blue;
    }
  }

  String _getPriorityLabel(SuggestionPriority priority) {
    switch (priority) {
      case SuggestionPriority.required:
        return 'OBRIGATÓRIO';
      case SuggestionPriority.recommended:
        return 'RECOMENDADO';
      case SuggestionPriority.optional:
        return 'OPCIONAL';
    }
  }

  void _addSuggestedDocument(DocumentType type) {
    _tabController.animateTo(0); // Voltar para aba de upload
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${type.displayName} adicionado às sugestões. Selecione o arquivo.'),
        action: SnackBarAction(
          label: 'SELECIONAR',
          onPressed: _pickFiles,
        ),
      ),
    );
  }

  void _pickFiles() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png', 'mp4', 'mp3'],
      );

      if (result != null) {
        final newDocuments = <DocumentUploadData>[];
        
        for (final file in result.files) {
          if (file.bytes != null && file.name.isNotEmpty) {
            // Tentar detectar automaticamente o tipo
            DocumentType? detectedType = DocumentTypeMapper.classifyFromFilename(
              file.name,
              widget.caseArea,
            );

            // Se não detectou automaticamente, usar categoria selecionada ou 'other'
            detectedType ??= (_selectedCategory != null 
                ? DocumentType.getTypesByCategory(_selectedCategory!).first
                : DocumentType.other);

            newDocuments.add(DocumentUploadData(
              fileName: file.name,
              fileBytes: file.bytes!,
              type: detectedType,
              autoDetected: DocumentTypeMapper.classifyFromFilename(file.name, widget.caseArea) != null,
            ));
          }
        }

        setState(() {
          _selectedDocuments.addAll(newDocuments);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao selecionar arquivos: $e')),
      );
    }
  }

  void _confirmUpload() {
    Navigator.pop(context);
    widget.onDocumentsSelected(_selectedDocuments);
  }
}

/// Modelo para dados de upload de documento
class DocumentUploadData {
  final String fileName;
  final List<int> fileBytes;
  final DocumentType type;
  final bool autoDetected;

  const DocumentUploadData({
    required this.fileName,
    required this.fileBytes,
    required this.type,
    required this.autoDetected,
  });

  DocumentUploadData copyWith({
    String? fileName,
    List<int>? fileBytes,
    DocumentType? type,
    bool? autoDetected,
  }) {
    return DocumentUploadData(
      fileName: fileName ?? this.fileName,
      fileBytes: fileBytes ?? this.fileBytes,
      type: type ?? this.type,
      autoDetected: autoDetected ?? this.autoDetected,
    );
  }
} 