import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/sla_audit_entity.dart';
import '../repositories/sla_audit_repository.dart';

class CreateSlaAudit implements UseCase<SlaAuditEntity, CreateSlaAuditParams> {
  final SlaAuditRepository repository;

  CreateSlaAudit(this.repository);

  @override
  Future<Either<Failure, SlaAuditEntity>> call(CreateSlaAuditParams params) async {
    return await repository.createAuditEntry(
      firmId: params.firmId,
      eventType: params.eventType,
      entityId: params.entityId,
      entityType: params.entityType,
      userId: params.userId,
      changes: params.changes,
      metadata: params.metadata,
    );
  }
}

class CreateSlaAuditParams {
  final String firmId;
  final SlaAuditEventType eventType;
  final String entityId;
  final String entityType;
  final String userId;
  final Map<String, dynamic> changes;
  final Map<String, dynamic> metadata;

  CreateSlaAuditParams({
    required this.firmId,
    required this.eventType,
    required this.entityId,
    required this.entityType,
    required this.userId,
    required this.changes,
    required this.metadata,
  });

  Map<String, dynamic> toMap() {
    return {
      'firmId': firmId,
      'eventType': eventType.toString(),
      'entityId': entityId,
      'entityType': entityType,
      'userId': userId,
      'changes': changes,
      'metadata': metadata,
    };
  }
}

class GetSlaAuditTrail implements UseCase<List<SlaAuditEntity>, GetSlaAuditTrailParams> {
  final SlaAuditRepository repository;

  GetSlaAuditTrail(this.repository);

  @override
  Future<Either<Failure, List<SlaAuditEntity>>> call(GetSlaAuditTrailParams params) async {
    return await repository.getAuditTrail(
      firmId: params.firmId,
      entityId: params.entityId,
      entityType: params.entityType,
      eventTypes: params.eventTypes,
      userId: params.userId,
      startDate: params.startDate,
      endDate: params.endDate,
      limit: params.limit,
      offset: params.offset,
    );
  }
}

class GetSlaAuditTrailParams {
  final String firmId;
  final String? entityId;
  final String? entityType;
  final List<SlaAuditEventType>? eventTypes;
  final String? userId;
  final DateTime? startDate;
  final DateTime? endDate;
  final int limit;
  final int offset;

  GetSlaAuditTrailParams({
    required this.firmId,
    this.entityId,
    this.entityType,
    this.eventTypes,
    this.userId,
    this.startDate,
    this.endDate,
    this.limit = 100,
    this.offset = 0,
  });
}

class GenerateComplianceReport implements UseCase<Map<String, dynamic>, GenerateComplianceReportParams> {
  final SlaAuditRepository repository;

  GenerateComplianceReport(this.repository);

  @override
  Future<Either<Failure, Map<String, dynamic>>> call(GenerateComplianceReportParams params) async {
    return await repository.generateComplianceReport(
      firmId: params.firmId,
      period: params.period,
      includeDetails: params.includeDetails,
      complianceStandards: params.complianceStandards,
      format: params.format,
    );
  }
}

class GenerateComplianceReportParams {
  final String firmId;
  final String period; // 'daily', 'weekly', 'monthly', 'quarterly', 'yearly'
  final bool includeDetails;
  final List<String> complianceStandards; // ['ISO9001', 'LGPD', 'OAB', 'INTERNAL']
  final String format; // 'json', 'pdf', 'excel'

  GenerateComplianceReportParams({
    required this.firmId,
    required this.period,
    this.includeDetails = true,
    this.complianceStandards = const ['ISO9001', 'LGPD', 'OAB', 'INTERNAL'],
    this.format = 'json',
  });
}

class VerifyAuditIntegrity implements UseCase<Map<String, dynamic>, VerifyAuditIntegrityParams> {
  final SlaAuditRepository repository;

  VerifyAuditIntegrity(this.repository);

  @override
  Future<Either<Failure, Map<String, dynamic>>> call(VerifyAuditIntegrityParams params) async {
    return await repository.verifyIntegrity(
      firmId: params.firmId,
      startDate: params.startDate,
      endDate: params.endDate,
    );
  }
}

class VerifyAuditIntegrityParams {
  final String firmId;
  final DateTime? startDate;
  final DateTime? endDate;

  VerifyAuditIntegrityParams({
    required this.firmId,
    this.startDate,
    this.endDate,
  });
}

class ExportAuditLog implements UseCase<String, ExportAuditLogParams> {
  final SlaAuditRepository repository;

  ExportAuditLog(this.repository);

  @override
  Future<Either<Failure, String>> call(ExportAuditLogParams params) async {
    return await repository.exportAuditLog(
      firmId: params.firmId,
      format: params.format,
      startDate: params.startDate,
      endDate: params.endDate,
      includeMetadata: params.includeMetadata,
      encryptFile: params.encryptFile,
    );
  }
}

class ExportAuditLogParams {
  final String firmId;
  final String format; // 'json', 'csv', 'xml', 'pdf'
  final DateTime? startDate;
  final DateTime? endDate;
  final bool includeMetadata;
  final bool encryptFile;

  ExportAuditLogParams({
    required this.firmId,
    required this.format,
    this.startDate,
    this.endDate,
    this.includeMetadata = true,
    this.encryptFile = false,
  });
} 
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/sla_audit_entity.dart';
import '../repositories/sla_audit_repository.dart';

