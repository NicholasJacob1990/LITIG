import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/admin_dashboard_data.dart';
import '../entities/admin_metrics.dart';
import '../entities/admin_audit_log.dart';

abstract class AdminRepository {
  Future<Either<Failure, AdminDashboardData>> getAdminDashboard();
  Future<Either<Failure, AdminMetrics>> getAdminMetrics(String metricsType);
  Future<Either<Failure, List<AdminAuditLog>>> getAdminAuditLogs({
    DateTime? startDate,
    DateTime? endDate,
    String? logType,
  });
  Future<Either<Failure, Map<String, dynamic>>> generateExecutiveReport({
    required String reportType,
    Map<String, dynamic>? dateRange,
  });
  Future<Either<Failure, Map<String, dynamic>>> forceGlobalSync();
} 