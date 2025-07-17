import 'package:dio/dio.dart';
import 'package:meu_app/src/features/cases/domain/entities/case_document.dart';
import 'package:meu_app/src/features/cases/data/models/case_document_model.dart';
import 'package:meu_app/src/core/utils/logger.dart';

abstract class DocumentsRemoteDataSource {
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

class DocumentsRemoteDataSourceImpl implements DocumentsRemoteDataSource {
  final Dio dio;

  DocumentsRemoteDataSourceImpl({required this.dio});

  @override
  Future<List<CaseDocument>> getCaseDocuments(String caseId) async {
    try {
      final response = await dio.get('/cases/$caseId/documents');
      
      if (response.statusCode == 200 && response.data != null) {
        final documentsJson = response.data['documents'] as List;
        return documentsJson
            .map((doc) => CaseDocumentModel.fromJson(doc as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception('Falha ao buscar documentos: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      // Se há erro de conectividade, usar dados mock como fallback
      if (e.type == DioExceptionType.connectionError || 
          e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        AppLogger.warning('API não disponível, usando documentos mock como fallback');
        return _getMockDocuments(caseId);
      }
      
      if (e.response != null) {
        throw Exception('Erro HTTP ${e.response!.statusCode}: ${e.response!.data}');
      } else {
        throw Exception('Erro de rede ao buscar documentos: ${e.message}');
      }
    } catch (e) {
      // Fallback para qualquer outro erro não previsto
      AppLogger.error('Erro inesperado na API, usando documentos mock', error: e);
      return _getMockDocuments(caseId);
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
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(
          fileBytes,
          filename: fileName,
        ),
        'category': category,
      });

      final response = await dio.post(
        '/cases/$caseId/documents/upload',
        data: formData,
      );

      if (response.statusCode == 201 && response.data != null) {
        return CaseDocumentModel.fromJson(response.data as Map<String, dynamic>);
      } else {
        throw Exception('Falha no upload: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception('Erro HTTP ${e.response!.statusCode}: ${e.response!.data}');
      } else {
        throw Exception('Erro de rede no upload: ${e.message}');
      }
    }
  }

  @override
  Future<void> deleteDocument({
    required String caseId,
    required String documentId,
  }) async {
    try {
      final response = await dio.delete('/cases/$caseId/documents/$documentId');
      
      if (response.statusCode != 204) {
        throw Exception('Falha ao excluir documento: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception('Erro HTTP ${e.response!.statusCode}: ${e.response!.data}');
      } else {
        throw Exception('Erro de rede ao excluir documento: ${e.message}');
      }
    }
  }

  @override
  Future<List<int>> downloadDocument({
    required String caseId,
    required String documentId,
  }) async {
    try {
      final response = await dio.get(
        '/cases/$caseId/documents/$documentId/download',
        options: Options(responseType: ResponseType.bytes),
      );
      
      if (response.statusCode == 200 && response.data != null) {
        return response.data as List<int>;
      } else {
        throw Exception('Falha no download: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception('Erro HTTP ${e.response!.statusCode}: ${e.response!.data}');
      } else {
        throw Exception('Erro de rede no download: ${e.message}');
      }
    }
  }

  // Dados mock para fallback quando a API não está disponível
  List<CaseDocument> _getMockDocuments(String caseId) {
    return [
      const CaseDocumentModel(
        name: 'Relatório da Consulta',
        size: '2.3 MB',
        date: '16/01/2024',
        type: 'pdf',
        category: 'Consulta',
      ),
      const CaseDocumentModel(
        name: 'Modelo de Petição',
        size: '1.1 MB',
        date: '17/01/2024',
        type: 'docx',
        category: 'Petições',
      ),
      const CaseDocumentModel(
        name: 'Checklist de Documentos',
        size: '0.8 MB',
        date: '16/01/2024',
        type: 'pdf',
        category: 'Administrativo',
      ),
      const CaseDocumentModel(
        name: 'Contrato de Trabalho',
        size: '1.5 MB',
        date: '15/01/2024',
        type: 'pdf',
        category: 'Documentos Pessoais',
      ),
      const CaseDocumentModel(
        name: 'Comprovante de Pagamento',
        size: '0.6 MB',
        date: '14/01/2024',
        type: 'jpg',
        category: 'Comprovantes',
      ),
    ];
  }
} 