class CreateSlaAudit implements UseCase<SlaAuditEntity, CreateSlaAuditParams> {
  final SlaAuditRepository repository;

  CreateSlaAudit(this.repository);

  @override
  Future<Either<Failure, SlaAuditEntity>> call(CreateSlaAuditParams params) async {
    return await repository.createAuditEntry(
      firmId: params.firmId,
      eventType: params.eventType,
      entityId: params.entityId,
      entityType: params.entityType,
      userId: params.userId,
      changes: params.changes,
      metadata: params.metadata,
    );
  }
}

class CreateSlaAuditParams {
  final String firmId;
  final SlaAuditEventType eventType;
  final String entityId;
  final String entityType;
  final String userId;
  final Map<String, dynamic> changes;
  final Map<String, dynamic> metadata;

  CreateSlaAuditParams({
    required this.firmId,
    required this.eventType,
    required this.entityId,
    required this.entityType,
    required this.userId,
    required this.changes,
    required this.metadata,
  });

  Map<String, dynamic> toMap() {
    return {
      'firmId': firmId,
      'eventType': eventType.toString(),
      'entityId': entityId,
      'entityType': entityType,
      'userId': userId,
      'changes': changes,
      'metadata': metadata,
    };
  }
}

class GetSlaAuditTrail implements UseCase<List<SlaAuditEntity>, GetSlaAuditTrailParams> {
  final SlaAuditRepository repository;

  GetSlaAuditTrail(this.repository);

  @override
  Future<Either<Failure, List<SlaAuditEntity>>> call(GetSlaAuditTrailParams params) async {
    return await repository.getAuditTrail(
      firmId: params.firmId,
      entityId: params.entityId,
      entityType: params.entityType,
      eventTypes: params.eventTypes,
      userId: params.userId,
      startDate: params.startDate,
      endDate: params.endDate,
      limit: params.limit,
      offset: params.offset,
    );
  }
}

class GetSlaAuditTrailParams {
  final String firmId;
  final String? entityId;
  final String? entityType;
  final List<SlaAuditEventType>? eventTypes;
  final String? userId;
  final DateTime? startDate;
  final DateTime? endDate;
  final int limit;
  final int offset;

  GetSlaAuditTrailParams({
    required this.firmId,
    this.entityId,
    this.entityType,
    this.eventTypes,
    this.userId,
    this.startDate,
    this.endDate,
    this.limit = 100,
    this.offset = 0,
  });
}

class GenerateComplianceReport implements UseCase<Map<String, dynamic>, GenerateComplianceReportParams> {
  final SlaAuditRepository repository;

  GenerateComplianceReport(this.repository);

  @override
  Future<Either<Failure, Map<String, dynamic>>> call(GenerateComplianceReportParams params) async {
    return await repository.generateComplianceReport(
      firmId: params.firmId,
      period: params.period,
      includeDetails: params.includeDetails,
      complianceStandards: params.complianceStandards,
      format: params.format,
    );
  }
}

class GenerateComplianceReportParams {
  final String firmId;
  final String period; // 'daily', 'weekly', 'monthly', 'quarterly', 'yearly'
  final bool includeDetails;
  final List<String> complianceStandards; // ['ISO9001', 'LGPD', 'OAB', 'INTERNAL']
  final String format; // 'json', 'pdf', 'excel'

  GenerateComplianceReportParams({
    required this.firmId,
    required this.period,
    this.includeDetails = true,
    this.complianceStandards = const ['ISO9001', 'LGPD', 'OAB', 'INTERNAL'],
    this.format = 'json',
  });
}

class VerifyAuditIntegrity implements UseCase<Map<String, dynamic>, VerifyAuditIntegrityParams> {
  final SlaAuditRepository repository;

  VerifyAuditIntegrity(this.repository);

  @override
  Future<Either<Failure, Map<String, dynamic>>> call(VerifyAuditIntegrityParams params) async {
    return await repository.verifyIntegrity(
      firmId: params.firmId,
      startDate: params.startDate,
      endDate: params.endDate,
    );
  }
}

class VerifyAuditIntegrityParams {
  final String firmId;
  final DateTime? startDate;
  final DateTime? endDate;

  VerifyAuditIntegrityParams({
    required this.firmId,
    this.startDate,
    this.endDate,
  });
}

class ExportAuditLog implements UseCase<String, ExportAuditLogParams> {
  final SlaAuditRepository repository;

  ExportAuditLog(this.repository);

  @override
  Future<Either<Failure, String>> call(ExportAuditLogParams params) async {
    return await repository.exportAuditLog(
      firmId: params.firmId,
      format: params.format,
      startDate: params.startDate,
      endDate: params.endDate,
      includeMetadata: params.includeMetadata,
      encryptFile: params.encryptFile,
    );
  }
}

class ExportAuditLogParams {
  final String firmId;
  final String format; // 'json', 'csv', 'xml', 'pdf'
  final DateTime? startDate;
  final DateTime? endDate;
  final bool includeMetadata;
  final bool encryptFile;

  ExportAuditLogParams({
    required this.firmId,
    required this.format,
    this.startDate,
    this.endDate,
    this.includeMetadata = true,
    this.encryptFile = false,
  });
} 