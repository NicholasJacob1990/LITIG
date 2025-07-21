// Service for mapping document types and providing intelligent suggestions
// Integrates with backend document_type_mappings table

import '../../core/enums/document_enums.dart';

/// Modelo para dados de tipo de documento do backend
class DocumentTypeData {
  final DocumentType type;
  final DocumentCategory category;
  final String displayName;
  final String description;
  final List<String> requiredForAreas;
  final List<String> suggestedForAreas;

  const DocumentTypeData({
    required this.type,
    required this.category,
    required this.displayName,
    required this.description,
    required this.requiredForAreas,
    required this.suggestedForAreas,
  });

  factory DocumentTypeData.fromJson(Map<String, dynamic> json) {
    return DocumentTypeData(
      type: DocumentType.fromValue(json['document_type'] ?? ''),
      category: DocumentCategory.fromCode(json['category_code'] ?? ''),
      displayName: json['display_name'] ?? '',
      description: json['description'] ?? '',
      requiredForAreas: List<String>.from(json['is_required_for_areas'] ?? []),
      suggestedForAreas: List<String>.from(json['suggested_for_areas'] ?? []),
    );
  }
}

/// Serviço principal para mapeamento e sugestões de tipos de documentos
class DocumentTypeMapper {
  static final DocumentTypeMapper _instance = DocumentTypeMapper._internal();
  factory DocumentTypeMapper() => _instance;
  DocumentTypeMapper._internal();

  /// Cache de dados de tipos de documentos
  // TODO: Implement caching functionality
  // List<DocumentTypeData>? _cachedTypeData;

  /// Retorna categoria para um tipo específico
  static DocumentCategory getCategoryForType(String documentType) {
    final type = DocumentType.fromValue(documentType);
    return type.category;
  }

  /// Retorna todos os tipos organizados por categoria
  static Map<DocumentCategory, List<DocumentType>> getTypesByCategory() {
    final Map<DocumentCategory, List<DocumentType>> categoryMap = {};
    
    for (final category in DocumentCategory.values) {
      categoryMap[category] = DocumentType.getTypesByCategory(category);
    }
    
    return categoryMap;
  }

  /// Sugere tipos de documentos baseado na área do caso
  static List<DocumentTypeSuggestion> suggestTypesForCase({
    required String caseArea,
    String? caseSubarea,
    List<String>? existingDocumentTypes,
  }) {
    final suggestions = <DocumentTypeSuggestion>[];
    final existing = existingDocumentTypes ?? [];

    // Obter tipos obrigatórios
    final requiredTypes = DocumentType.getRequiredForArea(caseArea);
    for (final type in requiredTypes) {
      if (!existing.contains(type.value)) {
        suggestions.add(DocumentTypeSuggestion(
          type: type,
          priority: SuggestionPriority.required,
          reason: 'Documento obrigatório para casos de $caseArea',
        ));
      }
    }

    // Obter tipos sugeridos
    final suggestedTypes = DocumentType.getSuggestedForArea(caseArea);
    for (final type in suggestedTypes) {
      if (!existing.contains(type.value) && !requiredTypes.contains(type)) {
        suggestions.add(DocumentTypeSuggestion(
          type: type,
          priority: SuggestionPriority.recommended,
          reason: 'Comumente utilizado em casos de $caseArea',
        ));
      }
    }

    // Sugestões específicas por subárea
    if (caseSubarea != null) {
      final subareaTypes = _getTypesForSubarea(caseArea, caseSubarea);
      for (final type in subareaTypes) {
        if (!existing.contains(type.value) && 
            !suggestions.any((s) => s.type == type)) {
          suggestions.add(DocumentTypeSuggestion(
            type: type,
            priority: SuggestionPriority.optional,
            reason: 'Relevante para $caseSubarea',
          ));
        }
      }
    }

    // Ordenar por prioridade
    suggestions.sort((a, b) => a.priority.index.compareTo(b.priority.index));
    
    return suggestions;
  }

  /// Retorna tipos específicos para subáreas
  static List<DocumentType> _getTypesForSubarea(String area, String subarea) {
    final key = '${area.toLowerCase()}_${subarea.toLowerCase()}';
    
    switch (key) {
      case 'trabalhista_rescisão':
        return [
          DocumentType.employmentContract,
          DocumentType.medicalReport,
          DocumentType.incomeProof,
        ];
      case 'trabalhista_acidente':
        return [
          DocumentType.medicalReport,
          DocumentType.photographicEvidence,
          DocumentType.expertReport,
        ];
      case 'civil_acidentes':
        return [
          DocumentType.medicalReport,
          DocumentType.vehicleRegistration,
          DocumentType.photographicEvidence,
          DocumentType.insurancePolicy,
        ];
      case 'civil_imobiliário':
        return [
          DocumentType.propertyDeed,
          DocumentType.leaseAgreement,
          DocumentType.purchaseAgreement,
        ];
      case 'empresarial_societário':
        return [
          DocumentType.corporateDocuments,
          DocumentType.partnershipAgreement,
          DocumentType.financialStatement,
        ];
      case 'criminal_lesão':
        return [
          DocumentType.medicalReport,
          DocumentType.forensicReport,
          DocumentType.photographicEvidence,
        ];
      default:
        return [];
    }
  }

