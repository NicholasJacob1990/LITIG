// Intelligent document validation service
// Provides real-time validation and smart suggestions

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../enums/document_enums.dart';
import '../services/document_type_mapper.dart';

/// Serviço principal para validação inteligente de documentos
class DocumentValidationService {
  static final DocumentValidationService _instance = DocumentValidationService._internal();
  factory DocumentValidationService() => _instance;
  DocumentValidationService._internal();

  /// Cache de sugestões por caso
  final Map<String, List<DocumentSuggestion>> _suggestionCache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheTimeout = Duration(minutes: 30);

  /// Valida upload de documento em tempo real
  Future<DocumentValidationResult> validateDocumentUpload({
    required String caseId,
    required String fileName,
    required DocumentType proposedType,
    String? caseArea,
    String? caseSubarea,
    int? fileSizeBytes,
  }) async {
    final errors = <String>[];
    final warnings = <String>[];
    final suggestions = <String>[];

    try {
      // 1. Validação básica do arquivo
      _validateFileBasics(fileName, fileSizeBytes, errors, warnings);

      // 2. Validação do tipo proposto
      if (caseArea != null) {
        final typeValidation = DocumentTypeMapper.validateTypeForArea(proposedType, caseArea);
        if (typeValidation.level == ValidationLevel.warning) {
          warnings.add(typeValidation.message);
        } else if (typeValidation.level == ValidationLevel.error) {
          errors.add(typeValidation.message);
        }
      }

      // 3. Sugestão automática baseada no nome do arquivo
      final autoDetected = DocumentTypeMapper.classifyFromFilename(fileName, caseArea);
      if (autoDetected != null && autoDetected != proposedType) {
        suggestions.add(
          'Baseado no nome do arquivo, sugerimos o tipo "${autoDetected.displayName}" '
          'em vez de "${proposedType.displayName}"'
        );
      }

      // 4. Verificar duplicatas (simulado - em produção viria do backend)
      await _checkForDuplicates(caseId, fileName, warnings);

      // 5. Verificar requisitos específicos da área
      if (caseArea != null) {
        _validateAreaRequirements(proposedType, caseArea, caseSubarea, warnings, suggestions);
      }

      return DocumentValidationResult(
        isValid: errors.isEmpty,
        errors: errors,
        warnings: warnings,
        suggestions: suggestions,
        recommendedType: autoDetected,
        confidence: _calculateConfidence(errors, warnings, autoDetected != null),
      );

    } catch (e) {
      return DocumentValidationResult(
        isValid: false,
        errors: ['Erro na validação: $e'],
        warnings: [],
        suggestions: [],
        confidence: 0.0,
      );
    }
  }

