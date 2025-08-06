import 'package:dio/dio.dart';
import 'package:meu_app/src/features/cases/domain/entities/case.dart';
import 'package:meu_app/src/features/cases/domain/entities/lawyer_info.dart';
import 'package:meu_app/src/features/cases/data/models/case_model.dart';
import 'package:meu_app/src/features/firms/domain/entities/law_firm.dart';

abstract class CasesRemoteDataSource {
  Future<List<Case>> getMyCases({String? userId, String? userRole});
  Future<Case> getCaseById(String caseId);
}

class CasesRemoteDataSourceImpl implements CasesRemoteDataSource {
  final Dio dio;

  CasesRemoteDataSourceImpl({required this.dio});

  @override
  Future<List<Case>> getMyCases({String? userId, String? userRole}) async {
    try {
      // ############ SOLUÇÃO TEMPORÁRIA ############
      // O endpoint /cases/my-cases está retornando 404 no backend.
      // Para destravar o fluxo, vamos chamar um caso específico e retorná-lo
      // dentro de uma lista, simulando o comportamento esperado.
              // USANDO SOLUÇÃO TEMPORÁRIA: Chamando um caso mock filtrado por tipo de usuário
        return _getMockCasesForUser(userId: userId, userRole: userRole);
      // ##########################################
    } on DioException catch (e) {
      // Se há erro de conectividade, usar dados mock como fallback
      if (e.type == DioExceptionType.connectionError || 
          e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
                 // API não disponível, usando dados mock como fallback
        return _getMockCasesForUser(userId: userId, userRole: userRole);
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
      return _getMockCasesForUser(userId: userId, userRole: userRole);
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

  // Filtragem de casos por tipo de usuário
  List<Case> _getMockCasesForUser({String? userId, String? userRole}) {
    print('=== DEBUGGING DATA SOURCE ===');
    print('Filtering cases for userId: $userId, userRole: $userRole');
    
    final baseCases = _getBaseCases();
    final specificCases = _getSpecificCasesForUserRole(userRole);
    final allCases = [...baseCases, ...specificCases];
    
    print('Base cases count: ${baseCases.length}');
    print('Specific cases count: ${specificCases.length}');
    print('Total cases count: ${allCases.length}');
    
    // Filtrar casos que não devem aparecer para determinados tipos de usuário
    final filteredCases = _filterCasesForUserRole(allCases, userRole);
    
    print('Filtered cases count: ${filteredCases.length}');
    for (final caseItem in filteredCases) {
      print('Case: ${caseItem.id} - ${caseItem.title} - allocationType: ${caseItem.allocationType}');
    }
    
    return filteredCases;
  }

  // Casos base visíveis para todos os advogados
  List<Case> _getBaseCases() {
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

  // Casos específicos baseados no tipo de usuário
  List<Case> _getSpecificCasesForUserRole(String? userRole) {
    print('Getting specific cases for userRole: $userRole');
    
    switch (userRole) {
      case 'lawyer_firm_member':
        // APENAS advogados associados da firma veem casos delegados
        print('Returning delegated cases for lawyer_firm_member');
        return _getDelegatedCases();
      case 'lawyer_platform_associate':
        // Super associados veem casos da plataforma
        print('Returning platform cases for lawyer_platform_associate');
        return _getPlatformCases();
      case 'lawyer_individual':
        // Advogados autônomos veem casos individuais
        print('Returning individual cases for lawyer_individual');
        return _getIndividualCases();
      case 'lawyer_office':
        // Escritórios veem casos de escritório
        print('Returning office cases for lawyer_office');
        return _getOfficeCases();
      default:
        print('No specific cases for userRole: $userRole');
        return [];
    }
  }
  
  /// Filtrar casos que não devem aparecer para determinados tipos de usuário
  List<Case> _filterCasesForUserRole(List<Case> allCases, String? userRole) {
    print('Filtering ${allCases.length} cases for userRole: $userRole');
    
    return allCases.where((caseItem) {
      // Para clientes - filtrar todos os casos com allocation types específicos
      if (userRole == null || 
          userRole == 'client' || 
          userRole == 'client_pf' || 
          userRole == 'client_pj') {
        // Clientes não devem ver casos com allocation types específicos de advogados
        final shouldInclude = caseItem.allocationType == null || 
               caseItem.allocationType == 'direct' ||
               caseItem.allocationType == 'assigned';
        print('Client case ${caseItem.id}: ${shouldInclude ? "INCLUDE" : "EXCLUDE"} (allocationType: ${caseItem.allocationType})');
        return shouldInclude;
      }
      
      // Para casos delegados - APENAS lawyer_firm_member pode ver
      if (caseItem.allocationType == 'internal_delegation') {
        final shouldInclude = userRole == 'lawyer_firm_member';
        print('Delegated case ${caseItem.id}: ${shouldInclude ? "INCLUDE" : "EXCLUDE"} for $userRole');
        return shouldInclude;
      }
      
      // Para casos de plataforma - apenas lawyer_platform_associate
      if (caseItem.allocationType == 'platform_match') {
        final shouldInclude = userRole == 'lawyer_platform_associate';
        print('Platform case ${caseItem.id}: ${shouldInclude ? "INCLUDE" : "EXCLUDE"} for $userRole');
        return shouldInclude;
      }
      
      // Para outros casos, mostrar para todos os advogados (mas não para clientes)
      final isLawyer = (
        userRole.startsWith('lawyer_') || 
        userRole == 'firm'
      );
      print('Other case ${caseItem.id}: ${isLawyer ? "INCLUDE" : "EXCLUDE"} for $userRole');
      return isLawyer;
    }).toList();
  }

  // Casos delegados - apenas para advogados associados
  List<Case> _getDelegatedCases() {
    return [
      CaseModel(
        id: 'delegated-case-1',
        title: 'Divórcio Consensual - DELEGADO',
        status: 'Em Andamento',
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        lawyerName: 'Dr. João Silva (Supervisor)',
        lawyerId: 'mock-lawyer-supervisor',
        caseType: 'litigation',
        allocationType: 'internal_delegation',
        isPremium: false,
        lawyer: const LawyerInfo(
          avatarUrl: 'https://ui-avatars.com/api/?name=Supervisor&background=FF6B6B&color=fff',
          name: 'Dr. João Silva (Supervisor)',
          specialty: 'Família',
          unreadMessages: 1,
          createdDate: '2025-01-20',
          pendingDocsText: 'Delegado por Dr. Silva - Prazo: 15 dias',
          plan: 'PRO',
        ),
      ),
      CaseModel(
        id: 'delegated-case-2',
        title: 'Ação Trabalhista - Horas Extras (DELEGADO)',
        status: 'Aguardando',
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
        lawyerName: 'Dra. Maria Costa (Supervisora)',
        lawyerId: 'mock-lawyer-supervisor-2',
        caseType: 'litigation',
        allocationType: 'internal_delegation',
        isPremium: false,
        lawyer: const LawyerInfo(
          avatarUrl: 'https://ui-avatars.com/api/?name=Maria+Costa&background=FF6B6B&color=fff',
          name: 'Dra. Maria Costa (Supervisora)',
          specialty: 'Trabalhista',
          unreadMessages: 0,
          createdDate: '2025-01-22',
          pendingDocsText: 'Delegado por Dra. Costa - Análise inicial',
          plan: 'PRO',
        ),
      ),
    ];
  }

  // Casos da plataforma - apenas para super associados
  List<Case> _getPlatformCases() {
    return [
      CaseModel(
        id: 'platform-case-1',
        title: 'Consultoria Tributária - Match 95%',
        status: 'Em Andamento',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        lawyerName: 'Sistema (Match Automático)',
        lawyerId: 'platform-match',
        caseType: 'consultancy',
        allocationType: 'platform_match',
        isPremium: true,
        lawyer: const LawyerInfo(
          avatarUrl: 'https://ui-avatars.com/api/?name=Platform&background=6366F1&color=fff',
          name: 'Sistema (Match Automático)',
          specialty: 'Tributário',
          unreadMessages: 2,
          createdDate: '2025-01-23',
          pendingDocsText: 'Match: 95% - Cliente Premium',
          plan: 'PLATFORM',
        ),
      ),
    ];
  }

  // Casos individuais - apenas para advogados autônomos
  List<Case> _getIndividualCases() {
    return [
      CaseModel(
        id: 'individual-case-1',
        title: 'Inventário - Cliente Direto',
        status: 'Em Andamento',
        createdAt: DateTime.now().subtract(const Duration(days: 7)),
        lawyerName: 'Cliente Direto',
        lawyerId: 'direct-client',
        caseType: 'litigation',
        allocationType: 'direct_client',
        isPremium: false,
        lawyer: const LawyerInfo(
          avatarUrl: 'https://ui-avatars.com/api/?name=Direct&background=10B981&color=fff',
          name: 'Cliente Direto',
          specialty: 'Sucessões',
          unreadMessages: 0,
          createdDate: '2025-01-18',
          pendingDocsText: 'Cliente captado diretamente',
          plan: 'FREE',
        ),
      ),
    ];
  }

  // Casos de escritório - apenas para escritórios
  List<Case> _getOfficeCases() {
    return [
      CaseModel(
        id: 'office-case-1',
        title: 'Fusão Empresarial - Parceria',
        status: 'Em Andamento',
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
        lawyerName: 'Parceria Estratégica',
        lawyerId: 'partnership',
        caseType: 'CORPORATE',
        allocationType: 'partnership',
        isPremium: true,
        lawyer: const LawyerInfo(
          avatarUrl: 'https://ui-avatars.com/api/?name=Partnership&background=F59E0B&color=fff',
          name: 'Parceria Estratégica',
          specialty: 'Empresarial',
          unreadMessages: 1,
          createdDate: '2025-01-15',
          pendingDocsText: 'Caso obtido via parceria',
          plan: 'PRO',
        ),
      ),
    ];
  }

  Case _getMockCaseById(String caseId) {
    // Buscar em todos os casos (base + específicos)
    final allCases = [
      ..._getBaseCases(),
      ..._getDelegatedCases(),
      ..._getPlatformCases(),
      ..._getIndividualCases(),
      ..._getOfficeCases(),
    ];
    
    // Tentar encontrar o caso específico
    try {
      return allCases.firstWhere((caso) => caso.id == caseId);
    } catch (e) {
      // Se não encontrar, retornar o primeiro caso como padrão
      return allCases.first;
    }
  }
} 