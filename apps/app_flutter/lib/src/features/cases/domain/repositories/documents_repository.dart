import 'package:meu_app/src/features/cases/domain/entities/case_document.dart';

abstract class DocumentsRepository {
  Future<List<CaseDocument>> getCaseDocuments(String caseId);
  
  Future<CaseDocument> uploadDocument({
    required String caseId,
    required String fileName,
    required List<int> fileBytes,
    required String category,
  });
  
  Future<void> deleteDocument({
    required String caseId,
    required String documentId,
  });
  
  Future<List<int>> downloadDocument({
    required String caseId,
    required String documentId,
  });
} 