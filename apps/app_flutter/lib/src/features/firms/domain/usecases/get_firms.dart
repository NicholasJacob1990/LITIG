import 'package:equatable/equatable.dart';
import 'package:dartz/dartz.dart';
import '../entities/law_firm.dart';
import '../repositories/firm_repository.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/error/failures.dart';

/// Use case para buscar uma lista de escritórios com filtros opcionais
/// 
/// Este caso de uso encapsula a lógica de negócio para buscar escritórios,
/// permitindo aplicar filtros como taxa de sucesso mínima e tamanho da equipe.
class GetFirms implements UseCase<List<LawFirm>, GetFirmsParams> {
  final FirmRepository repository;

  const GetFirms(this.repository);

  @override
  Future<Either<Failure, List<LawFirm>>> call(GetFirmsParams params) async {
    try {
      final result = await repository.getFirms(
        limit: params.limit,
        offset: params.offset,
        includeKpis: params.includeKpis,
        includeLawyersCount: params.includeLawyersCount,
        minSuccessRate: params.minSuccessRate,
        minTeamSize: params.minTeamSize,
      );
      
      if (result.isSuccess) {
        return Right(result.value);
      } else {
        return Left(result.failure);
      }
    } catch (e) {
      return Left(ServerFailure(message: 'Erro ao buscar escritórios: $e'));
    }
  }
}

/// Parâmetros para o use case GetFirms
/// 
/// Esta classe encapsula todos os parâmetros necessários para buscar escritórios,
/// incluindo filtros opcionais e configurações de paginação.
class GetFirmsParams extends Equatable {
  final int limit;
  final int offset;
  final bool includeKpis;
  final bool includeLawyersCount;
  final double? minSuccessRate;
  final int? minTeamSize;

  const GetFirmsParams({
    this.limit = 50,
    this.offset = 0,
    this.includeKpis = true,
    this.includeLawyersCount = true,
    this.minSuccessRate,
    this.minTeamSize,
  });

  /// Cria uma cópia dos parâmetros com valores atualizados
  GetFirmsParams copyWith({
    int? limit,
    int? offset,
    bool? includeKpis,
    bool? includeLawyersCount,
    double? minSuccessRate,
    int? minTeamSize,
  }) {
    return GetFirmsParams(
      limit: limit ?? this.limit,
      offset: offset ?? this.offset,
      includeKpis: includeKpis ?? this.includeKpis,
      includeLawyersCount: includeLawyersCount ?? this.includeLawyersCount,
      minSuccessRate: minSuccessRate ?? this.minSuccessRate,
      minTeamSize: minTeamSize ?? this.minTeamSize,
    );
  }

  @override
  List<Object?> get props => [
        limit,
        offset,
        includeKpis,
        includeLawyersCount,
        minSuccessRate,
        minTeamSize,
      ];

  @override
  String toString() {
    return 'GetFirmsParams(limit: $limit, offset: $offset, includeKpis: $includeKpis, includeLawyersCount: $includeLawyersCount, minSuccessRate: $minSuccessRate, minTeamSize: $minTeamSize)';
  }
} 