  /// Busca sugestões inteligentes para um caso específico
  Future<List<DocumentSuggestion>> getSmartSuggestions({
    required String caseId,
    String? caseArea,
    String? caseSubarea,
    bool forceRefresh = false,
  }) async {
    // Verificar cache
    if (!forceRefresh && _isCacheValid(caseId)) {
      return _suggestionCache[caseId] ?? [];
    }

    try {
      // Buscar sugestões do backend
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/documents/enhanced/suggestions/$caseId'),
        headers: ApiConfig.defaultHeaders,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List;
        final suggestions = data.map((item) => DocumentSuggestion.fromJson(item)).toList();
        
        // Atualizar cache
        _suggestionCache[caseId] = suggestions;
        _cacheTimestamps[caseId] = DateTime.now();
        
        return suggestions;
      } else if (caseArea != null) {
        // Fallback para sugestões locais se API falhar
        return _generateLocalSuggestions(caseArea, caseSubarea);
      }
      
      return [];
      
    } catch (e) {
      // Fallback para sugestões locais em caso de erro
      if (caseArea != null) {
        return _generateLocalSuggestions(caseArea, caseSubarea);
      }
      return [];
    }
  }

  /// Verifica documentos obrigatórios faltantes
  Future<List<MissingDocumentAlert>> checkMissingRequiredDocuments({
    required String caseId,
    required String caseArea,
    required List<String> existingDocumentTypes,
  }) async {
    final alerts = <MissingDocumentAlert>[];
    
    try {
      final requiredTypes = DocumentType.getRequiredForArea(caseArea);
      
      for (final requiredType in requiredTypes) {
        if (!existingDocumentTypes.contains(requiredType.value)) {
          alerts.add(MissingDocumentAlert(
            documentType: requiredType,
            severity: AlertSeverity.critical,
            message: 'Documento obrigatório para casos de $caseArea',
            dueDate: _calculateDueDate(requiredType, caseArea),
            consequences: _getConsequences(requiredType, caseArea),
          ));
        }
      }

      // Verificar documentos altamente recomendados
      final recommendedTypes = DocumentType.getSuggestedForArea(caseArea);
      for (final recType in recommendedTypes) {
        if (!existingDocumentTypes.contains(recType.value) && 
            !requiredTypes.contains(recType)) {
          alerts.add(MissingDocumentAlert(
            documentType: recType,
            severity: AlertSeverity.warning,
            message: 'Documento altamente recomendado para casos de $caseArea',
            dueDate: null,
            consequences: 'Pode impactar a qualidade da análise do caso',
          ));
        }
      }

      return alerts;
      
    } catch (e) {
      return [];
    }
  }

  /// Analisa a completude dos documentos de um caso
  Future<DocumentCompletenessReport> analyzeDocumentCompleteness({
    required String caseId,
    required String caseArea,
    String? caseSubarea,
    required List<String> existingDocumentTypes,
  }) async {
    try {
      final requiredTypes = DocumentType.getRequiredForArea(caseArea);
      final suggestedTypes = DocumentType.getSuggestedForArea(caseArea);
      
      final requiredCount = requiredTypes.length;
      final requiredPresent = requiredTypes.where((type) => 
        existingDocumentTypes.contains(type.value)).length;
      
      final suggestedCount = suggestedTypes.length;
      final suggestedPresent = suggestedTypes.where((type) => 
        existingDocumentTypes.contains(type.value)).length;

      final completenessScore = _calculateCompletenessScore(
        requiredPresent, requiredCount,
        suggestedPresent, suggestedCount,
        existingDocumentTypes.length,
      );

      return DocumentCompletenessReport(
        caseId: caseId,
        caseArea: caseArea,
        overallScore: completenessScore,
        requiredDocuments: RequiredDocumentStatus(
          total: requiredCount,
          present: requiredPresent,
          missing: requiredCount - requiredPresent,
          completionPercentage: requiredCount > 0 ? (requiredPresent / requiredCount) * 100 : 100,
        ),
        recommendedDocuments: RecommendedDocumentStatus(
          total: suggestedCount,
          present: suggestedPresent,
          missing: suggestedCount - suggestedPresent,
          completionPercentage: suggestedCount > 0 ? (suggestedPresent / suggestedCount) * 100 : 100,
        ),
        totalDocuments: existingDocumentTypes.length,
        qualityIndicator: _getQualityIndicator(completenessScore),
        recommendations: await _generateRecommendations(caseArea, existingDocumentTypes),
      );
      
    } catch (e) {
      throw Exception('Erro ao analisar completude: $e');
    }
  }

  // ========================================================================
  // Métodos privados de validação
  // ========================================================================

  void _validateFileBasics(String fileName, int? fileSizeBytes, List<String> errors, List<String> warnings) {
    // Validar nome do arquivo
    if (fileName.isEmpty) {
      errors.add('Nome do arquivo não pode estar vazio');
    }

    if (fileName.length > 255) {
      errors.add('Nome do arquivo muito longo (máximo 255 caracteres)');
    }

    // Validar caracteres especiais
    if (RegExp(r'[<>:"/\\|?*]').hasMatch(fileName)) {
      warnings.add('Nome do arquivo contém caracteres que podem causar problemas');
    }

    // Validar tamanho
    if (fileSizeBytes != null) {
      if (fileSizeBytes > 10 * 1024 * 1024) { // 10MB
        errors.add('Arquivo muito grande (máximo 10MB)');
      } else if (fileSizeBytes < 1024) { // 1KB
        warnings.add('Arquivo muito pequeno, verifique se não está corrompido');
      }
    }

    // Validar extensão
    final extension = fileName.split('.').last.toLowerCase();
    final allowedExtensions = ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png', 'mp4', 'mp3', 'txt'];
    if (!allowedExtensions.contains(extension)) {
      errors.add('Tipo de arquivo não suportado. Permitidos: ${allowedExtensions.join(', ')}');
    }
  }

  Future<void> _checkForDuplicates(String caseId, String fileName, List<String> warnings) async {
    // Em produção, faria uma chamada real para o backend
    // Por agora, simulamos a verificação
    if (fileName.toLowerCase().contains('duplicado')) {
      warnings.add('Possível arquivo duplicado detectado');
    }
  }

  void _validateAreaRequirements(
    DocumentType proposedType, 
    String caseArea, 
    String? caseSubarea,
    List<String> warnings,
    List<String> suggestions,
  ) {
    // Validações específicas por área
    switch (caseArea.toLowerCase()) {
      case 'trabalhista':
        if (proposedType == DocumentType.vehicleRegistration) {
          warnings.add('Documentos de veículo são raros em casos trabalhistas');
        }
        break;
      case 'criminal':
        if (proposedType == DocumentType.employmentContract) {
          warnings.add('Contratos de trabalho são raros em casos criminais');
        }
        break;
    }

    // Sugestões específicas por subárea
    if (caseSubarea != null) {
      _addSubareaSpecificSuggestions(caseArea, caseSubarea, proposedType, suggestions);
    }
  }

  void _addSubareaSpecificSuggestions(
    String area, 
    String subarea, 
    DocumentType proposedType,
    List<String> suggestions,
  ) {
    final key = '${area.toLowerCase()}_${subarea.toLowerCase()}';
    
    switch (key) {
      case 'trabalhista_rescisão':
        if (proposedType == DocumentType.employmentContract) {
          suggestions.add('Para casos de rescisão, considere também enviar: comprovantes de renda, atestados médicos');
        }
        break;
      case 'civil_acidentes':
        if (proposedType == DocumentType.medicalReport) {
          suggestions.add('Para casos de acidente, são importantes também: fotos do local, documentos do veículo');
        }
        break;
    }
  }

  List<DocumentSuggestion> _generateLocalSuggestions(String caseArea, String? caseSubarea) {
    final localSuggestions = DocumentTypeMapper.suggestTypesForCase(
      caseArea: caseArea,
      caseSubarea: caseSubarea,
    );

    return localSuggestions.map((suggestion) => DocumentSuggestion(
      type: suggestion.type,
      priority: suggestion.priority,
      reason: suggestion.reason,
      category: suggestion.type.category,
      estimatedImportance: _mapPriorityToImportance(suggestion.priority),
    )).toList();
  }

  double _calculateConfidence(List<String> errors, List<String> warnings, bool hasAutoDetection) {
    if (errors.isNotEmpty) return 0.0;
    
    double confidence = 1.0;
    confidence -= warnings.length * 0.1; // Cada warning reduz 10%
    if (hasAutoDetection) confidence += 0.2; // Auto-detecção aumenta confiança
    
    return (confidence * 100).clamp(0.0, 100.0);
  }

  bool _isCacheValid(String caseId) {
    final timestamp = _cacheTimestamps[caseId];
    if (timestamp == null) return false;
    
    return DateTime.now().difference(timestamp) < _cacheTimeout;
  }

  DateTime? _calculateDueDate(DocumentType type, String area) {
    // Calcular prazo baseado no tipo de documento e área
    if (type == DocumentType.powerOfAttorney) {
      return DateTime.now().add(const Duration(days: 7)); // Procuração: 7 dias
    }
    return null;
  }

  String _getConsequences(DocumentType type, String area) {
    if (type == DocumentType.powerOfAttorney) {
      return 'Sem procuração, não é possível representar o cliente legalmente';
    }
    return 'Pode impactar o andamento do processo';
  }

  double _calculateCompletenessScore(
    int requiredPresent, int requiredTotal,
    int suggestedPresent, int suggestedTotal,
    int totalDocuments,
  ) {
    // Peso: 70% para obrigatórios, 30% para sugeridos
    final requiredScore = requiredTotal > 0 ? (requiredPresent / requiredTotal) : 1.0;
    final suggestedScore = suggestedTotal > 0 ? (suggestedPresent / suggestedTotal) : 1.0;
    
    return (requiredScore * 0.7 + suggestedScore * 0.3) * 100;
  }

  QualityIndicator _getQualityIndicator(double score) {
    if (score >= 90) return QualityIndicator.excellent;
    if (score >= 75) return QualityIndicator.good;
    if (score >= 50) return QualityIndicator.fair;
    return QualityIndicator.poor;
  }

  Future<List<String>> _generateRecommendations(String area, List<String> existingTypes) async {
    final recommendations = <String>[];
    
    final missing = DocumentType.getRequiredForArea(area)
        .where((type) => !existingTypes.contains(type.value))
        .toList();
    
    if (missing.isNotEmpty) {
      recommendations.add('Envie os documentos obrigatórios: ${missing.map((t) => t.displayName).join(', ')}');
    }
    
    return recommendations;
  }

  int _mapPriorityToImportance(SuggestionPriority priority) {
    switch (priority) {
      case SuggestionPriority.required: return 100;
      case SuggestionPriority.recommended: return 75;
      case SuggestionPriority.optional: return 50;
    }
  }
}

