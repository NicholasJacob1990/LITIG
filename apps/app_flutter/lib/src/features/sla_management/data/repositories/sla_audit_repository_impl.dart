import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/error/exceptions.dart';
import '../../domain/entities/sla_audit_entity.dart';
import '../../domain/entities/sla_enums.dart';
import '../datasources/sla_audit_remote_data_source.dart';

class SlaAuditRepositoryImpl {
  final SlaAuditRemoteDataSource remoteDataSource;

  SlaAuditRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, SlaAuditEntity>> createAuditEntry({
    required String firmId,
    required AuditEventType eventType,
    required String entityId,
    required String entityType,
    required String userId,
    required Map<String, dynamic> changes,
    required Map<String, dynamic> metadata,
  }) async {
    try {
      final result = await remoteDataSource.createAuditEntry(
        firmId: firmId,
        eventType: eventType,
        entityId: entityId,
        entityType: entityType,
        userId: userId,
        changes: changes,
        metadata: metadata,
      );
      return Right(result);
    } on ServerException {
      return const Left(ServerFailure(message: 'Erro ao criar entrada de auditoria'));
    } on NetworkException {
      return const Left(NetworkFailure(message: 'Erro de conexão'));
    } catch (e) {
      return Left(UnexpectedFailure(message: 'Erro inesperado: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<SlaAuditEntity>>> getAuditTrail({
    required String firmId,
    String? entityId,
    String? entityType,
    List<AuditEventType>? eventTypes,
    String? userId,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 100,
    int offset = 0,
  }) async {
    try {
      final result = await remoteDataSource.getAuditTrail(
        firmId: firmId,
        entityId: entityId,
        entityType: entityType,
        eventTypes: eventTypes,
        userId: userId,
        startDate: startDate,
        endDate: endDate,
        limit: limit,
        offset: offset,
      );
      return Right(result);
    } on ServerException {
      return const Left(ServerFailure(message: 'Erro ao obter trilha de auditoria'));
    } on NetworkException {
      return const Left(NetworkFailure(message: 'Erro de conexão'));
    } catch (e) {
      return Left(UnexpectedFailure(message: 'Erro inesperado: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> generateComplianceReport({
    required String firmId,
    required String period,
    bool includeDetails = true,
    List<String> complianceStandards = const ['ISO9001', 'LGPD', 'OAB', 'INTERNAL'],
    String format = 'json',
  }) async {
    try {
      final result = await remoteDataSource.generateComplianceReport(
        firmId: firmId,
        period: period,
        includeDetails: includeDetails,
        complianceStandards: complianceStandards,
        format: format,
      );
      return Right(result);
    } on ServerException {
      return const Left(ServerFailure(message: 'Erro ao gerar relatório de compliance'));
    } on NetworkException {
      return const Left(NetworkFailure(message: 'Erro de conexão'));
    } catch (e) {
      return Left(UnexpectedFailure(message: 'Erro inesperado: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> verifyIntegrity({
    required String firmId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final result = await remoteDataSource.verifyIntegrity(
        firmId: firmId,
        startDate: startDate,
        endDate: endDate,
      );
      return Right(result);
    } on ServerException {
      return const Left(ServerFailure(message: 'Erro ao verificar integridade'));
    } on NetworkException {
      return const Left(NetworkFailure(message: 'Erro de conexão'));
    } catch (e) {
      return Left(UnexpectedFailure(message: 'Erro inesperado: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, String>> exportAuditLog({
    required String firmId,
    required String format,
    DateTime? startDate,
    DateTime? endDate,
    bool includeMetadata = true,
    bool encryptFile = false,
  }) async {
    try {
      final result = await remoteDataSource.exportAuditLog(
        firmId: firmId,
        format: format,
        startDate: startDate,
        endDate: endDate,
        includeMetadata: includeMetadata,
        encryptFile: encryptFile,
      );
      return Right(result);
    } on ServerException {
      return const Left(ServerFailure(message: 'Erro ao exportar log de auditoria'));
    } on NetworkException {
      return const Left(NetworkFailure(message: 'Erro de conexão'));
    } catch (e) {
      return Left(UnexpectedFailure(message: 'Erro inesperado: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> getSecurityEvents({
    required String firmId,
    DateTime? startDate,
    DateTime? endDate,
    String? severity,
  }) async {
    try {
      final result = await remoteDataSource.getSecurityEvents(
        firmId: firmId,
        startDate: startDate,
        endDate: endDate,
        severity: severity,
      );
      return Right(result);
    } on ServerException {
      return const Left(ServerFailure(message: 'Erro ao obter eventos de segurança'));
    } on NetworkException {
      return const Left(NetworkFailure(message: 'Erro de conexão'));
    } catch (e) {
      return Left(UnexpectedFailure(message: 'Erro inesperado: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getAuditStatistics({
    required String firmId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final result = await remoteDataSource.getAuditStatistics(
        firmId: firmId,
        startDate: startDate,
        endDate: endDate,
      );
      return Right(result);
    } on ServerException {
      return const Left(ServerFailure(message: 'Erro ao obter estatísticas de auditoria'));
    } on NetworkException {
      return const Left(NetworkFailure(message: 'Erro de conexão'));
    } catch (e) {
      return Left(UnexpectedFailure(message: 'Erro inesperado: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> getUserActivity({
    required String firmId,
    required String userId,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 100,
    int offset = 0,
  }) async {
    try {
      final result = await remoteDataSource.getUserActivity(
        firmId: firmId,
        userId: userId,
        startDate: startDate,
        endDate: endDate,
        limit: limit,
        offset: offset,
      );
      return Right(result);
    } on ServerException {
      return const Left(ServerFailure(message: 'Erro ao obter atividade do usuário'));
    } on NetworkException {
      return const Left(NetworkFailure(message: 'Erro de conexão'));
    } catch (e) {
      return Left(UnexpectedFailure(message: 'Erro inesperado: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getChangeHistory({
    required String firmId,
    required String entityId,
    String? entityType,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final result = await remoteDataSource.getChangeHistory(
        firmId: firmId,
        entityId: entityId,
        entityType: entityType,
        startDate: startDate,
        endDate: endDate,
      );
      return Right(result);
    } on ServerException {
      return const Left(ServerFailure(message: 'Erro ao obter histórico de mudanças'));
    } on NetworkException {
      return const Left(NetworkFailure(message: 'Erro de conexão'));
    } catch (e) {
      return Left(UnexpectedFailure(message: 'Erro inesperado: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> getComplianceViolations({
    required String firmId,
    DateTime? startDate,
    DateTime? endDate,
    String? standard,
    String? severity,
  }) async {
    try {
      final result = await remoteDataSource.getComplianceViolations(
        firmId: firmId,
        startDate: startDate,
        endDate: endDate,
        standard: standard,
        severity: severity,
      );
      return Right(result);
    } on ServerException {
      return const Left(ServerFailure(message: 'Erro ao obter violações de compliance'));
    } on NetworkException {
      return const Left(NetworkFailure(message: 'Erro de conexão'));
    } catch (e) {
      return Left(UnexpectedFailure(message: 'Erro inesperado: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, bool>> createRetentionPolicy({
    required String firmId,
    required Map<String, dynamic> policy,
  }) async {
    try {
      final result = await remoteDataSource.createRetentionPolicy(
        firmId: firmId,
        policy: policy,
      );
      return Right(result);
    } on ServerException {
      return const Left(ServerFailure(message: 'Erro ao criar política de retenção'));
    } on NetworkException {
      return const Left(NetworkFailure(message: 'Erro de conexão'));
    } catch (e) {
      return Left(UnexpectedFailure(message: 'Erro inesperado: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> getRetentionPolicies(String firmId) async {
    try {
      final result = await remoteDataSource.getRetentionPolicies(firmId);
      return Right(result);
    } on ServerException {
      return const Left(ServerFailure(message: 'Erro ao obter políticas de retenção'));
    } on NetworkException {
      return const Left(NetworkFailure(message: 'Erro de conexão'));
    } catch (e) {
      return Left(UnexpectedFailure(message: 'Erro inesperado: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, bool>> executeRetentionPolicy({
    required String firmId,
    required String policyId,
    bool dryRun = false,
  }) async {
    try {
      final result = await remoteDataSource.executeRetentionPolicy(
        firmId: firmId,
        policyId: policyId,
        dryRun: dryRun,
      );
      return Right(result);
    } on ServerException {
      return const Left(ServerFailure(message: 'Erro ao executar política de retenção'));
    } on NetworkException {
      return const Left(NetworkFailure(message: 'Erro de conexão'));
    } catch (e) {
      return Left(UnexpectedFailure(message: 'Erro inesperado: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getDataGovernanceReport({
    required String firmId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final result = await remoteDataSource.getDataGovernanceReport(
        firmId: firmId,
        startDate: startDate,
        endDate: endDate,
      );
      return Right(result);
    } on ServerException {
      return const Left(ServerFailure(message: 'Erro ao obter relatório de governança'));
    } on NetworkException {
      return const Left(NetworkFailure(message: 'Erro de conexão'));
    } catch (e) {
      return Left(UnexpectedFailure(message: 'Erro inesperado: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, bool>> createComplianceAlert({
    required String firmId,
    required Map<String, dynamic> alertConfig,
  }) async {
    try {
      final result = await remoteDataSource.createComplianceAlert(
        firmId: firmId,
        alertConfig: alertConfig,
      );
      return Right(result);
    } on ServerException {
      return const Left(ServerFailure(message: 'Erro ao criar alerta de compliance'));
    } on NetworkException {
      return const Left(NetworkFailure(message: 'Erro de conexão'));
    } catch (e) {
      return Left(UnexpectedFailure(message: 'Erro inesperado: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> getComplianceAlerts({
    required String firmId,
    bool activeOnly = true,
  }) async {
    try {
      final result = await remoteDataSource.getComplianceAlerts(
        firmId: firmId,
        activeOnly: activeOnly,
      );
      return Right(result);
    } on ServerException {
      return const Left(ServerFailure(message: 'Erro ao obter alertas de compliance'));
    } on NetworkException {
      return const Left(NetworkFailure(message: 'Erro de conexão'));
    } catch (e) {
      return Left(UnexpectedFailure(message: 'Erro inesperado: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getRiskAssessment({
    required String firmId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final result = await remoteDataSource.getRiskAssessment(
        firmId: firmId,
        startDate: startDate,
        endDate: endDate,
      );
      return Right(result);
    } on ServerException {
      return const Left(ServerFailure(message: 'Erro ao obter avaliação de risco'));
    } on NetworkException {
      return const Left(NetworkFailure(message: 'Erro de conexão'));
    } catch (e) {
      return Left(UnexpectedFailure(message: 'Erro inesperado: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, bool>> archiveAuditEntries({
    required String firmId,
    required DateTime beforeDate,
    String? archiveLocation,
  }) async {
    try {
      final result = await remoteDataSource.archiveAuditEntries(
        firmId: firmId,
        beforeDate: beforeDate,
        archiveLocation: archiveLocation,
      );
      return Right(result);
    } on ServerException {
      return const Left(ServerFailure(message: 'Erro ao arquivar entradas de auditoria'));
    } on NetworkException {
      return const Left(NetworkFailure(message: 'Erro de conexão'));
    } catch (e) {
      return Left(UnexpectedFailure(message: 'Erro inesperado: ${e.toString()}'));
    }
  }
} 
