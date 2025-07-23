import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/case_detail.dart';
import '../../domain/entities/process_status.dart' as process_status;

sealed class CaseDetailEvent {}

class LoadCaseDetail extends CaseDetailEvent {
  final String caseId;
  LoadCaseDetail(this.caseId);
}

class CaseDetailState extends Equatable {
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
        error: error,
        caseDetail: caseDetail ?? this.caseDetail,
      );

  @override
  List<Object?> get props => [loading, error, caseDetail];
}

class CaseDetailBloc extends Bloc<CaseDetailEvent, CaseDetailState> {
  CaseDetailBloc() : super(const CaseDetailState()) {
    on<LoadCaseDetail>((event, emit) async {
      emit(state.copyWith(loading: true));
      try {
        // Simulando busca de dados da API
        await Future.delayed(const Duration(milliseconds: 800));
        
        // Dados mockeados para demonstração
        final mockCaseDetail = _createLitigationCase(event.caseId);
        
        emit(state.copyWith(
          loading: false,
          caseDetail: mockCaseDetail,
          error: null,
        ));
      } catch (e) {
        emit(state.copyWith(loading: false, error: e.toString()));
      }
    });
  }

  CaseDetail _createLitigationCase(String caseId) {
    return CaseDetail(
      id: caseId,
      title: 'Rescisão Indireta - Assédio Moral',
      description: 'Ação trabalhista por rescisão indireta decorrente de assédio moral no ambiente de trabalho.',
      status: 'em_andamento',
      createdAt: DateTime.now().subtract(const Duration(days: 15)),
      updatedAt: DateTime.now().subtract(const Duration(hours: 6)),
      assignedLawyer: const LawyerInfo(
        id: 'lawyer_002',
        name: 'Dr. João Silva',
        specialty: 'Direito do Trabalho',
        avatarUrl: 'https://ui-avatars.com/api/?name=Joao+Silva&background=3B82F6&color=fff',
        rating: 4.9,
        experienceYears: 18,
        isAvailable: true,
      ),
      consultation: ConsultationInfo(
        date: DateTime.now().subtract(const Duration(days: 10)),
        durationMinutes: 90,
        modality: 'presencial',
        plan: 'êxito',
        notes: 'Cliente relata situação grave de assédio moral sistemático',
      ),
      preAnalysis: PreAnalysis(
        summary: 'Caso com fortes evidências de assédio moral configurando justa causa do empregador. Documentação robusta e testemunhas disponíveis.',
        legalArea: 'Direito do Trabalho - Contencioso',
        urgencyLevel: 'alta',
        keyPoints: const [
          'Múltiplas evidências documentais de assédio',
          'Testemunhas confirmam relatos do cliente',
          'Danos morais configurados e quantificados',
          'Empresa tem histórico de problemas similares',
          'Jurisprudência favorável na região',
        ],
        recommendation: 'Prosseguir com ação de rescisão indireta. Chances de êxito são altas (85%). Solicitar indenizações por danos morais.',
        analyzedAt: DateTime.now().subtract(const Duration(days: 12)),
        requiredDocuments: const [
          'Contrato de trabalho assinado',
          'Carteira de trabalho (frente e verso)',
          'Últimos 12 holerites',
          'Prints de conversas/e-mails abusivos',
          'Atestados médicos relacionados ao stress',
          'Relatórios de RH (se disponíveis)',
        ],
        riskAssessment: 'Baixo risco. Documentação sólida e precedentes favoráveis na jurisprudência local.',
        estimatedCosts: const {
          'Consulta': 450.00,
          'Honorários (êxito)': 8500.00,
          'Custas processuais': 320.00,
        },
      ),
      nextSteps: [
        NextStep(
          id: 'lit_001',
          title: 'Protocolar Petição Inicial',
          description: 'Elaborar e protocolar petição inicial na Vara do Trabalho competente',
          dueDate: DateTime.now().add(const Duration(days: 3)),
          priority: 'alta',
          isCompleted: false,
          responsibleParty: 'advogado',
        ),
        NextStep(
          id: 'lit_002',
          title: 'Coleta de Testemunhas',
          description: 'Contatar e preparar depoimentos das testemunhas-chave',
          dueDate: DateTime.now().add(const Duration(days: 7)),
          priority: 'alta',
          isCompleted: false,
          responsibleParty: 'advogado',
        ),
        NextStep(
          id: 'lit_003',
          title: 'Exame Médico Complementar',
          description: 'Cliente deve realizar avaliação psicológica para quantificar danos',
          dueDate: DateTime.now().add(const Duration(days: 5)),
          priority: 'media',
          isCompleted: false,
          responsibleParty: 'cliente',
        ),
      ],
      documents: [
        CaseDocument(
          id: 'lit_doc_001',
          name: 'Contrato_Trabalho_Assinado.pdf',
          type: 'pdf',
          url: '',
          uploadedAt: DateTime.now().subtract(const Duration(days: 14)),
          uploadedBy: 'cliente',
          sizeBytes: 890000,
          isRequired: true,
        ),
        CaseDocument(
          id: 'lit_doc_002',
          name: 'Prints_Conversas_Assedio.pdf',
          type: 'pdf',
          url: '',
          uploadedAt: DateTime.now().subtract(const Duration(days: 12)),
          uploadedBy: 'cliente',
          sizeBytes: 2400000,
          isRequired: true,
        ),
        CaseDocument(
          id: 'lit_doc_003',
          name: 'Atestado_Medico_Stress.pdf',
          type: 'pdf',
          url: '',
          uploadedAt: DateTime.now().subtract(const Duration(days: 8)),
          uploadedBy: 'cliente',
          sizeBytes: 650000,
          isRequired: true,
        ),
        CaseDocument(
          id: 'lit_doc_004',
          name: 'Estrategia_Processual.docx',
          type: 'docx',
          url: '',
          uploadedAt: DateTime.now().subtract(const Duration(days: 2)),
          uploadedBy: 'advogado',
          sizeBytes: 450000,
          isRequired: false,
        ),
      ],
      processStatus: process_status.ProcessStatus(
        currentPhase: 'preparacao_inicial',
        description: 'Finalizando documentação e preparando petição inicial para protocolo.',
        progressPercentage: 25.0,
        phases: [
          process_status.ProcessPhase(
            name: 'Consulta Inicial',
            description: 'Avaliação do caso e definição de estratégia',
            isCompleted: true,
            isCurrent: false,
            completedAt: DateTime.now().subtract(const Duration(days: 10)),
            documents: const [
              process_status.PhaseDocument(name: 'Relatorio_Consulta.pdf', url: ''),
            ],
          ),
          const process_status.ProcessPhase(
            name: 'Preparação Inicial',
            description: 'Coleta e organização de documentos e evidências',
            isCompleted: false,
            isCurrent: true,
            documents: [
              process_status.PhaseDocument(name: 'Estrategia_Processual.docx', url: ''),
            ],
          ),
          const process_status.ProcessPhase(
            name: 'Protocolo da Ação',
            description: 'Protocolo da petição inicial na Vara do Trabalho',
            isCompleted: false,
            isCurrent: false,
          ),
          const process_status.ProcessPhase(
            name: 'Fase Processual',
            description: 'Acompanhamento do processo judicial',
            isCompleted: false,
            isCurrent: false,
          ),
        ],
      ),
    );
  }
} 