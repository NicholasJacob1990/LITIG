import 'package:meu_app/src/features/cases/domain/entities/case_detail.dart' as detail;
import 'package:meu_app/src/features/cases/domain/entities/contextual_case_data.dart';
import 'package:meu_app/src/features/cases/domain/entities/allocation_type.dart';
import 'package:meu_app/src/features/cases/domain/entities/case_detail_models.dart' as models;
import 'package:meu_app/src/features/cases/domain/entities/case_document.dart' as doc;
import 'package:meu_app/src/features/cases/domain/entities/process_status.dart' as status;
import 'package:meu_app/src/features/cases/domain/usecases/get_contextual_case_data_usecase.dart';
import 'package:meu_app/src/features/cases/domain/usecases/get_contextual_kpis.dart';
import 'package:meu_app/src/features/cases/domain/usecases/get_contextual_actions.dart';
import 'package:meu_app/src/core/utils/logger.dart';

/// Helper methods for ContextualCaseBloc
mixin ContextualCaseBlocHelpers {
  
  /// Creates a dummy CaseDetail for testing/fallback
  detail.CaseDetail createDummyCaseDetail(String caseId) {
    return detail.CaseDetail(
      id: caseId,
      title: 'Caso $caseId',
      description: 'Carregando detalhes...',
      status: 'pending',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      assignedLawyer: const detail.LawyerInfo(
        id: 'lawyer_dummy',
        name: 'Carregando...',
        specialty: 'Geral',
        avatarUrl: '',
        rating: 0.0,
        experienceYears: 0,
        isAvailable: true,
      ),
      consultation: detail.ConsultationInfo(
        date: DateTime.now(),
        durationMinutes: 60,
        modality: 'online',
        plan: 'standard',
        notes: 'Consulta padrão',
      ),
      preAnalysis: detail.PreAnalysis(
        summary: 'Carregando análise...',
        legalArea: 'Geral',
        urgencyLevel: 'medium',
        keyPoints: const ['Carregando...'],
        recommendation: 'Aguardar análise',
        analyzedAt: DateTime.now(),
        requiredDocuments: const ['Documentos básicos'],
        riskAssessment: 'medium',
        estimatedCosts: const {'honorarios': 5000.0},
      ),
      nextSteps: const [],
      documents: const [],
      processStatus: detail.ProcessStatus(
        currentPhase: 'inicial',
        description: 'Caso em análise inicial',
        progressPercentage: 10.0,
        lastUpdate: DateTime.now(),
        phases: const [],
      ),
    );
  }

  /// Loads contextual data with timeout
  Future<ContextualCaseData> loadContextualDataWithTimeout(
    String caseId, 
    String userId, {
    Duration timeout = const Duration(seconds: 10),
  }) async {
    try {
      // Mock implementation - replace with actual use case call
      await Future.delayed(const Duration(milliseconds: 500));
      return ContextualCaseData(
        allocationType: AllocationType.internalDelegation,
        matchScore: 85.0,
        responseDeadline: DateTime.now().add(const Duration(days: 7)),
        partnerId: 'partner_123',
        delegatedBy: 'admin_user',
        contextMetadata: const {
          'complexity': 'medium',
          'priority': 'high',
        },
        partnerName: 'Escritório Parceiro',
        partnerSpecialization: 'Direito Civil',
        partnerRating: 4.5,
        yourShare: 60,
        partnerShare: 40,
        collaborationArea: 'Contencioso',
        responseTimeLeft: '7 dias',
        distance: 15.5,
        estimatedValue: 25000.0,
        initiatorName: 'Cliente ABC',
        slaHours: 48,
        conversionRate: 0.85,
        complexityScore: 7,
        hoursBudgeted: 40,
        hourlyRate: 200.0,
        delegatedByName: 'Coordenador Legal',
        deadlineDays: 30,
        aiSuccessRate: 0.87,
        aiReason: 'Caso complexo que requer atenção especializada',
      );
    } catch (e) {
      AppLogger.error('Error loading contextual data', error: e);
      rethrow;
    }
  }

  /// Loads KPIs with timeout
  Future<List<ContextualKPI>> _loadKPIsWithTimeout(
    String caseId, 
    String userId) async {
    try {
      // Mock implementation
      await Future.delayed(const Duration(milliseconds: 300));
      return [
        const ContextualKPI(
          icon: '📈',
          label: 'Taxa de Sucesso',
          value: '87%',
        ),
        const ContextualKPI(
          icon: '⏱️',
          label: 'Tempo Médio',
          value: '45d',
        ),
      ];
    } catch (e) {
      AppLogger.error('Error loading KPIs', error: e);
      return [];
    }
  }

  /// Loads actions with timeout
  Future<ContextualActions> _loadActionsWithTimeout(
    String caseId, 
    String userId) async {
    try {
      // Mock implementation
      await Future.delayed(const Duration(milliseconds: 200));
      return const ContextualActions(
        primaryAction: ContextualAction(
          action: 'view_details',
          label: 'Ver Detalhes',
        ),
        secondaryActions: [
          ContextualAction(
            action: 'contact_client',
            label: 'Contatar Cliente',
          ),
          ContextualAction(
            action: 'update_status',
            label: 'Atualizar Status',
          ),
        ],
      );
    } catch (e) {
      AppLogger.error('Error loading actions', error: e);
      // Return default actions
      return const ContextualActions(
        primaryAction: ContextualAction(
          action: 'view_details',
          label: 'Ver Detalhes',
        ),
        secondaryActions: [],
      );
    }
  }
}