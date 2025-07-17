import 'package:dartz/dartz.dart';
import '../entities/hiring_proposal.dart';
import '../entities/hiring_result.dart';
import '../usecases/hire_lawyer.dart';
import '../../../../core/error/failures.dart';

abstract class LawyerHiringRepository {
  Future<Either<Failure, HiringResult>> sendHiringProposal(HireLawyerParams params);
  Future<Either<Failure, List<HiringProposal>>> getHiringProposals(String lawyerId, String? status);
  Future<Either<Failure, HiringProposal>> acceptHiringProposal(String proposalId);
  Future<Either<Failure, HiringProposal>> rejectHiringProposal(String proposalId, String? reason);
}