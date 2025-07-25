# backend/utils/case_type_mapper.py
"""
Mapeamento entre áreas jurídicas identificadas pela triagem e tipos de caso do frontend.
"""

from typing import Dict, Optional

# Mapeamento principal entre área jurídica e tipo de caso
AREA_TO_CASE_TYPE_MAPPING: Dict[str, str] = {
    # Áreas que tendem ao contencioso → litigation
    "Trabalhista": "litigation",
    "Criminal": "litigation",
    "Consumidor": "litigation",
    "Família": "litigation",
    "Imobiliário": "litigation",
    "Ambiental": "litigation",
    "Bancário": "litigation",
    "Saúde": "litigation",
    "Civil": "litigation",
    
    # Áreas que tendem à consultoria → consultancy
    "Empresarial": "consultancy",
    "Tributário": "consultancy",
    "Administrativo": "consultancy",
    "Previdenciário": "consultancy",
    "Digital": "consultancy",
    
    # Mapeamentos diretos para tipos específicos
    "Propriedade Intelectual": "ip",
    "Startups": "corporate",
    "M&A": "ma",
    "Fusões e Aquisições": "ma",
    "Due Diligence": "due_diligence",
    "Compliance": "compliance",
    "Contratos": "contract",
    "Contratual": "contract",
    
    # Contencioso administrativo e regulatório (pré-judicial)
    "PROCON": "administrative_litigation",
    "CARF": "administrative_litigation",
    "Conselhos de Contribuintes": "administrative_litigation",
    "ANATEL": "regulatory_litigation",
    "ANVISA": "regulatory_litigation",
    "ANEEL": "regulatory_litigation",
    # ... (outras agências)

    # NOVO: Mapeamento para MARCS - O tipo será refinado por palavras-chave
    "Arbitragem": "alternative_dispute_resolution",
    "Mediação": "alternative_dispute_resolution",
    "Conciliação": "alternative_dispute_resolution",
}

