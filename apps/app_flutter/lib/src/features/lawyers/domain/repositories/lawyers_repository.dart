import 'package:meu_app/src/features/lawyers/domain/entities/matched_lawyer.dart';
import 'package:meu_app/src/features/lawyers/domain/entities/match_result.dart';

abstract class LawyersRepository {
  Future<List<MatchedLawyer>> findMatches({String? caseId});
  
  /// Nova versão que retorna tanto advogados quanto escritórios
  Future<MatchResult> findMatchesWithFirms({String? caseId, bool expandSearch = false});
} 