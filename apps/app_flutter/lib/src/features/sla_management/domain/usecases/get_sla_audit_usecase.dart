import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/sla_audit_entity.dart';
import '../entities/sla_enums.dart';
import '../repositories/sla_audit_repository.dart';

class GetSlaAuditUseCase implements UseCase<List<SlaAuditEntity>, GetSlaAuditParams> {
  final SlaAuditRepository repository;

  GetSlaAuditUseCase(this.repository);

  @override
  Future<Either<Failure, List<SlaAuditEntity>>> call(GetSlaAuditParams params) async {
    return await repository.getAuditEvents(
      firmId: params.firmId,
      startDate: params.startDate,
      endDate: params.endDate,
      eventTypes: params.eventTypes,
      categories: params.categories,
      severities: params.severities,
      userId: params.userId,
      entityType: params.entityType,
      entityId: params.entityId,
      limit: params.limit,
      offset: params.offset,
    );
  }
}

class GetSlaAuditParams {
  final String firmId;
  final DateTime? startDate;
  final DateTime? endDate;
  final List<AuditEventType>? eventTypes;
  final List<AuditEventCategory>? categories;
  final List<AuditSeverity>? severities;
  final String? userId;
  final String? entityType;
  final String? entityId;
  final int limit;
  final int offset;

  GetSlaAuditParams({
    required this.firmId,
    this.startDate,
    this.endDate,
    this.eventTypes,
    this.categories,
    this.severities,
    this.userId,
    this.entityType,
    this.entityId,
    this.limit = 100,
    this.offset = 0,
  });
}