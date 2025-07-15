import 'package:dartz/dartz.dart';
import 'package:meu_app/src/core/error/failures.dart';
import 'package:meu_app/src/features/search/domain/entities/search_params.dart';
import 'package:meu_app/src/features/search/domain/repositories/search_repository.dart';

class PerformSearch {
  final SearchRepository repository;

  PerformSearch(this.repository);

  Future<Either<Failure, List<dynamic>>> call(SearchParams params) async {
    return await repository.performSearch(params);
  }
} 
 