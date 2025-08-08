import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:meu_app/src/features/dashboard/domain/entities/dashboard_stats.dart';
import 'package:meu_app/src/features/dashboard/domain/usecases/get_lawyer_stats_usecase.dart';

part 'dashboard_event.dart';
part 'dashboard_state.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final GetLawyerStatsUseCase getLawyerStatsUseCase;
  final GetContractorStatsUseCase? getContractorStatsUseCase;
  final GetClientStatsUseCase? getClientStatsUseCase;

  DashboardBloc({required this.getLawyerStatsUseCase, this.getContractorStatsUseCase, this.getClientStatsUseCase}) : super(DashboardInitial()) {
    on<FetchLawyerStats>(_onFetchLawyerStats);
    on<FetchContractorStats>(_onFetchContractorStats);
    on<FetchClientStats>(_onFetchClientStats);
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

  Future<void> _onFetchContractorStats(
    FetchContractorStats event,
    Emitter<DashboardState> emit,
  ) async {
    emit(DashboardLoading());
    try {
      if (getContractorStatsUseCase == null) {
        // Fallback simples a lawyer stats
        final stats = await getLawyerStatsUseCase();
        emit(DashboardLoaded(stats));
        return;
      }
      final stats = await getContractorStatsUseCase!();
      emit(DashboardLoaded(stats));
    } catch (e) {
      emit(DashboardError(e.toString()));
    }
  }

  Future<void> _onFetchClientStats(
    FetchClientStats event,
    Emitter<DashboardState> emit,
  ) async {
    emit(DashboardLoading());
    try {
      if (getClientStatsUseCase != null) {
        final stats = await getClientStatsUseCase!();
        emit(DashboardLoaded(stats));
        return;
      }
      final stats = await getLawyerStatsUseCase();
      emit(DashboardLoaded(stats));
    } catch (e) {
      emit(DashboardError(e.toString()));
    }
  }
} 