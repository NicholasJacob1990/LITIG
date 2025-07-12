import 'package:flutter_bloc/flutter_bloc.dart';

sealed class CaseDetailEvent {}
class LoadCaseDetail extends CaseDetailEvent {
  final String caseId;
  LoadCaseDetail(this.caseId);
}

class CaseDetailState {
  const CaseDetailState({
    this.loading = false,
    this.error,
    /* TODO: adicione campos de domínio */
  });

  final bool   loading;
  final String? error;

  CaseDetailState copyWith({bool? loading, String? error}) =>
      CaseDetailState(loading: loading ?? this.loading, error: error);
}

class CaseDetailBloc extends Bloc<CaseDetailEvent, CaseDetailState> {
  CaseDetailBloc() : super(const CaseDetailState()) {
    on<LoadCaseDetail>((event, emit) async {
      emit(state.copyWith(loading: true));
      try {
        // TODO buscar dados reais em repositório / API
        await Future.delayed(const Duration(milliseconds: 500));
        emit(state.copyWith(loading: false));
      } catch (e) {
        emit(state.copyWith(loading: false, error: e.toString()));
      }
    });
  }
} 