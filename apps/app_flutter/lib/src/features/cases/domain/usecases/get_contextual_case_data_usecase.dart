import '../entities/case_detail.dart' as case_detail;
import '../entities/contextual_case_data.dart';
import '../entities/allocation_type.dart';
import '../repositories/contextual_case_repository.dart';
import '../../../../core/utils/logger.dart';
import 'get_contextual_case_data_converters.dart';

/// Use case para buscar dados contextuais completos de um caso
/// 
/// Coordena a busca de todas as informações necessárias para
/// renderizar a interface contextual baseada no perfil do usuário.
class GetContextualCaseDataUseCase with ContextualCaseDataConverters {
  final ContextualCaseRepository repository;

  GetContextualCaseDataUseCase(this.repository);

  /// Executa o use case retornando dados contextuais processados
  /// 
  /// [caseId] - ID do caso
  /// [userId] - ID do usuário para contexto
  /// 
  /// Retorna um mapa com todos os dados necessários:
  /// - caseDetail: CaseDetail
  /// - contextualData: ContextualCaseData  
  /// - kpis: List<ContextualKPI>
  /// - actions: ContextualActions
  /// - highlight: ContextualHighlight
  Future<ContextualCaseDataResult> call({
    required String caseId,
    required String userId,
  }) async {
    AppLogger.info('UseCase: Getting contextual data for case $caseId, user $userId');

    try {
      // Buscar dados do repository
      final rawData = await repository.getContextualCaseData(
        caseId: caseId,
        userId: userId,
      );

      // Converter para entidades tipadas
      final result = _convertToEntities(rawData);
      
      AppLogger.info('UseCase: Contextual data converted successfully');
      return result;

    } catch (e, stackTrace) {
      AppLogger.error('UseCase: Error getting contextual data', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Converte dados brutos para entidades tipadas
  ContextualCaseDataResult _convertToEntities(Map<String, dynamic> rawData) {
    try {
      // Converter CaseDetail
      final caseDetailMap = rawData['case_detail'] as Map<String, dynamic>;
      final caseDetail = _convertToCaseDetail(caseDetailMap);

      // Converter ContextualCaseData
      final contextualDataMap = rawData['contextual_data'] as Map<String, dynamic>;
      final contextualData = _convertToContextualCaseData(contextualDataMap);

      // Converter KPIs
      final kpisData = rawData['kpis'] as List<dynamic>? ?? [];
      final kpis = kpisData
          .map((kpi) => ContextualKPI.fromMap(kpi as Map<String, dynamic>))
          .toList();

      // Converter Actions
      final actionsData = rawData['actions'] as Map<String, dynamic>;
      final actions = ContextualActions.fromMap(actionsData);

      // Converter Highlight
      final highlightData = rawData['highlight'] as Map<String, dynamic>;
      final highlight = ContextualHighlight.fromMap(highlightData);

      return ContextualCaseDataResult(
        caseDetail: caseDetail,
        contextualData: contextualData,
        kpis: kpis,
        actions: actions,
        highlight: highlight,
      );

    } catch (e) {
      AppLogger.error('Error converting entities', error: e);
      throw Exception('Failed to convert contextual data: $e');
    }
  }

  /// Converte dados brutos para CaseDetail
  case_detail.CaseDetail _convertToCaseDetail(Map<String, dynamic> data) {
    return case_detail.CaseDetail(
      id: data['id'] as String,
      title: data['title'] as String,
      description: data['description'] as String,
      status: data['status'] as String,
      createdAt: data['created_at'] is DateTime 
          ? data['created_at'] as DateTime
          : DateTime.parse(data['created_at'] as String),
      updatedAt: data['updated_at'] is DateTime
          ? data['updated_at'] as DateTime
          : DateTime.parse(data['updated_at'] as String),
      assignedLawyer: convertLawyerInfo(data['assigned_lawyer'] as Map<String, dynamic>),
      consultation: convertConsultationInfo(data['consultation'] as Map<String, dynamic>),
      preAnalysis: convertPreAnalysis(data['pre_analysis'] as Map<String, dynamic>),
      nextSteps: (data['next_steps'] as List<dynamic>? ?? [])
          .map((step) => convertNextStep(step as Map<String, dynamic>))
          .toList(),
      documents: (data['documents'] as List<dynamic>? ?? [])
          .map((document) => convertCaseDocument(document as Map<String, dynamic>))
          .toList(),
      processStatus: convertProcessStatus(data['process_status'] as Map<String, dynamic>? ?? {}),
    );
  }

  /// Converte dados brutos para ContextualCaseData
  ContextualCaseData _convertToContextualCaseData(Map<String, dynamic> data) {
    // Converter allocation_type
    AllocationType allocationType;
    if (data['allocation_type'] is AllocationType) {
      allocationType = data['allocation_type'] as AllocationType;
    } else {
      allocationType = AllocationType.fromString(data['allocation_type'] as String);
    }

    return ContextualCaseData(
      allocationType: allocationType,
      matchScore: data['match_score'] as double?,
      responseDeadline: data['response_deadline'] is DateTime
          ? data['response_deadline'] as DateTime
          : data['response_deadline'] != null
              ? DateTime.parse(data['response_deadline'] as String)
              : null,
      partnerId: data['partner_id'] as String?,
      delegatedBy: data['delegated_by'] as String?,
      contextMetadata: data['context_metadata'] as Map<String, dynamic>? ?? {},
      partnerName: data['partner_name'] as String?,
      partnerSpecialization: data['partner_specialization'] as String?,
      partnerRating: data['partner_rating'] as double?,
      yourShare: data['your_share'] as int?,
      partnerShare: data['partner_share'] as int?,
      collaborationArea: data['collaboration_area'] as String?,
      responseTimeLeft: data['response_time_left'] as String?,
      distance: data['distance'] as double?,
      estimatedValue: data['estimated_value'] as double?,
      initiatorName: data['initiator_name'] as String?,
      slaHours: data['sla_hours'] as int?,
      conversionRate: data['conversion_rate'] as double?,
      complexityScore: data['complexity_score'] as int?,
      hoursBudgeted: data['hours_budgeted'] as int?,
      hourlyRate: data['hourly_rate'] as double?,
      delegatedByName: data['delegated_by_name'] as String?,
      deadlineDays: data['deadline_days'] as int?,
      aiSuccessRate: data['ai_success_rate'] as double?,
      aiReason: data['ai_reason'] as String?,
    );
  }
}

/// Resultado do use case com dados contextuais tipados
class ContextualCaseDataResult {
  final case_detail.CaseDetail caseDetail;
  final ContextualCaseData contextualData;
  final List<ContextualKPI> kpis;
  final ContextualActions actions;
  final ContextualHighlight highlight;

  const ContextualCaseDataResult({
    required this.caseDetail,
    required this.contextualData,
    required this.kpis,
    required this.actions,
    required this.highlight,
  });

  @override
  String toString() {
    return 'ContextualCaseDataResult(caseId: ${caseDetail.id}, allocationType: ${contextualData.allocationType})';
  }
} 

