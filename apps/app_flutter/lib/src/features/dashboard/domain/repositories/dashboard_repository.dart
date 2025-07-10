import 'package:meu_app/src/features/dashboard/domain/entities/dashboard_stats.dart';

abstract class DashboardRepository {
  Future<DashboardStats> getLawyerStats();
} 