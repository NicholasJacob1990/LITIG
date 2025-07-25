/// Constantes e mapeamentos para tipos de casos jurídicos
class CaseTypeConstants {
  static const String litigation = 'litigation';
  static const String consultancy = 'consultancy';
  static const String contract = 'contract';
  static const String compliance = 'compliance';
  static const String dueDiligence = 'due_diligence';
  static const String ma = 'ma';
  static const String ip = 'ip';
  static const String corporate = 'corporate';
  static const String custom = 'custom';
  
  // NOVO: Contencioso pré-judicial
  static const String administrativeLitigation = 'administrative_litigation';
  static const String regulatoryLitigation = 'regulatory_litigation';
  static const String taxAdministrative = 'tax_administrative';
  static const String alternativeDisputeResolution = 'alternative_dispute_resolution';

  // Mapeamentos de status para o novo tipo de caso
  static const Map<String, String> adrStatusMapping = {
    'preliminary_analysis': 'Análise Preliminar',
    'negotiation': 'Fase de Negociação',
    'mediation_session': 'Sessão de Mediação',
    'arbitration_hearing': 'Audiência de Arbitragem',
    'drafting_agreement': 'Elaboração do Acordo',
    'awaiting_award': 'Aguardando Sentença Arbitral',
    'settled': 'Acordo Celebrado',
    'award_issued': 'Sentença Proferida',
    'enforcement': 'Fase de Execução',
    'cancelled': 'Cancelado',
  };

  // Status específicos por tipo (mapeamento visual)
  static const Map<String, String> consultancyStatusMapping = {
    'draft': 'Rascunho',
    'in_review': 'Em Análise',
    'under_development': 'Em Desenvolvimento',
    'client_review': 'Revisão do Cliente',
    'finalized': 'Finalizado',
    'delivered': 'Entregue',
    'cancelled': 'Cancelado',
  };

  static const Map<String, String> litigationStatusMapping = {
    'case_analysis': 'Análise do Caso',
    'petition_draft': 'Elaboração da Petição',
    'filed': 'Protocolado',
    'awaiting_decision': 'Aguardando Decisão',
    'in_progress': 'Em Andamento',
    'appeal': 'Recurso',
    'concluded': 'Concluído',
    'archived': 'Arquivado',
  };

  // NOVO: Status para contencioso pré-judicial administrativo
  static const Map<String, String> administrativeLitigationStatusMapping = {
    'preparation': 'Preparação',
    'filed_administrative': 'Protocolado Administrativamente',
    'under_analysis': 'Em Análise no Órgão',
    'awaiting_documents': 'Aguardando Documentos',
    'defense_period': 'Prazo de Defesa',
    'appeal_period': 'Prazo de Recurso',
    'administrative_decision': 'Decisão Administrativa',
    'concluded_favorable': 'Concluído Favorável',
    'concluded_unfavorable': 'Concluído Desfavorável',
    'judicial_appeal': 'Recurso Judicial',
  };

  // NOVO: Status para contencioso regulatório
  static const Map<String, String> regulatoryLitigationStatusMapping = {
    'preparation': 'Preparação',
    'filed_agency': 'Protocolado na Agência',
    'technical_analysis': 'Análise Técnica',
    'public_consultation': 'Consulta Pública',
    'agency_decision': 'Decisão da Agência',
    'compliance_period': 'Prazo de Adequação',
    'appeal_period': 'Prazo de Recurso',
    'concluded': 'Concluído',
    'judicial_appeal': 'Recurso Judicial',
  };

