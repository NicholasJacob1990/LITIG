import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/case_detail.dart';

sealed class CaseDetailEvent {}
class LoadCaseDetail extends CaseDetailEvent {
  final String caseId;
  LoadCaseDetail(this.caseId);
}

class CaseDetailState {
  const CaseDetailState({
    this.loading = false,
    this.error,
    this.caseDetail,
  });

  final bool loading;
  final String? error;
  final CaseDetail? caseDetail;

  CaseDetailState copyWith({
    bool? loading, 
    String? error, 
    CaseDetail? caseDetail,
  }) =>
      CaseDetailState(
        loading: loading ?? this.loading, 
        error: error ?? this.error,
        caseDetail: caseDetail ?? this.caseDetail,
      );
}

class CaseDetailBloc extends Bloc<CaseDetailEvent, CaseDetailState> {
  CaseDetailBloc() : super(const CaseDetailState()) {
    on<LoadCaseDetail>((event, emit) async {
      emit(state.copyWith(loading: true));
      try {
        // Simulando busca de dados da API
        await Future.delayed(const Duration(milliseconds: 800));
        
        // Dados mockeados para demonstração
        final mockCaseDetail = _createMockCaseDetail(event.caseId);
        
        emit(state.copyWith(
          loading: false,
          caseDetail: mockCaseDetail,
        ));
      } catch (e) {
        emit(state.copyWith(loading: false, error: e.toString()));
      }
    });
  }

  CaseDetail _createMockCaseDetail(String caseId) {
    return CaseDetail(
      id: caseId,
      title: 'Revisão de Contrato de Trabalho',
      description: 'Análise detalhada de cláusulas contratuais e adequação às normas trabalhistas vigentes.',
      status: 'em_andamento',
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
      updatedAt: DateTime.now().subtract(const Duration(hours: 2)),
      assignedLawyer: const LawyerInfo(
        id: 'lawyer_001',
        name: 'Dra. Ana Carolina Silva',
        specialty: 'Direito do Trabalho',
        avatarUrl: 'https://images.unsplash.com/photo-1494790108755-2616b612b786',
        rating: 4.8,
        experienceYears: 12,
        isAvailable: true,
      ),
      consultation: ConsultationInfo(
        date: DateTime.now().add(const Duration(days: 2)),
        durationMinutes: 60,
        modality: 'video',
        plan: 'por_ato',
        notes: 'Consulta inicial para análise do caso',
      ),
      preAnalysis: PreAnalysis(
        summary: 'Contrato apresenta cláusulas que podem ser questionadas juridicamente.',
        legalArea: 'Direito do Trabalho',
        urgencyLevel: 'media',
        keyPoints: [
          'Cláusula de não competição excessiva',
          'Horas extras não especificadas',
          'Benefícios abaixo do padrão de mercado',
        ],
        recommendation: 'Recomenda-se renegociação de algumas cláusulas específicas.',
        analyzedAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      nextSteps: [
        NextStep(
          id: 'step_001',
          title: 'Análise Documental',
          description: 'Revisar todos os documentos fornecidos pelo cliente',
          dueDate: DateTime.now().add(const Duration(days: 1)),
          priority: 'alta',
          isCompleted: true,
          responsibleParty: 'advogado',
        ),
        NextStep(
          id: 'step_002',
          title: 'Consulta Inicial',
          description: 'Reunião com cliente para esclarecimentos adicionais',
          dueDate: DateTime.now().add(const Duration(days: 2)),
          priority: 'alta',
          isCompleted: false,
          responsibleParty: 'ambos',
        ),
        NextStep(
          id: 'step_003',
          title: 'Elaboração de Proposta',
          description: 'Preparar proposta de renegociação contratual',
          dueDate: DateTime.now().add(const Duration(days: 5)),
          priority: 'media',
          isCompleted: false,
          responsibleParty: 'advogado',
        ),
      ],
      documents: [
        CaseDocument(
          id: 'doc_001',
          name: 'Contrato Original.pdf',
          type: 'pdf',
          url: 'https://example.com/docs/contrato.pdf',
          uploadedAt: DateTime.now().subtract(const Duration(days: 3)),
          uploadedBy: 'cliente',
          sizeBytes: 1024000,
          isRequired: true,
        ),
        CaseDocument(
          id: 'doc_002',
          name: 'Comprovante de Renda.pdf',
          type: 'pdf',
          url: 'https://example.com/docs/renda.pdf',
          uploadedAt: DateTime.now().subtract(const Duration(days: 2)),
          uploadedBy: 'cliente',
          sizeBytes: 512000,
          isRequired: true,
        ),
        CaseDocument(
          id: 'doc_003',
          name: 'Análise Preliminar.docx',
          type: 'doc',
          url: 'https://example.com/docs/analise.docx',
          uploadedAt: DateTime.now().subtract(const Duration(hours: 4)),
          uploadedBy: 'advogado',
          sizeBytes: 256000,
          isRequired: false,
        ),
      ],
      processStatus: ProcessStatus(
        currentPhase: 'analise_inicial',
        description: 'Análise inicial dos documentos em andamento',
        progressPercentage: 35.0,
        lastUpdate: DateTime.now().subtract(const Duration(hours: 2)),
        phases: [
          const ProcessPhase(
            id: 'phase_001',
            name: 'Recebimento',
            description: 'Recebimento e catalogação dos documentos',
            isCompleted: true,
            isCurrent: false,
            completedAt: null,
          ),
          const ProcessPhase(
            id: 'phase_002',
            name: 'Análise Inicial',
            description: 'Análise preliminar da documentação',
            isCompleted: false,
            isCurrent: true,
            completedAt: null,
          ),
          const ProcessPhase(
            id: 'phase_003',
            name: 'Consulta',
            description: 'Consulta com o cliente',
            isCompleted: false,
            isCurrent: false,
            completedAt: null,
          ),
          const ProcessPhase(
            id: 'phase_004',
            name: 'Elaboração',
            description: 'Elaboração da estratégia jurídica',
            isCompleted: false,
            isCurrent: false,
            completedAt: null,
          ),
          const ProcessPhase(
            id: 'phase_005',
            name: 'Finalização',
            description: 'Entrega final dos documentos',
            isCompleted: false,
            isCurrent: false,
            completedAt: null,
          ),
        ],
      ),
    );
  }
} 