  /// Classifica automaticamente um documento baseado no nome do arquivo
  static DocumentType? classifyFromFilename(String filename, String? caseArea) {
    final name = filename.toLowerCase();
    
    // Padrões específicos de nome de arquivo
    if (name.contains('procuração') || name.contains('procuracao')) {
      return DocumentType.powerOfAttorney;
    }
    
    if (name.contains('contrato') && name.contains('trabalho')) {
      return DocumentType.employmentContract;
    }
    
    if (name.contains('atestado') || name.contains('laudo') || name.contains('médico')) {
      return DocumentType.medicalReport;
    }
    
    if (name.contains('extrato') || name.contains('banco')) {
      return DocumentType.bankStatement;
    }
    
    if (name.contains('foto') || name.contains('imagem')) {
      return DocumentType.photographicEvidence;
    }
    
    if (name.contains('audio') || name.contains('gravação')) {
      return DocumentType.audioEvidence;
    }
    
    if (name.contains('video') || name.contains('filmagem')) {
      return DocumentType.videoEvidence;
    }
    
    if (name.contains('email') || name.contains('e-mail')) {
      return DocumentType.emailEvidence;
    }
    
    if (name.contains('whatsapp') || name.contains('wpp')) {
      return DocumentType.whatsappEvidence;
    }
    
    if (name.contains('petição') || name.contains('peticao')) {
      return DocumentType.petition;
    }
    
    if (name.contains('recurso')) {
      return DocumentType.appeal;
    }
    
    if (name.contains('comprovante') && name.contains('residencia')) {
      return DocumentType.proofOfResidence;
    }
    
    if (name.contains('comprovante') && name.contains('renda')) {
      return DocumentType.incomeProof;
    }
    
    if (name.contains('rg') || name.contains('cpf') || name.contains('cnh')) {
      return DocumentType.personalIdentification;
    }
    
    if (name.contains('recibo') || name.contains('pagamento')) {
      return DocumentType.receipt;
    }

    // Classificação por extensão e contexto
    if (caseArea != null) {
      final extension = filename.split('.').last.toLowerCase();
      
      if (['jpg', 'jpeg', 'png', 'gif'].contains(extension)) {
        return DocumentType.photographicEvidence;
      }
      
      if (['mp3', 'wav', 'm4a'].contains(extension)) {
        return DocumentType.audioEvidence;
      }
      
      if (['mp4', 'avi', 'mov'].contains(extension)) {
        return DocumentType.videoEvidence;
      }
    }
    
    return null; // Não foi possível classificar automaticamente
  }

  /// Valida se um tipo de documento é adequado para uma área específica
  static ValidationResult validateTypeForArea(DocumentType type, String area) {
    if (type.isRequiredForArea(area)) {
      return ValidationResult.valid('Documento obrigatório para casos de $area');
    }
    
    if (type.isSuggestedForArea(area)) {
      return ValidationResult.valid('Documento recomendado para casos de $area');
    }
    
    // Verificar compatibilidade geral
    if (_isCompatibleWithArea(type, area)) {
      return ValidationResult.valid('Documento compatível com casos de $area');
    }
    
    return ValidationResult.warning(
      'Este tipo de documento não é comumente usado em casos de $area. '
      'Tem certeza de que é apropriado?'
    );
  }

  /// Verifica compatibilidade geral entre tipo e área
  static bool _isCompatibleWithArea(DocumentType type, String area) {
    switch (area.toLowerCase()) {
      case 'trabalhista':
        return ![
          DocumentType.propertyDeed,
          DocumentType.vehicleRegistration,
          DocumentType.forensicReport,
        ].contains(type);
      
      case 'criminal':
        return ![
          DocumentType.employmentContract,
          DocumentType.leaseAgreement,
          DocumentType.auditReport,
        ].contains(type);
      
      case 'empresarial':
        return ![
          DocumentType.medicalReport,
          DocumentType.forensicReport,
          DocumentType.vehicleRegistration,
        ].contains(type);
      
      default:
        return true; // Permite qualquer tipo para outras áreas
    }
  }

  /// Retorna estatísticas de uso de tipos de documento
  static Map<DocumentCategory, int> getCategoryStats(List<String> documentTypes) {
    final stats = <DocumentCategory, int>{};
    
    for (final category in DocumentCategory.values) {
      stats[category] = 0;
    }
    
    for (final typeValue in documentTypes) {
      final type = DocumentType.fromValue(typeValue);
      stats[type.category] = (stats[type.category] ?? 0) + 1;
    }
    
    return stats;
  }
}

/// Modelo para sugestões de tipos de documentos
class DocumentTypeSuggestion {
  final DocumentType type;
  final SuggestionPriority priority;
  final String reason;

  const DocumentTypeSuggestion({
    required this.type,
    required this.priority,
    required this.reason,
  });
}

/// Prioridade das sugestões
enum SuggestionPriority {
  required,    // Obrigatório
  recommended, // Recomendado
  optional,    // Opcional
}

/// Resultado de validação
class ValidationResult {
  final bool isValid;
  final String message;
  final ValidationLevel level;

  const ValidationResult._(this.isValid, this.message, this.level);

  factory ValidationResult.valid(String message) {
    return ValidationResult._(true, message, ValidationLevel.success);
  }

  factory ValidationResult.warning(String message) {
    return ValidationResult._(true, message, ValidationLevel.warning);
  }

  factory ValidationResult.error(String message) {
    return ValidationResult._(false, message, ValidationLevel.error);
  }
}

/// Nível de validação
enum ValidationLevel {
  success,
  warning,
  error,
} 