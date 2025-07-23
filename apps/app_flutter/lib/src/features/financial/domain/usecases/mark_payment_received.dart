import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/financial_repository.dart';

class MarkPaymentReceivedParams extends Equatable {
  final String paymentId;

  const MarkPaymentReceivedParams({
    required this.paymentId,
  });

  @override
  List<Object?> get props => [paymentId];
}

class MarkPaymentReceived implements UseCase<void, MarkPaymentReceivedParams> {
  final FinancialRepository repository;

  MarkPaymentReceived(this.repository);

  @override
  Future<Either<Failure, void>> call(MarkPaymentReceivedParams params) async {
    return await repository.markPaymentReceived(
      paymentId: params.paymentId,
    );
  }
} 