import 'package:dio/dio.dart';
import 'package:meu_app/src/features/cases/domain/entities/case.dart';
import 'package:meu_app/src/features/cases/data/models/case_model.dart';
import 'package:meu_app/src/core/services/dio_service.dart';

abstract class CasesRemoteDataSource {
  Future<List<Case>> getMyCases();
  Future<Case> getCaseById(String caseId);
}

class CasesRemoteDataSourceImpl implements CasesRemoteDataSource {
  final Dio dio;

  CasesRemoteDataSourceImpl({required this.dio});

  @override
  Future<List<Case>> getMyCases() async {
    try {
      final response = await dio.get('/cases/my-cases');
      
      if (response.statusCode == 200 && response.data != null) {
        // O backend retorna um objeto com a propriedade 'cases'
        final data = response.data;
        
        if (data is Map<String, dynamic> && data['cases'] != null) {
          final List<dynamic> caseList = data['cases'];
          return caseList.map((json) => CaseModel.fromJson(json as Map<String, dynamic>)).toList();
        } else if (data is List) {
          // Caso o backend retorne diretamente uma lista
          return data.map((json) => CaseModel.fromJson(json as Map<String, dynamic>)).toList();
        } else {
          throw Exception('Formato de resposta inesperado do servidor');
        }
      } else {
        throw Exception('Falha ao buscar casos: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      // Melhor tratamento de erro Dio
      if (e.response != null) {
        throw Exception('Erro HTTP ${e.response!.statusCode}: ${e.response!.data}');
      } else {
        throw Exception('Erro de rede ao buscar casos: ${e.message}');
      }
    } catch (e) {
      throw Exception('Erro inesperado: ${e.toString()}');
    }
  }

  @override
  Future<Case> getCaseById(String caseId) async {
    try {
      final response = await dio.get('/cases/$caseId');
      
      if (response.statusCode == 200 && response.data != null) {
        return CaseModel.fromJson(response.data as Map<String, dynamic>);
      } else {
        throw Exception('Falha ao buscar detalhes do caso: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        if (e.response!.statusCode == 404) {
          throw Exception('Caso não encontrado');
        } else if (e.response!.statusCode == 403) {
          throw Exception('Sem permissão para acessar este caso');
        } else {
          throw Exception('Erro HTTP ${e.response!.statusCode}: ${e.response!.data}');
        }
      } else {
        throw Exception('Erro de rede ao buscar detalhes do caso: ${e.message}');
      }
    } catch (e) {
      throw Exception('Erro inesperado: ${e.toString()}');
    }
  }
} 