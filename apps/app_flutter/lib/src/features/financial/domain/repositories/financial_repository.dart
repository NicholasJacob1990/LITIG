import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/financial_data.dart';

abstract class FinancialRepository {
  Future<Either<Failure, FinancialData>> getFinancialData({
    String? period,
    String? feeType,
  });

  Future<Either<Failure, void>> exportFinancialData({
    required String format,
    String? period,
  });

  Future<Either<Failure, void>> markPaymentReceived({
    required String paymentId,
  });

  Future<Either<Failure, void>> requestPaymentRepass({
    required String paymentId,
  });
} 