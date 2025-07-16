import 'package:meu_app/src/features/cases/domain/repositories/documents_repository.dart';

class DeleteDocumentUseCase {
  final DocumentsRepository repository;

  DeleteDocumentUseCase(this.repository);

  Future<void> call({
    required String caseId,
    required String documentId,
  }) async {
    return await repository.deleteDocument(
      caseId: caseId,
      documentId: documentId,
    );
  }
} 