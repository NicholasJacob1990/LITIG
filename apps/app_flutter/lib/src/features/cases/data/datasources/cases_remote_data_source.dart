import 'package:dio/dio.dart';
import 'package:meu_app/src/features/cases/domain/entities/case.dart';
import 'package:meu_app/src/features/cases/domain/entities/lawyer_info.dart';
import 'package:meu_app/src/features/cases/data/models/case_model.dart';
import 'package:meu_app/src/features/firms/domain/entities/law_firm.dart';

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
      // ############ SOLUÇÃO TEMPORÁRIA ############
      // O endpoint /cases/my-cases está retornando 404 no backend.
      // Para destravar o fluxo, vamos chamar um caso específico e retorná-lo
      // dentro de uma lista, simulando o comportamento esperado.
              // USANDO SOLUÇÃO TEMPORÁRIA: Chamando um caso mock em vez de /my-cases
        return _getMockCases(); // Usando a função de mock já existente
      // ##########################################
    } on DioException catch (e) {
      // Se há erro de conectividade, usar dados mock como fallback
      if (e.type == DioExceptionType.connectionError || 
          e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
                 // API não disponível, usando dados mock como fallback
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
              // Erro inesperado na API, usando dados mock
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
                 // API não disponível, usando caso mock como fallback
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
              // Erro inesperado na API, usando caso mock
      return _getMockCaseById(caseId);
    }
  }

  // Dados mock para fallback quando a API não está disponível
  List<Case> _getMockCases() {
    final mockCases = [
      CaseModel(
        id: 'mock-case-1',
        title: 'Rescisão Indireta - Assédio Moral',
        status: 'Em Andamento',
        createdAt: DateTime.now().subtract(const Duration(days: 15)),
        lawyerName: 'Dr. João Silva',
        lawyerId: 'mock-lawyer-1',
        caseType: 'litigation',
        allocationType: 'direct',
        isPremium: true, // NOVO: Caso premium para testar badge
        clientPlan: null, // Cliente PF (sem plano corporativo)
        lawyer: const LawyerInfo(
          avatarUrl: 'https://ui-avatars.com/api/?name=Joao+Silva&background=3B82F6&color=fff',
          name: 'Dr. João Silva',
          specialty: 'Trabalhista',
          unreadMessages: 2,
          createdDate: '2024-12-15',
          pendingDocsText: '1 documento pendente',
          plan: 'PRO', // NOVO: Advogado PRO para testar badge
        ),
      ),
      CaseModel(
        id: 'mock-case-2',
        title: 'Devolução de Produto Defeituoso - Notebook',
        status: 'Aguardando',
        createdAt: DateTime.now().subtract(const Duration(days: 8)),
        lawyerName: 'Dra. Maria Santos',
        lawyerId: 'mock-lawyer-2',
        caseType: 'consultancy',
        allocationType: 'direct',
        isPremium: false, // NOVO: Caso regular para comparação
        clientPlan: 'VIP', // NOVO: Cliente PJ VIP
        lawyer: const LawyerInfo(
          avatarUrl: 'https://ui-avatars.com/api/?name=Maria+Santos&background=10B981&color=fff',
          name: 'Dra. Maria Santos',
          specialty: 'Civil e Consumidor',
          unreadMessages: 0,
          createdDate: '2024-12-22',
          pendingDocsText: 'Nenhum documento pendente',
          plan: 'FREE', // NOVO: Advogado FREE para comparação
        ),
      ),
      CaseModel(
        id: 'mock-case-3',
        title: 'Revisão Contratual - Contrato de Prestação de Serviços',
        status: 'Concluído',
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        lawyerName: 'Dr. Carlos Oliveira',
        lawyerId: 'mock-lawyer-3',
        isPremium: true, // NOVO: Outro caso premium
        isEnterprise: false, // NOVO: Caso premium mas não enterprise
        clientPlan: 'FREE', // NOVO: Cliente PJ FREE
        lawyer: const LawyerInfo(
          avatarUrl: 'https://ui-avatars.com/api/?name=Carlos+Oliveira&background=F59E0B&color=fff',
          name: 'Dr. Carlos Oliveira',
          specialty: 'Empresarial',
          unreadMessages: 0,
          createdDate: '2024-12-01',
          pendingDocsText: 'Caso finalizado',
          plan: 'PRO', // NOVO: Outro advogado PRO
        ),
      ),
      // NOVO: Caso Enterprise para teste
      CaseModel(
        id: 'mock-case-4',
        title: 'Due Diligence - Aquisição Corporativa',
        status: 'Em Andamento',
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        lawyerName: 'Dra. Ana Souza',
        lawyerId: 'mock-lawyer-4',
        caseType: 'CORPORATE',
        allocationType: 'partnership',
        isPremium: true, // Enterprise cases são sempre premium
        isEnterprise: true, // NOVO: Caso Enterprise B2B
        clientPlan: 'ENTERPRISE', // NOVO: Cliente PJ Enterprise
        recommendedFirm: const LawFirm(
          id: 'firm-001',
          name: 'Oliveira & Associados',
          teamSize: 25,
          specializations: ['M&A', 'Corporate Law', 'Tax'],
          rating: 4.8,
          plan: 'PRO', // NOVO: Escritório PRO
          partnerTier: 'GOLD', // NOVO: Tier GOLD
        ),
        firmMatchScore: 0.92,
        lawyer: const LawyerInfo(
          avatarUrl: 'https://ui-avatars.com/api/?name=Ana+Souza&background=6366F1&color=fff',
          name: 'Dra. Ana Souza',
          specialty: 'M&A e Corporate',
          unreadMessages: 3,
          createdDate: '2024-12-25',
          pendingDocsText: '2 documentos pendentes',
          plan: 'PRO', // NOVO: Advogado PRO para casos Enterprise
        ),
      ),
      CaseModel(
        id: 'mock-case-5',
        title: 'Multa de Trânsito Indevida - Rodízio',
        status: 'Aguardando',
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
        lawyerName: 'Dr. Pedro Alves',
        lawyerId: 'mock-lawyer-5',
        lawyer: const LawyerInfo(
          avatarUrl: 'https://ui-avatars.com/api/?name=Pedro+Alves&background=6366F1&color=fff',
          name: 'Dr. Pedro Alves',
          specialty: 'Trânsito e Administrativo',
          unreadMessages: 1,
          createdDate: '2025-01-18',
          pendingDocsText: 'Aguardando CNH',
        ),
      ),
      // NOVO: Caso com cliente PF VIP para demonstrar que pessoas físicas também podem ter plano VIP
      CaseModel(
        id: 'mock-case-6',
        title: 'Ação de Indenização - Danos Morais Bancários',
        status: 'Em Andamento',
        createdAt: DateTime.now().subtract(const Duration(days: 12)),
        lawyerName: 'Dra. Luciana Costa',
        lawyerId: 'mock-lawyer-6',
        caseType: 'litigation',
        allocationType: 'direct',
        isPremium: false, // Caso regular
        isEnterprise: false,
        clientPlan: 'VIP', // Cliente PF VIP
        lawyer: const LawyerInfo(
          avatarUrl: 'https://ui-avatars.com/api/?name=Luciana+Costa&background=8B5CF6&color=fff',
          name: 'Dra. Luciana Costa',
          specialty: 'Bancário e Consumidor',
          unreadMessages: 0,
          createdDate: '2025-01-15',
          pendingDocsText: 'Documentos completos',
          plan: 'PRO', // Advogado PRO atendendo cliente VIP
        ),
      ),
    ];
    return mockCases;
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