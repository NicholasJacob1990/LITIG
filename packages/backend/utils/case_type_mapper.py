# backend/utils/case_type_mapper.py
"""
Mapeamento entre áreas jurídicas identificadas pela triagem e tipos de caso do frontend.
"""

from typing import Dict, Optional

# Mapeamento principal entre área jurídica e tipo de caso
AREA_TO_CASE_TYPE_MAPPING: Dict[str, str] = {
    # Áreas contenciosas → litigation
    "Trabalhista": "litigation",
    "Criminal": "litigation",
    "Consumidor": "litigation",
    "Família": "litigation",
    "Imobiliário": "litigation",
    "Ambiental": "litigation",
    "Bancário": "litigation",
    "Saúde": "litigation",
    
    # Áreas consultivas → consultancy
    "Empresarial": "consultancy",
    "Tributário": "consultancy",
    "Administrativo": "consultancy",
    "Previdenciário": "consultancy",
    
    # Áreas específicas
    "Propriedade Intelectual": "ip",
    "Digital": "consultancy",
    
    # Áreas corporativas especiais
    "M&A": "ma",
    "Fusões e Aquisições": "ma",
    "Due Diligence": "due_diligence",
    "Compliance": "compliance",
    "Governança Corporativa": "corporate",
    
    # Contratos
    "Contratos": "contract",
    "Contratual": "contract",
    
    # Padrão
    "Civil": "litigation",
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
    
    Args:
        area: Área jurídica principal (ex: "Trabalhista", "Empresarial")
        subarea: Subárea específica (ex: "Rescisão", "M&A")
        keywords: Lista de palavras-chave extraídas
        summary: Resumo do caso
        nature: Natureza do caso (Preventivo/Contencioso)
    
    Returns:
        Tipo de caso para o frontend (ex: "litigation", "consultancy")
    """
    # 1. Verificar mapeamento direto por área
    if area and area in AREA_TO_CASE_TYPE_MAPPING:
        base_type = AREA_TO_CASE_TYPE_MAPPING[area]
    else:
        base_type = "litigation"  # Padrão
    
    # 2. Verificar subárea para casos especiais
    if subarea:
        subarea_lower = subarea.lower()
        if "m&a" in subarea_lower or "fusão" in subarea_lower or "aquisição" in subarea_lower:
            return "ma"
        elif "due diligence" in subarea_lower:
            return "due_diligence"
        elif "compliance" in subarea_lower:
            return "compliance"
        elif "contrato" in subarea_lower:
            return "contract"
    
    # 3. Verificar palavras-chave para refinamento
    if keywords:
        text_to_analyze = " ".join(keywords).lower()
    elif summary:
        text_to_analyze = summary.lower()
    else:
        text_to_analyze = ""
    
    for keyword, case_type in KEYWORD_TO_CASE_TYPE_MAPPING.items():
        if keyword in text_to_analyze:
            return case_type
    
    # 4. Usar natureza como critério final
    if nature and nature in NATURE_TO_CASE_TYPE_PREFERENCE:
        # Se a natureza conflita com a área, priorizar a natureza
        nature_type = NATURE_TO_CASE_TYPE_PREFERENCE[nature]
        if base_type == "litigation" and nature == "Preventivo":
            return "consultancy"
        elif base_type == "consultancy" and nature == "Contencioso":
            return "litigation"
    
    return base_type


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
    }
    return descriptions.get(case_type, "Caso Jurídico")