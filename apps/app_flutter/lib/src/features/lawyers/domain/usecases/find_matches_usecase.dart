import 'package:meu_app/src/features/lawyers/domain/entities/matched_lawyer.dart';
import 'package:meu_app/src/features/lawyers/domain/repositories/lawyers_repository.dart';

class FindMatchesUseCase {
  final LawyersRepository repository;

  FindMatchesUseCase(this.repository);

  Future<List<MatchedLawyer>> call({String? caseId}) async {
    // Se o caseId for nulo, a lógica de fallback está no repositório.
    return await repository.findMatches(caseId: caseId);
  }
} 