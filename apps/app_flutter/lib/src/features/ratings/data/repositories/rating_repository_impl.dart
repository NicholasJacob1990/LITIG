import 'package:dartz/dartz.dart';
import 'package:meu_app/src/core/error/failures.dart';
import 'package:meu_app/src/core/network/network_info.dart';
import '../../domain/entities/case_rating.dart';
import '../../domain/entities/lawyer_rating_stats.dart';
import '../../domain/repositories/rating_repository.dart';
import '../datasources/rating_remote_datasource.dart';
import '../models/case_rating_model.dart';

/// Implementação concreta do repositório de avaliações
class RatingRepositoryImpl implements RatingRepository {
  final RatingRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  RatingRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, String>> createRating(CaseRating rating) async {
    if (await networkInfo.isConnected) {
      try {
        final model = CaseRatingModel.fromEntity(rating);
        final ratingId = await remoteDataSource.createRating(model);
        return Right(ratingId);
      } catch (e) {
        return Left(_handleException(e));
      }
    } else {
      return Left(ConnectionFailure(message: 'Sem conexão com a internet'));
    }
  }

  @override
  Future<Either<Failure, List<CaseRating>>> getLawyerRatings(
    String lawyerId, {
    int page = 1,
    int limit = 10,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final models = await remoteDataSource.getLawyerRatings(
          lawyerId,
          page: page,
          limit: limit,
        );
        final entities = models.map((model) => model.toEntity()).toList();
        return Right(entities);
      } catch (e) {
        return Left(_handleException(e));
      }
    } else {
      return Left(ConnectionFailure(message: 'Sem conexão com a internet'));
    }
  }

  @override
  Future<Either<Failure, LawyerRatingStats>> getLawyerStats(String lawyerId) async {
    if (await networkInfo.isConnected) {
      try {
        final model = await remoteDataSource.getLawyerStats(lawyerId);
        return Right(model.toEntity());
      } catch (e) {
        return Left(_handleException(e));
      }
    } else {
      return Left(ConnectionFailure(message: 'Sem conexão com a internet'));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> canRateCase(String caseId) async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.canRateCase(caseId);
        return Right(result);
      } catch (e) {
        return Left(_handleException(e));
      }
    } else {
      return Left(ConnectionFailure(message: 'Sem conexão com a internet'));
    }
  }

  @override
  Future<Either<Failure, List<CaseRating>>> getCaseRatings(String caseId) async {
    if (await networkInfo.isConnected) {
      try {
        final models = await remoteDataSource.getCaseRatings(caseId);
        final entities = models.map((model) => model.toEntity()).toList();
        return Right(entities);
      } catch (e) {
        return Left(_handleException(e));
      }
    } else {
      return Left(ConnectionFailure(message: 'Sem conexão com a internet'));
    }
  }

  @override
  Future<Either<Failure, void>> updateRating(CaseRating rating) async {
    if (await networkInfo.isConnected) {
      try {
        final model = CaseRatingModel.fromEntity(rating);
        await remoteDataSource.updateRating(model);
        return const Right(null);
      } catch (e) {
        return Left(_handleException(e));
      }
    } else {
      return Left(ConnectionFailure(message: 'Sem conexão com a internet'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteRating(String ratingId) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.deleteRating(ratingId);
        return const Right(null);
      } catch (e) {
        return Left(_handleException(e));
      }
    } else {
      return Left(ConnectionFailure(message: 'Sem conexão com a internet'));
    }
  }

  @override
  Future<Either<Failure, void>> voteHelpful(String ratingId) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.voteHelpful(ratingId);
        return const Right(null);
      } catch (e) {
        return Left(_handleException(e));
      }
    } else {
      return Left(ConnectionFailure(message: 'Sem conexão com a internet'));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getSystemStats() async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.getSystemStats();
        return Right(result);
      } catch (e) {
        return Left(_handleException(e));
      }
    } else {
      return Left(ConnectionFailure(message: 'Sem conexão com a internet'));
    }
  }

  /// Trata exceções e converte para Failure apropriado
  Failure _handleException(dynamic error) {
    final errorMessage = error.toString();

    // Erros de validação
    if (errorMessage.contains('validation') || 
        errorMessage.contains('invalid') ||
        errorMessage.contains('obrigatório') ||
        errorMessage.contains('deve estar entre')) {
      return ValidationFailure(message: errorMessage);
    }

    // Erros de autenticação
    if (errorMessage.contains('401') || 
        errorMessage.contains('unauthorized') ||
        errorMessage.contains('não autenticado')) {
      return AuthenticationFailure(message: 'Usuário não autenticado');
    }

    // Erros de autorização
    if (errorMessage.contains('403') || 
        errorMessage.contains('forbidden') ||
        errorMessage.contains('permissão')) {
      return AuthorizationFailure(message: 'Sem permissão para esta operação');
    }

    // Erros de timeout
    if (errorMessage.contains('timeout') || 
        errorMessage.contains('connection timeout')) {
      return TimeoutFailure(message: 'Timeout na conexão');
    }

    // Erros de servidor
    if (errorMessage.contains('500') || 
        errorMessage.contains('502') ||
        errorMessage.contains('503') ||
        errorMessage.contains('504') ||
        errorMessage.contains('server error')) {
      return ServerFailure(message: 'Erro no servidor');
    }

    // Erros de rede
    if (errorMessage.contains('network') || 
        errorMessage.contains('connection') ||
        errorMessage.contains('socket')) {
      return ConnectionFailure(message: 'Erro de conexão');
    }

    // Erro genérico
    return GenericFailure(message: errorMessage);
  }
} 