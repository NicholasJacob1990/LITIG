import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/error/exceptions.dart';
import '../../domain/entities/sla_metrics_entity.dart';
import '../../domain/repositories/sla_metrics_repository.dart';
import '../datasources/sla_metrics_remote_data_source.dart';

class SlaMetricsRepositoryImpl implements SlaMetricsRepository {
  final SlaMetricsRemoteDataSource remoteDataSource;

  SlaMetricsRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, SlaMetricsEntity>> getMetrics({
    required String firmId,
    required DateTime startDate,
    required DateTime endDate,
    String? lawyerId,
    String? priority,
    String? caseType,
  }) async {
    try {
      final result = await remoteDataSource.getMetrics(
        firmId: firmId,
        startDate: startDate,
        endDate: endDate,
        lawyerId: lawyerId,
        priority: priority,
        caseType: caseType,
      );
      return Right(result);
    } on ServerException {
      return Left(ServerFailure('Erro ao obter métricas SLA'));
    } on NetworkException {
      return Left(NetworkFailure('Erro de conexão'));
    } catch (e) {
      return Left(UnexpectedFailure('Erro inesperado: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<SlaComplianceMetric>>> getComplianceMetrics({
    required String firmId,
    required DateTime startDate,
    required DateTime endDate,
    String? groupBy,
  }) async {
    try {
      final result = await remoteDataSource.getComplianceMetrics(
        firmId: firmId,
        startDate: startDate,
        endDate: endDate,
        groupBy: groupBy,
      );
      return Right(result);
    } on ServerException {
      return Left(ServerFailure('Erro ao obter métricas de compliance'));
    } on NetworkException {
      return Left(NetworkFailure('Erro de conexão'));
    } catch (e) {
      return Left(UnexpectedFailure('Erro inesperado: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<SlaPerformanceMetric>>> getPerformanceMetrics({
    required String firmId,
    required DateTime startDate,
    required DateTime endDate,
    String? lawyerId,
  }) async {
    try {
      final result = await remoteDataSource.getPerformanceMetrics(
        firmId: firmId,
        startDate: startDate,
        endDate: endDate,
        lawyerId: lawyerId,
      );
      return Right(result);
    } on ServerException {
      return Left(ServerFailure('Erro ao obter métricas de performance'));
    } on NetworkException {
      return Left(NetworkFailure('Erro de conexão'));
    } catch (e) {
      return Left(UnexpectedFailure('Erro inesperado: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<SlaViolationMetric>>> getViolationMetrics({
    required String firmId,
    required DateTime startDate,
    required DateTime endDate,
    String? reason,
  }) async {
    try {
      final result = await remoteDataSource.getViolationMetrics(
        firmId: firmId,
        startDate: startDate,
        endDate: endDate,
        reason: reason,
      );
      return Right(result);
    } on ServerException {
      return Left(ServerFailure('Erro ao obter métricas de violação'));
    } on NetworkException {
      return Left(NetworkFailure('Erro de conexão'));
    } catch (e) {
      return Left(UnexpectedFailure('Erro inesperado: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<SlaEscalationMetric>>> getEscalationMetrics({
    required String firmId,
    required DateTime startDate,
    required DateTime endDate,
    String? level,
  }) async {
    try {
      final result = await remoteDataSource.getEscalationMetrics(
        firmId: firmId,
        startDate: startDate,
        endDate: endDate,
        level: level,
      );
      return Right(result);
    } on ServerException {
      return Left(ServerFailure('Erro ao obter métricas de escalação'));
    } on NetworkException {
      return Left(NetworkFailure('Erro de conexão'));
    } catch (e) {
      return Left(UnexpectedFailure('Erro inesperado: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<SlaTrendMetric>>> getTrendMetrics({
    required String firmId,
    required String metric,
    required String period,
    String? granularity,
  }) async {
    try {
      final result = await remoteDataSource.getTrendMetrics(
        firmId: firmId,
        metric: metric,
        period: period,
        granularity: granularity,
      );
      return Right(result);
    } on ServerException {
      return Left(ServerFailure('Erro ao obter métricas de tendência'));
    } on NetworkException {
      return Left(NetworkFailure('Erro de conexão'));
    } catch (e) {
      return Left(UnexpectedFailure('Erro inesperado: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> generateComplianceReport({
    required String firmId,
    required String period,
    bool includeDetails = true,
    String format = 'json',
  }) async {
    try {
      final result = await remoteDataSource.generateComplianceReport(
        firmId: firmId,
        period: period,
        includeDetails: includeDetails,
        format: format,
      );
      return Right(result);
    } on ServerException {
      return Left(ServerFailure('Erro ao gerar relatório de compliance'));
    } on NetworkException {
      return Left(NetworkFailure('Erro de conexão'));
    } catch (e) {
      return Left(UnexpectedFailure('Erro inesperado: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> generatePerformanceReport({
    required String firmId,
    required DateTime startDate,
    required DateTime endDate,
    List<String>? lawyers,
    String format = 'json',
  }) async {
    try {
      final result = await remoteDataSource.generatePerformanceReport(
        firmId: firmId,
        startDate: startDate,
        endDate: endDate,
        lawyers: lawyers,
        format: format,
      );
      return Right(result);
    } on ServerException {
      return Left(ServerFailure('Erro ao gerar relatório de performance'));
    } on NetworkException {
      return Left(NetworkFailure('Erro de conexão'));
    } catch (e) {
      return Left(UnexpectedFailure('Erro inesperado: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> getPerformanceTrends({
    required String firmId,
    required String metric,
    required String period,
    required String granularity,
  }) async {
    try {
      final result = await remoteDataSource.getPerformanceTrends(
        firmId: firmId,
        metric: metric,
        period: period,
        granularity: granularity,
      );
      return Right(result);
    } on ServerException {
      return Left(ServerFailure('Erro ao obter tendências de performance'));
    } on NetworkException {
      return Left(NetworkFailure('Erro de conexão'));
    } catch (e) {
      return Left(UnexpectedFailure('Erro inesperado: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getBenchmarkData({
    required String firmId,
    required String metric,
    String? industry,
    String? firmSize,
  }) async {
    try {
      final result = await remoteDataSource.getBenchmarkData(
        firmId: firmId,
        metric: metric,
        industry: industry,
        firmSize: firmSize,
      );
      return Right(result);
    } on ServerException {
      return Left(ServerFailure('Erro ao obter dados de benchmark'));
    } on NetworkException {
      return Left(NetworkFailure('Erro de conexão'));
    } catch (e) {
      return Left(UnexpectedFailure('Erro inesperado: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getPredictiveAnalytics({
    required String firmId,
    required String metric,
    int forecastDays = 30,
  }) async {
    try {
      final result = await remoteDataSource.getPredictiveAnalytics(
        firmId: firmId,
        metric: metric,
        forecastDays: forecastDays,
      );
      return Right(result);
    } on ServerException {
      return Left(ServerFailure('Erro ao obter análise preditiva'));
    } on NetworkException {
      return Left(NetworkFailure('Erro de conexão'));
    } catch (e) {
      return Left(UnexpectedFailure('Erro inesperado: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<SlaAlertMetric>>> getAlertMetrics({
    required String firmId,
    String? severity,
    bool activeOnly = true,
  }) async {
    try {
      final result = await remoteDataSource.getAlertMetrics(
        firmId: firmId,
        severity: severity,
        activeOnly: activeOnly,
      );
      return Right(result);
    } on ServerException {
      return Left(ServerFailure('Erro ao obter métricas de alertas'));
    } on NetworkException {
      return Left(NetworkFailure('Erro de conexão'));
    } catch (e) {
      return Left(UnexpectedFailure('Erro inesperado: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getCustomReport({
    required String firmId,
    required Map<String, dynamic> reportConfig,
  }) async {
    try {
      final result = await remoteDataSource.getCustomReport(
        firmId: firmId,
        reportConfig: reportConfig,
      );
      return Right(result);
    } on ServerException {
      return Left(ServerFailure('Erro ao gerar relatório customizado'));
    } on NetworkException {
      return Left(NetworkFailure('Erro de conexão'));
    } catch (e) {
      return Left(UnexpectedFailure('Erro inesperado: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, bool>> exportMetrics({
    required String firmId,
    required DateTime startDate,
    required DateTime endDate,
    required String format,
    String? filePath,
  }) async {
    try {
      final result = await remoteDataSource.exportMetrics(
        firmId: firmId,
        startDate: startDate,
        endDate: endDate,
        format: format,
        filePath: filePath,
      );
      return Right(result);
    } on ServerException {
      return Left(ServerFailure('Erro ao exportar métricas'));
    } on NetworkException {
      return Left(NetworkFailure('Erro de conexão'));
    } catch (e) {
      return Left(UnexpectedFailure('Erro inesperado: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getMetricsSummary({
    required String firmId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final result = await remoteDataSource.getMetricsSummary(
        firmId: firmId,
        startDate: startDate,
        endDate: endDate,
      );
      return Right(result);
    } on ServerException {
      return Left(ServerFailure('Erro ao obter resumo de métricas'));
    } on NetworkException {
      return Left(NetworkFailure('Erro de conexão'));
    } catch (e) {
      return Left(UnexpectedFailure('Erro inesperado: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> getTopPerformers({
    required String firmId,
    required String metric,
    int limit = 10,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final result = await remoteDataSource.getTopPerformers(
        firmId: firmId,
        metric: metric,
        limit: limit,
        startDate: startDate,
        endDate: endDate,
      );
      return Right(result);
    } on ServerException {
      return Left(ServerFailure('Erro ao obter top performers'));
    } on NetworkException {
      return Left(NetworkFailure('Erro de conexão'));
    } catch (e) {
      return Left(UnexpectedFailure('Erro inesperado: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getKPIDashboard({
    required String firmId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final result = await remoteDataSource.getKPIDashboard(
        firmId: firmId,
        startDate: startDate,
        endDate: endDate,
      );
      return Right(result);
    } on ServerException {
      return Left(ServerFailure('Erro ao obter dashboard KPI'));
    } on NetworkException {
      return Left(NetworkFailure('Erro de conexão'));
    } catch (e) {
      return Left(UnexpectedFailure('Erro inesperado: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, bool>> scheduleReport({
    required String firmId,
    required Map<String, dynamic> reportConfig,
    required String schedule,
    required List<String> recipients,
  }) async {
    try {
      final result = await remoteDataSource.scheduleReport(
        firmId: firmId,
        reportConfig: reportConfig,
        schedule: schedule,
        recipients: recipients,
      );
      return Right(result);
    } on ServerException {
      return Left(ServerFailure('Erro ao agendar relatório'));
    } on NetworkException {
      return Left(NetworkFailure('Erro de conexão'));
    } catch (e) {
      return Left(UnexpectedFailure('Erro inesperado: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> getScheduledReports(String firmId) async {
    try {
      final result = await remoteDataSource.getScheduledReports(firmId);
      return Right(result);
    } on ServerException {
      return Left(ServerFailure('Erro ao obter relatórios agendados'));
    } on NetworkException {
      return Left(NetworkFailure('Erro de conexão'));
    } catch (e) {
      return Left(UnexpectedFailure('Erro inesperado: ${e.toString()}'));
    }
  }
} 