# Mapeamento baseado em palavras-chave no texto
KEYWORD_TO_CASE_TYPE_MAPPING: Dict[str, str] = {
    # Palavras que indicam consultoria
    "consultoria": "consultancy",
    "parecer": "consultancy",
    "orientação": "consultancy",
    "análise preventiva": "consultancy",
    "planejamento": "consultancy",
    
    # Palavras que indicam compliance
    "compliance": "compliance",
    "conformidade": "compliance",
    "regulatório": "compliance",
    "adequação": "compliance",
    
    # Palavras que indicam due diligence
    "due diligence": "due_diligence",
    "auditoria": "due_diligence",
    "investigação": "due_diligence",
    "análise de riscos": "due_diligence",
    
    # Palavras que indicam M&A
    "fusão": "ma",
    "aquisição": "ma",
    "incorporação": "ma",
    "reestruturação": "ma",
    
    # Palavras que indicam contratos
    "contrato": "contract",
    "acordo": "contract",
    "cláusula": "contract",
    "negociação": "contract",
    
    # Palavras que indicam propriedade intelectual
    "marca": "ip",
    "patente": "ip",
    "direito autoral": "ip",
    "propriedade intelectual": "ip",
    
    # Palavras que indicam corporativo
    "governança": "corporate",
    "societário": "corporate",
    "assembleia": "corporate",
    "conselho": "corporate",
    
    # NOVO: Palavras que indicam contencioso pré-judicial administrativo
    "procon": "administrative_litigation",
    "carf": "administrative_litigation",
    "conselho de contribuintes": "administrative_litigation",
    "tribunal administrativo": "administrative_litigation",
    "processo administrativo": "administrative_litigation",
    "recurso administrativo": "administrative_litigation",
    "defesa administrativa": "administrative_litigation",
    "impugnação administrativa": "administrative_litigation",
    
    # NOVO: Agências reguladoras
    "anatel": "regulatory_litigation", 
    "anvisa": "regulatory_litigation",
    "aneel": "regulatory_litigation",
    "anp": "regulatory_litigation",
    "ancine": "regulatory_litigation",
    "anac": "regulatory_litigation",
    "antaq": "regulatory_litigation",
    "antt": "regulatory_litigation",
    "ans": "regulatory_litigation",
    "ana": "regulatory_litigation",
    "agência reguladora": "regulatory_litigation",
    "processo regulatório": "regulatory_litigation",
    
    # NOVO: Processos tributários pré-judiciais
    "receita federal": "tax_administrative",
    "receita estadual": "tax_administrative", 
    "receita municipal": "tax_administrative",
    "auto de infração": "tax_administrative",
    "notificação fiscal": "tax_administrative",
    "processo administrativo fiscal": "tax_administrative",
    
    # EXPANSÃO: Direito Digital Completo
    "marco civil da internet": "consultancy",
    "neutralidade da rede": "consultancy",
    "direito de imagem digital": "litigation",
    "uso indevido de imagem": "litigation",
    "contrato eletrônico": "contract",
    "assinatura digital": "contract",
    "cibersegurança": "consultancy",
    "segurança da informação": "consultancy",
    "data breach": "litigation",
    "bitcoin": "consultancy",
    "criptomoeda": "consultancy",
    "nft": "consultancy",
    "blockchain": "consultancy",
    "direito ao esquecimento": "litigation",
    "remoção de conteúdo": "litigation",
    "fake news": "litigation",
    "notícias falsas": "litigation",
    "cyberbullying": "litigation",
    "assédio digital": "litigation",
    "pirataria digital": "litigation",
    "download ilegal": "litigation",
    "jogos online": "consultancy",
    "apostas online": "consultancy",
    
    # EXPANSÃO: Direito do Consumidor Completo
    "vício do produto": "litigation",
    "produto defeituoso": "litigation",
    "vício do serviço": "litigation",
    "serviço mal prestado": "litigation",
    "propaganda enganosa": "litigation",
    "publicidade falsa": "litigation",
    "propaganda abusiva": "litigation",
    "spc": "litigation",
    "serasa": "litigation",
    "negativação": "litigation",
    "plano de saúde": "litigation",
    "negativa de cobertura": "litigation",
    "telefonia": "litigation",
    "operadora": "litigation",
    "tv por assinatura": "litigation",
    "tarifa bancária": "litigation",
    "conta corrente": "litigation",
    "superendividamento": "consultancy",
    "renegociação de dívidas": "consultancy",
    "compra online": "litigation",
    "loja virtual": "litigation",
    "direito de arrependimento": "litigation",
    "marketplace": "litigation",
    "energia elétrica": "litigation",
    "serviços essenciais": "litigation",
    "seguradora": "litigation",
    "sinistro": "litigation",
    "transporte público": "litigation",
    "uber": "litigation",
    "99": "litigation",
    "delivery": "litigation",
    "ifood": "litigation",
    "segurança alimentar": "litigation",
    "mensalidade": "litigation",
    "agência de turismo": "litigation",
    "voo cancelado": "litigation",
    "concessionária": "litigation",
    "financiamento de veículo": "litigation",
    "construtora": "litigation",
    "apartamento na planta": "litigation",
    "cartão de crédito": "litigation",
    "fraude no cartão": "litigation",
    "empréstimo": "litigation",
    "crediário": "litigation",
    "juros abusivos": "litigation",
    
    # EXPANSÃO: Direitos das Startups - Ecossistema Completo
    "startup": "corporate",
    "startups": "corporate", 
    "empresa de tecnologia": "corporate",
    "tech company": "corporate",
    "inovação": "consultancy",
    "empreendedorismo": "consultancy",
    "ecossistema de inovação": "consultancy",
    
    # Investimentos e Venture Capital
    "venture capital": "ma",
    "vc": "ma",
    "private equity": "ma",
    "pe": "ma",
    "fundo de investimento": "ma",
    "rodada de investimento": "ma",
    "seed": "ma",
    "series a": "ma",
    "series b": "ma",
    "round": "ma",
    
    # Estruturação Societária
    "constituição de empresa": "corporate",
    "alteração contratual": "contract",
    "estatuto social": "corporate",
    "acordo de sócios": "contract",
    "governança corporativa": "corporate",
    
    # Contratos de Investment
    "term sheet": "contract",
    "sha": "contract",
    "investment agreement": "contract",
    "acordo de investimento": "contract",
    "contrato de investimento": "contract",
    "shareholders agreement": "contract",
    
    # Equity e Stock Options
    "equity": "corporate",
    "stock options": "corporate",
    "stock option plan": "corporate",
    "participação societária": "corporate",
    "vesting": "corporate",
    "cliff": "corporate",
    "distribuição de quotas": "corporate",
    
    # Propriedade Intelectual Tech
    "patent": "ip",
    "patente": "ip",
    "software": "ip",
    "trade secret": "ip",
    "segredo comercial": "ip",
    "marca de tecnologia": "ip",
    
    # Marco Legal das Startups
    "marco legal das startups": "compliance",
    "lei 14195": "compliance",
    "lei complementar 182": "compliance",
    "empresa simples de crédito": "compliance",
    "inova simples": "compliance",
    
    # Compliance e Regulatório
    "sandbox regulatório": "compliance",
    "regulamentação de startups": "compliance",
    "cvm": "compliance",
    "bacen": "compliance",
    
    # Aceleradoras e Programas
    "aceleradora": "contract",
    "incubadora": "contract",
    "programa de aceleração": "contract",
    "corporate venture": "ma",
    "venture builder": "corporate",
    
    # Due Diligence Tech
    "due diligence": "due_diligence",
    "dd": "due_diligence",
    "auditoria legal": "due_diligence",
    "revisão legal": "due_diligence",
    "legal review": "due_diligence",
    
    # Crowdfunding
    "crowdfunding": "compliance",
    "financiamento coletivo": "compliance",
    "equity crowdfunding": "compliance",
    "captação pública": "compliance",
    
    # Parcerias Estratégicas
    "joint venture": "ma",
    "parceria estratégica": "contract",
    "partnership": "contract",
    "aliança estratégica": "contract",
    
    # Tributário Startups
    "regime tributário": "consultancy",
    "lucro real": "consultancy",
    "lucro presumido": "consultancy",
    "simples nacional": "consultancy",
    "incentivos fiscais": "consultancy",
    "lei do bem": "consultancy",
    
    # Trabalhista Tech
    "contratação tech": "consultancy",
    "remote work": "consultancy",
    "trabalho remoto": "consultancy",
    "equity compensation": "corporate",
    "pj ou clt": "consultancy",
    
    # Contratos Tecnológicos
    "saas": "contract",
    "api": "contract",
    "software license": "contract",
    "licenciamento": "contract",
    "development agreement": "contract",
    "msa": "contract",
    "sow": "contract",
    "statement of work": "contract",
    
    # Exit Strategy
    "ipo": "ma",
    "exit": "ma",
    "trade sale": "ma",
    "liquidação": "corporate",
    "desinvestimento": "ma",
    
    # Corporate Governance
    "conselho de administração": "corporate",
    "board": "corporate",
    "comitês": "corporate",
    "corporate governance": "corporate",
    
    # ESG e Sustentabilidade
    "esg": "compliance",
    "sustentabilidade": "compliance",
    "impacto social": "compliance",
    "empresa b": "corporate",
    "bcorp": "corporate",
    "impact investing": "ma",
    
    # International Expansion
    "expansão internacional": "corporate",
    "flip": "corporate",
    "subsidiária": "corporate",
    "offshore": "corporate",
    "cross border": "corporate",
    "international expansion": "corporate",
    
    # Fintech
    "fintech": "compliance",
    "pagamentos": "compliance",
    "pix": "compliance",
    "open banking": "compliance",
    "arranjo de pagamento": "compliance",
    "instituição de pagamento": "compliance",
    
    # Healthtech
    "healthtech": "compliance",
    "saúde digital": "compliance",
    "telemedicina": "compliance",
    "anvisa": "compliance",
    "dispositivo médico": "compliance",
    "software médico": "compliance",

    # NOVO: Palavras-chave para MARCS (Arbitragem, Mediação, Conciliação)
    "arbitragem": "alternative_dispute_resolution",
    "arbitral": "alternative_dispute_resolution",
    "árbitro": "alternative_dispute_resolution",
    "câmara de arbitragem": "alternative_dispute_resolution",
    "tribunal arbitral": "alternative_dispute_resolution",
    "cláusula compromissória": "alternative_dispute_resolution",
    "convenção de arbitragem": "alternative_dispute_resolution",
    "compromisso arbitral": "alternative_dispute_resolution",
    "sentença arbitral": "alternative_dispute_resolution",
    "execução de sentença arbitral": "alternative_dispute_resolution",
    "mediação": "alternative_dispute_resolution",
    "mediador": "alternative_dispute_resolution",
    "termo de mediação": "alternative_dispute_resolution",
    "sessão de mediação": "alternative_dispute_resolution",
    "conciliação": "alternative_dispute_resolution",
    "conciliador": "alternative_dispute_resolution",
    "audiência de conciliação": "alternative_dispute_resolution",
    "termo de conciliação": "alternative_dispute_resolution",
    "dispute board": "alternative_dispute_resolution",
    "comitê de resolução de disputas": "alternative_dispute_resolution",
    "transação tributária": "alternative_dispute_resolution",
    "negociação de dívida fiscal": "alternative_dispute_resolution",
    "CAM-CCBC": "alternative_dispute_resolution",
    "Ciesp/Fiesp": "alternative_dispute_resolution",
    "FGV Câmara": "alternative_dispute_resolution",

    # EXPANSÃO: Erro Médico e Serviços de Saúde como Direito do Consumidor
    "erro médico": "litigation",
    "negligência médica": "litigation",
    "imperícia": "litigation",
    "imprudência médica": "litigation",
    "iatrogenia": "litigation",
    "responsabilidade civil médica": "litigation",
    "dano moral médico": "litigation",
    "indenização médica": "litigation",
    "falha médica": "litigation",
    "cirurgia plástica": "litigation",
    "procedimento estético": "litigation",
    "botox": "litigation",
    "preenchimento": "litigation",
    "lipoaspiração": "litigation",
    "harmonização facial": "litigation",
    "convênio médico": "litigation",
    "operadora de saúde": "litigation",
    "negativa de cobertura": "litigation",
    "reajuste abusivo": "litigation",
    "hospital": "litigation",
    "clínica": "litigation",
    "consultório": "litigation",
    "internação": "litigation",
    "diagnóstico errado": "litigation",
    "cirurgia": "litigation",
    "procedimento médico": "litigation",
}

