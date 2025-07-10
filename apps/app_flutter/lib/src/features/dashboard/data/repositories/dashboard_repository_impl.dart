import 'package:meu_app/src/features/dashboard/data/datasources/dashboard_remote_data_source.dart';
import 'package:meu_app/src/features/dashboard/domain/entities/dashboard_stats.dart';
import 'package:meu_app/src/features/dashboard/domain/repositories/dashboard_repository.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  final DashboardRemoteDataSource remoteDataSource;

  DashboardRepositoryImpl({required this.remoteDataSource});

  @override
  Future<DashboardStats> getLawyerStats() async {
    return await remoteDataSource.getLawyerStats();
  }
} 