import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/admin_dashboard_data.dart';
import '../repositories/admin_repository.dart';

class GetAdminDashboard implements UseCase<AdminDashboardData, NoParams> {
  final AdminRepository repository;

  GetAdminDashboard(this.repository);

  @override
  Future<Either<Failure, AdminDashboardData>> call(NoParams params) async {
    return await repository.getAdminDashboard();
  }
} 