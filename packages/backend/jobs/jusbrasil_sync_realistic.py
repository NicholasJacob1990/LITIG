#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
jobs/jusbrasil_sync_realistic.py

Job assíncrono REALISTA para sincronizar dados da API Jusbrasil.
Foca apenas em dados factíveis disponíveis na API real.
"""

import asyncio
import json
import logging
import os
from datetime import datetime, timedelta
from typing import Any, Dict, List, Optional

import psycopg2
from psycopg2.extras import RealDictCursor

from backend.services.jusbrasil_integration_realistic import (
    DataQuality,
    JusbrasilRealisticStats,
    RealisticJusbrasilIntegration,
)

# Configurações
DATABASE_URL = os.getenv("DATABASE_URL")
BATCH_SIZE = 10  # Reduzido para ser respeitoso com a API
SYNC_INTERVAL_HOURS = 24  # Sincronizar uma vez por dia

logger = logging.getLogger(__name__)


class RealisticJusbrasilSyncJob:
    """Job de sincronização REALISTA do Jusbrasil"""

    def __init__(self):
        self.db_connection = None
        self.integration = None
        self.stats = {
            'total_lawyers': 0,
            'successful_syncs': 0,
            'failed_syncs': 0,
            'no_data_lawyers': 0,
            'api_errors': [],
            'start_time': None,
            'end_time': None
        }

    def connect_db(self):
        """Conecta ao banco de dados"""
        if not DATABASE_URL:
            raise ValueError("DATABASE_URL não configurada")

        self.db_connection = psycopg2.connect(
            DATABASE_URL,
            cursor_factory=RealDictCursor
        )
        self.integration = RealisticJusbrasilIntegration(self.db_connection)

    def close_db(self):
        """Fecha conexão com banco"""
        if self.db_connection:
            self.db_connection.close()

    async def get_lawyers_to_sync(self) -> List[Dict]:
        """
        Obtém lista de advogados que precisam ser sincronizados

        Prioriza:
        1. Advogados que nunca foram sincronizados
        2. Advogados com sync desatualizado (>24h)
        3. Advogados com dados de baixa qualidade
        """
        cursor = self.db_connection.cursor()

        try:
            # Buscar advogados que precisam de sincronização
            cursor.execute("""
                SELECT
                    id,
                    nome,
                    oab_numero,
                    uf,
                    last_jusbrasil_sync,
                    jusbrasil_data_quality,
                    total_cases
                FROM lawyers
                WHERE status = 'active'
                AND oab_numero IS NOT NULL
                AND uf IS NOT NULL
                AND (
                    last_jusbrasil_sync IS NULL OR
                    last_jusbrasil_sync < (NOW() - INTERVAL '24 hours') OR
                    jusbrasil_data_quality IN ('low', 'unavailable')
                )
                ORDER BY
                    last_jusbrasil_sync ASC NULLS FIRST,
                    jusbrasil_data_quality ASC NULLS FIRST,
                    total_cases DESC
                LIMIT %(batch_size)s
            """, {'batch_size': BATCH_SIZE})

            lawyers = cursor.fetchall()

            logger.info(f"Encontrados {len(lawyers)} advogados para sincronização")
            return [dict(lawyer) for lawyer in lawyers]

        except Exception as e:
            logger.error(f"Erro ao buscar advogados para sincronização: {e}")
            return []

    async def sync_lawyer_batch(self, lawyers: List[Dict]) -> Dict[str, Any]:
        """Sincroniza lote de advogados"""

        batch_stats = {
            'processed': 0,
            'successful': 0,
            'failed': 0,
            'no_data': 0,
            'errors': []
        }

        for lawyer in lawyers:
            try:
                lawyer_id = lawyer['id']
                logger.info(f"Sincronizando advogado {lawyer_id} - {lawyer['nome']}")

                # Sincronizar dados realistas
                stats = await self.integration.sync_lawyer_realistic_data(lawyer)

                batch_stats['processed'] += 1

                if stats.data_quality == DataQuality.UNAVAILABLE:
                    batch_stats['no_data'] += 1
                    logger.warning(
                        f"Advogado {lawyer_id} não possui dados no Jusbrasil")
                else:
                    batch_stats['successful'] += 1
                    logger.info(
                        f"Advogado {lawyer_id} sincronizado: {stats.total_processes} processos")

                # Delay entre advogados para ser respeitoso com a API
                await asyncio.sleep(2)

            except Exception as e:
                batch_stats['failed'] += 1
                batch_stats['errors'].append({
                    'lawyer_id': lawyer.get('id'),
                    'error': str(e)
                })
                logger.error(f"Erro ao sincronizar advogado {lawyer.get('id')}: {e}")
                continue

        return batch_stats

    async def run_sync_job(self) -> Dict[str, Any]:
        """Executa job completo de sincronização"""

        self.stats['start_time'] = datetime.now()
        logger.info("Iniciando sincronização REALISTA do Jusbrasil")

        try:
            self.connect_db()

            # Buscar advogados para sincronizar
            lawyers = await self.get_lawyers_to_sync()
            self.stats['total_lawyers'] = len(lawyers)

            if not lawyers:
                logger.info("Nenhum advogado precisa ser sincronizado")
                return self.stats

            # Sincronizar em lote
            batch_stats = await self.sync_lawyer_batch(lawyers)

            # Atualizar estatísticas
            self.stats['successful_syncs'] = batch_stats['successful']
            self.stats['failed_syncs'] = batch_stats['failed']
            self.stats['no_data_lawyers'] = batch_stats['no_data']
            self.stats['api_errors'] = batch_stats['errors']

            # Salvar estatísticas do job
            await self.save_job_stats()

            logger.info(
                f"Sincronização concluída: {batch_stats['successful']}/{len(lawyers)} sucesso")

        except Exception as e:
            logger.error(f"Erro durante sincronização: {e}")
            self.stats['api_errors'].append({'job_error': str(e)})

        finally:
            self.stats['end_time'] = datetime.now()
            self.close_db()

        return self.stats

    async def save_job_stats(self):
        """Salva estatísticas do job no banco"""

        cursor = self.db_connection.cursor()

        try:
            cursor.execute("""
                INSERT INTO jusbrasil_job_stats (
                    job_timestamp,
                    total_lawyers,
                    successful_syncs,
                    failed_syncs,
                    no_data_lawyers,
                    execution_time_seconds,
                    api_errors
                ) VALUES (
                    %(start_time)s,
                    %(total_lawyers)s,
                    %(successful_syncs)s,
                    %(failed_syncs)s,
                    %(no_data_lawyers)s,
                    %(execution_time)s,
                    %(api_errors)s
                )
            """, {
                'start_time': self.stats['start_time'].isoformat(),
                'total_lawyers': self.stats['total_lawyers'],
                'successful_syncs': self.stats['successful_syncs'],
                'failed_syncs': self.stats['failed_syncs'],
                'no_data_lawyers': self.stats['no_data_lawyers'],
                'execution_time': (self.stats['end_time'] - self.stats['start_time']).total_seconds(),
                'api_errors': json.dumps(self.stats['api_errors'])
            })

            self.db_connection.commit()

        except Exception as e:
            logger.error(f"Erro ao salvar estatísticas do job: {e}")
            self.db_connection.rollback()

    async def health_check(self) -> Dict[str, Any]:
        """Verifica saúde do sistema de sincronização"""

        try:
            self.connect_db()
            cursor = self.db_connection.cursor()

            # Verificar última sincronização
            cursor.execute("""
                SELECT
                    MAX(last_jusbrasil_sync) as last_sync,
                    COUNT(*) as total_lawyers,
                    COUNT(CASE WHEN last_jusbrasil_sync IS NOT NULL THEN 1 END) as synced_lawyers,
                    COUNT(CASE WHEN jusbrasil_data_quality = 'high' THEN 1 END) as high_quality_data
                FROM lawyers
                WHERE status = 'active'
            """)

            result = cursor.fetchone()

            # Verificar jobs recentes
            cursor.execute("""
                SELECT
                    job_timestamp,
                    successful_syncs,
                    failed_syncs,
                    api_errors
                FROM jusbrasil_job_stats
                WHERE job_timestamp > (NOW() - INTERVAL '24 hours')
                ORDER BY job_timestamp DESC
                LIMIT 5
            """)

            recent_jobs = cursor.fetchall()

            return {
                'status': 'healthy',
                'last_sync': result['last_sync'].isoformat() if result['last_sync'] else None,
                'total_lawyers': result['total_lawyers'],
                'synced_lawyers': result['synced_lawyers'],
                'high_quality_data': result['high_quality_data'],
                'sync_coverage': result['synced_lawyers'] / result['total_lawyers'] if result['total_lawyers'] > 0 else 0,
                'recent_jobs': [dict(job) for job in recent_jobs],
                'limitations': [
                    "Dados são estimativas baseadas em heurísticas",
                    "API não fornece vitórias/derrotas reais",
                    "Foco em volume e distribuição de casos",
                    "Sincronização limitada por rate limits da API"
                ]
            }

        except Exception as e:
            return {
                'status': 'unhealthy',
                'error': str(e)
            }

        finally:
            self.close_db()

# Funcões para integração com Celery


async def run_realistic_sync_job():
    """Executa job de sincronização realista"""

    job = RealisticJusbrasilSyncJob()
    result = await job.run_sync_job()

    return result


async def run_health_check():
    """Executa health check do sistema"""

    job = RealisticJusbrasilSyncJob()
    result = await job.health_check()

    return result

# Exemplo de uso standalone


async def main():
    """Executa sincronização manual"""

    print("=== SINCRONIZAÇÃO REALISTA JUSBRASIL ===")
    print("Dados limitados mas factíveis e transparentes")
    print()

    job = RealisticJusbrasilSyncJob()
    stats = await job.run_sync_job()

    print("📊 RESULTADO DA SINCRONIZAÇÃO:")
    print(f"   Total advogados processados: {stats['total_lawyers']}")
    print(f"   Sincronizações bem-sucedidas: {stats['successful_syncs']}")
    print(f"   Sincronizações falharam: {stats['failed_syncs']}")
    print(f"   Advogados sem dados: {stats['no_data_lawyers']}")

    if stats['api_errors']:
        print(f"   Erros encontrados: {len(stats['api_errors'])}")
        for error in stats['api_errors'][:3]:  # Primeiros 3 erros
            print(f"     - {error}")

    execution_time = stats['end_time'] - stats['start_time']
    print(f"   Tempo de execução: {execution_time.total_seconds():.2f}s")
    print()

    print("🔍 HEALTH CHECK:")
    health = await run_health_check()
    print(f"   Status: {health['status']}")
    print(f"   Cobertura de sincronização: {health.get('sync_coverage', 0):.1%}")
    print(
        f"   Advogados com dados de alta qualidade: {
            health.get(
                'high_quality_data',
                0)}")
    print()

    print("⚠️  LIMITAÇÕES DOS DADOS:")
    for limitation in health.get('limitations', []):
        print(f"   - {limitation}")

if __name__ == "__main__":
    asyncio.run(main())
