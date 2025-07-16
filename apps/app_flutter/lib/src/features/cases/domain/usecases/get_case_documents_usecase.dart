import 'package:meu_app/src/features/cases/domain/entities/case_document.dart';
import 'package:meu_app/src/features/cases/domain/repositories/documents_repository.dart';

class GetCaseDocumentsUseCase {
  final DocumentsRepository repository;

  GetCaseDocumentsUseCase(this.repository);

  Future<List<CaseDocument>> call(String caseId) async {
    return await repository.getCaseDocuments(caseId);
  }
} 