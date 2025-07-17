import 'package:dartz/dartz.dart';
import '../entities/hiring_result.dart';
import '../repositories/lawyer_hiring_repository.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';

class HireLawyer implements UseCase<HiringResult, HireLawyerParams> {
  final LawyerHiringRepository repository;

  HireLawyer(this.repository);

  @override
  Future<Either<Failure, HiringResult>> call(HireLawyerParams params) async {
    return await repository.sendHiringProposal(params);
  }
}

class HireLawyerParams {
  final String lawyerId;
  final String caseId;
  final String clientId;
  final String contractType;
  final double budget;
  final String? notes;

  const HireLawyerParams({
    required this.lawyerId,
    required this.caseId,
    required this.clientId,
    required this.contractType,
    required this.budget,
    this.notes,
  });

  HireLawyerParams copyWith({
    String? lawyerId,
    String? caseId,
    String? clientId,
    String? contractType,
    double? budget,
    String? notes,
  }) {
    return HireLawyerParams(
      lawyerId: lawyerId ?? this.lawyerId,
      caseId: caseId ?? this.caseId,
      clientId: clientId ?? this.clientId,
      contractType: contractType ?? this.contractType,
      budget: budget ?? this.budget,
      notes: notes ?? this.notes,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is HireLawyerParams &&
        other.lawyerId == lawyerId &&
        other.caseId == caseId &&
        other.clientId == clientId &&
        other.contractType == contractType &&
        other.budget == budget &&
        other.notes == notes;
  }

  @override
  int get hashCode {
    return lawyerId.hashCode ^
        caseId.hashCode ^
        clientId.hashCode ^
        contractType.hashCode ^
        budget.hashCode ^
        notes.hashCode;
  }
}