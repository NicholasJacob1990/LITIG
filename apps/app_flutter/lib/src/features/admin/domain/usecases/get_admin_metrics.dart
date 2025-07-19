import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/admin_metrics.dart';
import '../repositories/admin_repository.dart';

class GetAdminMetricsParams {
  final String metricsType;

  const GetAdminMetricsParams({required this.metricsType});
}

class GetAdminMetrics implements UseCase<AdminMetrics, GetAdminMetricsParams> {
  final AdminRepository repository;

  GetAdminMetrics(this.repository);

  @override
  Future<Either<Failure, AdminMetrics>> call(GetAdminMetricsParams params) async {
    return await repository.getAdminMetrics(params.metricsType);
  }
} 