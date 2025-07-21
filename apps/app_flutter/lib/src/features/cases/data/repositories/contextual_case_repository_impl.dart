import '../../domain/entities/contextual_case_data.dart';
import '../../domain/entities/allocation_type.dart';
import '../../domain/repositories/contextual_case_repository.dart';
import '../datasources/contextual_case_remote_data_source.dart';
import '../../../../core/utils/logger.dart';

/// Implementação concreta do ContextualCaseRepository
/// 
/// Segue Clean Architecture coordenando entre data sources
/// e aplicando lógica de negócio específica da camada de dados.
class ContextualCaseRepositoryImpl implements ContextualCaseRepository {
  final ContextualCaseRemoteDataSource remoteDataSource;

  ContextualCaseRepositoryImpl({
    required this.remoteDataSource,
  });

  @override
  Future<Map<String, dynamic>> getContextualCaseData({
    required String caseId,
    required String userId,
  }) async {
    AppLogger.info('Repository: Getting contextual data for case $caseId, user $userId');

    try {
      // Buscar dados do remote data source
      final rawData = await remoteDataSource.getContextualCaseData(
        caseId: caseId,
        userId: userId,
      );

      // Processar e validar dados antes de retornar
      final processedData = await _processContextualData(rawData);
      
      AppLogger.info('Repository: Contextual data processed successfully');
      return processedData;

    } catch (e, stackTrace) {
      AppLogger.error('Repository: Error getting contextual data', error: e, stackTrace: stackTrace);
      
      // Para erros de repositório, não fazer fallback aqui
      // O data source já faz fallback para mock quando necessário
      rethrow;
    }
  }