  // NOVO: Status para contencioso tributário administrativo
  static const Map<String, String> taxAdministrativeStatusMapping = {
    'preparation': 'Preparação',
    'filed_tax_authority': 'Protocolado no Fisco',
    'under_analysis': 'Em Análise Fiscal',
    'awaiting_documents': 'Aguardando Documentos',
    'defense_period': 'Prazo de Defesa',
    'first_instance': 'Primeira Instância',
    'appeal_period': 'Prazo de Recurso',
    'second_instance': 'Segunda Instância',
    'concluded_favorable': 'Concluído Favorável',
    'concluded_unfavorable': 'Concluído Desfavorável',
    'judicial_appeal': 'Recurso Judicial',
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

  static Map<String, String> getStatusMappingForType(String caseType) {
    switch (caseType) {
      case litigation:
        return litigationStatusMapping;
      case consultancy:
        return consultancyStatusMapping;
      case administrativeLitigation:
      case regulatoryLitigation:
      case taxAdministrative:
        return administrativeLitigationStatusMapping;
      case alternativeDisputeResolution:
        return adrStatusMapping;
      default:
        return litigationStatusMapping; // fallback
    }
  }
  
  // Lista de todos os tipos disponíveis
  static const List<String> allTypes = [
    litigation,
    consultancy,
    contract,
    compliance,
    dueDiligence,
    ma,
    ip,
    corporate,
    custom,
    administrativeLitigation,
    regulatoryLitigation,
    taxAdministrative,
    alternativeDisputeResolution,
  ];

  // Descrições dos tipos de caso
  static const Map<String, String> typeDescriptions = {
    litigation: 'Processos judiciais e litígios tradicionais',
    consultancy: 'Projetos de consultoria, pareceres e análises preventivas',
    contract: 'Elaboração, revisão e negociação de contratos',
    compliance: 'Adequação regulatória e auditoria de conformidade',
    dueDiligence: 'Análise de riscos e due diligence empresarial',
    ma: 'Fusões, aquisições e reestruturação societária',
    ip: 'Propriedade intelectual, marcas e patentes',
    corporate: 'Direito corporativo e societário',
    custom: 'Casos personalizados conforme necessidade específica',
    administrativeLitigation: 'Contencioso administrativo pré-judicial (PROCON, CARF, Conselhos)',
    regulatoryLitigation: 'Processos em agências reguladoras (ANATEL, ANVISA, etc.)',
    taxAdministrative: 'Processos administrativos tributários (Receitas Federal/Estadual/Municipal)',
    alternativeDisputeResolution: 'Arbitragem, Mediação e Outros Métodos Consensuais',
  };
  
  // NOVO: Subareas específicas para Direito Digital
  static const Map<String, List<String>> digitalSubareas = {
    'Básicas': ['LGPD', 'Crimes Digitais', 'E-commerce', 'Redes Sociais', 'Propriedade Digital'],
    'Avançadas': [
      'Marco Civil da Internet',
      'Direito de Imagem Digital', 
      'Contratos Digitais',
      'Cibersegurança',
      'Criptomoedas',
      'Direito ao Esquecimento',
      'Fake News',
      'Cyberbullying',
      'Pirataria Digital',
      'Jogos Online'
    ]
  };
  
  // NOVO: Subareas específicas para Direito do Consumidor
  static const Map<String, List<String>> consumerSubareas = {
    'Produtos e Serviços': [
      'Garantia',
      'Vício do Produto',
      'Vício do Serviço',
      'Propaganda Enganosa',
      'Propaganda Abusiva'
    ],
    'Serviços Financeiros': [
      'Banco de Dados',
      'Serviços Bancários',
      'Cartões de Crédito', 
      'Financiamentos',
      'Superendividamento'
    ],
    'Serviços Especializados': [
      'Planos de Saúde',
      'Telecomunicações',
      'Seguro',
      'Educação',
      'Turismo'
    ],
    'Comércio e Transporte': [
      'E-commerce Consumidor',
      'Automóveis',
      'Transporte',
      'Alimentação'
    ],
    'Serviços Essenciais': [
      'Serviços Públicos',
      'Imóveis',
      'Cobrança Indevida'
    ],
    'Serviços de Saúde': [
      'Erro Médico',
      'Serviços Médicos',
      'Tratamentos Estéticos',
      'Planos de Saúde'
    ]
  };
  
  // NOVO: Subareas específicas para Direitos das Startups
  static const Map<String, List<String>> startupSubareas = {
    'Investimentos e Captação': [
      'Investimentos e Venture Capital',
      'Contratos de Investment',
      'Equity e Stock Options',
      'Crowdfunding',
      'Exit Strategy'
    ],
    'Estruturação e Governança': [
      'Estruturação Societária',
      'Corporate Governance',
      'Marco Legal das Startups',
      'Compliance e Regulatório'
    ],
    'Propriedade e Tecnologia': [
      'Propriedade Intelectual Tech',
      'Contratos Tecnológicos',
      'Due Diligence Tech'
    ],
    'Parcerias e Crescimento': [
      'Contratos de Aceleração',
      'Parcerias Estratégicas',
      'International Expansion',
      'ESG e Sustentabilidade'
    ],
    'Setores Específicos': [
      'Fintech Regulation',
      'Healthtech Regulation',
      'Tributário Startups',
      'Trabalhista Tech'
    ]
  };
}