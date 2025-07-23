import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/financial_repository.dart';

class RequestPaymentRepassParams extends Equatable {
  final String paymentId;

  const RequestPaymentRepassParams({
    required this.paymentId,
  });

  @override
  List<Object?> get props => [paymentId];
}

class RequestPaymentRepass implements UseCase<void, RequestPaymentRepassParams> {
  final FinancialRepository repository;

  RequestPaymentRepass(this.repository);

  @override
  Future<Either<Failure, void>> call(RequestPaymentRepassParams params) async {
    return await repository.requestPaymentRepass(
      paymentId: params.paymentId,
    );
  }
} 