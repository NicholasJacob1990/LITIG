import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/admin_repository.dart';

class GenerateExecutiveReportParams {
  final String reportType;
  final Map<String, dynamic>? dateRange;

  const GenerateExecutiveReportParams({
    required this.reportType,
    this.dateRange,
  });
}

class GenerateExecutiveReport implements UseCase<Map<String, dynamic>, GenerateExecutiveReportParams> {
  final AdminRepository repository;

  GenerateExecutiveReport(this.repository);

  @override
  Future<Either<Failure, Map<String, dynamic>>> call(GenerateExecutiveReportParams params) async {
    return await repository.generateExecutiveReport(
      reportType: params.reportType,
      dateRange: params.dateRange,
    );
  }
} 