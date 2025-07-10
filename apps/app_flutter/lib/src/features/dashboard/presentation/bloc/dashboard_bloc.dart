import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:meu_app/src/features/dashboard/domain/entities/dashboard_stats.dart';
import 'package:meu_app/src/features/dashboard/domain/usecases/get_lawyer_stats_usecase.dart';

part 'dashboard_event.dart';
part 'dashboard_state.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final GetLawyerStatsUseCase getLawyerStatsUseCase;

  DashboardBloc({required this.getLawyerStatsUseCase}) : super(DashboardInitial()) {
    on<FetchLawyerStats>(_onFetchLawyerStats);
  }

  Future<void> _onFetchLawyerStats(
    FetchLawyerStats event,
    Emitter<DashboardState> emit,
  ) async {
    emit(DashboardLoading());
    try {
      final stats = await getLawyerStatsUseCase();
      emit(DashboardLoaded(stats));
    } catch (e) {
      emit(DashboardError(e.toString()));
    }
  }
} 