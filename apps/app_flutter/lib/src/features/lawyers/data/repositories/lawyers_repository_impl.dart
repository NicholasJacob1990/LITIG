import 'package:meu_app/src/features/lawyers/data/datasources/lawyers_remote_data_source.dart';
import 'package:meu_app/src/features/lawyers/domain/entities/matched_lawyer.dart';
import 'package:meu_app/src/features/lawyers/domain/repositories/lawyers_repository.dart';

class LawyersRepositoryImpl implements LawyersRepository {
  final LawyersRemoteDataSource remoteDataSource;

  LawyersRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<MatchedLawyer>> findMatches({required String caseId}) async {
    try {
      return await remoteDataSource.findMatches(caseId: caseId);
    } catch (e) {
      // TODO: Implementar tratamento de erro
      rethrow;
    }
  }
} 