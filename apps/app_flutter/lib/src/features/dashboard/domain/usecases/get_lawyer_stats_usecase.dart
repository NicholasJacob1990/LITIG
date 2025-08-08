import 'package:meu_app/src/features/dashboard/domain/entities/dashboard_stats.dart';
import 'package:meu_app/src/features/dashboard/domain/repositories/dashboard_repository.dart';

class GetLawyerStatsUseCase {
  final DashboardRepository repository;

  GetLawyerStatsUseCase(this.repository);

  Future<DashboardStats> call() async {
    return await repository.getLawyerStats();
  }
} 

class GetContractorStatsUseCase {
  final DashboardRepository repository;

  GetContractorStatsUseCase(this.repository);

  Future<DashboardStats> call() async {
    return await repository.getContractorStats();
  }
}

class GetClientStatsUseCase {
  final DashboardRepository repository;

  GetClientStatsUseCase(this.repository);

  Future<DashboardStats> call() async {
    return await repository.getClientStats();
  }
}