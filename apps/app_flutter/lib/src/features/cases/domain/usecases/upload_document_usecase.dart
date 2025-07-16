import 'package:meu_app/src/features/cases/domain/entities/case_document.dart';
import 'package:meu_app/src/features/cases/domain/repositories/documents_repository.dart';

class UploadDocumentUseCase {
  final DocumentsRepository repository;

  UploadDocumentUseCase(this.repository);

  Future<CaseDocument> call({
    required String caseId,
    required String fileName,
    required List<int> fileBytes,
    required String category,
  }) async {
    return await repository.uploadDocument(
      caseId: caseId,
      fileName: fileName,
      fileBytes: fileBytes,
      category: category,
    );
  }
} 