// ============================================================================
// Modelos de dados para validação
// ============================================================================

class DocumentValidationResult {
  final bool isValid;
  final List<String> errors;
  final List<String> warnings;
  final List<String> suggestions;
  final DocumentType? recommendedType;
  final double confidence;

  const DocumentValidationResult({
    required this.isValid,
    required this.errors,
    required this.warnings,
    required this.suggestions,
    this.recommendedType,
    required this.confidence,
  });
}

class DocumentSuggestion {
  final DocumentType type;
  final SuggestionPriority priority;
  final String reason;
  final DocumentCategory category;
  final int estimatedImportance;

  const DocumentSuggestion({
    required this.type,
    required this.priority,
    required this.reason,
    required this.category,
    required this.estimatedImportance,
  });

  factory DocumentSuggestion.fromJson(Map<String, dynamic> json) {
    return DocumentSuggestion(
      type: DocumentType.fromValue(json['type'] ?? ''),
      priority: _parsePriority(json['priority'] ?? ''),
      reason: json['reason'] ?? '',
      category: DocumentCategory.fromCode(json['category_code'] ?? ''),
      estimatedImportance: json['estimated_importance'] ?? 50,
    );
  }

  static SuggestionPriority _parsePriority(String priority) {
    switch (priority.toLowerCase()) {
      case 'required': return SuggestionPriority.required;
      case 'recommended': return SuggestionPriority.recommended;
      default: return SuggestionPriority.optional;
    }
  }
}

