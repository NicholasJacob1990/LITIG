import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/client_profile.dart';

class AddDocumentDialog extends StatefulWidget {
  final ClientType clientType;
  final Function(Document) onDocumentAdded;
  
  const AddDocumentDialog({
    super.key,
    required this.clientType,
    required this.onDocumentAdded,
  });

  @override
  State<AddDocumentDialog> createState() => _AddDocumentDialogState();
}

class _AddDocumentDialogState extends State<AddDocumentDialog> {
  DocumentType? _selectedType;
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Adicionar Documento'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<DocumentType>(
            decoration: const InputDecoration(
              labelText: 'Tipo de Documento',
              border: OutlineInputBorder(),
            ),
            value: _selectedType,
            items: _getAvailableDocumentTypes().map((type) => DropdownMenuItem(
              value: type,
              child: Text(_getDocumentTypeName(type)),
            )).toList(),
            onChanged: (type) => setState(() => _selectedType = type),
          ),
          const SizedBox(height: 16),
          if (_selectedType != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info, color: Colors.blue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _getDocumentDescription(_selectedType!),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _selectedType != null
              ? () {
                  // Create mock document for now
                  final document = Document(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    type: _selectedType!,
                    fileName: 'document_${_selectedType!.name}.pdf',
                    originalFileName: '${_getDocumentTypeName(_selectedType!)}.pdf',
                    filePath: '/path/to/document',
                    mimeType: 'application/pdf',
                    fileSize: 1024000,
                    status: DocumentStatus.pending,
                    uploadedAt: DateTime.now(),
                  );
                  widget.onDocumentAdded(document);
                  Navigator.of(context).pop();
                }
              : null,
          child: const Text('Selecionar Arquivo'),
        ),
      ],
    );
  }

  List<DocumentType> _getAvailableDocumentTypes() {
    if (widget.clientType == ClientType.individual) {
      return [
        DocumentType.cpf,
        DocumentType.rg,
        DocumentType.birthCertificate,
        DocumentType.marriageCertificate,
        DocumentType.addressProof,
        DocumentType.incomeProof,
        DocumentType.powerOfAttorney,
        DocumentType.photo,
        DocumentType.signature,
        DocumentType.other,
      ];
    } else {
      return [
        DocumentType.cnpj,
        DocumentType.stateRegistration,
        DocumentType.articlesOfIncorporation,
        DocumentType.corporateByLaws,
        DocumentType.boardResolution,
        DocumentType.addressProof,
        DocumentType.powerOfAttorney,
        DocumentType.other,
      ];
    }
  }

  String _getDocumentTypeName(DocumentType type) {
    switch (type) {
      case DocumentType.cpf:
        return 'CPF';
      case DocumentType.rg:
        return 'RG';
      case DocumentType.birthCertificate:
        return 'Certidão de Nascimento';
      case DocumentType.marriageCertificate:
        return 'Certidão de Casamento';
      case DocumentType.addressProof:
        return 'Comprovante de Endereço';
      case DocumentType.incomeProof:
        return 'Comprovante de Renda';
      case DocumentType.cnpj:
        return 'CNPJ';
      case DocumentType.stateRegistration:
        return 'Inscrição Estadual';
      case DocumentType.articlesOfIncorporation:
        return 'Contrato Social';
      case DocumentType.corporateByLaws:
        return 'Estatuto Social';
      case DocumentType.boardResolution:
        return 'Ata de Reunião';
      case DocumentType.powerOfAttorney:
        return 'Procuração';
      case DocumentType.contract:
        return 'Contrato';
      case DocumentType.courtDecision:
        return 'Decisão Judicial';
      case DocumentType.petition:
        return 'Petição';
      case DocumentType.evidence:
        return 'Prova';
      case DocumentType.photo:
        return 'Foto';
      case DocumentType.signature:
        return 'Assinatura';
      case DocumentType.other:
        return 'Outro';
    }
  }

  String _getDocumentDescription(DocumentType type) {
    switch (type) {
      case DocumentType.cpf:
        return 'Documento de identidade fiscal brasileiro';
      case DocumentType.rg:
        return 'Registro Geral - documento de identidade civil';
      case DocumentType.addressProof:
        return 'Conta de luz, água, telefone ou extrato bancário (últimos 3 meses)';
      case DocumentType.cnpj:
        return 'Cadastro Nacional da Pessoa Jurídica';
      case DocumentType.articlesOfIncorporation:
        return 'Documento que formaliza a criação da empresa';
      case DocumentType.powerOfAttorney:
        return 'Documento que confere poderes de representação';
      default:
        return 'Documento necessário para verificação';
    }
  }
}

class DocumentViewDialog extends StatelessWidget {
  final Document document;
  
