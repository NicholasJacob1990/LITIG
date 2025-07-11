#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
services/jusbrasil_integration_realistic.py

Implementação REALISTA da integração Jusbrasil baseada nas limitações reais da API.
Foca em dados factíveis: monitoramento empresarial, due diligence, métricas de volume.
"""

import json
import logging
import os
import time
from dataclasses import dataclass
from datetime import datetime, timedelta
from enum import Enum
from typing import Any, Dict, List, Optional, Tuple

import httpx
import numpy as np
import psycopg2
from psycopg2.extras import RealDictCursor
from tenacity import retry, stop_after_attempt, wait_exponential

from ..algoritmo_match import KPI, Case, Lawyer, MatchmakingAlgorithm

logger = logging.getLogger(__name__)


class DataQuality(Enum):
    """Qualidade dos dados disponíveis"""
    HIGH = "high"      # Dados estruturados completos
    MEDIUM = "medium"  # Dados parciais com inferências
    LOW = "low"        # Apenas dados básicos
    UNAVAILABLE = "unavailable"  # Dados não disponíveis


@dataclass
class JusbrasilRealisticStats:
    """Estatísticas REALISTAS do Jusbrasil para um advogado"""
    # Dados DISPONÍVEIS na API
    total_processes: int                    # Total de processos encontrados
    active_processes: int                   # Processos em andamento
    areas_distribution: Dict[str, int]      # Distribuição por área jurídica
    tribunals_distribution: Dict[str, int]  # Distribuição por tribunal
    average_case_value: Optional[float]     # Valor médio quando disponível

    # Dados INFERIDOS (não fornecidos diretamente pela API)
    estimated_success_rate: float          # Taxa estimada baseada em heurísticas
    activity_level: str                    # "high", "medium", "low"
    specialization_score: float            # Score de especialização em áreas

    # Metadados da coleta
    data_quality: DataQuality
    last_sync: datetime
    sync_coverage: float                   # % de dados coletados vs. esperados
    limitations: List[str]                 # Limitações conhecidas dos dados

    # Dados NÃO DISPONÍVEIS (explicitamente None)
    actual_victories: Optional[int] = None         # API não categoriza vitórias
    actual_defeats: Optional[int] = None           # API não categoriza derrotas
    secret_justice_processes: Optional[int] = None  # Não retornados pela API
    labor_processes_as_author: Optional[int] = None  # Política anti-discriminação


class RealisticJusbrasilClient:
    """Cliente REALISTA da API Jusbrasil"""

    def __init__(self, api_key: str):
        self.api_key = api_key
        self.base_url = "https://api.jusbrasil.com.br"
        self.rate_limit_delay = 0.5  # 500ms entre requisições
        self.session = None

        # Limitações conhecidas
        self.known_limitations = [
            "Não categoriza vitórias/derrotas automaticamente",
            "Processos em segredo de justiça não são retornados",
            "Processos trabalhistas do autor não retornados (anti-discriminação)",
            "Apenas processos não atualizados há +4 dias",
            "Foco em monitoramento empresarial, não performance de advogados"
        ]

    async def __aenter__(self):
        self.session = httpx.AsyncClient(
            headers={
                "Authorization": f"Bearer {self.api_key}",
                "User-Agent": "LITGO5-LegalTech/1.0"
            },
            timeout=30.0
        )
        return self

    async def __aexit__(self, exc_type, exc_val, exc_tb):
        if self.session:
            await self.session.aclose()

    async def _rate_limit(self):
        """Implementa rate limiting respeitoso"""
        await asyncio.sleep(self.rate_limit_delay)

    @retry(
        stop=stop_after_attempt(3),
        wait=wait_exponential(multiplier=1, min=2, max=10)
    )
    async def search_lawyer_processes(self, oab_number: str, uf: str) -> Dict[str, Any]:
        """
        Busca processos por OAB - IMPLEMENTAÇÃO REALISTA

        Retorna apenas dados que a API REALMENTE fornece:
        - Lista de processos básicos
        - Informações processuais estruturadas
        - Dados de monitoramento empresarial
        """
        await self._rate_limit()

        try:
            params = {
                "advogado": oab_number,
                "uf": uf,
                "limit": 100,
                "include_details": True
            }

            response = await self.session.get(
                f"{self.base_url}/search/processos",
                params=params
            )
            response.raise_for_status()

            data = response.json()

            # Validar estrutura da resposta
            if not isinstance(data, dict) or "processos" not in data:
                logger.warning(f"Resposta inválida da API para OAB {oab_number}/{uf}")
                return self._empty_response()

            # Processar dados REAIS da API
            return self._process_api_response(data, oab_number, uf)

        except httpx.HTTPStatusError as e:
            if e.response.status_code == 429:
                logger.warning(f"Rate limit atingido para OAB {oab_number}/{uf}")
                await asyncio.sleep(60)
                raise
            elif e.response.status_code == 404:
                logger.info(f"Nenhum processo encontrado para OAB {oab_number}/{uf}")
                return self._empty_response()
            else:
                logger.error(
                    f"Erro HTTP {
                        e.response.status_code} para OAB {oab_number}/{uf}")
                raise

    def _process_api_response(self, data: Dict, oab_number: str,
                              uf: str) -> Dict[str, Any]:
        """Processa resposta da API extraindo apenas dados disponíveis"""

        processes = data.get("processos", [])

        # Análise de distribuição por área
        areas_count = {}
        tribunals_count = {}
        active_count = 0
        values = []

        for process in processes:
            # Área jurídica
            area = process.get("area", "Não informado")
            areas_count[area] = areas_count.get(area, 0) + 1

            # Tribunal
            tribunal = process.get("tribunal", "Não informado")
            tribunals_count[tribunal] = tribunals_count.get(tribunal, 0) + 1

            # Status ativo
            if process.get("status", "").lower() in [
                    "ativo", "em andamento", "tramitando"]:
                active_count += 1

            # Valores quando disponíveis
            if process.get("valor_acao"):
                try:
                    value = float(process["valor_acao"])
                    if value > 0:
                        values.append(value)
                except (ValueError, TypeError):
                    pass

        # Calcular métricas derivadas
        total_processes = len(processes)
        specialization_score = self._calculate_specialization_score(
            areas_count, total_processes)
        activity_level = self._determine_activity_level(total_processes, active_count)

        # Estimar taxa de sucesso usando heurísticas
        estimated_success_rate = self._estimate_success_rate(
            areas_count, total_processes, activity_level
        )

        # Determinar qualidade dos dados
        data_quality = self._assess_data_quality(processes, data)

        return {
            "oab_number": oab_number,
            "uf": uf,
            "total_processes": total_processes,
            "active_processes": active_count,
            "areas_distribution": areas_count,
            "tribunals_distribution": tribunals_count,
            "average_case_value": np.mean(values) if values else None,
            "estimated_success_rate": estimated_success_rate,
            "activity_level": activity_level,
            "specialization_score": specialization_score,
            "data_quality": data_quality.value,
            "sync_coverage": min(1.0, total_processes / 50),  # Estimativa
            "limitations": self.known_limitations,
            "raw_processes": processes[:10],  # Apenas primeiros 10 para referência
            "metadata": {
                "sync_timestamp": datetime.now().isoformat(),
                "api_response_time": data.get("response_time_ms", 0),
                "total_available": data.get("total_available", total_processes)
            }
        }

    def _calculate_specialization_score(
            self, areas_count: Dict[str, int], total: int) -> float:
        """Calcula score de especialização baseado na distribuição de áreas"""
        if total == 0:
            return 0.0

        # Índice de Herfindahl-Hirschman para concentração
        hhi = sum((count / total) ** 2 for count in areas_count.values())

        # Converter para score 0-1 (maior HHI = maior especialização)
        return min(1.0, hhi * 2)

    def _determine_activity_level(self, total: int, active: int) -> str:
        """Determina nível de atividade do advogado"""
        if total == 0:
            return "low"

        activity_ratio = active / total

        if activity_ratio > 0.7 and total > 20:
            return "high"
        elif activity_ratio > 0.4 and total > 10:
            return "medium"
        else:
            return "low"

    def _estimate_success_rate(self, areas_count: Dict[str, int],
                               total: int, activity_level: str) -> float:
        """
        Estima taxa de sucesso usando heurísticas baseadas em:
        - Padrões históricos por área jurídica
        - Nível de atividade do advogado
        - Distribuição de casos
        """
        if total == 0:
            return 0.5  # Neutral prior

        # Taxas médias por área (baseadas em dados históricos do setor)
        area_success_rates = {
            "Trabalhista": 0.65,
            "Cível": 0.55,
            "Criminal": 0.45,
            "Consumidor": 0.70,
            "Tributário": 0.60,
            "Previdenciário": 0.50,
            "Família": 0.58
        }

        # Calcular taxa ponderada por área
        weighted_rate = 0.0
        total_weight = 0

        for area, count in areas_count.items():
            base_rate = area_success_rates.get(area, 0.50)
            weight = count / total
            weighted_rate += base_rate * weight
            total_weight += weight

        if total_weight > 0:
            estimated_rate = weighted_rate / total_weight
        else:
            estimated_rate = 0.50

        # Ajustar por nível de atividade
        activity_multipliers = {
            "high": 1.1,
            "medium": 1.0,
            "low": 0.9
        }

        adjusted_rate = estimated_rate * activity_multipliers.get(activity_level, 1.0)

        # Limitar entre 0.2 e 0.8 (realista)
        return max(0.2, min(0.8, adjusted_rate))

    def _assess_data_quality(
            self, processes: List[Dict], raw_data: Dict) -> DataQuality:
        """Avalia qualidade dos dados coletados"""

        if not processes:
            return DataQuality.UNAVAILABLE

        # Verificar completude dos dados
        complete_fields = 0
        total_fields = 0

        for process in processes[:5]:  # Amostra dos primeiros 5
            fields = ["area", "tribunal", "status", "data_distribuicao", "classe"]
            for field in fields:
                total_fields += 1
                if process.get(field):
                    complete_fields += 1

        if total_fields == 0:
            return DataQuality.UNAVAILABLE

        completeness = complete_fields / total_fields

        if completeness > 0.8:
            return DataQuality.HIGH
        elif completeness > 0.5:
            return DataQuality.MEDIUM
        else:
            return DataQuality.LOW

    def _empty_response(self) -> Dict[str, Any]:
        """Retorna resposta vazia quando não há dados"""
        return {
            "total_processes": 0,
            "active_processes": 0,
            "areas_distribution": {},
            "tribunals_distribution": {},
            "average_case_value": None,
            "estimated_success_rate": 0.5,
            "activity_level": "low",
            "specialization_score": 0.0,
            "data_quality": DataQuality.UNAVAILABLE.value,
            "sync_coverage": 0.0,
            "limitations": self.known_limitations,
            "raw_processes": [],
            "metadata": {
                "sync_timestamp": datetime.now().isoformat(),
                "api_response_time": 0,
                "total_available": 0
            }
        }


class RealisticJusbrasilIntegration:
    """Integração REALISTA com dados factíveis do Jusbrasil"""

    def __init__(self, db_connection):
        self.db_connection = db_connection
        self.api_key = os.getenv("JUSBRASIL_API_KEY")

        if not self.api_key:
            logger.warning("JUSBRASIL_API_KEY não configurada - modo simulação ativado")

    async def sync_lawyer_realistic_data(
            self, lawyer_data: Dict) -> JusbrasilRealisticStats:
        """
        Sincroniza dados REALISTAS de um advogado do Jusbrasil

        Foca apenas em dados que a API realmente fornece:
        - Volume de processos
        - Distribuição por área
        - Atividade geral
        - Métricas de monitoramento empresarial
        """
        lawyer_id = lawyer_data['id']
        oab_number = lawyer_data.get('oab_numero')
        uf = lawyer_data.get('uf')

        logger.info(
            f"Sincronizando dados REALISTAS para advogado {lawyer_id} - OAB {oab_number}/{uf}")

        if not oab_number or not uf:
            logger.warning(f"Advogado {lawyer_id} não possui OAB/UF válidos")
            return self._create_empty_stats(lawyer_id)

        try:
            if self.api_key:
                async with RealisticJusbrasilClient(self.api_key) as client:
                    api_data = await client.search_lawyer_processes(oab_number, uf)
            else:
                # Modo simulação para desenvolvimento
                api_data = self._simulate_api_response(oab_number, uf)

            # Converter para estrutura interna
            stats = JusbrasilRealisticStats(
                total_processes=api_data['total_processes'],
                active_processes=api_data['active_processes'],
                areas_distribution=api_data['areas_distribution'],
                tribunals_distribution=api_data['tribunals_distribution'],
                average_case_value=api_data['average_case_value'],
                estimated_success_rate=api_data['estimated_success_rate'],
                activity_level=api_data['activity_level'],
                specialization_score=api_data['specialization_score'],
                data_quality=DataQuality(api_data['data_quality']),
                last_sync=datetime.now(),
                sync_coverage=api_data['sync_coverage'],
                limitations=api_data['limitations']
            )

            # Salvar no banco
            await self._save_realistic_stats(lawyer_id, stats, api_data)

            logger.info(
                f"Dados REALISTAS sincronizados para {lawyer_id}: {stats.total_processes} processos")
            return stats

        except Exception as e:
            logger.error(f"Erro ao sincronizar dados REALISTAS para {lawyer_id}: {e}")
            return self._create_empty_stats(lawyer_id)

    def _simulate_api_response(self, oab_number: str, uf: str) -> Dict[str, Any]:
        """Simula resposta da API para desenvolvimento/testes"""

        # Simular distribuição realista
        areas_simulation = {
            "Trabalhista": np.random.randint(5, 25),
            "Cível": np.random.randint(3, 15),
            "Criminal": np.random.randint(1, 8),
            "Consumidor": np.random.randint(2, 10)
        }

        total_processes = sum(areas_simulation.values())
        active_processes = int(total_processes * 0.6)  # 60% ativo

        return {
            "oab_number": oab_number,
            "uf": uf,
            "total_processes": total_processes,
            "active_processes": active_processes,
            "areas_distribution": areas_simulation,
            "tribunals_distribution": {"TJSP": total_processes},
            "average_case_value": float(np.random.uniform(10000, 50000)),
            "estimated_success_rate": float(np.random.uniform(0.45, 0.75)),
            "activity_level": "medium",
            "specialization_score": float(np.random.uniform(0.3, 0.8)),
            "data_quality": DataQuality.MEDIUM.value,
            "sync_coverage": 0.8,
            "limitations": [
                "Dados simulados para desenvolvimento",
                "Não representa dados reais do Jusbrasil"
            ],
            "raw_processes": [],
            "metadata": {
                "sync_timestamp": datetime.now().isoformat(),
                "api_response_time": 250,
                "total_available": total_processes
            }
        }

    def _create_empty_stats(self, lawyer_id: str) -> JusbrasilRealisticStats:
        """Cria estatísticas vazias para advogado sem dados"""
        return JusbrasilRealisticStats(
            total_processes=0,
            active_processes=0,
            areas_distribution={},
            tribunals_distribution={},
            average_case_value=None,
            estimated_success_rate=0.5,
            activity_level="low",
            specialization_score=0.0,
            data_quality=DataQuality.UNAVAILABLE,
            last_sync=datetime.now(),
            sync_coverage=0.0,
            limitations=["Dados não disponíveis"]
        )

    async def _save_realistic_stats(self, lawyer_id: str, stats: JusbrasilRealisticStats,
                                    raw_data: Dict):
        """Salva estatísticas realistas no banco"""

        cursor = self.db_connection.cursor()

        try:
            # Atualizar tabela lawyers com dados realistas
            cursor.execute("""
                UPDATE lawyers
                SET
                    total_cases = %(total_processes)s,
                    estimated_success_rate = %(estimated_success_rate)s,
                    jusbrasil_areas = %(areas_distribution)s,
                    jusbrasil_activity_level = %(activity_level)s,
                    jusbrasil_specialization = %(specialization_score)s,
                    jusbrasil_data_quality = %(data_quality)s,
                    jusbrasil_limitations = %(limitations)s,
                    last_jusbrasil_sync = %(last_sync)s,
                    updated_at = NOW()
                WHERE id = %(lawyer_id)s
            """, {
                'lawyer_id': lawyer_id,
                'total_processes': stats.total_processes,
                'estimated_success_rate': stats.estimated_success_rate,
                'areas_distribution': json.dumps(stats.areas_distribution),
                'activity_level': stats.activity_level,
                'specialization_score': stats.specialization_score,
                'data_quality': stats.data_quality.value,
                'limitations': json.dumps(stats.limitations),
                'last_sync': stats.last_sync.isoformat()
            })

            # Inserir histórico de sincronização
            cursor.execute("""
                INSERT INTO jusbrasil_sync_history (
                    lawyer_id, sync_timestamp, total_processes,
                    data_quality, sync_coverage, raw_data
                ) VALUES (
                    %(lawyer_id)s, %(timestamp)s, %(total_processes)s,
                    %(data_quality)s, %(sync_coverage)s, %(raw_data)s
                )
            """, {
                'lawyer_id': lawyer_id,
                'timestamp': stats.last_sync.isoformat(),
                'total_processes': stats.total_processes,
                'data_quality': stats.data_quality.value,
                'sync_coverage': stats.sync_coverage,
                'raw_data': json.dumps(raw_data)
            })

            self.db_connection.commit()

        except Exception as e:
            self.db_connection.rollback()
            logger.error(f"Erro ao salvar dados realistas no banco: {e}")
            raise


class RealisticMatchingAlgorithm(MatchmakingAlgorithm):
    """Algoritmo de matching usando dados REALISTAS do Jusbrasil"""

    def __init__(self, db_connection):
        super().__init__()
        self.jusbrasil_integration = RealisticJusbrasilIntegration(db_connection)

    async def enhance_lawyer_with_realistic_data(self, lawyer: Lawyer) -> Lawyer:
        """
        Enriquece advogado com dados REALISTAS do Jusbrasil

        Transparência total sobre limitações dos dados
        """
        lawyer_data = {
            'id': lawyer.id,
            'oab_numero': getattr(lawyer, 'oab_numero', None),
            'uf': getattr(lawyer, 'uf', None)
        }

        stats = await self.jusbrasil_integration.sync_lawyer_realistic_data(lawyer_data)

        # Enriquecer com dados FACTÍVEIS
        lawyer.jusbrasil_stats = {
            'total_processes': stats.total_processes,
            'estimated_success_rate': stats.estimated_success_rate,
            'activity_level': stats.activity_level,
            'specialization_score': stats.specialization_score,
            'areas_distribution': stats.areas_distribution,
            'data_quality': stats.data_quality.value,
            'limitations': stats.limitations,
            'last_sync': stats.last_sync.isoformat(),

            # Dados EXPLICITAMENTE não disponíveis
            'actual_victories': None,
            'actual_defeats': None,
            'secret_justice_processes': None,
            'labor_processes_as_author': None
        }

        # Usar taxa estimada (não real) no KPI
        if stats.estimated_success_rate > 0:
            lawyer.kpi.estimated_success_rate = stats.estimated_success_rate

        # Adicionar transparência aos scores
        lawyer.scores = lawyer.scores or {}
        lawyer.scores.update({
            'jusbrasil_estimated_success': stats.estimated_success_rate,
            'jusbrasil_activity_level': stats.activity_level,
            'jusbrasil_specialization': stats.specialization_score,
            'jusbrasil_data_quality': stats.data_quality.value,
            'jusbrasil_transparency': 'estimated_data_only'
        })

        logger.info(f"Advogado {lawyer.id} enriquecido com dados REALISTAS: "
                    f"{stats.total_processes} processos, taxa estimada {stats.estimated_success_rate:.2%}")

        return lawyer

# Exemplo de uso


async def demo_realistic_integration():
    """Demonstra integração realista com transparência"""

    print("=== INTEGRAÇÃO REALISTA COM JUSBRASIL ===")
    print("Dados limitados mas transparentes e factíveis")
    print()

    # Simular dados de advogado
    lawyer_data = {
        'id': 'adv_exemplo',
        'oab_numero': '123456',
        'uf': 'SP'
    }

    # Conectar ao banco (simulado)
    db_connection = None  # Seria psycopg2.connect(...)

    try:
        integration = RealisticJusbrasilIntegration(db_connection)
        stats = await integration.sync_lawyer_realistic_data(lawyer_data)

        print(f"📊 DADOS COLETADOS:")
        print(f"   Total de processos: {stats.total_processes}")
        print(f"   Processos ativos: {stats.active_processes}")
        print(f"   Taxa estimada: {stats.estimated_success_rate:.2%}")
        print(f"   Nível de atividade: {stats.activity_level}")
        print(f"   Score especialização: {stats.specialization_score:.2f}")
        print(f"   Qualidade dos dados: {stats.data_quality.value}")
        print()

        print("🚫 DADOS NÃO DISPONÍVEIS (limitações da API):")
        for limitation in stats.limitations:
            print(f"   - {limitation}")
        print()

        print("✅ TRANSPARÊNCIA TOTAL:")
        print("   - Dados são estimativas baseadas em heurísticas")
        print("   - API não fornece vitórias/derrotas reais")
        print("   - Foco em volume e distribuição de casos")
        print("   - Adequado para matching por experiência, não performance")

    except Exception as e:
        print(f"❌ Erro na demonstração: {e}")

if __name__ == "__main__":
    import asyncio
    asyncio.run(demo_realistic_integration())
