import 'package:dartz/dartz.dart';
import 'package:meu_app/src/core/error/failures.dart';
import 'package:meu_app/src/core/error/exceptions.dart';
import 'package:meu_app/src/features/search/domain/entities/search_params.dart';
import 'package:meu_app/src/features/search/domain/repositories/search_repository.dart';
import 'package:meu_app/src/features/search/data/datasources/search_remote_data_source.dart';

class SearchRepositoryImpl implements SearchRepository {
  final SearchRemoteDataSource remoteDataSource;

  SearchRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<dynamic>>> performSearch(SearchParams params) async {
    try {
      final results = await remoteDataSource.performSearch(params);
      return Right(results);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, List<dynamic>>> performSemanticFirmSearch(SearchParams params) async {
    try {
      final results = await remoteDataSource.performSemanticFirmSearch(params);
      return Right(results);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }
} 
 