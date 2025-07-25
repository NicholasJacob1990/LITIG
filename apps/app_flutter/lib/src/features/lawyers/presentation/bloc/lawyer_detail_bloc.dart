import 'package:flutter_bloc/flutter_bloc.dart';
import 'lawyer_detail_event.dart';
import 'lawyer_detail_state.dart';
import '../../domain/usecases/get_enriched_lawyer.dart';

class LawyerDetailBloc extends Bloc<LawyerDetailEvent, LawyerDetailState> {
  final GetEnrichedLawyerUseCase _getEnrichedLawyer;
  final RefreshEnrichedLawyerUseCase _refreshEnrichedLawyer;

  LawyerDetailBloc({
    required GetEnrichedLawyerUseCase getEnrichedLawyer,
    required RefreshEnrichedLawyerUseCase refreshEnrichedLawyer,
  }) : _getEnrichedLawyer = getEnrichedLawyer,
       _refreshEnrichedLawyer = refreshEnrichedLawyer,
       super(LawyerDetailInitial()) {
    on<LoadLawyerDetail>(_onLoadLawyerDetail);
    on<RefreshLawyerDetail>(_onRefreshLawyerDetail);
  }

  Future<void> _onLoadLawyerDetail(
    LoadLawyerDetail event,
    Emitter<LawyerDetailState> emit,
  ) async {
    emit(LawyerDetailLoading());
    try {
      final enrichedLawyer = await _getEnrichedLawyer(event.lawyerId);
      emit(LawyerDetailLoaded(enrichedLawyer: enrichedLawyer));
    } catch (e) {
      emit(LawyerDetailError(message: e.toString()));
    }
  }

    Future<void> _onRefreshLawyerDetail(
    RefreshLawyerDetail event,
    Emitter<LawyerDetailState> emit,
  ) async {
    emit(LawyerDetailLoading());
    try {
      final enrichedLawyer = await _refreshEnrichedLawyer(event.lawyerId);
      emit(LawyerDetailLoaded(enrichedLawyer: enrichedLawyer));
    } catch (e) {
      emit(LawyerDetailError(message: e.toString()));
    }
  }
} 