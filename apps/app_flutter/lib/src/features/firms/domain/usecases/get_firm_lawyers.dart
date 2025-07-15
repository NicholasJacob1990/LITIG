import 'package:equatable/equatable.dart';
import 'package:dartz/dartz.dart';
import '../repositories/firm_repository.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/error/failures.dart';
import '../entities/lawyer.dart';

/// Use case para buscar advogados de um escritório específico
/// 
/// Este caso de uso encapsula a lógica de negócio para buscar todos os
/// advogados associados a um escritório específico com paginação.
class GetFirmLawyers implements UseCase<List<Lawyer>, GetFirmLawyersParams> {
  final FirmRepository repository;

  const GetFirmLawyers(this.repository);

  @override
  Future<Either<Failure, List<Lawyer>>> call(GetFirmLawyersParams params) async {
    try {
      final result = await repository.getFirmLawyers(
        params.firmId,
        limit: params.limit,
        offset: params.offset,
      );
      
      if (result.isSuccess) {
        return Right(result.value);
      } else {
        return Left(result.failure);
      }
    } catch (e) {
      return Left(ServerFailure(message: 'Erro ao buscar advogados: $e'));
    }
  }
}

/// Parâmetros para o use case GetFirmLawyers
/// 
/// Esta classe encapsula os parâmetros necessários para buscar advogados
/// de um escritório, incluindo configurações de paginação.
class GetFirmLawyersParams extends Equatable {
  final String firmId;
  final int limit;
  final int offset;

  const GetFirmLawyersParams({
    required this.firmId,
    this.limit = 50,
    this.offset = 0,
  });

  /// Cria uma cópia dos parâmetros com valores atualizados
  GetFirmLawyersParams copyWith({
    String? firmId,
    int? limit,
    int? offset,
  }) {
    return GetFirmLawyersParams(
      firmId: firmId ?? this.firmId,
      limit: limit ?? this.limit,
      offset: offset ?? this.offset,
    );
  }

  @override
  List<Object?> get props => [firmId, limit, offset];

  @override
  String toString() {
    return 'GetFirmLawyersParams(firmId: $firmId, limit: $limit, offset: $offset)';
  }
} 