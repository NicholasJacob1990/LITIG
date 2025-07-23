import '../../domain/repositories/sla_metrics_repository.dart';
import '../datasources/sla_metrics_remote_data_source.dart';

class SlaMetricsRepositoryImpl implements SlaMetricsRepository {
  final SlaMetricsRemoteDataSource remoteDataSource;

  SlaMetricsRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<Map<String, dynamic>>> getComplianceMetrics({
    required String firmId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final result = await remoteDataSource.getComplianceMetrics(
        firmId: firmId,
        startDate: startDate,
        endDate: endDate,
      );
      return result;
    } catch (e) {
      return [];
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getPerformanceMetrics({
    required String firmId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final result = await remoteDataSource.getPerformanceMetrics(
        firmId: firmId,
        startDate: startDate,
        endDate: endDate,
      );
      return result;
    } catch (e) {
      return [];
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getViolationMetrics({
    required String firmId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final result = await remoteDataSource.getViolationMetrics(
        firmId: firmId,
        startDate: startDate,
        endDate: endDate,
      );
      return result;
    } catch (e) {
      return [];
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getEscalationMetrics({
    required String firmId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final result = await remoteDataSource.getEscalationMetrics(
        firmId: firmId,
        startDate: startDate,
        endDate: endDate,
      );
      return result;
    } catch (e) {
      return [];
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getTrendMetrics({
    required String firmId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final result = await remoteDataSource.getPerformanceTrends(
        firmId: firmId,
        startDate: startDate,
        endDate: endDate,
      );
      return result;
    } catch (e) {
      return [];
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getAlertMetrics({
    required String firmId,
  }) async {
    try {
      final result = await remoteDataSource.getAlertMetrics(
        firmId: firmId,
        startDate: DateTime.now().subtract(const Duration(days: 30)),
        endDate: DateTime.now(),
      );
      return result;
    } catch (e) {
      return [];
    }
  }
} 