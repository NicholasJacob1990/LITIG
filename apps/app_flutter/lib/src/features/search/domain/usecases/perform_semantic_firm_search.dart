import 'package:dartz/dartz.dart';
import 'package:meu_app/src/core/error/failures.dart';
import 'package:meu_app/src/core/usecases/usecase.dart';
import 'package:meu_app/src/features/search/domain/entities/search_params.dart';
import 'package:meu_app/src/features/search/domain/repositories/search_repository.dart';

class PerformSemanticFirmSearch implements UseCase<List<dynamic>, SearchParams> {
  final SearchRepository repository;

  PerformSemanticFirmSearch(this.repository);

  @override
  Future<Either<Failure, List<dynamic>>> call(SearchParams params) async {
    return await repository.performSemanticFirmSearch(params);
  }
} 
 