  const DocumentViewDialog({
    super.key,
    required this.document,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(document.originalFileName),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Tipo', _getDocumentTypeName(document.type)),
            _buildInfoRow('Status', _getStatusText(document.status)),
            _buildInfoRow('Enviado em', DateFormat('dd/MM/yyyy HH:mm').format(document.uploadedAt)),
            if (document.verifiedAt != null)
              _buildInfoRow('Verificado em', DateFormat('dd/MM/yyyy HH:mm').format(document.verifiedAt!)),
            if (document.expirationDate != null)
              _buildInfoRow('Data de Expiração', DateFormat('dd/MM/yyyy').format(document.expirationDate!)),
            _buildInfoRow('Tamanho', _formatFileSize(document.fileSize)),
            _buildInfoRow('Tipo MIME', document.mimeType),
            if (document.verificationNotes != null) ...[
              const SizedBox(height: 16),
              Text('Observações:', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(document.verificationNotes!),
              ),
            ],
          ],
        ),
      ),
      actions: [
        if (document.status == DocumentStatus.verified)
          ElevatedButton.icon(
            icon: const Icon(Icons.download),
            label: const Text('Baixar'),
            onPressed: () {
              // TODO: Implementar download
            },
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Fechar'),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  String _getDocumentTypeName(DocumentType type) {
    switch (type) {
      case DocumentType.cpf:
        return 'CPF';
      case DocumentType.rg:
        return 'RG';
      case DocumentType.birthCertificate:
        return 'Certidão de Nascimento';
      case DocumentType.marriageCertificate:
        return 'Certidão de Casamento';
      case DocumentType.addressProof:
        return 'Comprovante de Endereço';
      case DocumentType.incomeProof:
        return 'Comprovante de Renda';
      case DocumentType.cnpj:
        return 'CNPJ';
      case DocumentType.stateRegistration:
        return 'Inscrição Estadual';
      case DocumentType.articlesOfIncorporation:
        return 'Contrato Social';
      case DocumentType.corporateByLaws:
        return 'Estatuto Social';
      case DocumentType.boardResolution:
        return 'Ata de Reunião';
      case DocumentType.powerOfAttorney:
        return 'Procuração';
      case DocumentType.contract:
        return 'Contrato';
      case DocumentType.courtDecision:
        return 'Decisão Judicial';
      case DocumentType.petition:
        return 'Petição';
      case DocumentType.evidence:
        return 'Prova';
      case DocumentType.photo:
        return 'Foto';
      case DocumentType.signature:
        return 'Assinatura';
      case DocumentType.other:
        return 'Outro';
    }
  }

  String _getStatusText(DocumentStatus status) {
    switch (status) {
      case DocumentStatus.pending:
        return 'Aguardando verificação';
      case DocumentStatus.verified:
        return 'Verificado';
      case DocumentStatus.rejected:
        return 'Rejeitado';
      case DocumentStatus.expired:
        return 'Expirado';
      case DocumentStatus.archived:
        return 'Arquivado';
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

class DocumentProgressIndicator extends StatelessWidget {
  final int totalDocuments;
  final int completedDocuments;
  
  const DocumentProgressIndicator({
    super.key,
    required this.totalDocuments,
    required this.completedDocuments,
  });

  @override
  Widget build(BuildContext context) {
    final progress = totalDocuments > 0 ? completedDocuments / totalDocuments : 0.0;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor.withValues(alpha: 0.1),
            Theme.of(context).primaryColor.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Progresso dos Documentos',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '$completedDocuments de $totalDocuments',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(
              progress == 1.0 ? Colors.green : Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${(progress * 100).toInt()}% completo',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class DocumentTypeFilter extends StatelessWidget {
  final DocumentType? selectedType;
  final ClientType clientType;
  final Function(DocumentType?) onTypeSelected;
  
  const DocumentTypeFilter({
    super.key,
    this.selectedType,
    required this.clientType,
    required this.onTypeSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          FilterChip(
            label: const Text('Todos'),
            selected: selectedType == null,
            onSelected: (selected) => onTypeSelected(null),
          ),
          const SizedBox(width: 8),
          ..._getDocumentTypes().map((type) => Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(_getTypeName(type)),
              selected: selectedType == type,
              onSelected: (selected) => onTypeSelected(selected ? type : null),
            ),
          )),
        ],
      ),
    );
  }

  List<DocumentType> _getDocumentTypes() {
    if (clientType == ClientType.individual) {
      return [
        DocumentType.cpf,
        DocumentType.rg,
        DocumentType.addressProof,
        DocumentType.incomeProof,
        DocumentType.powerOfAttorney,
      ];
    } else {
      return [
        DocumentType.cnpj,
        DocumentType.articlesOfIncorporation,
        DocumentType.addressProof,
        DocumentType.powerOfAttorney,
      ];
    }
  }

  String _getTypeName(DocumentType type) {
    switch (type) {
      case DocumentType.cpf:
        return 'CPF';
      case DocumentType.rg:
        return 'RG';
      case DocumentType.cnpj:
        return 'CNPJ';
      case DocumentType.addressProof:
        return 'Endereço';
      case DocumentType.incomeProof:
        return 'Renda';
      case DocumentType.articlesOfIncorporation:
        return 'Contrato Social';
      case DocumentType.powerOfAttorney:
        return 'Procuração';
      default:
        return type.toString().split('.').last;
    }
  }
}