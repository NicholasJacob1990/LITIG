import 'package:meu_app/src/features/cases/data/datasources/documents_remote_data_source.dart';
import 'package:meu_app/src/features/cases/domain/entities/case_document.dart';
import 'package:meu_app/src/features/cases/domain/repositories/documents_repository.dart';

class DocumentsRepositoryImpl implements DocumentsRepository {
  final DocumentsRemoteDataSource remoteDataSource;

  DocumentsRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<CaseDocument>> getCaseDocuments(String caseId) async {
    try {
      return await remoteDataSource.getCaseDocuments(caseId);
    } catch (e) {
      // TODO: Melhorar tratamento de erro
      rethrow;
    }
  }

  @override
  Future<CaseDocument> uploadDocument({
    required String caseId,
    required String fileName,
    required List<int> fileBytes,
    required String category,
  }) async {
    try {
      return await remoteDataSource.uploadDocument(
        caseId: caseId,
        fileName: fileName,
        fileBytes: fileBytes,
        category: category,
      );
    } catch (e) {
      // TODO: Melhorar tratamento de erro
      rethrow;
    }
  }

  @override
  Future<void> deleteDocument({
    required String caseId,
    required String documentId,
  }) async {
    try {
      return await remoteDataSource.deleteDocument(
        caseId: caseId,
        documentId: documentId,
      );
    } catch (e) {
      // TODO: Melhorar tratamento de erro
      rethrow;
    }
  }

  @override
  Future<List<int>> downloadDocument({
    required String caseId,
    required String documentId,
  }) async {
    try {
      return await remoteDataSource.downloadDocument(
        caseId: caseId,
        documentId: documentId,
      );
    } catch (e) {
      // TODO: Melhorar tratamento de erro
      rethrow;
    }
  }
} 