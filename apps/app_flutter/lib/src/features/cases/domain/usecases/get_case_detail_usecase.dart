import 'package:meu_app/src/features/cases/domain/entities/case.dart';
import 'package:meu_app/src/features/cases/domain/repositories/cases_repository.dart';

class GetCaseDetailUseCase {
  final CasesRepository repository;

  GetCaseDetailUseCase(this.repository);

  Future<Case> call(String caseId) async {
    return await repository.getCaseById(caseId);
  }
} 