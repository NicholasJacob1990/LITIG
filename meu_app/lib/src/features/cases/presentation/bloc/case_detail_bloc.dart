import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/case_detail_models.dart';
import '../../domain/usecases/get_case_detail.dart';

// Events
abstract class CaseDetailEvent extends Equatable {
  const CaseDetailEvent();

  @override
  List<Object?> get props => [];
}

class LoadCaseDetail extends CaseDetailEvent {
  final String caseId;

  const LoadCaseDetail(this.caseId);

  @override
  List<Object?> get props => [caseId];
}

class RefreshCaseDetail extends CaseDetailEvent {
  final String caseId;

  const RefreshCaseDetail(this.caseId);

  @override
  List<Object?> get props => [caseId];
}

class UpdateCaseStatus extends CaseDetailEvent {
  final String caseId;
  final String newStatus;

  const UpdateCaseStatus(this.caseId, this.newStatus);

  @override
  List<Object?> get props => [caseId, newStatus];
}

class MarkTaskComplete extends CaseDetailEvent {
  final String caseId;
  final String taskId;

  const MarkTaskComplete(this.caseId, this.taskId);

  @override
  List<Object?> get props => [caseId, taskId];
}

// States
abstract class CaseDetailState extends Equatable {
  const CaseDetailState();

  @override
  List<Object?> get props => [];
}

class CaseDetailInitial extends CaseDetailState {}

class CaseDetailLoading extends CaseDetailState {}

class CaseDetailLoaded extends CaseDetailState {
  final CaseDetail caseDetail;

  const CaseDetailLoaded(this.caseDetail);

  @override
  List<Object?> get props => [caseDetail];
}

class CaseDetailError extends CaseDetailState {
  final String message;

  const CaseDetailError(this.message);

  @override
  List<Object?> get props => [message];
}

class CaseDetailUpdating extends CaseDetailState {
  final CaseDetail caseDetail;

  const CaseDetailUpdating(this.caseDetail);

  @override
  List<Object?> get props => [caseDetail];
}

// BLoC
class CaseDetailBloc extends Bloc<CaseDetailEvent, CaseDetailState> {
  final GetCaseDetail getCaseDetail;

  CaseDetailBloc({required this.getCaseDetail}) : super(CaseDetailInitial()) {
    on<LoadCaseDetail>(_onLoadCaseDetail);
    on<RefreshCaseDetail>(_onRefreshCaseDetail);
    on<UpdateCaseStatus>(_onUpdateCaseStatus);
    on<MarkTaskComplete>(_onMarkTaskComplete);
  }

  Future<void> _onLoadCaseDetail(
    LoadCaseDetail event,
    Emitter<CaseDetailState> emit,
  ) async {
    emit(CaseDetailLoading());
    
    try {
      // TODO: Replace with real use case call
      await Future.delayed(const Duration(seconds: 1));
      final mockDetail = _getMockCaseDetail(event.caseId);
      emit(CaseDetailLoaded(mockDetail));
    } catch (e) {
      emit(const CaseDetailError('Falha ao carregar detalhes do caso'));
    }
  }

  Future<void> _onRefreshCaseDetail(
    RefreshCaseDetail event,
    Emitter<CaseDetailState> emit,
  ) async {
    if (state is CaseDetailLoaded) {
      final currentData = (state as CaseDetailLoaded).caseDetail;
      emit(CaseDetailUpdating(currentData));
    } else {
      emit(CaseDetailLoading());
    }
    
    try {
      await Future.delayed(const Duration(milliseconds: 800));
      final mockDetail = _getMockCaseDetail(event.caseId);
      emit(CaseDetailLoaded(mockDetail));
    } catch (e) {
      emit(CaseDetailError('Erro ao atualizar caso: ${e.toString()}'));
    }
  }

  Future<void> _onUpdateCaseStatus(
    UpdateCaseStatus event,
    Emitter<CaseDetailState> emit,
  ) async {
    if (state is CaseDetailLoaded) {
      final currentData = (state as CaseDetailLoaded).caseDetail;
      emit(CaseDetailUpdating(currentData));
      
      try {
        await Future.delayed(const Duration(milliseconds: 500));
        
        final updatedDetail = CaseDetail(
          title: currentData.title,
          caseNumber: currentData.caseNumber,
          status: event.newStatus,
          lawyer: currentData.lawyer,
          consultationInfo: currentData.consultationInfo,
          preAnalysis: currentData.preAnalysis,
          nextSteps: currentData.nextSteps,
          documents: currentData.documents,
        );
        
        emit(CaseDetailLoaded(updatedDetail));
      } catch (e) {
        emit(CaseDetailError('Erro ao atualizar status: ${e.toString()}'));
      }
    }
  }

