import 'dart:io';
import '../../domain/entities/law_firm.dart';
import '../../domain/entities/firm_kpi.dart';
import '../../domain/entities/firm_stats.dart';
import '../../domain/entities/lawyer.dart';
import '../../domain/repositories/firm_repository.dart';
import '../datasources/firm_remote_data_source.dart';
import '../models/lawyer_model.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/utils/result.dart';

/// Implementação concreta do FirmRepository
/// 
/// Esta classe é responsável por coordenar as operações de dados,
/// convertendo exceções em Results e mapeando modelos para entidades.
class FirmRepositoryImpl implements FirmRepository {
  final FirmRemoteDataSource remoteDataSource;

  const FirmRepositoryImpl({
    required this.remoteDataSource,
  });

  @override
  Future<Result<List<LawFirm>>> getFirms({
    int limit = 50,
    int offset = 0,
    bool includeKpis = true,
    bool includeLawyersCount = true,
    double? minSuccessRate,
    int? minTeamSize,
  }) async {
    try {
      final models = await remoteDataSource.getFirms(
        limit: limit,
        offset: offset,
        includeKpis: includeKpis,
        includeLawyersCount: includeLawyersCount,
        minSuccessRate: minSuccessRate,
        minTeamSize: minTeamSize,
      );

      final entities = models.map((model) => model.toEntity()).toList();
      return Result.success(entities);
    } on SocketException {
      return const Result.failure(
        ConnectionFailure(
          message: 'Falha na conexão com o servidor',
          code: 'CONNECTION_ERROR',
        ),
      );
    } on HttpException catch (e) {
      return Result.failure(
        ServerFailure(
          message: e.message,
          code: 'HTTP_ERROR',
        ),
      );
    } catch (e) {
      return Result.failure(
        GenericFailure(
          message: 'Erro inesperado ao buscar escritórios: $e',
          code: 'UNKNOWN_ERROR',
        ),
      );
    }
  }

  @override
  Future<Result<LawFirm?>> getFirmById(
    String firmId, {
    bool includeKpis = true,
    bool includeLawyersCount = true,
  }) async {
    try {
      final model = await remoteDataSource.getFirmById(
        firmId,
        includeKpis: includeKpis,
        includeLawyersCount: includeLawyersCount,
      );

      if (model == null) {
        return const Result.success(null);
      }

      return Result.success(model.toEntity());
    } on SocketException {
      return const Result.failure(
        ConnectionFailure(
          message: 'Falha na conexão com o servidor',
          code: 'CONNECTION_ERROR',
        ),
      );
    } on HttpException catch (e) {
      return Result.failure(
        ServerFailure(
          message: e.message,
          code: 'HTTP_ERROR',
        ),
      );
    } catch (e) {
      return Result.failure(
        GenericFailure(
          message: 'Erro inesperado ao buscar escritório: $e',
          code: 'UNKNOWN_ERROR',
        ),
      );
    }
  }

  @override
  Future<Result<FirmStats>> getFirmStats() async {
    try {
      final model = await remoteDataSource.getFirmStats();
      return Result.success(model.toEntity());
    } on SocketException {
      return const Result.failure(
        ConnectionFailure(
          message: 'Falha na conexão com o servidor',
          code: 'CONNECTION_ERROR',
        ),
      );
    } on HttpException catch (e) {
      return Result.failure(
        ServerFailure(
          message: e.message,
          code: 'HTTP_ERROR',
        ),
      );
    } catch (e) {
      return Result.failure(
        GenericFailure(
          message: 'Erro inesperado ao buscar estatísticas: $e',
          code: 'UNKNOWN_ERROR',
        ),
      );
    }
  }

  @override
  Future<Result<FirmKPI?>> getFirmKpis(String firmId) async {
    try {
      final model = await remoteDataSource.getFirmKpis(firmId);
      
      if (model == null) {
        return const Result.success(null);
      }

      return Result.success(model.toEntity());
    } on SocketException {
      return const Result.failure(
        ConnectionFailure(
          message: 'Falha na conexão com o servidor',
          code: 'CONNECTION_ERROR',
        ),
      );
    } on HttpException catch (e) {
      return Result.failure(
        ServerFailure(
          message: e.message,
          code: 'HTTP_ERROR',
        ),
      );
    } catch (e) {
      return Result.failure(
        GenericFailure(
          message: 'Erro inesperado ao buscar KPIs: $e',
          code: 'UNKNOWN_ERROR',
        ),
      );
    }
  }

