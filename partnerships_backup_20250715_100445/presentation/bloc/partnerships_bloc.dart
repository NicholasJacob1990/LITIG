import 'package:bloc/bloc.dart';
import 'package:meu_app/src/features/partnerships/domain/usecases/get_partnerships.dart';
import 'package:meu_app/src/features/partnerships/presentation/bloc/partnerships_event.dart';
import 'package:meu_app/src/features/partnerships/presentation/bloc/partnerships_state.dart';

class PartnershipsBloc extends Bloc<PartnershipsEvent, PartnershipsState> {
  final GetPartnerships getPartnerships;

  PartnershipsBloc({required this.getPartnerships}) : super(PartnershipsInitial()) {
    on<FetchPartnerships>(_onFetchPartnerships);
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
} 