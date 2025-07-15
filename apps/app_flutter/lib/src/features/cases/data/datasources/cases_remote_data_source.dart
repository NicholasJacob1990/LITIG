import 'package:dio/dio.dart';
import 'package:meu_app/src/features/cases/domain/entities/case.dart';
import 'package:meu_app/src/features/cases/domain/entities/lawyer_info.dart';
import 'package:meu_app/src/features/cases/data/models/case_model.dart';
import 'package:meu_app/src/core/services/dio_service.dart';
import 'package:meu_app/src/core/utils/logger.dart';

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
      // Se há erro de conectividade, usar dados mock como fallback
      if (e.type == DioExceptionType.connectionError || 
          e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        AppLogger.warning('API não disponível, usando dados mock como fallback');
        return _getMockCases();
      }
      
      // Melhor tratamento de erro Dio para outros casos
      if (e.response != null) {
        throw Exception('Erro HTTP ${e.response!.statusCode}: ${e.response!.data}');
      } else {
        throw Exception('Erro de rede ao buscar casos: ${e.message}');
      }
    } catch (e) {
      // Fallback para qualquer outro erro não previsto
      AppLogger.error('Erro inesperado na API, usando dados mock', error: e);
      return _getMockCases();
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
      // Se há erro de conectividade, usar dados mock como fallback
      if (e.type == DioExceptionType.connectionError || 
          e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        AppLogger.warning('API não disponível, usando caso mock como fallback');
        return _getMockCaseById(caseId);
      }
      
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
      // Fallback para qualquer outro erro não previsto
      AppLogger.error('Erro inesperado na API, usando caso mock', error: e);
      return _getMockCaseById(caseId);
    }
  }

  // Dados mock para fallback quando a API não está disponível
  List<Case> _getMockCases() {
    return [
      CaseModel(
        id: 'mock-case-1',
        title: 'Caso de Exemplo - Trabalhista',
        status: 'Em Andamento',
        createdAt: DateTime.now().subtract(const Duration(days: 15)),
        lawyerName: 'Dr. João Silva',
        lawyerId: 'mock-lawyer-1',
        lawyer: const LawyerInfo(
          avatarUrl: 'https://ui-avatars.com/api/?name=Joao+Silva&background=3B82F6&color=fff',
          name: 'Dr. João Silva',
          specialty: 'Trabalhista',
          unreadMessages: 2,
          createdDate: '2024-12-15',
          pendingDocsText: '1 documento pendente',
        ),
      ),
      CaseModel(
        id: 'mock-case-2',
        title: 'Processo Civil - Consumidor',
        status: 'Aguardando',
        createdAt: DateTime.now().subtract(const Duration(days: 8)),
        lawyerName: 'Dra. Maria Santos',
        lawyerId: 'mock-lawyer-2',
        lawyer: const LawyerInfo(
          avatarUrl: 'https://ui-avatars.com/api/?name=Maria+Santos&background=10B981&color=fff',
          name: 'Dra. Maria Santos',
          specialty: 'Civil e Consumidor',
          unreadMessages: 0,
          createdDate: '2024-12-22',
          pendingDocsText: 'Nenhum documento pendente',
        ),
      ),
      CaseModel(
        id: 'mock-case-3',
        title: 'Consultoria Empresarial',
        status: 'Concluído',
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        lawyerName: 'Dr. Carlos Oliveira',
        lawyerId: 'mock-lawyer-3',
        lawyer: const LawyerInfo(
          avatarUrl: 'https://ui-avatars.com/api/?name=Carlos+Oliveira&background=F59E0B&color=fff',
          name: 'Dr. Carlos Oliveira',
          specialty: 'Empresarial',
          unreadMessages: 0,
          createdDate: '2024-12-01',
          pendingDocsText: 'Caso finalizado',
        ),
      ),
    ];
  }

  Case _getMockCaseById(String caseId) {
    final mockCases = _getMockCases();
    
    // Tentar encontrar o caso específico
    try {
      return mockCases.firstWhere((caso) => caso.id == caseId);
    } catch (e) {
      // Se não encontrar, retornar o primeiro caso como padrão
      return mockCases.first;
    }
  }
} 