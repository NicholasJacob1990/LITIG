#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
services/jusbrasil_integration.py

Serviço para integrar o algoritmo de match com os dados sincronizados do Jusbrasil.
Carrega dados históricos dos advogados e alimenta o algoritmo de match.
"""

import json
import logging
from dataclasses import dataclass
from typing import Any, Dict, List, Optional, Tuple

import numpy as np
import psycopg2
from psycopg2.extras import RealDictCursor

from algoritmo_match import (
    EMBEDDING_DIM,
    KPI,
    Case,
    FeatureCalculator,
    Lawyer,
    MatchmakingAlgorithm,
)
from services.cache_service_simple import simple_cache_service

logger = logging.getLogger(__name__)


@dataclass
class JusbrasilStats:
    """Estatísticas do Jusbrasil para um advogado"""
    total_cases: int
    victories: int
    defeats: int
    ongoing: int
    success_rate: float
    kpi_subarea: Dict[str, float]
    case_outcomes: List[bool]
    embeddings: List[np.ndarray]
    last_sync: Optional[str]


class JusbrasilDataLoader:
    """Carrega dados históricos do Jusbrasil para alimentar o algoritmo de match"""

    def __init__(self, db_connection):
        self.db_connection = db_connection

    async def load_lawyer_jusbrasil_data(
            self, lawyer_id: str) -> Optional[JusbrasilStats]:
        """
        Carrega dados históricos de um advogado específico

        Args:
            lawyer_id: ID do advogado

        Returns:
            JusbrasilStats com dados históricos ou None se não encontrado
        """
        cursor = self.db_connection.cursor()

        try:
            # Buscar dados básicos do advogado
            cursor.execute("""
                SELECT
                    total_cases,
                    success_rate,
                    kpi_subarea,
                    last_jusbrasil_sync
                FROM lawyers
                WHERE id = %s
            """, (lawyer_id,))

            lawyer_data = cursor.fetchone()
            if not lawyer_data:
                logger.warning(f"Advogado {lawyer_id} não encontrado")
                return None

            # Buscar casos históricos
            cursor.execute("""
                SELECT
                    outcome,
                    area,
                    subarea,
                    embedding
                FROM lawyer_cases
                WHERE lawyer_id = %s
                AND outcome IS NOT NULL
                ORDER BY created_at DESC
            """, (lawyer_id,))

            cases = cursor.fetchall()

            # Buscar embeddings históricos
            cursor.execute("""
                SELECT
                    embedding,
                    outcome
                FROM lawyer_embeddings
                WHERE lawyer_id = %s
                ORDER BY created_at DESC
            """, (lawyer_id,))

            embeddings_data = cursor.fetchall()

            # Processar dados
            victories = sum(1 for case in cases if case['outcome'] is True)
            defeats = sum(1 for case in cases if case['outcome'] is False)
            ongoing = len(cases) - victories - defeats

            success_rate = lawyer_data['success_rate'] or 0.0
            kpi_subarea = json.loads(lawyer_data['kpi_subarea'] or '{}')

            # Converter embeddings
            case_outcomes = [case['outcome']
                             for case in cases if case['outcome'] is not None]
            embeddings = []

            for emb_data in embeddings_data:
                if emb_data['embedding']:
                    embedding = np.array(emb_data['embedding'], dtype=np.float32)
                    embeddings.append(embedding)

            return JusbrasilStats(
                total_cases=lawyer_data['total_cases'] or 0,
                victories=victories,
                defeats=defeats,
                ongoing=ongoing,
                success_rate=success_rate,
                kpi_subarea=kpi_subarea,
                case_outcomes=case_outcomes,
                embeddings=embeddings,
                last_sync=lawyer_data['last_jusbrasil_sync'].isoformat(
                ) if lawyer_data['last_jusbrasil_sync'] else None
            )

        except Exception as e:
            logger.error(
                f"Erro ao carregar dados do Jusbrasil para advogado {lawyer_id}: {e}")
            return None

    def load_all_lawyers_with_jusbrasil_data(self) -> List[Tuple[str, JusbrasilStats]]:
        """
        Carrega dados do Jusbrasil para todos os advogados

        Returns:
            Lista de tuplas (lawyer_id, JusbrasilStats)
        """
        cursor = self.db_connection.cursor()

        try:
            # Buscar todos os advogados que têm dados do Jusbrasil
            cursor.execute("""
                SELECT id FROM lawyers
                WHERE total_cases > 0
                AND last_jusbrasil_sync IS NOT NULL
                ORDER BY total_cases DESC
            """)

            lawyer_ids = [row['id'] for row in cursor.fetchall()]

            results = []
            for lawyer_id in lawyer_ids:
                stats = self.load_lawyer_jusbrasil_data(lawyer_id)
                if stats:
                    results.append((lawyer_id, stats))

            return results

        except Exception as e:
            logger.error(
                f"Erro ao carregar dados do Jusbrasil para todos os advogados: {e}")
            return []

    def get_case_similarity_data(
            self, lawyer_id: str, case_embedding: np.ndarray) -> Tuple[float, List[bool]]:
        """
        Calcula similaridade com casos históricos de um advogado

        Args:
            lawyer_id: ID do advogado
            case_embedding: Embedding do caso atual

        Returns:
            Tupla com (similarity_score, outcomes)
        """
        cursor = self.db_connection.cursor()

        try:
            # Buscar embeddings históricos com outcomes
            cursor.execute("""
                SELECT
                    embedding,
                    outcome
                FROM lawyer_embeddings
                WHERE lawyer_id = %s
                ORDER BY created_at DESC
                LIMIT 10
            """, (lawyer_id,))

            embeddings_data = cursor.fetchall()

            if not embeddings_data:
                return 0.0, []

            similarities = []
            outcomes = []

            for emb_data in embeddings_data:
                if emb_data['embedding']:
                    historical_embedding = np.array(
                        emb_data['embedding'], dtype=np.float32)

                    # Calcular similaridade cosseno
                    similarity = np.dot(case_embedding, historical_embedding) / (
                        np.linalg.norm(case_embedding) *
                        np.linalg.norm(historical_embedding)
                    )

                    similarities.append(similarity)
                    outcomes.append(emb_data['outcome'])

            if not similarities:
                return 0.0, []

            # Similaridade ponderada por outcomes (vitórias têm peso maior)
            weights = [1.0 if outcome else 0.8 for outcome in outcomes]
            weighted_similarity = np.average(similarities, weights=weights)

            return float(weighted_similarity), outcomes

        except Exception as e:
            logger.error(
                f"Erro ao calcular similaridade para advogado {lawyer_id}: {e}")
            return 0.0, []


class EnhancedMatchingAlgorithm(MatchmakingAlgorithm):
    """Algoritmo de match aprimorado com dados do Jusbrasil"""

    def __init__(self, db_connection):
        super().__init__()
        self.jusbrasil_loader = JusbrasilDataLoader(db_connection)

    async def enhance_lawyer_with_jusbrasil_data(self, lawyer: Lawyer) -> Lawyer:
        """
        Enriquece dados do advogado com informações do Jusbrasil

        Args:
            lawyer: Objeto Lawyer básico

        Returns:
            Lawyer enriquecido com dados do Jusbrasil
        """
        stats = await self.jusbrasil_loader.load_lawyer_jusbrasil_data(lawyer.id)

        if not stats:
            logger.warning(f"Advogado {lawyer.id} não possui dados do Jusbrasil")
            return lawyer

        # Atualizar KPI com dados reais
        lawyer.kpi.success_rate = stats.success_rate
        lawyer.kpi.cases_30d = min(stats.total_cases, 30)  # Aproximação

        # Adicionar KPI granular
        lawyer.kpi_subarea = stats.kpi_subarea

        # Adicionar embeddings históricos
        lawyer.casos_historicos_embeddings = stats.embeddings

        # Adicionar outcomes históricos
        lawyer.case_outcomes = stats.case_outcomes

        # Adicionar informações aos scores
        lawyer.scores = lawyer.scores or {}
        lawyer.scores.update({
            'jusbrasil_total_cases': stats.total_cases,
            'jusbrasil_victories': stats.victories,
            'jusbrasil_defeats': stats.defeats,
            'jusbrasil_success_rate': stats.success_rate,
            'jusbrasil_last_sync': stats.last_sync
        })

        logger.info(
            f"Advogado {lawyer.id} enriquecido com dados do Jusbrasil: {stats.total_cases} casos, {stats.success_rate:.2%} sucesso")

        return lawyer

    async def rank_with_jusbrasil_data(self, case: Case, base_lawyers: List[Lawyer],
                                       top_n: int = 5, preset: str = "balanced") -> List[Lawyer]:
        """
        Classifica advogados usando dados do Jusbrasil

        Args:
            case: Caso para matching
            base_lawyers: Lista de advogados base
            top_n: Número de advogados a retornar
            preset: Preset de pesos a usar

        Returns:
            Lista de advogados classificados com dados do Jusbrasil
        """
        # Enriquecer advogados com dados do Jusbrasil
        enhanced_lawyers = []
        for lawyer in base_lawyers:
            enhanced_lawyer = self.enhance_lawyer_with_jusbrasil_data(lawyer)
            enhanced_lawyers.append(enhanced_lawyer)

        # Usar o algoritmo original com dados enriquecidos
        result = await super().rank(case, enhanced_lawyers, top_n, preset)

        # Adicionar informações extras sobre o matching
        for lawyer in result:
            if lawyer.casos_historicos_embeddings:
                similarity_score, outcomes = self.jusbrasil_loader.get_case_similarity_data(
                    lawyer.id,
                    case.summary_embedding
                )

                lawyer.scores = lawyer.scores or {}
                lawyer.scores.update({
                    'jusbrasil_case_similarity': similarity_score,
                    'jusbrasil_similar_outcomes': outcomes
                })

        return result


class JusbrasilFeatureCalculator(FeatureCalculator):
    """Calculator de features aprimorado com dados do Jusbrasil"""

    def __init__(self, case: Case, lawyer: Lawyer,
                 jusbrasil_loader: JusbrasilDataLoader):
        super().__init__(case, lawyer)
        self.jusbrasil_loader = jusbrasil_loader

    def success_rate(self) -> float:
        """Success rate aprimorado com dados granulares do Jusbrasil"""
        # Tentar usar dados granulares primeiro
        area_key = f"{self.case.area}/{self.case.subarea}"

        if area_key in self.lawyer.kpi_subarea:
            granular_rate = self.lawyer.kpi_subarea[area_key]
            logger.debug(f"Usando taxa granular para {area_key}: {granular_rate:.2%}")
            return granular_rate

        # Fallback para taxa geral com suavização bayesiana
        return super().success_rate()

    def case_similarity(self) -> float:
        """Case similarity aprimorada com dados reais do Jusbrasil"""
        if not self.lawyer.casos_historicos_embeddings:
            return 0.0

        # Calcular similaridade ponderada por outcomes
        similarities = []
        for embedding in self.lawyer.casos_historicos_embeddings:
            similarity = np.dot(self.case.summary_embedding, embedding) / (
                np.linalg.norm(self.case.summary_embedding) * np.linalg.norm(embedding)
            )
            similarities.append(similarity)

        if not similarities:
            return 0.0

        # Ponderar por outcomes históricos
        outcomes = self.lawyer.case_outcomes
        if outcomes and len(outcomes) == len(similarities):
            weights = [1.0 if outcome else 0.8 for outcome in outcomes]
            weighted_similarity = np.average(similarities, weights=weights)
        else:
            weighted_similarity = np.mean(similarities)

        return float(np.clip(weighted_similarity, 0, 1))

# Exemplo de uso


async def demo_jusbrasil_integration():
    """Demonstra como usar a integração com Jusbrasil"""
    import os

    # Conectar ao banco
    db_connection = psycopg2.connect(
        os.getenv("DATABASE_URL"),
        cursor_factory=RealDictCursor
    )

    try:
        # Criar caso de exemplo
        case = Case(
            id="caso_exemplo",
            area="Trabalhista",
            subarea="Rescisão",
            urgency_h=48,
            coords=(-23.5505, -46.6333),
            complexity="HIGH",
            summary_embedding=np.random.rand(EMBEDDING_DIM)
        )

        # Criar advogados base (normalmente vindos do banco)
        base_lawyers = [
            Lawyer(
                id="adv_1",
                nome="Dr. João Silva",
                tags_expertise=["Trabalhista"],
                geo_latlon=(-23.5505, -46.6333),
                curriculo_json={"anos_experiencia": 15},
                kpi=KPI(
                    success_rate=0.85,
                    cases_30d=20,
                    capacidade_mensal=25,
                    avaliacao_media=4.5,
                    tempo_resposta_h=8
                )
            )
        ]

        # Usar algoritmo aprimorado
        enhanced_algorithm = EnhancedMatchingAlgorithm(db_connection)

        # Fazer matching com dados do Jusbrasil
        result = await enhanced_algorithm.rank_with_jusbrasil_data(
            case,
            base_lawyers,
            top_n=3,
            preset="expert"
        )

        # Mostrar resultados
        print("=== Resultado do Matching com Dados do Jusbrasil ===")
        for i, lawyer in enumerate(result, 1):
            print(f"\n{i}. {lawyer.nome}")
            print(f"   Score Fair: {lawyer.scores.get('fair', 0):.3f}")
            print(
                f"   Success Rate: {
                    lawyer.scores.get(
                        'jusbrasil_success_rate',
                        0):.2%}")
            print(f"   Total Cases: {lawyer.scores.get('jusbrasil_total_cases', 0)}")
            print(
                f"   Case Similarity: {
                    lawyer.scores.get(
                        'jusbrasil_case_similarity',
                        0):.3f}")
            print(f"   Última Sync: {lawyer.scores.get('jusbrasil_last_sync', 'N/A')}")

    finally:
        db_connection.close()

if __name__ == "__main__":
    import asyncio
    asyncio.run(demo_jusbrasil_integration())
