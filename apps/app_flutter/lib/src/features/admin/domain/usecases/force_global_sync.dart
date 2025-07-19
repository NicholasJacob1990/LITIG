import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/admin_repository.dart';

class ForceGlobalSync implements UseCase<Map<String, dynamic>, NoParams> {
  final AdminRepository repository;

  ForceGlobalSync(this.repository);

  @override
  Future<Either<Failure, Map<String, dynamic>>> call(NoParams params) async {
    return await repository.forceGlobalSync();
  }
} 