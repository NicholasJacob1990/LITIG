import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';

class GetPendingOffersUseCase implements UseCase<List<Map<String, dynamic>>, GetPendingOffersParams> {
  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> call(GetPendingOffersParams params) async {
    // Mock implementation - replace with actual repository call
    return const Right([]);
  }
}

class GetPendingOffersParams {
  final String userId;

  GetPendingOffersParams({required this.userId});
}