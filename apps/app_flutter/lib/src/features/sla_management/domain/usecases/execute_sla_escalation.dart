import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/sla_escalation_entity.dart';

class ExecuteSlaEscalation implements UseCase<SlaEscalationExecutionResult, ExecuteSlaEscalationParams> {
  final SlaEscalationRepository repository;

  ExecuteSlaEscalation(this.repository);

  @override
  Future<Either<Failure, SlaEscalationExecutionResult>> call(ExecuteSlaEscalationParams params) async {
    return await repository.executeEscalation(
      caseId: params.caseId,
      escalationId: params.escalationId,
      triggeredBy: params.triggeredBy,
      reason: params.reason,
      forceExecute: params.forceExecute,
    );
  }
}

class ExecuteSlaEscalationParams {
  final String caseId;
  final String escalationId;
  final String triggeredBy;
  final String reason;
  final bool forceExecute;

  ExecuteSlaEscalationParams({
    required this.caseId,
    required this.escalationId,
    required this.triggeredBy,
    required this.reason,
    this.forceExecute = false,
  });
}

class SlaEscalationExecutionResult {
  final bool success;
  final String executionId;
  final DateTime executedAt;
  final List<String> actionsExecuted;
  final List<String> recipientsNotified;
  final Map<String, dynamic> executionDetails;
  final String? errorMessage;

  SlaEscalationExecutionResult({
    required this.success,
    required this.executionId,
    required this.executedAt,
    required this.actionsExecuted,
    required this.recipientsNotified,
    required this.executionDetails,
    this.errorMessage,
  });

  Map<String, dynamic> toMap() {
    return {
      'success': success,
      'executionId': executionId,
      'executedAt': executedAt.toIso8601String(),
      'actionsExecuted': actionsExecuted,
      'recipientsNotified': recipientsNotified,
      'executionDetails': executionDetails,
      if (errorMessage != null) 'errorMessage': errorMessage,
    };
  }
}

abstract class SlaEscalationRepository {
  Future<Either<Failure, SlaEscalationExecutionResult>> executeEscalation({
    required String caseId,
    required String escalationId,
    required String triggeredBy,
    required String reason,
    bool forceExecute = false,
  });

  Future<Either<Failure, List<SlaEscalationEntity>>> getAvailableEscalations(String firmId);
  Future<Either<Failure, SlaEscalationEntity>> createEscalation(SlaEscalationEntity escalation);
  Future<Either<Failure, SlaEscalationEntity>> updateEscalation(SlaEscalationEntity escalation);
  Future<Either<Failure, bool>> deleteEscalation(String escalationId);

  Future<Either<Failure, List<Map<String, dynamic>>>> getEscalationHistory({
    required String firmId,
    String? caseId,
    DateTime? startDate,
    DateTime? endDate,
  });

  Future<Either<Failure, Map<String, dynamic>>> getEscalationStatistics(String firmId);
  Future<Either<Failure, bool>> testEscalationWorkflow(String escalationId);
}

class GetAvailableEscalations implements UseCase<List<SlaEscalationEntity>, GetAvailableEscalationsParams> {
  final SlaEscalationRepository repository;

  GetAvailableEscalations(this.repository);

  @override
  Future<Either<Failure, List<SlaEscalationEntity>>> call(GetAvailableEscalationsParams params) async {
    return await repository.getAvailableEscalations(params.firmId);
  }
}

class GetAvailableEscalationsParams {
  final String firmId;

  GetAvailableEscalationsParams({required this.firmId});
}

class CreateSlaEscalation implements UseCase<SlaEscalationEntity, CreateSlaEscalationParams> {
  final SlaEscalationRepository repository;

  CreateSlaEscalation(this.repository);

  @override
  Future<Either<Failure, SlaEscalationEntity>> call(CreateSlaEscalationParams params) async {
    return await repository.createEscalation(params.escalation);
  }
}

class CreateSlaEscalationParams {
  final SlaEscalationEntity escalation;

  CreateSlaEscalationParams({required this.escalation});
}

class TestEscalationWorkflow implements UseCase<bool, TestEscalationWorkflowParams> {
  final SlaEscalationRepository repository;

  TestEscalationWorkflow(this.repository);

  @override
  Future<Either<Failure, bool>> call(TestEscalationWorkflowParams params) async {
    return await repository.testEscalationWorkflow(params.escalationId);
  }
}

class TestEscalationWorkflowParams {
  final String escalationId;

