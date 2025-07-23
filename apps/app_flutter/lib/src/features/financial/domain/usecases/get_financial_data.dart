import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/financial_data.dart';
import '../repositories/financial_repository.dart';

class GetFinancialDataParams extends Equatable {
  final String? period;
  final String? feeType;

  const GetFinancialDataParams({
    this.period,
    this.feeType,
  });

  @override
  List<Object?> get props => [period, feeType];
}

class GetFinancialData implements UseCase<FinancialData, GetFinancialDataParams> {
  final FinancialRepository repository;

  GetFinancialData(this.repository);

  @override
  Future<Either<Failure, FinancialData>> call(GetFinancialDataParams params) async {
    return await repository.getFinancialData(
      period: params.period,
      feeType: params.feeType,
    );
  }
} 