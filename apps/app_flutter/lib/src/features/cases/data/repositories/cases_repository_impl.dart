import 'package:meu_app/src/features/cases/data/datasources/cases_remote_data_source.dart';
import 'package:meu_app/src/features/cases/domain/entities/case.dart';
import 'package:meu_app/src/features/cases/domain/repositories/cases_repository.dart';

class CasesRepositoryImpl implements CasesRepository {
  final CasesRemoteDataSource remoteDataSource;

  CasesRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<Case>> getMyCases() async {
    try {
      return await remoteDataSource.getMyCases();
    } catch (e) {
      // TODO: Melhorar tratamento de erro
      rethrow;
    }
  }
} 