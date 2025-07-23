"""
Adaptadores para APIs de dados de maturidade profissional.

Este módulo implementa o padrão Adapter para desacoplar o algoritmo de matching
das especificidades de APIs externas (Unipile, etc.). Cada adaptador converte
os dados brutos de uma API específica para o formato padronizado interno.
"""

import os
from typing import Dict, Any, Callable

try:
    from algoritmo_match import ProfessionalMaturityData
except ImportError:
    # Fallback para execução standalone
    from algoritmo_match import ProfessionalMaturityData


def _adapt_from_unipile(raw_data: Dict[str, Any]) -> ProfessionalMaturityData:
    """Adapta os dados brutos da API Unipile para o nosso formato interno.
    
    Args:
        raw_data: Dados brutos retornados pela API Unipile
        
    Returns:
        ProfessionalMaturityData: Estrutura de dados padronizada
    """
    if not raw_data:
        return ProfessionalMaturityData()  # Retorna o objeto padrão se não houver dados

    return ProfessionalMaturityData(
        experience_years=raw_data.get("linkedin_experience_years", 0.0),
        network_strength=raw_data.get("linkedin_connections", 0),
        reputation_signals=raw_data.get("linkedin_recommendations_received", 0),
        responsiveness_hours=raw_data.get("email_responsiveness_hours", 48.0)
    )


def _adapt_from_linkedin_api(raw_data: Dict[str, Any]) -> ProfessionalMaturityData:
    """Adapta os dados brutos de uma API LinkedIn direta para o nosso formato.
    
    Exemplo de estrutura esperada:
    {
        "profile": {
            "experience_total_years": 12,
            "connections_count": 800,
            "recommendations_received": 15
        },
        "activity": {
            "avg_response_time_hours": 8
        }
    }
    """
    if not raw_data:
        return ProfessionalMaturityData()

    profile = raw_data.get("profile", {})
    activity = raw_data.get("activity", {})

    return ProfessionalMaturityData(
        experience_years=profile.get("experience_total_years", 0.0),
        network_strength=profile.get("connections_count", 0),
        reputation_signals=profile.get("recommendations_received", 0),
        responsiveness_hours=activity.get("avg_response_time_hours", 48.0)
    )


def _adapt_from_custom_api(raw_data: Dict[str, Any]) -> ProfessionalMaturityData:
    """Adapta os dados brutos de uma API customizada para o nosso formato.
    
    Exemplo de estrutura esperada:
    {
        "professional_data": {
            "xp_total_anos": 12,
            "conexoes_total": 800,
            "recomendacoes": 15
        },
        "communication_kpis": {
            "tempo_medio_resposta_h": 8
        }
    }
    """
    if not raw_data:
        return ProfessionalMaturityData()

    prof_data = raw_data.get("professional_data", {})
    comm_kpis = raw_data.get("communication_kpis", {})

    return ProfessionalMaturityData(
        experience_years=prof_data.get("xp_total_anos", 0.0),
        network_strength=prof_data.get("conexoes_total", 0),
        reputation_signals=prof_data.get("recomendacoes", 0),
        responsiveness_hours=comm_kpis.get("tempo_medio_resposta_h", 48.0)
    )


def _adapt_from_mock_data(raw_data: Dict[str, Any]) -> ProfessionalMaturityData:
    """Adaptador para dados de teste/mock (útil para testes unitários).
    
    Retorna dados fixos para testes, independente da entrada.
    """
    return ProfessionalMaturityData(
        experience_years=10.0,
        network_strength=500,
        reputation_signals=8,
        responsiveness_hours=12.0
    )


# Mapeia a string de configuração para a função adaptadora correspondente
ADAPTER_MAP = {
    "unipile": _adapt_from_unipile,
    "linkedin_api": _adapt_from_linkedin_api,
    "custom_api": _adapt_from_custom_api,
    "mock": _adapt_from_mock_data,
}


def get_maturity_adapter() -> Callable[[Dict[str, Any]], ProfessionalMaturityData]:
    """Lê a configuração do ambiente e retorna a função adaptadora correta.
    
    Variável de ambiente: MATURITY_PROVIDER
    Valores suportados: unipile, linkedin_api, custom_api, mock
    Default: unipile
    
    Returns:
        Callable: Função adaptadora correspondente ao provider configurado
    """
    provider_name = os.getenv("MATURITY_PROVIDER", "unipile").lower()
    adapter_func = ADAPTER_MAP.get(provider_name, _adapt_from_unipile)
    
    # Log da configuração escolhida para auditoria
    import logging
    logger = logging.getLogger(__name__)
    logger.info(f"Maturity adapter configured: {provider_name}")
    
    return adapter_func


def convert_raw_to_maturity_data(raw_data: Dict[str, Any]) -> ProfessionalMaturityData:
    """Função de conveniência que usa o adaptador configurado para converter dados brutos.
    
    Esta é a função que deve ser usada pelo resto do sistema para converter
    dados brutos em estrutura padronizada.
    
    Args:
        raw_data: Dados brutos de qualquer API
        
    Returns:
        ProfessionalMaturityData: Estrutura de dados padronizada
    """
    adapter = get_maturity_adapter()
    return adapter(raw_data) 