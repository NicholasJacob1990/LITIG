import 'package:equatable/equatable.dart';
import 'package:dartz/dartz.dart';
import '../entities/law_firm.dart';
import '../repositories/firm_repository.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/error/failures.dart';

/// Use case para buscar um escritório específico por ID
/// 
/// Este caso de uso encapsula a lógica de negócio para buscar um escritório
/// específico, incluindo a opção de carregar KPIs e contagem de advogados.
class GetFirmById implements UseCase<LawFirm?, GetFirmByIdParams> {
  final FirmRepository repository;

  const GetFirmById(this.repository);

  @override
  Future<Either<Failure, LawFirm?>> call(GetFirmByIdParams params) async {
    try {
      final result = await repository.getFirmById(
        params.firmId,
        includeKpis: params.includeKpis,
        includeLawyersCount: params.includeLawyersCount,
      );
      
      if (result.isSuccess) {
        return Right(result.value);
      } else {
        return Left(result.failure);
      }
    } catch (e) {
      return Left(ServerFailure(message: 'Erro ao buscar escritório: $e'));
    }
  }
}

/// Parâmetros para o use case GetFirmById
/// 
/// Esta classe encapsula os parâmetros necessários para buscar um escritório
/// específico, incluindo opções de configuração para dados adicionais.
class GetFirmByIdParams extends Equatable {
  final String firmId;
  final bool includeKpis;
  final bool includeLawyersCount;

  const GetFirmByIdParams({
    required this.firmId,
    this.includeKpis = true,
    this.includeLawyersCount = true,
  });

  /// Cria uma cópia dos parâmetros com valores atualizados
  GetFirmByIdParams copyWith({
    String? firmId,
    bool? includeKpis,
    bool? includeLawyersCount,
  }) {
    return GetFirmByIdParams(
      firmId: firmId ?? this.firmId,
      includeKpis: includeKpis ?? this.includeKpis,
      includeLawyersCount: includeLawyersCount ?? this.includeLawyersCount,
    );
  }

  @override
  List<Object?> get props => [firmId, includeKpis, includeLawyersCount];

  @override
  String toString() {
    return 'GetFirmByIdParams(firmId: $firmId, includeKpis: $includeKpis, includeLawyersCount: $includeLawyersCount)';
  }
} 