import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/allocation_type.dart';
import '../repositories/cases_repository.dart';

class UpdateCaseAllocation implements UseCase<void, UpdateCaseAllocationParams> {
  final CasesRepository repository;

  UpdateCaseAllocation(this.repository);

  @override
  Future<Either<Failure, void>> call(UpdateCaseAllocationParams params) async {
    return await repository.updateCaseAllocation(
      caseId: params.caseId,
      allocationType: params.allocationType,
      newAssigneeId: params.targetLawyerId,
      reason: params.reason,
      metadata: params.metadata,
    );
  }
}

class UpdateCaseAllocationParams {
  final String caseId;
  final AllocationType allocationType;
  final String? targetLawyerId;
  final String? reason;
  final Map<String, dynamic>? metadata;

  const UpdateCaseAllocationParams({
    required this.caseId,
    required this.allocationType,
    this.targetLawyerId,
    this.reason,
    this.metadata,
  });
}