  @override
  Future<List<ContextualKPI>> getContextualKPIs({
    required String caseId,
    required String userId,
  }) async {
    AppLogger.info('Repository: Getting contextual KPIs for case $caseId');

    try {
      final kpis = await remoteDataSource.getContextualKPIs(
        caseId: caseId,
        userId: userId,
      );

      // Validar e processar KPIs
      final validatedKPIs = _validateKPIs(kpis);
      
      AppLogger.info('Repository: KPIs validated, count: ${validatedKPIs.length}');
      return validatedKPIs;

    } catch (e, stackTrace) {
      AppLogger.error('Repository: Error getting KPIs', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<ContextualActions> getContextualActions({
    required String caseId,
    required String userId,
  }) async {
    AppLogger.info('Repository: Getting contextual actions for case $caseId');

    try {
      final actions = await remoteDataSource.getContextualActions(
        caseId: caseId,
        userId: userId,
      );

      // Validar ações baseadas em regras de negócio
      final validatedActions = _validateActions(actions, userId);
      
      AppLogger.info('Repository: Actions validated');
      return validatedActions;

    } catch (e, stackTrace) {
      AppLogger.error('Repository: Error getting actions', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> setCaseAllocation({
    required String caseId,
    required AllocationType allocationType,
    required Map<String, dynamic> metadata,
  }) async {
    AppLogger.info('Repository: Setting allocation for case $caseId to $allocationType');

    try {
      // Validar dados antes de enviar
      _validateAllocationData(allocationType, metadata);

      // Processar metadados se necessário
      final processedMetadata = _processAllocationMetadata(metadata);

      await remoteDataSource.setCaseAllocation(
        caseId: caseId,
        allocationType: allocationType,
        metadata: processedMetadata,
      );

      AppLogger.info('Repository: Allocation set successfully');

    } catch (e, stackTrace) {
      AppLogger.error('Repository: Error setting allocation', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<Map<String, List<Map<String, dynamic>>>> getCasesByAllocation({
    required String userId,
  }) async {
    AppLogger.info('Repository: Getting cases by allocation for user $userId');

    try {
      final casesByAllocation = await remoteDataSource.getCasesByAllocation(
        userId: userId,
      );

      // Processar e agrupar dados
      final processedCases = _processCasesByAllocation(casesByAllocation);
      
      AppLogger.info('Repository: Cases by allocation processed');
      return processedCases;

    } catch (e, stackTrace) {
      AppLogger.error('Repository: Error getting cases by allocation', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> updateContextualData({
    required String caseId,
    required Map<String, dynamic> contextualUpdates,
  }) async {
    AppLogger.info('Repository: Updating contextual data for case $caseId');

    try {
      // Validar updates antes de aplicar
      _validateContextualUpdates(contextualUpdates);

      // Para updates, usar endpoint de allocation com merge
      final currentData = await getContextualCaseData(
        caseId: caseId,
        userId: 'current_user', // TODO: Get from auth context
      );

      final currentContextual = currentData['contextual_data'] as Map<String, dynamic>? ?? {};
      final mergedData = {...currentContextual, ...contextualUpdates};

      // Determinar allocation type
      final allocationTypeString = mergedData['allocation_type'] as String?;
      if (allocationTypeString != null) {
        final allocationType = AllocationType.fromString(allocationTypeString);
        
        await setCaseAllocation(
          caseId: caseId,
          allocationType: allocationType,
          metadata: mergedData,
        );
      }

      AppLogger.info('Repository: Contextual data updated successfully');

    } catch (e, stackTrace) {
      AppLogger.error('Repository: Error updating contextual data', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getAllocationHistory({
    required String caseId,
  }) async {
    AppLogger.info('Repository: Getting allocation history for case $caseId');

    try {
      // TODO: Implementar endpoint específico quando disponível na API
      // Por enquanto, retornar lista vazia
      AppLogger.warning('Allocation history not implemented yet, returning empty list');
      return [];

    } catch (e, stackTrace) {
      AppLogger.error('Repository: Error getting allocation history', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<bool> validateAllocationChange({
    required String caseId,
    required String userId,
    required AllocationType newAllocationType,
  }) async {
    AppLogger.info('Repository: Validating allocation change for case $caseId to $newAllocationType');

    try {
      // Buscar dados atuais do caso
      final currentData = await getContextualCaseData(
        caseId: caseId,
        userId: userId,
      );

      final currentContextual = currentData['contextual_data'] as Map<String, dynamic>? ?? {};
      final currentAllocationString = currentContextual['allocation_type'] as String?;
      
      if (currentAllocationString == null) {
        AppLogger.info('No current allocation, change allowed');
        return true;
      }

      final currentAllocationType = AllocationType.fromString(currentAllocationString);

      // Aplicar regras de negócio para mudanças de alocação
      final isValid = _validateAllocationTransition(
        from: currentAllocationType,
        to: newAllocationType,
        userId: userId,
      );

      AppLogger.info('Allocation change validation result: $isValid');
      return isValid;

    } catch (e, stackTrace) {
      AppLogger.error('Repository: Error validating allocation change', error: e, stackTrace: stackTrace);
      return false; // Em caso de erro, não permitir mudança
    }
  }

  // ==================== PRIVATE METHODS ====================

  /// Processa dados contextuais aplicando regras de negócio
  Future<Map<String, dynamic>> _processContextualData(Map<String, dynamic> rawData) async {
    final processedData = Map<String, dynamic>.from(rawData);

    // Processar case detail
    if (processedData['case_detail'] != null) {
      processedData['case_detail'] = _processCaseDetail(
        processedData['case_detail'] as Map<String, dynamic>
      );
    }

    // Processar contextual data
    if (processedData['contextual_data'] != null) {
      processedData['contextual_data'] = _processContextualCaseData(
        processedData['contextual_data'] as Map<String, dynamic>
      );
    }

    // Validar integridade dos dados
    _validateDataIntegrity(processedData);

    return processedData;
  }

  /// Processa dados do CaseDetail
  Map<String, dynamic> _processCaseDetail(Map<String, dynamic> caseDetailData) {
    // Converter datas string para DateTime se necessário
    if (caseDetailData['created_at'] is String) {
      caseDetailData['created_at'] = DateTime.parse(caseDetailData['created_at']);
    }
    if (caseDetailData['updated_at'] is String) {
      caseDetailData['updated_at'] = DateTime.parse(caseDetailData['updated_at']);
    }

    return caseDetailData;
  }

  /// Processa dados contextuais específicos
  Map<String, dynamic> _processContextualCaseData(Map<String, dynamic> contextualData) {
    // Converter allocation_type string para enum
    if (contextualData['allocation_type'] is String) {
      final allocationType = AllocationType.fromString(contextualData['allocation_type']);
      contextualData['allocation_type'] = allocationType;
    }

    // Processar datas se presentes
    if (contextualData['response_deadline'] is String) {
      contextualData['response_deadline'] = DateTime.parse(contextualData['response_deadline']);
    }

    return contextualData;
  }

  /// Valida KPIs removendo inválidos
  List<ContextualKPI> _validateKPIs(List<ContextualKPI> kpis) {
    return kpis.where((kpi) {
      // Validar que KPI tem dados mínimos necessários
      return kpi.icon.isNotEmpty && 
             kpi.label.isNotEmpty && 
             kpi.value.isNotEmpty;
    }).toList();
  }

  /// Valida ações baseadas em regras de negócio
  ContextualActions _validateActions(ContextualActions actions, String userId) {
    // TODO: Implementar validação baseada em permissões do usuário
    // Por enquanto, retornar as ações como estão
    return actions;
  }

  /// Valida dados de alocação
  void _validateAllocationData(AllocationType allocationType, Map<String, dynamic> metadata) {
    // Validações básicas
    if (metadata.isEmpty) {
      throw ArgumentError('Metadata cannot be empty for allocation');
    }

    // Validações específicas por tipo de alocação
    switch (allocationType) {
      case AllocationType.internalDelegation:
        if (!metadata.containsKey('delegated_by_name')) {
          throw ArgumentError('Internal delegation requires delegated_by_name');
        }
        break;
      
      case AllocationType.platformMatchDirect:
        if (!metadata.containsKey('match_score')) {
          throw ArgumentError('Platform match requires match_score');
        }
        break;
      
      case AllocationType.partnershipProactiveSearch:
      case AllocationType.partnershipPlatformSuggestion:
      case AllocationType.platformMatchPartnership:
        if (!metadata.containsKey('partner_name')) {
          throw ArgumentError('Partnership allocation requires partner_name');
        }
        break;
    }
  }

  /// Processa metadados de alocação
  Map<String, dynamic> _processAllocationMetadata(Map<String, dynamic> metadata) {
    final processed = Map<String, dynamic>.from(metadata);

    // Converter datas se necessário
    for (final key in ['deadline', 'response_deadline', 'assignment_date']) {
      if (processed[key] is String) {
        try {
          processed[key] = DateTime.parse(processed[key]);
        } catch (e) {
          AppLogger.warning('Failed to parse date for key $key: ${processed[key]}');
        }
      }
    }

    return processed;
  }

  /// Processa casos agrupados por alocação
  Map<String, List<Map<String, dynamic>>> _processCasesByAllocation(
    Map<String, List<Map<String, dynamic>>> rawCases
  ) {
    final processed = <String, List<Map<String, dynamic>>>{};

    for (final entry in rawCases.entries) {
      final allocationType = entry.key;
      final cases = entry.value;

      // Processar cada caso
      final processedCases = cases.map((caseData) {
        // Converter datas
        if (caseData['created_at'] is String) {
          caseData['created_at'] = DateTime.parse(caseData['created_at']);
        }
        
        return caseData;
      }).toList();

      processed[allocationType] = processedCases;
    }

    return processed;
  }

  /// Valida atualizações contextuais
  void _validateContextualUpdates(Map<String, dynamic> updates) {
    if (updates.isEmpty) {
      throw ArgumentError('Contextual updates cannot be empty');
    }

    // Validar que não há tentativas de alterar campos protegidos
    const protectedFields = ['id', 'case_id', 'created_at'];
    for (final field in protectedFields) {
      if (updates.containsKey(field)) {
        throw ArgumentError('Cannot update protected field: $field');
      }
    }
  }

  /// Valida integridade geral dos dados
  void _validateDataIntegrity(Map<String, dynamic> data) {
    // Verificar que dados essenciais estão presentes
    if (!data.containsKey('case_detail') || !data.containsKey('contextual_data')) {
      throw StateError('Missing essential data components');
    }

    final caseDetail = data['case_detail'] as Map<String, dynamic>?;
    final contextualData = data['contextual_data'] as Map<String, dynamic>?;

    if (caseDetail == null || contextualData == null) {
      throw StateError('Essential data components are null');
    }

    // Verificar consistência entre case_detail e contextual_data
    final caseId = caseDetail['id'] as String?;
    if (caseId == null || caseId.isEmpty) {
      throw StateError('Case ID is missing or empty');
    }
  }

  /// Valida transições de alocação baseadas em regras de negócio
  bool _validateAllocationTransition({
    required AllocationType from,
    required AllocationType to,
    required String userId,
  }) {
    // Regras básicas de transição
    
    // Não permitir mudar de volta para o mesmo tipo
    if (from == to) {
      return false;
    }

    // Regras específicas por tipo de origem
    switch (from) {
      case AllocationType.internalDelegation:
        // Delegação interna pode virar qualquer outra com aprovação
        return true;
      
      case AllocationType.platformMatchDirect:
        // Match direto não pode virar delegação interna
        return to != AllocationType.internalDelegation;
      
      case AllocationType.partnershipProactiveSearch:
      case AllocationType.partnershipPlatformSuggestion:
      case AllocationType.platformMatchPartnership:
        // Parcerias podem mudar entre si mas não para delegação
        return to != AllocationType.internalDelegation;
    }
  }
} 
