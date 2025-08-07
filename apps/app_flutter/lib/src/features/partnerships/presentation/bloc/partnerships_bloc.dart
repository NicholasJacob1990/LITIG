import 'package:bloc/bloc.dart';
import 'package:meu_app/src/features/partnerships/domain/usecases/get_partnerships.dart';
import 'package:meu_app/src/features/partnerships/domain/usecases/accept_partnership.dart' as use_cases;
import 'package:meu_app/src/features/partnerships/domain/usecases/reject_partnership.dart' as use_cases;
import 'package:meu_app/src/features/partnerships/presentation/bloc/partnerships_event.dart';
import 'package:meu_app/src/features/partnerships/presentation/bloc/partnerships_state.dart';

class PartnershipsBloc extends Bloc<PartnershipsEvent, PartnershipsState> {
  final GetPartnerships getPartnerships;
  final use_cases.AcceptPartnership acceptPartnership;
  final use_cases.RejectPartnership rejectPartnership;

  PartnershipsBloc({
    required this.getPartnerships,
    required this.acceptPartnership,
    required this.rejectPartnership,
  }) : super(PartnershipsInitial()) {
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
    try {
      emit(PartnershipsLoading());
      
      final result = await acceptPartnership(event.partnershipId);
      
      if (result.isSuccess) {
        // Recarregar parcerias após aceitar
        final partnershipsResult = await getPartnerships();
        partnershipsResult.fold(
          (failure) => emit(PartnershipsError(failure.message)),
          (partnerships) => emit(PartnershipsLoaded(partnerships)),
        );
      } else {
        emit(PartnershipsError(result.failure.message));
      }
    } catch (e) {
      emit(PartnershipsError('Erro ao aceitar parceria: $e'));
    }
  }

  Future<void> _onRejectPartnership(
    RejectPartnership event,
    Emitter<PartnershipsState> emit,
  ) async {
    try {
      emit(PartnershipsLoading());
      
      final result = await rejectPartnership(event.partnershipId);
      
      if (result.isSuccess) {
        // Recarregar parcerias após rejeitar
        final partnershipsResult = await getPartnerships();
        partnershipsResult.fold(
          (failure) => emit(PartnershipsError(failure.message)),
          (partnerships) => emit(PartnershipsLoaded(partnerships)),
        );
      } else {
        emit(PartnershipsError(result.failure.message));
      }
    } catch (e) {
      emit(PartnershipsError('Erro ao rejeitar parceria: $e'));
    }
  }
} 