import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';

class GetOfferHistoryUseCase implements UseCase<List<Map<String, dynamic>>, GetOfferHistoryParams> {
  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> call(GetOfferHistoryParams params) async {
    // Mock implementation - replace with actual repository call
    return const Right([]);
  }
}

class GetOfferHistoryParams {
  final String userId;

  GetOfferHistoryParams({required this.userId});
}