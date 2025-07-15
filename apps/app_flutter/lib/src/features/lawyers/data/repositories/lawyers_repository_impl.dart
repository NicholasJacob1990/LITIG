import 'package:meu_app/src/features/lawyers/data/datasources/lawyers_remote_data_source.dart';
import 'package:meu_app/src/features/lawyers/domain/entities/matched_lawyer.dart';
import 'package:meu_app/src/features/lawyers/domain/repositories/lawyers_repository.dart';
import 'package:meu_app/src/core/utils/logger.dart';

class LawyersRepositoryImpl implements LawyersRepository {
  final LawyersRemoteDataSource remoteDataSource;

  LawyersRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<MatchedLawyer>> findMatches({String? caseId}) async {
    // TODO: Se caseId for nulo, buscar o último caso do usuário aqui
    // antes de chamar o remoteDataSource.
    if (caseId == null) {
      // Por enquanto, retorna uma lista vazia para não quebrar.
      return [];
    }
    
    try {
      final lawyers = await remoteDataSource.findMatches(caseId: caseId);
      return lawyers;
    } catch (e) {
      AppLogger.error('Erro no repositório de lawyers', error: e);
      rethrow;
    }
  }
} 