  @override
  Future<Result<List<Lawyer>>> getFirmLawyers(
    String firmId, {
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final data = await remoteDataSource.getFirmLawyers(
        firmId,
        limit: limit,
        offset: offset,
      );

      // A API retorna um mapa com a chave 'data' contendo a lista
      final List<dynamic> lawyerListJson = data['data'] as List<dynamic>? ?? [];
      
      final lawyers = lawyerListJson
          .map((json) => LawyerModel.fromJson(json as Map<String, dynamic>))
          .toList();

      return Result.success(lawyers);
    } on SocketException {
      return const Result.failure(
        ConnectionFailure(
          message: 'Falha na conexão com o servidor',
          code: 'CONNECTION_ERROR',
        ),
      );
    } on HttpException catch (e) {
      return Result.failure(
        ServerFailure(
          message: e.message,
          code: 'HTTP_ERROR',
        ),
      );
    } catch (e) {
      return Result.failure(
        GenericFailure(
          message: 'Erro inesperado ao buscar advogados: $e',
          code: 'UNKNOWN_ERROR',
        ),
      );
    }
  }

  @override
  Future<Result<LawFirm>> createFirm(Map<String, dynamic> firmData) async {
    try {
      final model = await remoteDataSource.createFirm(firmData);
      return Result.success(model.toEntity());
    } on SocketException {
      return const Result.failure(
        ConnectionFailure(
          message: 'Falha na conexão com o servidor',
          code: 'CONNECTION_ERROR',
        ),
      );
    } on HttpException catch (e) {
      return Result.failure(
        ServerFailure(
          message: e.message,
          code: 'HTTP_ERROR',
        ),
      );
    } catch (e) {
      return Result.failure(
        GenericFailure(
          message: 'Erro inesperado ao criar escritório: $e',
          code: 'UNKNOWN_ERROR',
        ),
      );
    }
  }

  @override
  Future<Result<LawFirm>> updateFirm(
    String firmId,
    Map<String, dynamic> firmData,
  ) async {
    try {
      final model = await remoteDataSource.updateFirm(firmId, firmData);
      return Result.success(model.toEntity());
    } on SocketException {
      return const Result.failure(
        ConnectionFailure(
          message: 'Falha na conexão com o servidor',
          code: 'CONNECTION_ERROR',
        ),
      );
    } on HttpException catch (e) {
      return Result.failure(
        ServerFailure(
          message: e.message,
          code: 'HTTP_ERROR',
        ),
      );
    } catch (e) {
      return Result.failure(
        GenericFailure(
          message: 'Erro inesperado ao atualizar escritório: $e',
          code: 'UNKNOWN_ERROR',
        ),
      );
    }
  }

  @override
  Future<Result<FirmKPI>> updateFirmKpis(
    String firmId,
    Map<String, dynamic> kpiData,
  ) async {
    try {
      final model = await remoteDataSource.updateFirmKpis(firmId, kpiData);
      return Result.success(model.toEntity());
    } on SocketException {
      return const Result.failure(
        ConnectionFailure(
          message: 'Falha na conexão com o servidor',
          code: 'CONNECTION_ERROR',
        ),
      );
    } on HttpException catch (e) {
      return Result.failure(
        ServerFailure(
          message: e.message,
          code: 'HTTP_ERROR',
        ),
      );
    } catch (e) {
      return Result.failure(
        GenericFailure(
          message: 'Erro inesperado ao atualizar KPIs: $e',
          code: 'UNKNOWN_ERROR',
        ),
      );
    }
  }

  @override
  Future<Result<bool>> deleteFirm(String firmId) async {
    try {
      final success = await remoteDataSource.deleteFirm(firmId);
      return Result.success(success);
    } on SocketException {
      return const Result.failure(
        ConnectionFailure(
          message: 'Falha na conexão com o servidor',
          code: 'CONNECTION_ERROR',
        ),
      );
    } on HttpException catch (e) {
      return Result.failure(
        ServerFailure(
          message: e.message,
          code: 'HTTP_ERROR',
        ),
      );
    } catch (e) {
      return Result.failure(
        GenericFailure(
          message: 'Erro inesperado ao deletar escritório: $e',
          code: 'UNKNOWN_ERROR',
        ),
      );
    }
  }
} 