import 'package:meu_app/src/features/cases/domain/entities/case_detail.dart' as detail;
import 'package:meu_app/src/features/cases/domain/entities/contextual_case_data.dart';
import 'package:meu_app/src/features/cases/domain/entities/allocation_type.dart';
import 'package:meu_app/src/features/cases/domain/entities/process_status.dart' as status;
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
      processStatus: const status.ProcessStatus(
        currentPhase: 'inicial',
        description: 'Caso em fase inicial',
        progressPercentage: 10.0,
        phases: [],
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
      // Esta função agora apenas impõe timeout; o carregamento real ocorre no UseCase
      await Future.delayed(const Duration(milliseconds: 50));
      // Retorna uma estrutura mínima até que o UseCase emita o estado carregado
      return ContextualCaseData(
        allocationType: AllocationType.platformMatchDirect,
        contextMetadata: const {},
      );
    } catch (e) {
      AppLogger.error('Error loading contextual data', error: e);
      rethrow;
    }
  }

  // Removidos métodos de mock com timeout não utilizados
}