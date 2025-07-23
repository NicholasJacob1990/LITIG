import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/contract.dart';

abstract class ContractsRepository {
  Future<Either<Failure, List<Contract>>> getContracts({
    String? status,
    String? searchQuery,
  });

  Future<Either<Failure, Contract>> createContract({
    required String caseId,
    required String lawyerId,
    required Map<String, dynamic> feeModel,
  });

  Future<Either<Failure, Contract>> signContract({
    required String contractId,
    required String role,
  });

  Future<Either<Failure, Contract>> cancelContract({
    required String contractId,
  });

  Future<Either<Failure, String>> downloadContract({
    required String contractId,
  });
} 