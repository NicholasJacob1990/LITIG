import 'package:meu_app/src/features/dashboard/domain/entities/dashboard_stats.dart';

abstract class DashboardRemoteDataSource {
  Future<DashboardStats> getLawyerStats();
}

class DashboardRemoteDataSourceImpl implements DashboardRemoteDataSource {
  // final Dio dio; // Será usado quando o endpoint existir
  // DashboardRemoteDataSourceImpl({required this.dio});

  @override
  Future<DashboardStats> getLawyerStats() async {
    // Simula uma chamada de rede
    await Future.delayed(const Duration(milliseconds: 800));
    
    // Retorna dados simulados
    return const DashboardStats(
      activeCases: 12,
      newLeads: 3,
      alerts: 1,
    );
  }
} 