import 'package:dartz/dartz.dart';
import '../entities/hiring_proposal.dart';
import '../repositories/lawyer_hiring_repository.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';

class GetHiringProposals implements UseCase<List<HiringProposal>, GetHiringProposalsParams> {
  final LawyerHiringRepository repository;

  GetHiringProposals(this.repository);

  @override
  Future<Either<Failure, List<HiringProposal>>> call(GetHiringProposalsParams params) async {
    return await repository.getHiringProposals(params.lawyerId, params.status);
  }
}

class GetHiringProposalsParams {
  final String lawyerId;
  final String? status; // 'pending', 'accepted', 'rejected', 'expired', null for all

  const GetHiringProposalsParams({
    required this.lawyerId,
    this.status,
  });

  GetHiringProposalsParams copyWith({
    String? lawyerId,
    String? status,
  }) {
    return GetHiringProposalsParams(
      lawyerId: lawyerId ?? this.lawyerId,
      status: status ?? this.status,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GetHiringProposalsParams &&
        other.lawyerId == lawyerId &&
        other.status == status;
  }

  @override
  int get hashCode => lawyerId.hashCode ^ status.hashCode;
}