  TestEscalationWorkflowParams({required this.escalationId});
} 
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/sla_escalation_entity.dart';

class ExecuteSlaEscalation implements UseCase<SlaEscalationExecutionResult, ExecuteSlaEscalationParams> {
  final SlaEscalationRepository repository;

  ExecuteSlaEscalation(this.repository);

  @override
  Future<Either<Failure, SlaEscalationExecutionResult>> call(ExecuteSlaEscalationParams params) async {
    return await repository.executeEscalation(
      caseId: params.caseId,
      escalationId: params.escalationId,
      triggeredBy: params.triggeredBy,
      reason: params.reason,
      forceExecute: params.forceExecute,
    );
  }
}

class ExecuteSlaEscalationParams {
  final String caseId;
  final String escalationId;
  final String triggeredBy;
  final String reason;
  final bool forceExecute;

  ExecuteSlaEscalationParams({
    required this.caseId,
    required this.escalationId,
    required this.triggeredBy,
    required this.reason,
    this.forceExecute = false,
  });
}

class SlaEscalationExecutionResult {
  final bool success;
  final String executionId;
  final DateTime executedAt;
  final List<String> actionsExecuted;
  final List<String> recipientsNotified;
  final Map<String, dynamic> executionDetails;
  final String? errorMessage;

  SlaEscalationExecutionResult({
    required this.success,
    required this.executionId,
    required this.executedAt,
    required this.actionsExecuted,
    required this.recipientsNotified,
    required this.executionDetails,
    this.errorMessage,
  });

  Map<String, dynamic> toMap() {
    return {
      'success': success,
      'executionId': executionId,
      'executedAt': executedAt.toIso8601String(),
      'actionsExecuted': actionsExecuted,
      'recipientsNotified': recipientsNotified,
      'executionDetails': executionDetails,
      if (errorMessage != null) 'errorMessage': errorMessage,
    };
  }
}

abstract class SlaEscalationRepository {
  Future<Either<Failure, SlaEscalationExecutionResult>> executeEscalation({
    required String caseId,
    required String escalationId,
    required String triggeredBy,
    required String reason,
    bool forceExecute = false,
  });

  Future<Either<Failure, List<SlaEscalationEntity>>> getAvailableEscalations(String firmId);
  Future<Either<Failure, SlaEscalationEntity>> createEscalation(SlaEscalationEntity escalation);
  Future<Either<Failure, SlaEscalationEntity>> updateEscalation(SlaEscalationEntity escalation);
  Future<Either<Failure, bool>> deleteEscalation(String escalationId);

  Future<Either<Failure, List<Map<String, dynamic>>>> getEscalationHistory({
    required String firmId,
    String? caseId,
    DateTime? startDate,
    DateTime? endDate,
  });

  Future<Either<Failure, Map<String, dynamic>>> getEscalationStatistics(String firmId);
  Future<Either<Failure, bool>> testEscalationWorkflow(String escalationId);
}

class GetAvailableEscalations implements UseCase<List<SlaEscalationEntity>, GetAvailableEscalationsParams> {
  final SlaEscalationRepository repository;

  GetAvailableEscalations(this.repository);

  @override
  Future<Either<Failure, List<SlaEscalationEntity>>> call(GetAvailableEscalationsParams params) async {
    return await repository.getAvailableEscalations(params.firmId);
  }
}

class GetAvailableEscalationsParams {
  final String firmId;

  GetAvailableEscalationsParams({required this.firmId});
}

class CreateSlaEscalation implements UseCase<SlaEscalationEntity, CreateSlaEscalationParams> {
  final SlaEscalationRepository repository;

  CreateSlaEscalation(this.repository);

  @override
  Future<Either<Failure, SlaEscalationEntity>> call(CreateSlaEscalationParams params) async {
    return await repository.createEscalation(params.escalation);
  }
}

class CreateSlaEscalationParams {
  final SlaEscalationEntity escalation;

  CreateSlaEscalationParams({required this.escalation});
}

class TestEscalationWorkflow implements UseCase<bool, TestEscalationWorkflowParams> {
  final SlaEscalationRepository repository;

  TestEscalationWorkflow(this.repository);

  @override
  Future<Either<Failure, bool>> call(TestEscalationWorkflowParams params) async {
    return await repository.testEscalationWorkflow(params.escalationId);
  }
}

class TestEscalationWorkflowParams {
  final String escalationId;

  TestEscalationWorkflowParams({required this.escalationId});
} 