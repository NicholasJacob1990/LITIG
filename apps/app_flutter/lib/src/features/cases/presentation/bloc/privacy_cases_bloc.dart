import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:meu_app/src/core/utils/logger.dart';
import 'package:meu_app/src/features/cases/domain/entities/accepted_case_preview.dart';
import 'package:meu_app/src/features/cases/domain/usecases/privacy_cases_usecases.dart';

// Events
abstract class PrivacyCasesEvent extends Equatable {
  const PrivacyCasesEvent();
  @override
  List<Object?> get props => [];
}

class LoadMyAcceptedCases extends PrivacyCasesEvent {}

class AcceptCaseRequested extends PrivacyCasesEvent {
  final String caseId;
  const AcceptCaseRequested(this.caseId);
  @override
  List<Object?> get props => [caseId];
}

class AbandonCaseRequested extends PrivacyCasesEvent {
  final String caseId;
  final String? reason;
  const AbandonCaseRequested(this.caseId, {this.reason});
  @override
  List<Object?> get props => [caseId, reason];
}

class CheckAccessRequested extends PrivacyCasesEvent {
  final String caseId;
  const CheckAccessRequested(this.caseId);
  @override
  List<Object?> get props => [caseId];
}

// States
abstract class PrivacyCasesState extends Equatable {
  const PrivacyCasesState();
  @override
  List<Object?> get props => [];
}

class PrivacyCasesInitial extends PrivacyCasesState {}

class PrivacyCasesLoading extends PrivacyCasesState {}

class MyAcceptedCasesLoaded extends PrivacyCasesState {
  final List<AcceptedCasePreview> cases;
  const MyAcceptedCasesLoaded(this.cases);
  @override
  List<Object?> get props => [cases];
}

class PrivacyCasesActionSuccess extends PrivacyCasesState {
  final String message;
  const PrivacyCasesActionSuccess(this.message);
  @override
  List<Object?> get props => [message];
}

class PrivacyCasesError extends PrivacyCasesState {
  final String message;
  const PrivacyCasesError(this.message);
  @override
  List<Object?> get props => [message];
}

class AccessStatusLoaded extends PrivacyCasesState {
  final bool fullAccess;
  const AccessStatusLoaded(this.fullAccess);
  @override
  List<Object?> get props => [fullAccess];
}

class PrivacyCasesBloc extends Bloc<PrivacyCasesEvent, PrivacyCasesState> {
  final ListMyAcceptedCasesUseCase listMyAcceptedCases;
  final AcceptCaseUseCase acceptCase;
  final AbandonCaseUseCase abandonCase;
  final HasFullAccessUseCase hasFullAccess;

  PrivacyCasesBloc({
    required this.listMyAcceptedCases,
    required this.acceptCase,
    required this.abandonCase,
    required this.hasFullAccess,
  }) : super(PrivacyCasesInitial()) {
    on<LoadMyAcceptedCases>(_onLoadMyAccepted);
    on<AcceptCaseRequested>(_onAcceptCase);
    on<AbandonCaseRequested>(_onAbandonCase);
    on<CheckAccessRequested>(_onCheckAccess);
  }

  Future<void> _onLoadMyAccepted(
    LoadMyAcceptedCases event,
    Emitter<PrivacyCasesState> emit,
  ) async {
    emit(PrivacyCasesLoading());
    try {
      final cases = await listMyAcceptedCases();
      emit(MyAcceptedCasesLoaded(cases));
    } catch (e) {
      AppLogger.error('Failed to load accepted cases', error: e);
      emit(const PrivacyCasesError('Erro ao carregar casos aceitos'));
    }
  }

  Future<void> _onAcceptCase(
    AcceptCaseRequested event,
    Emitter<PrivacyCasesState> emit,
  ) async {
    emit(PrivacyCasesLoading());
    try {
      final ok = await acceptCase(event.caseId);
      if (ok) {
        emit(const PrivacyCasesActionSuccess('Caso aceito com sucesso'));
      } else {
        emit(const PrivacyCasesError('Falha ao aceitar o caso'));
      }
    } catch (e) {
      AppLogger.error('Failed to accept case', error: e);
      emit(const PrivacyCasesError('Erro ao aceitar o caso'));
    }
  }

  Future<void> _onAbandonCase(
    AbandonCaseRequested event,
    Emitter<PrivacyCasesState> emit,
  ) async {
    emit(PrivacyCasesLoading());
    try {
      await abandonCase(event.caseId, reason: event.reason);
      emit(const PrivacyCasesActionSuccess('Caso abandonado com sucesso'));
    } catch (e) {
      AppLogger.error('Failed to abandon case', error: e);
      emit(const PrivacyCasesError('Erro ao abandonar o caso'));
    }
  }

  Future<void> _onCheckAccess(
    CheckAccessRequested event,
    Emitter<PrivacyCasesState> emit,
  ) async {
    try {
      final full = await hasFullAccess(event.caseId);
      emit(AccessStatusLoaded(full));
    } catch (e) {
      AppLogger.error('Failed to check access', error: e);
    }
  }
}


