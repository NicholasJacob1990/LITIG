import 'package:dartz/dartz.dart';
import 'package:meu_app/src/core/error/failures.dart';
import 'package:meu_app/src/features/search/domain/entities/search_params.dart';

abstract class SearchRepository {
  Future<Either<Failure, List<dynamic>>> performSearch(SearchParams params);
  Future<Either<Failure, List<dynamic>>> performSemanticFirmSearch(SearchParams params);
} 
 
 