import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/error/exceptions.dart';
import '../../domain/entities/financial_data.dart';
import '../../domain/repositories/financial_repository.dart';
import '../datasources/financial_remote_data_source.dart';

class FinancialRepositoryImpl implements FinancialRepository {
  final FinancialRemoteDataSource remoteDataSource;

  FinancialRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, FinancialData>> getFinancialData({
    String? period,
    String? feeType,
  }) async {
    try {
      final result = await remoteDataSource.getFinancialData(
        period: period,
        feeType: feeType,
      );
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'Erro inesperado: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> exportFinancialData({
    required String format,
    String? period,
  }) async {
    try {
      await remoteDataSource.exportFinancialData(
        format: format,
        period: period,
      );
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'Erro inesperado: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> markPaymentReceived({
    required String paymentId,
  }) async {
    try {
      await remoteDataSource.markPaymentReceived(
        paymentId: paymentId,
      );
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'Erro inesperado: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> requestPaymentRepass({
    required String paymentId,
  }) async {
    try {
      await remoteDataSource.requestPaymentRepass(
        paymentId: paymentId,
      );
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'Erro inesperado: $e'));
    }
  }
} 