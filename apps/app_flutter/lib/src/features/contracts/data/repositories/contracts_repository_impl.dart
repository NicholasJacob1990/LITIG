import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/error/exceptions.dart';
import '../../domain/entities/contract.dart';
import '../../domain/repositories/contracts_repository.dart';
import '../datasources/contracts_remote_data_source.dart';

class ContractsRepositoryImpl implements ContractsRepository {
  final ContractsRemoteDataSource remoteDataSource;

  ContractsRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<Contract>>> getContracts({
    String? status,
    String? searchQuery,
  }) async {
    try {
      final contracts = await remoteDataSource.getContracts(
        status: status,
        searchQuery: searchQuery,
      );
      return Right(contracts);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'Erro inesperado: $e'));
    }
  }

  @override
  Future<Either<Failure, Contract>> createContract({
    required String caseId,
    required String lawyerId,
    required Map<String, dynamic> feeModel,
  }) async {
    try {
      final contract = await remoteDataSource.createContract(
        caseId: caseId,
        lawyerId: lawyerId,
        feeModel: feeModel,
      );
      return Right(contract);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'Erro inesperado: $e'));
    }
  }

  @override
  Future<Either<Failure, Contract>> signContract({
    required String contractId,
    required String role,
  }) async {
    try {
      final contract = await remoteDataSource.signContract(
        contractId: contractId,
        role: role,
      );
      return Right(contract);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'Erro inesperado: $e'));
    }
  }

  @override
  Future<Either<Failure, Contract>> cancelContract({
    required String contractId,
  }) async {
    try {
      final contract = await remoteDataSource.cancelContract(
        contractId: contractId,
      );
      return Right(contract);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'Erro inesperado: $e'));
    }
  }

  @override
  Future<Either<Failure, String>> downloadContract({
    required String contractId,
  }) async {
    try {
      final url = await remoteDataSource.downloadContract(
        contractId: contractId,
      );
      return Right(url);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'Erro inesperado: $e'));
    }
  }
}