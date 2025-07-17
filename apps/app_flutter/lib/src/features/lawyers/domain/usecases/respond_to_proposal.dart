import 'package:dartz/dartz.dart';
import '../entities/hiring_proposal.dart';
import '../repositories/lawyer_hiring_repository.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';

class RespondToProposal implements UseCase<HiringProposal, RespondToProposalParams> {
  final LawyerHiringRepository repository;

  RespondToProposal(this.repository);

  @override
  Future<Either<Failure, HiringProposal>> call(RespondToProposalParams params) async {
    if (params.accept) {
      return await repository.acceptHiringProposal(params.proposalId);
    } else {
      return await repository.rejectHiringProposal(params.proposalId, params.reason);
    }
  }
}

class RespondToProposalParams {
  final String proposalId;
  final bool accept;
  final String? reason; // Required if accept is false

  const RespondToProposalParams({
    required this.proposalId,
    required this.accept,
    this.reason,
  });

  RespondToProposalParams copyWith({
    String? proposalId,
    bool? accept,
    String? reason,
  }) {
    return RespondToProposalParams(
      proposalId: proposalId ?? this.proposalId,
      accept: accept ?? this.accept,
      reason: reason ?? this.reason,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RespondToProposalParams &&
        other.proposalId == proposalId &&
        other.accept == accept &&
        other.reason == reason;
  }

  @override
  int get hashCode => proposalId.hashCode ^ accept.hashCode ^ reason.hashCode;
}