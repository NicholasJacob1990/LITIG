import 'dart:io';
import 'package:meu_app/src/core/utils/result.dart';
import 'package:meu_app/src/core/network/network_info.dart';
import 'package:meu_app/src/features/partnerships/data/datasources/partnership_remote_data_source.dart';
import 'package:meu_app/src/features/partnerships/domain/entities/partnership.dart';
import 'package:meu_app/src/features/partnerships/domain/repositories/partnership_repository.dart';

class PartnershipRepositoryImpl implements PartnershipRepository {
  final PartnershipRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  const PartnershipRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Result<List<Partnership>>> fetchPartnerships() async {
    if (await networkInfo.isConnected) {
      try {
        final remotePartnerships = await remoteDataSource.fetchPartnerships();
        // The models are subtypes of entities, so they can be returned directly.
        return Result.success(remotePartnerships);
      } on SocketException {
        return Result.connectionFailure(
          'Falha na conexão com o servidor',
          'CONNECTION_ERROR',
        );
      } on FormatException {
        return Result.validationFailure(
          'Formato de dados inválido recebido do servidor',
          'INVALID_FORMAT',
        );
      } catch (e) {
        return Result.genericFailure(
          'Ocorreu um erro inesperado: ${e.toString()}',
          'UNKNOWN_ERROR',
        );
      }
    } else {
      return Result.connectionFailure(
        'Sem conexão com a internet',
        'NO_CONNECTION',
      );
    }
  }
} 