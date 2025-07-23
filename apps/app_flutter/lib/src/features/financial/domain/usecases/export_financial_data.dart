import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/financial_repository.dart';

class ExportFinancialDataParams extends Equatable {
  final String format;
  final String? period;

  const ExportFinancialDataParams({
    required this.format,
    this.period,
  });

  @override
  List<Object?> get props => [format, period];
}

class ExportFinancialData implements UseCase<void, ExportFinancialDataParams> {
  final FinancialRepository repository;

  ExportFinancialData(this.repository);

  @override
  Future<Either<Failure, void>> call(ExportFinancialDataParams params) async {
    return await repository.exportFinancialData(
      format: params.format,
      period: params.period,
    );
  }
} 