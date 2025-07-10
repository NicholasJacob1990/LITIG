import 'package:meu_app/src/features/lawyers/domain/entities/matched_lawyer.dart';

abstract class LawyersRepository {
  Future<List<MatchedLawyer>> findMatches({required String caseId});
} 