#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
services/hybrid_integration.py

Serviço de integração híbrida para dados jurídicos.
- Orquestra a coleta de dados, priorizando a API do Escavador.
- Usa a API do Jusbrasil como fallback para garantir maior cobertura.
- Unifica e enriquece os dados de ambas as fontes.
"""

import asyncio
import logging
from dataclasses import dataclass
from datetime import datetime
from typing import Any, Dict, List, Optional

# Imports locais dos serviços de integração
from escavador_integration import EscavadorClient, OutcomeClassifier
from jusbrasil_integration_realistic import (
    JusbrasilRealisticAPI,
    JusbrasilRealisticService,
)

logger = logging.getLogger(__name__)


@dataclass
class HybridLawyerStats:
    """Estrutura de dados unificada para as estatísticas do advogado."""
    # Fonte primária dos dados ('escavador' ou 'jusbrasil')
    primary_source: str

    # Dados de Performance (prioritariamente do Escavador)
    total_cases: int
    victories: int
    defeats: int
    ongoing: int
    real_success_rate: float
    analysis_confidence: float

    # Métricas de Experiência (combinadas de ambas as fontes)
    area_distribution: Dict[str, int]
    tribunal_distribution: Dict[str, int]
    activity_level: str
    specialization_score: float

    # Metadados
    data_quality: str  # "high", "medium", "low", "unavailable"
    last_sync: datetime
    limitations: List[str]


class HybridLegalDataService:
    """
    Orquestra a coleta e unificação de dados das APIs do Escavador e Jusbrasil.
    """

    def __init__(self, db_connection, escavador_api_key: str,
                 jusbrasil_api_key: Optional[str] = None):
        if not escavador_api_key:
            raise ValueError("A API Key do Escavador é obrigatória.")

        self.db_connection = db_connection
        self.escavador_client = EscavadorClient(api_key=escavador_api_key)
        self.jusbrasil_integration = JusbrasilRealisticService(
            db_connection, api_key=jusbrasil_api_key)

        logger.info("Serviço de Integração Híbrida inicializado (Escavador + Jusbrasil).")

    async def get_unified_lawyer_data(self, lawyer_data: Dict) -> HybridLawyerStats:
        """
        Obtém os dados unificados de um advogado, priorizando o Escavador.

        Args:
            lawyer_data: Dicionário com 'id', 'oab_numero', 'uf' do advogado.

        Returns:
            Um objeto HybridLawyerStats com os dados combinados.
        """
        oab_number = lawyer_data.get('oab_numero')
        state = lawyer_data.get('uf')

        if not oab_number or not state:
            logger.warning(
                f"Advogado {
                    lawyer_data.get('id')} sem OAB/UF para consulta.")
            return self._create_empty_stats()

        # 1. Tenta buscar dados do Escavador (fonte primária)
        escavador_data = await self.escavador_client.get_lawyer_processes(oab_number, state)

        # 2. Se o Escavador retornar dados suficientes, use-os como primários
        if escavador_data and escavador_data.get("total_cases", 0) > 0:
            logger.info(
                f"Dados primários para OAB {oab_number}/{state} obtidos do Escavador.")
            return self._build_stats_from_escavador(escavador_data)

        # 3. Se não, busca no Jusbrasil como fallback
        logger.warning(
            f"Sem dados do Escavador para {oab_number}/{state}. Usando Jusbrasil como fallback.")
        jusbrasil_stats = await self.jusbrasil_integration.sync_lawyer_realistic_data(lawyer_data)

        if jusbrasil_stats and jusbrasil_stats.total_processes > 0:
            logger.info(
                f"Dados de fallback para OAB {oab_number}/{state} obtidos do Jusbrasil.")
            return self._build_stats_from_jusbrasil(jusbrasil_stats)

        # 4. Se nenhuma fonte retornou dados
        logger.error(
            f"Nenhuma fonte de dados encontrou informações para OAB {oab_number}/{state}.")
        return self._create_empty_stats()

    def _build_stats_from_escavador(
            self, escavador_data: Dict[str, Any]) -> HybridLawyerStats:
        """Cria a estrutura de dados unificada a partir dos dados do Escavador."""
        return HybridLawyerStats(
            primary_source='escavador',
            total_cases=escavador_data.get('total_cases', 0),
            victories=escavador_data.get('victories', 0),
            defeats=escavador_data.get('defeats', 0),
            ongoing=escavador_data.get('ongoing', 0),
            real_success_rate=escavador_data.get('success_rate', 0.0),
            analysis_confidence=0.8,  # Confiança alta por ser baseado em NLP
            area_distribution=escavador_data.get('area_distribution', {}),
            tribunal_distribution={},  # O SDK v2 não detalha tribunal por processo
            activity_level="high",  # Placeholder
            specialization_score=0.8,  # Placeholder
            data_quality="high", # Assuming DataQuality.HIGH.value is "high"
            last_sync=datetime.now(),
            limitations=[]
        )

    def _build_stats_from_jusbrasil(self, jusbrasil_stats) -> HybridLawyerStats:
        """Cria a estrutura de dados unificada a partir do fallback do Jusbrasil."""
        return HybridLawyerStats(
            primary_source='jusbrasil',
            total_cases=jusbrasil_stats.total_processes,
            victories=0,  # Dado indisponível
            defeats=0,  # Dado indisponível
            ongoing=jusbrasil_stats.active_processes,
            real_success_rate=jusbrasil_stats.estimated_success_rate,
            analysis_confidence=0.3,  # Confiança baixa (estimativa)
            area_distribution=jusbrasil_stats.areas_distribution,
            tribunal_distribution=jusbrasil_stats.tribunals_distribution,
            activity_level=jusbrasil_stats.activity_level,
            specialization_score=jusbrasil_stats.specialization_score,
            data_quality=jusbrasil_stats.data_quality.value,
            last_sync=jusbrasil_stats.last_sync,
            limitations=jusbrasil_stats.limitations
        )

    def _create_empty_stats(self) -> HybridLawyerStats:
        """Retorna estatísticas vazias quando nenhum dado é encontrado."""
        return HybridLawyerStats(
            primary_source='none', total_cases=0, victories=0, defeats=0,
            ongoing=0, real_success_rate=0.0, analysis_confidence=0.0,
            area_distribution={}, tribunal_distribution={}, activity_level='low',
            specialization_score=0.0, data_quality="unavailable",
            last_sync=datetime.now(), limitations=["Nenhuma fonte de dados disponível."]
        )

# Exemplo de uso do serviço híbrido


async def main():
    """Função para demonstrar o uso do serviço híbrido."""
    print("🚀 Testando Serviço de Integração Híbrida...")

    # Chaves das APIs (necessário ter no .env)
    escavador_key = os.getenv("ESCAVADOR_API_KEY")
    jusbrasil_key = os.getenv("JUSBRASIL_API_KEY")

    if not escavador_key:
        print("❌ Chave da API do Escavador não encontrada. Defina ESCAVADOR_API_KEY no .env")
        return

    # Dados do advogado para teste
    lawyer_info = {
        'id': 'adv_test_hybrid',
        'oab_numero': os.getenv("TEST_OAB_NUMBER", "12345"),  # Use OAB real para teste
        'uf': os.getenv("TEST_OAB_STATE", "SP")
    }

    # Simular conexão com o banco
    db_conn = None

    service = HybridLegalDataService(
        db_connection=db_conn,
        escavador_api_key=escavador_key,
        jusbrasil_api_key=jusbrasil_key
    )

    print(f"Buscando dados para OAB: {lawyer_info['oab_numero']}/{lawyer_info['uf']}")
    final_stats = await service.get_unified_lawyer_data(lawyer_info)

    print("\n✅ DADOS UNIFICADOS COLETADOS:")
    print(f"   - Fonte Primária: {final_stats.primary_source.upper()}")
    print(f"   - Total de Casos: {final_stats.total_cases}")
    print(f"   - Taxa de Sucesso: {final_stats.real_success_rate:.2%}")
    print(f"   - Confiança da Análise: {final_stats.analysis_confidence:.2%}")
    print(f"   - Nível de Atividade: {final_stats.activity_level}")
    print(f"   - Qualidade dos Dados: {final_stats.data_quality}")

    if final_stats.limitations:
        print("\n   - Limitações Aplicáveis:")
        for limit in final_stats.limitations:
            print(f"     * {limit}")

if __name__ == "__main__":
    asyncio.run(main())
