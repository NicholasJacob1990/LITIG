import 'package:meu_app/src/features/cases/domain/entities/case.dart';

abstract class CasesRepository {
  Future<List<Case>> getMyCases();
  Future<Case> getCaseById(String caseId);
} 