class MissingDocumentAlert {
  final DocumentType documentType;
  final AlertSeverity severity;
  final String message;
  final DateTime? dueDate;
  final String consequences;

  const MissingDocumentAlert({
    required this.documentType,
    required this.severity,
    required this.message,
    this.dueDate,
    required this.consequences,
  });
}

enum AlertSeverity { critical, warning, info }

class DocumentCompletenessReport {
  final String caseId;
  final String caseArea;
  final double overallScore;
  final RequiredDocumentStatus requiredDocuments;
  final RecommendedDocumentStatus recommendedDocuments;
  final int totalDocuments;
  final QualityIndicator qualityIndicator;
  final List<String> recommendations;

  const DocumentCompletenessReport({
    required this.caseId,
    required this.caseArea,
    required this.overallScore,
    required this.requiredDocuments,
    required this.recommendedDocuments,
    required this.totalDocuments,
    required this.qualityIndicator,
    required this.recommendations,
  });
}

class RequiredDocumentStatus {
  final int total;
  final int present;
  final int missing;
  final double completionPercentage;

  const RequiredDocumentStatus({
    required this.total,
    required this.present,
    required this.missing,
    required this.completionPercentage,
  });
}

class RecommendedDocumentStatus {
  final int total;
  final int present;
  final int missing;
  final double completionPercentage;

  const RecommendedDocumentStatus({
    required this.total,
    required this.present,
    required this.missing,
    required this.completionPercentage,
  });
}

enum QualityIndicator { excellent, good, fair, poor } 