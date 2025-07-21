/// Constantes e mapeamentos para tipos de casos jurídicos
class CaseTypeConstants {
  static const String consultancy = 'consultancy';
  static const String litigation = 'litigation';
  static const String contract = 'contract';
  static const String compliance = 'compliance';
  static const String dueDiligence = 'due_diligence';
  static const String ma = 'ma';
  static const String ip = 'ip';
  static const String corporate = 'corporate';
  static const String custom = 'custom';
  
  // Status específicos por tipo (mapeamento visual)
  static const Map<String, String> consultancyStatusMapping = {
    'OPEN': 'Briefing Inicial',
    'IN_PROGRESS': 'Em Desenvolvimento',
    'WAITING_CLIENT': 'Aguardando Cliente',
    'REVIEW': 'Em Revisão',
    'DELIVERED': 'Entregue',
    'CLOSED': 'Concluído',
  };
  
  static const Map<String, String> litigationStatusMapping = {
    'OPEN': 'Em Andamento',
    'IN_PROGRESS': 'Em Andamento',
    'WAITING_COURT': 'Aguardando Decisão',
    'CLOSED': 'Concluído',
  };
  
  static const Map<String, String> contractStatusMapping = {
    'OPEN': 'Análise Inicial',
    'IN_PROGRESS': 'Em Redação',
    'REVIEW': 'Em Revisão',
    'NEGOTIATION': 'Em Negociação',
    'SIGNED': 'Assinado',
    'CLOSED': 'Concluído',
  };
  
  static const Map<String, String> complianceStatusMapping = {
    'OPEN': 'Análise Inicial',
    'IN_PROGRESS': 'Em Adequação',
    'AUDIT': 'Em Auditoria',
    'REMEDIATION': 'Em Correção',
    'COMPLIANT': 'Conforme',
    'CLOSED': 'Concluído',
  };
  
  static const Map<String, String> dueDiligenceStatusMapping = {
    'OPEN': 'Planejamento',
    'IN_PROGRESS': 'Em Investigação',
    'REVIEW': 'Em Análise',
    'REPORT': 'Elaborando Relatório',
    'DELIVERED': 'Entregue',
    'CLOSED': 'Concluído',
  };
  
  static const Map<String, String> maStatusMapping = {
    'OPEN': 'Estruturação',
    'IN_PROGRESS': 'Em Negociação',
    'DUE_DILIGENCE': 'Due Diligence',
    'DOCUMENTATION': 'Documentação',
    'CLOSING': 'Fechamento',
    'CLOSED': 'Concluído',
  };
  
  static const Map<String, String> ipStatusMapping = {
    'OPEN': 'Análise Inicial',
    'IN_PROGRESS': 'Em Processamento',
    'EXAMINATION': 'Em Exame',
    'GRANTED': 'Concedido',
    'DENIED': 'Negado',
    'CLOSED': 'Concluído',
  };
  
  static const Map<String, String> corporateStatusMapping = {
    'OPEN': 'Análise Inicial',
    'IN_PROGRESS': 'Em Desenvolvimento',
    'BOARD_REVIEW': 'Revisão Diretoria',
    'APPROVED': 'Aprovado',
    'IMPLEMENTED': 'Implementado',
    'CLOSED': 'Concluído',
  };
  
  // Método para obter mapeamento por tipo
  static Map<String, String> getStatusMapping(String? caseType) {
    switch (caseType) {
      case consultancy:
        return consultancyStatusMapping;
      case litigation:
        return litigationStatusMapping;
      case contract:
        return contractStatusMapping;
      case compliance:
        return complianceStatusMapping;
      case dueDiligence:
        return dueDiligenceStatusMapping;
      case ma:
        return maStatusMapping;
      case ip:
        return ipStatusMapping;
      case corporate:
        return corporateStatusMapping;
      default:
        return litigationStatusMapping; // Fallback padrão
    }
  }
  
  // Lista de todos os tipos disponíveis
  static const List<String> allTypes = [
    consultancy,
    litigation,
    contract,
    compliance,
    dueDiligence,
    ma,
    ip,
    corporate,
    custom,
  ];
  
  // Descrições detalhadas para cada tipo
  static const Map<String, String> typeDescriptions = {
    consultancy: 'Projetos de consultoria, pareceres e análises preventivas',
    litigation: 'Processos judiciais, litígios e representação em tribunal',
    contract: 'Elaboração, revisão e negociação de contratos',
    compliance: 'Adequação normativa, auditoria e conformidade regulatória',
    dueDiligence: 'Análise de riscos, investigações e due diligence',
    ma: 'Fusões, aquisições e reestruturações societárias',
    ip: 'Propriedade intelectual, patentes, marcas e direitos autorais',
    corporate: 'Governança corporativa, ESG e questões societárias',
    custom: 'Casos personalizados e demandas específicas',
  };
}