# Mapeamento baseado na natureza (preventivo vs contencioso)
NATURE_TO_CASE_TYPE_PREFERENCE: Dict[str, str] = {
    "Preventivo": "consultancy",
    "Contencioso": "litigation",
}


def map_area_to_case_type(
    area: Optional[str], 
    subarea: Optional[str] = None, 
    keywords: Optional[list] = None,
    summary: Optional[str] = None,
    nature: Optional[str] = None
) -> str:
    """
    Mapeia a área jurídica identificada pela triagem para o tipo de caso do frontend.
    A lógica foi refatorada para priorizar a natureza do caso (Contencioso vs. Consultivo)
    e tratar todas as áreas do direito como potencialmente duais.
    """
    
    # Prepara o texto para análise de palavras-chave
    text_to_analyze = " ".join(keywords or []).lower()
    if summary:
        text_to_analyze += " " + summary.lower()
    if subarea:
        text_to_analyze += " " + subarea.lower()

    # 1. Mapeamento de alta prioridade para tipos de caso específicos (não apenas lit/cons)
    #    Iteramos de forma reversa para que palavras-chave mais específicas
    #    (ex: 'processo administrativo fiscal') sejam detectadas antes das genéricas.
    specific_case_types = [
        "ma", "due_diligence", "compliance", "ip", "corporate", "contract",
        "administrative_litigation", "regulatory_litigation", "tax_administrative"
    ]
    for keyword, case_type in reversed(list(KEYWORD_TO_CASE_TYPE_MAPPING.items())):
        if case_type in specific_case_types and keyword in text_to_analyze:
            return case_type
    
    # 2. Prioridade máxima para a natureza do caso (Contencioso vs. Preventivo)
    if nature and nature in NATURE_TO_CASE_TYPE_PREFERENCE:
        return NATURE_TO_CASE_TYPE_PREFERENCE[nature]

    # 3. Se a natureza não for informada, inferir a partir de palavras-chave
    consultancy_keywords = ["consultoria", "parecer", "preventiva", "orientação", "planejamento", "análise"]
    for keyword in consultancy_keywords:
        if keyword in text_to_analyze:
            return "consultancy"
    
    # Palavras-chave que fortemente indicam litígio
    litigation_keywords = ["processo", "petição", "sentença", "audiência", "recurso", "liminar", "execução", "ação judicial", "defesa"]
    for keyword in litigation_keywords:
        if keyword in text_to_analyze:
            return "litigation"
    
    # 4. Como fallback, usar o mapeamento padrão da área
    if area and area in AREA_TO_CASE_TYPE_MAPPING:
        # Este mapeamento agora funciona como um "valor padrão" para a área
        return AREA_TO_CASE_TYPE_MAPPING[area]

    # 5. Padrão final se nada mais for encontrado
    return "litigation"


def get_case_type_description(case_type: str) -> str:
    """
    Retorna uma descrição em português do tipo de caso.
    
    Args:
        case_type: Tipo de caso (ex: "litigation")
    
    Returns:
        Descrição em português
    """
    descriptions = {
        "consultancy": "Consultoria Jurídica",
        "litigation": "Contencioso/Litígio",
        "contract": "Contratos",
        "compliance": "Compliance e Regulatório",
        "due_diligence": "Due Diligence",
        "ma": "Fusões e Aquisições",
        "ip": "Propriedade Intelectual",
        "corporate": "Direito Corporativo",
        "custom": "Personalizado",
        # NOVO: Tipos de contencioso pré-judicial
        "administrative_litigation": "Contencioso Administrativo Pré-Judicial",
        "regulatory_litigation": "Contencioso Regulatório", 
        "tax_administrative": "Contencioso Tributário Administrativo",
        "alternative_dispute_resolution": "Arbitragem, Mediação e Outros Métodos Consensuais",
    }
    return descriptions.get(case_type, "Caso Jurídico")