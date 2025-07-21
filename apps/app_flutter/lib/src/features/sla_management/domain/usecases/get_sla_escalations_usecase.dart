import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/sla_escalation_repository.dart';

class GetSlaEscalationsUseCase implements UseCase<List<Map<String, dynamic>>, GetSlaEscalationsParams> {
  final SlaEscalationRepository repository;

  GetSlaEscalationsUseCase(this.repository);

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> call(GetSlaEscalationsParams params) async {
    return await repository.getActiveEscalations(
      firmId: params.firmId,
      lawyerId: params.lawyerId,
      caseId: params.caseId,
      priority: params.priority,
    );
  }
}

class GetSlaEscalationsParams {
  final String firmId;
  final String? lawyerId;
  final String? caseId;
  final String? priority;

  GetSlaEscalationsParams({
    required this.firmId,
    this.lawyerId,
    this.caseId,
    this.priority,
  });
}