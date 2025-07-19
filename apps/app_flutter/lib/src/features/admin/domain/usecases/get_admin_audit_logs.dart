import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/admin_audit_log.dart';
import '../repositories/admin_repository.dart';

class GetAdminAuditLogsParams {
  final DateTime? startDate;
  final DateTime? endDate;
  final String? logType;

  const GetAdminAuditLogsParams({
    this.startDate,
    this.endDate,
    this.logType,
  });
}

class GetAdminAuditLogs implements UseCase<List<AdminAuditLog>, GetAdminAuditLogsParams> {
  final AdminRepository repository;

  GetAdminAuditLogs(this.repository);

  @override
  Future<Either<Failure, List<AdminAuditLog>>> call(GetAdminAuditLogsParams params) async {
    return await repository.getAdminAuditLogs(
      startDate: params.startDate,
      endDate: params.endDate,
      logType: params.logType,
    );
  }
} 