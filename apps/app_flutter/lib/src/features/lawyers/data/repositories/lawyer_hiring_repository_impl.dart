import 'package:dartz/dartz.dart';
import '../../domain/entities/hiring_proposal.dart';
import '../../domain/entities/hiring_result.dart';
import '../../domain/repositories/lawyer_hiring_repository.dart';
import '../../domain/usecases/hire_lawyer.dart';
import '../datasources/lawyer_hiring_remote_data_source.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/network/network_info.dart';

class LawyerHiringRepositoryImpl implements LawyerHiringRepository {
  final LawyerHiringRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  LawyerHiringRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, HiringResult>> sendHiringProposal(HireLawyerParams params) async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.sendHiringProposal(params);
        return Right(result.toEntity());
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      } catch (e) {
        return const Left(ServerFailure(message: 'Unexpected error occurred'));
      }
    } else {
      return const Left(NetworkFailure(message: 'No internet connection'));
    }
  }

  @override
  Future<Either<Failure, List<HiringProposal>>> getHiringProposals(String lawyerId, String? status) async {
    if (await networkInfo.isConnected) {
      try {
        final results = await remoteDataSource.getHiringProposals(lawyerId, status);
        return Right(results.map((model) => model.toEntity()).toList());
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      } catch (e) {
        return const Left(ServerFailure(message: 'Unexpected error occurred'));
      }
    } else {
      return const Left(NetworkFailure(message: 'No internet connection'));
    }
  }

  @override
  Future<Either<Failure, HiringProposal>> acceptHiringProposal(String proposalId) async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.acceptHiringProposal(proposalId);
        return Right(result.toEntity());
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      } catch (e) {
        return const Left(ServerFailure(message: 'Unexpected error occurred'));
      }
    } else {
      return const Left(NetworkFailure(message: 'No internet connection'));
    }
  }

  @override
  Future<Either<Failure, HiringProposal>> rejectHiringProposal(String proposalId, String? reason) async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.rejectHiringProposal(proposalId, reason);
        return Right(result.toEntity());
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      } catch (e) {
        return const Left(ServerFailure(message: 'Unexpected error occurred'));
      }
    } else {
      return const Left(NetworkFailure(message: 'No internet connection'));
    }
  }
}