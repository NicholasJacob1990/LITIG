import '../entities/contextual_case_data.dart';
import '../entities/allocation_type.dart';

/// Repository abstrato para gerenciar dados contextuais de casos
/// 
/// Segue os princípios de Clean Architecture, definindo contratos
/// para as operações contextuais sem dependências de implementação.
abstract class ContextualCaseRepository {
  /// Busca dados contextuais completos de um caso
  /// 
  /// Retorna todas as informações necessárias para renderizar
  /// a interface contextual baseada no perfil do usuário.
  Future<Map<String, dynamic>> getContextualCaseData({
    required String caseId,
    required String userId,
  });

  /// Busca apenas os KPIs contextuais de um caso
  /// 
  /// Útil para atualizações parciais ou widgets específicos
  /// que precisam apenas dos indicadores principais.
  Future<List<ContextualKPI>> getContextualKPIs({
    required String caseId,
    required String userId,
  });

  /// Busca ações contextuais disponíveis para um caso
  /// 
  /// Retorna as ações primárias e secundárias baseadas no
  /// perfil do usuário e tipo de alocação do caso.
  Future<ContextualActions> getContextualActions({
    required String caseId,
    required String userId,
  });

  /// Define o tipo de alocação de um caso
  /// 
  /// Permite alterar como um caso é gerenciado (delegação interna,
  /// match direto, parceria, etc.) e atualizar metadados relacionados.
  Future<void> setCaseAllocation({
    required String caseId,
    required AllocationType allocationType,
    required Map<String, dynamic> metadata,
  });

  /// Busca casos agrupados por tipo de alocação
  /// 
  /// Útil para dashboards e visões organizadas por contexto
  /// de trabalho do usuário (casos delegados, matches diretos, etc.).
  Future<Map<String, List<Map<String, dynamic>>>> getCasesByAllocation({
    required String userId,
  });

  /// Atualiza dados contextuais de um caso
  /// 
  /// Permite modificar informações específicas do contexto
  /// como KPIs, metadados ou configurações especiais.
  Future<void> updateContextualData({
    required String caseId,
    required Map<String, dynamic> contextualUpdates,
  });

  /// Busca histórico de mudanças de alocação
  /// 
  /// Para auditoria e rastreabilidade das mudanças
  /// de contexto de um caso ao longo do tempo.
  Future<List<Map<String, dynamic>>> getAllocationHistory({
    required String caseId,
  });

  /// Valida se uma alocação é permitida
  /// 
  /// Verifica regras de negócio antes de permitir
  /// mudanças de contexto (permissões, estado do caso, etc.).
  Future<bool> validateAllocationChange({
    required String caseId,
    required String userId,
    required AllocationType newAllocationType,
  });
} 

/// Repository abstrato para gerenciar dados contextuais de casos
/// 
/// Segue os princípios de Clean Architecture, definindo contratos
/// para as operações contextuais sem dependências de implementação.
abstract class ContextualCaseRepository {
  /// Busca dados contextuais completos de um caso
  /// 
  /// Retorna todas as informações necessárias para renderizar
  /// a interface contextual baseada no perfil do usuário.
  Future<Map<String, dynamic>> getContextualCaseData({
    required String caseId,
    required String userId,
  });

  /// Busca apenas os KPIs contextuais de um caso
  /// 
  /// Útil para atualizações parciais ou widgets específicos
  /// que precisam apenas dos indicadores principais.
  Future<List<ContextualKPI>> getContextualKPIs({
    required String caseId,
    required String userId,
  });

  /// Busca ações contextuais disponíveis para um caso
  /// 
  /// Retorna as ações primárias e secundárias baseadas no
  /// perfil do usuário e tipo de alocação do caso.
  Future<ContextualActions> getContextualActions({
    required String caseId,
    required String userId,
  });

  /// Define o tipo de alocação de um caso
  /// 
  /// Permite alterar como um caso é gerenciado (delegação interna,
  /// match direto, parceria, etc.) e atualizar metadados relacionados.
  Future<void> setCaseAllocation({
    required String caseId,
    required AllocationType allocationType,
    required Map<String, dynamic> metadata,
  });

  /// Busca casos agrupados por tipo de alocação
  /// 
  /// Útil para dashboards e visões organizadas por contexto
  /// de trabalho do usuário (casos delegados, matches diretos, etc.).
  Future<Map<String, List<Map<String, dynamic>>>> getCasesByAllocation({
    required String userId,
  });

  /// Atualiza dados contextuais de um caso
  /// 
  /// Permite modificar informações específicas do contexto
  /// como KPIs, metadados ou configurações especiais.
  Future<void> updateContextualData({
    required String caseId,
    required Map<String, dynamic> contextualUpdates,
  });

  /// Busca histórico de mudanças de alocação
  /// 
  /// Para auditoria e rastreabilidade das mudanças
  /// de contexto de um caso ao longo do tempo.
  Future<List<Map<String, dynamic>>> getAllocationHistory({
    required String caseId,
  });

  /// Valida se uma alocação é permitida
  /// 
  /// Verifica regras de negócio antes de permitir
  /// mudanças de contexto (permissões, estado do caso, etc.).
  Future<bool> validateAllocationChange({
    required String caseId,
    required String userId,
    required AllocationType newAllocationType,
  });
} 