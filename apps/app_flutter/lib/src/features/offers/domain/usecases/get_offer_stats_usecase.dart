import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';

class GetOfferStatsUseCase implements UseCase<Map<String, dynamic>, GetOfferStatsParams> {
  @override
  Future<Either<Failure, Map<String, dynamic>>> call(GetOfferStatsParams params) async {
    // Mock implementation - replace with actual repository call
    return const Right({});
  }
}

class GetOfferStatsParams {
  final String userId;

  GetOfferStatsParams({required this.userId});
}