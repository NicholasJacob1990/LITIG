import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';

class AcceptOfferUseCase implements UseCase<void, AcceptOfferParams> {
  @override
  Future<Either<Failure, void>> call(AcceptOfferParams params) async {
    // Mock implementation - replace with actual repository call
    return const Right(null);
  }
}

class AcceptOfferParams {
  final String offerId;

  AcceptOfferParams({required this.offerId});
}