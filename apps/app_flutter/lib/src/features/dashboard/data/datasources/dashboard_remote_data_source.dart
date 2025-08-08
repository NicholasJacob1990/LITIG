import 'package:dio/dio.dart';
import 'package:meu_app/src/features/dashboard/domain/entities/dashboard_stats.dart';

abstract class DashboardRemoteDataSource {
  Future<DashboardStats> getLawyerStats();
  Future<DashboardStats> getContractorStats();
  Future<DashboardStats> getClientStats();
}

class DashboardRemoteDataSourceImpl implements DashboardRemoteDataSource {
  final Dio dio;
  final String baseUrl;

  DashboardRemoteDataSourceImpl({required this.dio, this.baseUrl = 'http://127.0.0.1:8080/api/v1/dashboard'});

  @override
  Future<DashboardStats> getLawyerStats() async {
    final resp = await dio.get('$baseUrl/lawyer-stats');
    final data = resp.data as Map<String, dynamic>;
    return DashboardStats(
      activeCases: (data['activeCases'] ?? 0) as int,
      newLeads: (data['newLeads'] ?? 0) as int,
      alerts: (data['alerts'] ?? 0) as int,
      activeClients: (data['activeClients'] ?? 0) as int,
      activePartnerships: (data['activePartnerships'] ?? 0) as int,
      monthlyRevenue: (data['monthlyRevenue'] ?? 0.0).toDouble(),
      conversionRate: (data['conversionRate'] ?? 0) as int,
      prospects: (data['prospects'] ?? 0) as int,
      qualified: (data['qualified'] ?? 0) as int,
      proposal: (data['proposal'] ?? 0) as int,
      negotiation: (data['negotiation'] ?? 0) as int,
      closed: (data['closed'] ?? 0) as int,
    );
  }

  @override
  Future<DashboardStats> getContractorStats() async {
    final resp = await dio.get('$baseUrl/contractor-stats');
    final data = resp.data as Map<String, dynamic>;
    return DashboardStats(
      activeCases: (data['activeCases'] ?? 0) as int,
      newLeads: (data['newLeads'] ?? 0) as int,
      alerts: (data['alerts'] ?? 0) as int,
      activeClients: (data['activeClients'] ?? 0) as int,
      activePartnerships: (data['activePartnerships'] ?? 0) as int,
      monthlyRevenue: (data['monthlyRevenue'] ?? 0.0).toDouble(),
      conversionRate: (data['conversionRate'] ?? 0) as int,
      prospects: (data['prospects'] ?? 0) as int,
      qualified: (data['qualified'] ?? 0) as int,
      proposal: (data['proposal'] ?? 0) as int,
      negotiation: (data['negotiation'] ?? 0) as int,
      closed: (data['closed'] ?? 0) as int,
    );
  }

  @override
  Future<DashboardStats> getClientStats() async {
    final resp = await dio.get('$baseUrl/client-stats');
    final data = resp.data as Map<String, dynamic>;
    return DashboardStats(
      activeCases: (data['activeCases'] ?? 0) as int,
      newLeads: (data['newLeads'] ?? 0) as int,
      alerts: (data['alerts'] ?? 0) as int,
      activeClients: (data['activeClients'] ?? 0) as int,
      activePartnerships: (data['activePartnerships'] ?? 0) as int,
      monthlyRevenue: (data['monthlyRevenue'] ?? 0.0).toDouble(),
      conversionRate: (data['conversionRate'] ?? 0) as int,
      prospects: (data['prospects'] ?? 0) as int,
      qualified: (data['qualified'] ?? 0) as int,
      proposal: (data['proposal'] ?? 0) as int,
      negotiation: (data['negotiation'] ?? 0) as int,
      closed: (data['closed'] ?? 0) as int,
    );
  }
}