import 'package:meu_app/src/features/lawyers/domain/entities/matched_lawyer.dart';
import 'package:meu_app/src/features/lawyers/domain/repositories/lawyers_repository.dart';

class FindMatchesUseCase {
  final LawyersRepository repository;

  FindMatchesUseCase(this.repository);

  Future<List<MatchedLawyer>> call({required String caseId}) async {
    return await repository.findMatches(caseId: caseId);
  }
} 