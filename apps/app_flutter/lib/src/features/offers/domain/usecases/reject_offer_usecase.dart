import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';

class RejectOfferUseCase implements UseCase<void, RejectOfferParams> {
  @override
  Future<Either<Failure, void>> call(RejectOfferParams params) async {
    // Mock implementation - replace with actual repository call
    return const Right(null);
  }
}

class RejectOfferParams {
  final String offerId;

  RejectOfferParams({required this.offerId});
}