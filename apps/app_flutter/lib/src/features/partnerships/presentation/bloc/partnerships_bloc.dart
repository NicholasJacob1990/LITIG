import 'package:bloc/bloc.dart';
import 'package:meu_app/src/features/partnerships/domain/usecases/get_partnerships.dart';
import 'package:meu_app/src/features/partnerships/presentation/bloc/partnerships_event.dart';
import 'package:meu_app/src/features/partnerships/presentation/bloc/partnerships_state.dart';

class PartnershipsBloc extends Bloc<PartnershipsEvent, PartnershipsState> {
  final GetPartnerships getPartnerships;

  PartnershipsBloc({required this.getPartnerships}) : super(PartnershipsInitial()) {
    on<FetchPartnerships>(_onFetchPartnerships);
    on<LoadPartnerships>(_onLoadPartnerships);
    on<AcceptPartnership>(_onAcceptPartnership);
    on<RejectPartnership>(_onRejectPartnership);
  }

  Future<void> _onFetchPartnerships(
    FetchPartnerships event,
    Emitter<PartnershipsState> emit,
  ) async {
    emit(PartnershipsLoading());
    
    final result = await getPartnerships();

    result.fold(
      (failure) => emit(PartnershipsError(failure.message)),
      (partnerships) => emit(PartnershipsLoaded(partnerships)),
    );
  }

  Future<void> _onLoadPartnerships(
    LoadPartnerships event,
    Emitter<PartnershipsState> emit,
  ) async {
    emit(PartnershipsLoading());
    
    final result = await getPartnerships();

    result.fold(
      (failure) => emit(PartnershipsError(failure.message)),
      (partnerships) => emit(PartnershipsLoaded(partnerships)),
    );
  }

  Future<void> _onAcceptPartnership(
    AcceptPartnership event,
    Emitter<PartnershipsState> emit,
  ) async {
    // TODO: Implementar accept partnership use case
    try {
      emit(PartnershipsLoading());
      // Simular aceitação da parceria
      final result = await getPartnerships();
      result.fold(
        (failure) => emit(PartnershipsError(failure.message)),
        (partnerships) => emit(PartnershipsLoaded(partnerships)),
      );
    } catch (e) {
      emit(PartnershipsError('Erro ao aceitar parceria: $e'));
    }
  }

  Future<void> _onRejectPartnership(
    RejectPartnership event,
    Emitter<PartnershipsState> emit,
  ) async {
    // TODO: Implementar reject partnership use case
    try {
      emit(PartnershipsLoading());
      // Simular rejeição da parceria
      final result = await getPartnerships();
      result.fold(
        (failure) => emit(PartnershipsError(failure.message)),
        (partnerships) => emit(PartnershipsLoaded(partnerships)),
      );
    } catch (e) {
      emit(PartnershipsError('Erro ao rejeitar parceria: $e'));
    }
  }
} 