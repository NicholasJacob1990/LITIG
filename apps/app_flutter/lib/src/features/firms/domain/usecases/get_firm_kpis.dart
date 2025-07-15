import 'package:equatable/equatable.dart';
import 'package:dartz/dartz.dart';
import '../entities/firm_kpi.dart';
import '../repositories/firm_repository.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/error/failures.dart';

/// Use case para buscar KPIs específicos de um escritório
/// 
/// Este caso de uso encapsula a lógica de negócio para buscar os KPIs
/// (Key Performance Indicators) de um escritório específico.
class GetFirmKpis implements UseCase<FirmKPI?, GetFirmKpisParams> {
  final FirmRepository repository;

  const GetFirmKpis(this.repository);

  @override
  Future<Either<Failure, FirmKPI?>> call(GetFirmKpisParams params) async {
    try {
      final result = await repository.getFirmKpis(params.firmId);
      
      if (result.isSuccess) {
        return Right(result.value);
      } else {
        return Left(result.failure);
      }
    } catch (e) {
      return Left(ServerFailure(message: 'Erro ao buscar KPIs: $e'));
    }
  }
}

/// Parâmetros para o use case GetFirmKpis
/// 
/// Esta classe encapsula o parâmetro necessário para buscar KPIs de um escritório.
class GetFirmKpisParams extends Equatable {
  final String firmId;

  const GetFirmKpisParams({required this.firmId});

  @override
  List<Object?> get props => [firmId];

  @override
  String toString() => 'GetFirmKpisParams(firmId: $firmId)';
} 