  Future<void> _onMarkTaskComplete(
    MarkTaskComplete event,
    Emitter<CaseDetailState> emit,
  ) async {
    if (state is CaseDetailLoaded) {
      final currentData = (state as CaseDetailLoaded).caseDetail;
      emit(CaseDetailUpdating(currentData));
      
      try {
        await Future.delayed(const Duration(milliseconds: 500));
        
        final updatedSteps = currentData.nextSteps.map((step) {
          if (step.title.contains(event.taskId)) {
            return NextStep(
              title: step.title,
              description: step.description,
              dueDate: step.dueDate,
              priority: step.priority,
              status: 'COMPLETED',
            );
          }
          return step;
        }).toList();
        
        final updatedDetail = CaseDetail(
          title: currentData.title,
          caseNumber: currentData.caseNumber,
          status: currentData.status,
          lawyer: currentData.lawyer,
          consultationInfo: currentData.consultationInfo,
          preAnalysis: currentData.preAnalysis,
          nextSteps: updatedSteps,
          documents: currentData.documents,
        );
        
        emit(CaseDetailLoaded(updatedDetail));
      } catch (e) {
        emit(CaseDetailError('Erro ao marcar tarefa como concluída: ${e.toString()}'));
      }
    }
  }

  CaseDetail _getMockCaseDetail(String caseId) {
    return CaseDetail(
      title: 'Rescisão Trabalhista',
      caseNumber: caseId,
      status: 'Em Andamento',
      lawyer: Lawyer(
        avatarUrl: 'https://i.pravatar.cc/150?u=carlos',
        name: 'Dr. Carlos Mendes',
        specialty: 'Direito Trabalhista',
        rating: 4.8,
        experienceYears: 12,
      ),
      consultationInfo: ConsultationInfo(
        date: '16/01/2024',
        duration: '45 minutos',
        mode: 'Vídeo',
        plan: 'Plano por Ato',
      ),
      preAnalysis: PreAnalysis(
        priority: 'High',
        tag: 'Análise Preliminar por IA',
        tagColor: Colors.deepPurple,
        estimatedTime: '15 dias úteis',
        urgency: 8,
        summary: 'Com base nas informações fornecidas, identifica-se uma possível demissão sem justa causa com irregularidades no pagamento das verbas rescisórias...',
        requiredDocs: [
          'Contrato de trabalho',
          'Carta de demissão',
          'Comprovantes de pagamento',
          'Holerites dos últimos 12 meses',
          'Termo de rescisão',
          'Recibos de férias',
          '+2 documentos adicionais'
        ],
        costs: [
          CostEstimate(label: 'Consulta', value: 'R\$ 350,00'),
          CostEstimate(label: 'Representação', value: 'R\$ 2.500,00'),
        ],
        risk: 'Risco baixo. Documentação sólida e jurisprudência favorável. Recomenda-se prosseguir com a consulta especializada.',
      ),
      nextSteps: [
        NextStep(
          title: 'Enviar documentos',
          description: 'Contrato de trabalho, carta de demissão e comprovantes',
          dueDate: '24/01/2024',
          priority: 'HIGH',
          status: 'PENDING'
        ),
        NextStep(
          title: 'Análise dos documentos',
          description: 'Advogado analisará a documentação enviada',
          dueDate: '27/01/2024',
          priority: 'MEDIUM',
          status: 'PENDING'
        ),
        NextStep(
          title: 'Elaboração de petição',
          description: 'Preparação da ação trabalhista',
          dueDate: '04/02/2024',
          priority: 'MEDIUM',
          status: 'PENDING'
        ),
        NextStep(
          title: 'Protocolo na Justiça',
          description: 'Protocolo da petição inicial no tribunal',
          dueDate: '10/02/2024',
          priority: 'HIGH',
          status: 'PENDING'
        ),
        NextStep(
          title: 'Audiência de conciliação',
          description: 'Primeira tentativa de acordo',
          dueDate: '25/02/2024',
          priority: 'MEDIUM',
          status: 'PENDING'
        ),
      ],
      documents: [
        DocumentItem(name: 'Relatório da Consulta', sizeDate: '2.3 MB • 16/01/2024, 12:30:00'),
        DocumentItem(name: 'Modelo de Petição', sizeDate: '1.1 MB • 17/01/2024, 06:15:00'),
        DocumentItem(name: 'Checklist de Documentos', sizeDate: '0.8 MB • 16/01/2024, 13:00:00'),
        DocumentItem(name: 'Contrato de Prestação de Serviços', sizeDate: '0.5 MB • 14/01/2024, 10:00:00'),
        DocumentItem(name: 'Cálculo de Verbas Rescisórias', sizeDate: '1.2 MB • 18/01/2024, 14:20:00'),
      ],
    );
  }
} 