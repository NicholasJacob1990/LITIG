#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
jobs/jusbrasil_sync.py

Job assíncrono para sincronizar dados da API Jusbrasil e alimentar o algoritmo de match.
Extrai histórico processual, classifica outcomes (vitória/derrota) e gera embeddings.
"""

import asyncio
import json
import logging
import os
import re
import time
from dataclasses import dataclass
from datetime import datetime, timedelta
from pathlib import Path
from typing import Any, Dict, List, Optional, Tuple

try:
    import hashlib

    import httpx
    import numpy as np
    import psycopg2
    from psycopg2.extras import RealDictCursor
    from sentence_transformers import SentenceTransformer
    from tenacity import (
        retry,
        retry_if_exception_type,
        stop_after_attempt,
        wait_exponential,
    )
    from tqdm.asyncio import tqdm_asyncio
except ImportError as e:
    print(f"Erro: Dependências não instaladas. Execute: pip install {e.name}")
    exit(1)

# Configurações
JUSBRASIL_API_URL = "https://api.jusbrasil.com.br"
API_KEY = os.getenv("JUSBRASIL_API_KEY")
DB_DSN = os.getenv("DATABASE_URL")
EMBEDDING_MODEL = "sentence-transformers/all-MiniLM-L6-v2"
RATE_LIMIT_RPS = 5  # Requisições por segundo
BATCH_SIZE = 100
LGPD_SALT = os.getenv("LGPD_SALT", "default_salt_change_in_production")

# Configurar logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


@dataclass
class ProcessoJusbrasil:
    """Estrutura de dados para processo do Jusbrasil"""
    numero: str
    area: str
    subarea: str
    classe: str
    assunto: str
    sentenca: Optional[str]
    movimentacoes: List[str]
    status: str
    data_distribuicao: str
    valor_acao: Optional[float]
    partes: List[Dict[str, Any]]
    # True = vitória, False = derrota, None = em andamento
    outcome: Optional[bool] = None
    resumo: str = ""
    embedding: Optional[np.ndarray] = None


class JusbrasilClassifier:
    """Classifica outcomes de processos usando heurísticas e padrões"""

    # Padrões de vitória
    VICTORY_PATTERNS = [
        r"JULGO\s+PROCEDENTE",
        r"JULGO\s+PARCIALMENTE\s+PROCEDENTE",
        r"HOMOLO(GO|GAR)\s+ACORDO",
        r"ACORDO\s+HOMOLOGADO",
        r"DANO\s+MORAL\s+DEFERIDO",
        r"INDENIZAÇÃO\s+DEFERIDA",
        r"RESCISÃO\s+INDIRETA",
        r"HORAS\s+EXTRAS\s+DEFERIDAS",
        r"ADICIONAL\s+NOTURNO\s+DEFERIDO",
        r"CONDENAÇÃO\s+SOLIDÁRIA",
        r"REFORMA\s+DA\s+SENTENÇA.*PROCEDENTE",
        r"PROVIMENTO\s+DO\s+RECURSO",
        r"SENTENÇA\s+REFORMADA\s+PARA\s+JULGAR\s+PROCEDENTE"
    ]

    # Padrões de derrota
    DEFEAT_PATTERNS = [
        r"JULGO\s+IMPROCEDENTE",
        r"JULGO\s+TOTALMENTE\s+IMPROCEDENTE",
        r"EXTINÇÃO\s+SEM\s+RESOLUÇÃO\s+DO\s+MÉRITO",
        r"DESISTÊNCIA\s+HOMOLOGADA",
        r"ARQUIVAMENTO\s+DEFINITIVO",
        r"CARÊNCIA\s+DE\s+AÇÃO",
        r"FALTA\s+DE\s+INTERESSE\s+PROCESSUAL",
        r"ILEGITIMIDADE\s+PASSIVA",
        r"PRESCRIÇÃO\s+RECONHECIDA",
        r"DECADÊNCIA\s+RECONHECIDA",
        r"NEGOU\s+PROVIMENTO\s+AO\s+RECURSO",
        r"MANTIDA\s+A\s+SENTENÇA.*IMPROCEDENTE"
    ]

    def __init__(self):
        self.victory_regex = [re.compile(pattern, re.IGNORECASE)
                                         for pattern in self.VICTORY_PATTERNS]
        self.defeat_regex = [re.compile(pattern, re.IGNORECASE)
                                        for pattern in self.DEFEAT_PATTERNS]

    def classify_outcome(self, texto: str) -> Optional[bool]:
        """
        Classifica o outcome do processo
        Returns:
            True: vitória
            False: derrota
            None: em andamento ou inconclusivo
        """
        if not texto:
            return None

        # Verificar padrões de vitória
        for pattern in self.victory_regex:
            if pattern.search(texto):
                return True

        # Verificar padrões de derrota
        for pattern in self.defeat_regex:
            if pattern.search(texto):
                return False

        # Se não encontrou padrões claros, considerar em andamento
        return None

    def generate_summary(self, processo: ProcessoJusbrasil) -> str:
        """Gera resumo do processo para embedding"""
        parts = []

        # Informações básicas
        parts.append(f"Área: {processo.area}")
        parts.append(f"Subárea: {processo.subarea}")
        parts.append(f"Classe: {processo.classe}")
        parts.append(f"Assunto: {processo.assunto}")

        # Valor da ação se disponível
        if processo.valor_acao:
            parts.append(f"Valor: R$ {processo.valor_acao:,.2f}")

        # Sentença (mais importante)
        if processo.sentenca:
            parts.append(f"Sentença: {processo.sentenca}")

        # Últimas movimentações relevantes
        if processo.movimentacoes:
            relevant_moves = [m for m in processo.movimentacoes[-5:] if len(m) > 50]
            if relevant_moves:
                parts.append(f"Movimentações: {' | '.join(relevant_moves)}")

        return " ".join(parts)


class JusbrasilAPI:
    """Cliente da API Jusbrasil com rate limiting e retry"""

    def __init__(self, api_key: str, rate_limit: int = 5):
        self.api_key = api_key
        self.rate_limit = rate_limit
        self.last_request_time = 0
        self.session = None

    async def __aenter__(self):
        self.session = httpx.AsyncClient(
            headers={"Authorization": f"Bearer {self.api_key}"},
            timeout=30.0,
            limits=httpx.Limits(max_connections=10, max_keepalive_connections=5)
        )
        return self

    async def __aexit__(self, exc_type, exc_val, exc_tb):
        if self.session:
            await self.session.aclose()

    async def _rate_limit(self):
        """Implementa rate limiting"""
        now = time.time()
        time_since_last = now - self.last_request_time
        min_interval = 1.0 / self.rate_limit

        if time_since_last < min_interval:
            sleep_time = min_interval - time_since_last
            await asyncio.sleep(sleep_time)

        self.last_request_time = time.time()

    @retry(
        stop=stop_after_attempt(3),
        wait=wait_exponential(multiplier=1, min=4, max=10),
        retry=retry_if_exception_type((httpx.HTTPError, httpx.TimeoutException))
    )
    async def search_processes(self, oab_numero: str, uf: str,
                               limit: int = 100) -> List[Dict]:
        """Busca processos por OAB do advogado"""
        await self._rate_limit()

        params = {
            "advogado": oab_numero,
            "uf": uf,
            "limit": limit,
            "offset": 0
        }

        try:
            response = await self.session.get(
                f"{JUSBRASIL_API_URL}/search",
                params=params
            )
            response.raise_for_status()
            data = response.json()

            if not isinstance(data, dict):
                logger.warning(f"Resposta inválida da API para OAB {oab_numero}/{uf}")
                return []

            logger.info(
                f"Encontrados {len(data.get('processos', []))} processos para OAB {oab_numero}/{uf}")
            return data.get('processos', [])

        except httpx.HTTPStatusError as e:
            if e.response.status_code == 429:
                logger.warning(f"Rate limit atingido para OAB {oab_numero}/{uf}")
                await asyncio.sleep(60)  # Aguardar 1 minuto
                raise
            logger.error(
    f"Erro HTTP {
        e.response.status_code} para OAB {oab_numero}/{uf}")
            raise

    async def get_process_details(self, numero_processo: str) -> Optional[Dict]:
        """Obtém detalhes completos de um processo"""
        await self._rate_limit()

        try:
            response = await self.session.get(
                f"{JUSBRASIL_API_URL}/processos/{numero_processo}"
            )
            response.raise_for_status()
            data = response.json()

            if not isinstance(data, dict):
                logger.warning(f"Resposta inválida para processo {numero_processo}")
                return None

            return data

        except httpx.HTTPStatusError as e:
            if e.response.status_code == 404:
                logger.warning(f"Processo {numero_processo} não encontrado")
                return None
            logger.error(f"Erro ao buscar processo {numero_processo}: {e}")
            return None


class JusbrasilETL:
    """Pipeline ETL para sincronização com Jusbrasil"""

    def __init__(self):
        self.classifier = JusbrasilClassifier()
        self.embedding_model = SentenceTransformer(EMBEDDING_MODEL)
        self.db_connection = None

    def connect_db(self):
        """Conecta ao banco de dados"""
        if not DB_DSN:
            raise ValueError("DATABASE_URL não configurada")

        self.db_connection = psycopg2.connect(
            DB_DSN,
            cursor_factory=RealDictCursor
        )
        self.db_connection.autocommit = False

    def close_db(self):
        """Fecha conexão com banco"""
        if self.db_connection:
            self.db_connection.close()

    def hash_cpf(self, cpf: str) -> str:
        """Gera hash anônimo do CPF para conformidade LGPD"""
        return hashlib.sha256(f"{cpf}{LGPD_SALT}".encode()).hexdigest()

    def parse_jusbrasil_process(self, data: Dict) -> ProcessoJusbrasil:
        """Converte dados da API Jusbrasil para estrutura interna"""
        return ProcessoJusbrasil(
            numero=data.get('numero', ''),
            area=data.get('area', ''),
            subarea=data.get('subarea', ''),
            classe=data.get('classe', ''),
            assunto=data.get('assunto', ''),
            sentenca=data.get('sentenca'),
            movimentacoes=data.get('movimentacoes', []),
            status=data.get('status', ''),
            data_distribuicao=data.get('data_distribuicao', ''),
            valor_acao=data.get('valor_acao'),
            partes=data.get('partes', [])
        )

    def process_case_data(self, processo: ProcessoJusbrasil) -> ProcessoJusbrasil:
        """Processa dados do caso: classifica outcome e gera embedding"""

        # Classificar outcome
        texto_completo = ""
        if processo.sentenca:
            texto_completo += processo.sentenca + " "
        texto_completo += " ".join(processo.movimentacoes)

        processo.outcome = self.classifier.classify_outcome(texto_completo)

        # Gerar resumo
        processo.resumo = self.classifier.generate_summary(processo)

        # Gerar embedding
        if processo.resumo:
            embedding = self.embedding_model.encode(
                processo.resumo,
                normalize_embeddings=True
            )
            processo.embedding = embedding.astype(np.float32)

        return processo

    async def sync_lawyer_processes(self, lawyer_data: Dict) -> Dict[str, Any]:
        """Sincroniza processos de um advogado específico"""
        lawyer_id = lawyer_data['id']
        oab_numero = lawyer_data['oab_numero']
        uf = lawyer_data['uf']

        logger.info(
    f"Sincronizando processos do advogado {lawyer_id} - OAB {oab_numero}/{uf}")

        stats = {
            'lawyer_id': lawyer_id,
            'total_processes': 0,
            'victories': 0,
            'defeats': 0,
            'ongoing': 0,
            'areas': {},
            'subareas': {},
            'embeddings': [],
            'outcomes': [],
            'errors': []
        }

        try:
            if not API_KEY:
                raise ValueError("JUSBRASIL_API_KEY não configurada")

            async with JusbrasilAPI(API_KEY, RATE_LIMIT_RPS) as api:
                # Buscar processos
                raw_processes = await api.search_processes(oab_numero, uf)

                # Processar cada processo
                for raw_process in raw_processes:
                    try:
                        processo = self.parse_jusbrasil_process(raw_process)
                        processo = self.process_case_data(processo)

                        stats['total_processes'] += 1

                        # Estatísticas por outcome
                        if processo.outcome is True:
                            stats['victories'] += 1
                        elif processo.outcome is False:
                            stats['defeats'] += 1
                        else:
                            stats['ongoing'] += 1

                        # Estatísticas por área
                        area_key = f"{processo.area}/{processo.subarea}"
                        if area_key not in stats['areas']:
                            stats['areas'][area_key] = {'wins': 0, 'total': 0}

                        stats['areas'][area_key]['total'] += 1
                        if processo.outcome is True:
                            stats['areas'][area_key]['wins'] += 1

                        # Armazenar embeddings e outcomes para o algoritmo
                        if processo.embedding is not None and processo.outcome is not None:
                            stats['embeddings'].append(processo.embedding)
                            stats['outcomes'].append(processo.outcome)

                        # Salvar no banco
                        await self.save_process_to_db(lawyer_id, processo)

                    except Exception as e:
                        logger.error(
                            f"Erro ao processar processo {raw_process.get('numero', 'N/A')}: {e}")
                        stats['errors'].append(str(e))
                        continue

    except Exception as e:
            logger.error(f"Erro ao sincronizar advogado {lawyer_id}: {e}")
            stats['errors'].append(str(e))

        return stats
    
    async def save_process_to_db(self, lawyer_id: str, processo: ProcessoJusbrasil):
        """Salva processo no banco de dados"""
        if not self.db_connection:
            raise ValueError("Conexão com banco não estabelecida")
        
        cursor = self.db_connection.cursor()
        
        try:
            # Inserir/atualizar processo
            cursor.execute("""
                INSERT INTO lawyer_cases (
                    lawyer_id, numero_processo, area, subarea, classe, assunto,
                    outcome, resumo, embedding, data_distribuicao, valor_acao,
                    updated_at
                ) VALUES (
                    %(lawyer_id)s, %(numero)s, %(area)s, %(subarea)s, %(classe)s,
                    %(assunto)s, %(outcome)s, %(resumo)s, %(embedding)s,
                    %(data_distribuicao)s, %(valor_acao)s, NOW()
                )
                ON CONFLICT (lawyer_id, numero_processo) 
                DO UPDATE SET
                    outcome = EXCLUDED.outcome,
                    resumo = EXCLUDED.resumo,
                    embedding = EXCLUDED.embedding,
                    updated_at = NOW()
            """, {
                'lawyer_id': lawyer_id,
                'numero': processo.numero,
                'area': processo.area,
                'subarea': processo.subarea,
                'classe': processo.classe,
                'assunto': processo.assunto,
                'outcome': processo.outcome,
                'resumo': processo.resumo,
                'embedding': processo.embedding.tolist() if processo.embedding is not None else None,
                'data_distribuicao': processo.data_distribuicao,
                'valor_acao': processo.valor_acao
            })
            
        except Exception as e:
            logger.error(f"Erro ao salvar processo no banco: {e}")
            raise
    
    async def update_lawyer_stats(self, lawyer_id: str, stats: Dict[str, Any]):
        """Atualiza estatísticas do advogado baseadas nos processos"""
        if not self.db_connection:
            raise ValueError("Conexão com banco não estabelecida")
        
        cursor = self.db_connection.cursor()
        
        try:
            total = stats['total_processes']
            wins = stats['victories']
            
            # Calcular success rate com suavização bayesiana
            alpha, beta = 1, 1  # Prior Beta(1,1)
            success_rate = (wins + alpha) / (total + alpha + beta) if total > 0 else 0.5
            
            # Montar kpi_subarea
            kpi_subarea = {}
            for area_key, area_stats in stats['areas'].items():
                area_wins = area_stats['wins']
                area_total = area_stats['total']
                area_success_rate = (area_wins + alpha) / (area_total + alpha + beta) if area_total > 0 else 0.5
                kpi_subarea[area_key] = area_success_rate
            
            # Atualizar tabela lawyers
            cursor.execute("""
                UPDATE lawyers 
                SET 
                    success_rate = %(success_rate)s,
                    kpi_subarea = %(kpi_subarea)s,
                    total_cases = %(total_cases)s,
                    last_jusbrasil_sync = NOW()
                WHERE id = %(lawyer_id)s
            """, {
                'lawyer_id': lawyer_id,
                'success_rate': success_rate,
                'kpi_subarea': json.dumps(kpi_subarea),
                'total_cases': total
            })
            
            # Atualizar embeddings históricos na tabela lawyer_embeddings
            if stats['embeddings'] and stats['outcomes']:
                cursor.execute("""
                    DELETE FROM lawyer_embeddings WHERE lawyer_id = %(lawyer_id)s
                """, {'lawyer_id': lawyer_id})
                
                for embedding, outcome in zip(stats['embeddings'], stats['outcomes']):
                    cursor.execute("""
                        INSERT INTO lawyer_embeddings (lawyer_id, embedding, outcome)
                        VALUES (%(lawyer_id)s, %(embedding)s, %(outcome)s)
                    """, {
                        'lawyer_id': lawyer_id,
                        'embedding': embedding.tolist(),
                        'outcome': outcome
                    })
            
            if not self.db_connection:
                raise ValueError("Conexão com banco não estabelecida")
            
            self.db_connection.commit()
            logger.info(f"Estatísticas atualizadas para advogado {lawyer_id}: {wins}/{total} vitórias")
            
        except Exception as e:
            if self.db_connection:
                self.db_connection.rollback()
            logger.error(f"Erro ao atualizar estatísticas do advogado {lawyer_id}: {e}")
            raise

    async def sync_all_lawyers(self):
        """Sincroniza todos os advogados"""
        if not self.db_connection:
            raise ValueError("Conexão com banco não estabelecida")
        
        cursor = self.db_connection.cursor()
        
        # Buscar advogados que precisam de sincronização
        cursor.execute("""
            SELECT id, oab_numero, uf, nome
            FROM lawyers 
            WHERE oab_numero IS NOT NULL 
            AND uf IS NOT NULL
            AND (last_jusbrasil_sync IS NULL OR last_jusbrasil_sync < NOW() - INTERVAL '7 days')
            ORDER BY last_jusbrasil_sync NULLS FIRST
            LIMIT 100
        """)
        
        lawyers = cursor.fetchall()
        logger.info(f"Sincronizando {len(lawyers)} advogados")
        
        # Processar em lotes para controle de memória
        for i in range(0, len(lawyers), BATCH_SIZE):
            batch = lawyers[i:i+BATCH_SIZE]
            
            # Criar tasks para o lote
            tasks = []
            for lawyer in batch:
                tasks.append(self.sync_lawyer_processes(dict(lawyer)))
            
            # Executar lote em paralelo
            results = await asyncio.gather(*tasks, return_exceptions=True)
            
            # Processar resultados
            for lawyer, result in zip(batch, results):
                if isinstance(result, Exception):
                    lawyer_dict = dict(lawyer)
                    lawyer_id = lawyer_dict.get('id', 'Unknown')
                    logger.error(f"Erro ao sincronizar advogado {lawyer_id}: {result}")
                    continue
                
                try:
                    lawyer_dict = dict(lawyer)
                    lawyer_id = lawyer_dict.get('id', 'Unknown')
                    if isinstance(result, dict):
                        await self.update_lawyer_stats(lawyer_id, result)
                    else:
                        logger.error(f"Resultado inválido para advogado {lawyer_id}: {type(result)}")
                except Exception as e:
                    logger_dict = dict(lawyer)
                    logger_id = logger_dict.get('id', 'Unknown')
                    logger.error(f"Erro ao atualizar stats do advogado {logger_id}: {e}")
            
            # Pausa entre lotes
            await asyncio.sleep(5)
        
        logger.info("Sincronização concluída")

async def main():
    """Função principal do job"""
    if not API_KEY:
        logger.error("JUSBRASIL_API_KEY não configurada")
        return
    
    if not DB_DSN:
        logger.error("DATABASE_URL não configurada")
        return
    
    etl = JusbrasilETL()
    
    try:
        etl.connect_db()
        await etl.sync_all_lawyers()
    except Exception as e:
        logger.error(f"Erro na sincronização: {e}")
        raise
    finally:
        etl.close_db()

# Tarefas Celery
try:
    from backend.celery_app import celery_app
    
    @celery_app.task(name='backend.jobs.jusbrasil_sync.sync_all_lawyers_task')
    def sync_all_lawyers_task():
        """Tarefa Celery que executa a sincronização completa com Jusbrasil"""
        import asyncio
        
        loop = asyncio.new_event_loop()
        asyncio.set_event_loop(loop)
        
        try:
            # Executar o job assíncrono
            loop.run_until_complete(main())
            return {
                'status': 'success',
                'message': 'Sincronização completa concluída com sucesso'
            }
        except Exception as e:
            logger.error(f"Erro na tarefa Celery de sincronização completa: {e}")
            return {
                'status': 'error',
                'error': str(e)
            }
        finally:
            loop.close()
    
    @celery_app.task(name='backend.jobs.jusbrasil_sync.sync_incremental_task')
    def sync_incremental_task():
        """Tarefa Celery que executa sincronização incremental (advogados com poucos dados)"""
        import asyncio
        
        loop = asyncio.new_event_loop()
        asyncio.set_event_loop(loop)
        
        try:
            # Executar sincronização incremental
            loop.run_until_complete(sync_incremental_lawyers())
            return {
                'status': 'success', 
                'message': 'Sincronização incremental concluída com sucesso'
            }
        except Exception as e:
            logger.error(f"Erro na tarefa Celery de sincronização incremental: {e}")
            return {
                'status': 'error',
                'error': str(e)
            }
        finally:
            loop.close()
    
    @celery_app.task(name='backend.jobs.jusbrasil_sync.cleanup_old_data_task')
    def cleanup_old_data_task():
        """Tarefa Celery para limpeza de dados antigos"""
        import asyncio
        
        loop = asyncio.new_event_loop()
        asyncio.set_event_loop(loop)
        
        try:
            loop.run_until_complete(cleanup_old_data())
            return {
                'status': 'success',
                'message': 'Limpeza de dados antigos concluída com sucesso'
            }
        except Exception as e:
            logger.error(f"Erro na tarefa Celery de limpeza: {e}")
            return {
                'status': 'error',
                'error': str(e)
            }
        finally:
            loop.close()

except ImportError:
    # Se não conseguir importar Celery, continua funcionando como script standalone
    logger.warning("Celery não disponível. Tasks não serão registradas.")
    pass

async def sync_incremental_lawyers():
    """Sincronização incremental para advogados com poucos dados ou dados antigos"""
    if not API_KEY:
        logger.error("JUSBRASIL_API_KEY não configurada")
        return
    
    if not DB_DSN:
        logger.error("DATABASE_URL não configurada")
        return
    
    etl = JusbrasilETL()
    
    try:
        etl.connect_db()
        cursor = etl.db_connection.cursor()
        
        # Buscar advogados que precisam de sync incremental
        cursor.execute("""
            SELECT id, oab_numero, uf, nome
            FROM lawyers 
            WHERE oab_numero IS NOT NULL 
            AND uf IS NOT NULL
            AND (
                total_cases < 5 OR 
                last_jusbrasil_sync IS NULL OR 
                last_jusbrasil_sync < NOW() - INTERVAL '3 days'
            )
            ORDER BY last_jusbrasil_sync NULLS FIRST
            LIMIT 50
        """)
        
        lawyers = cursor.fetchall()
        logger.info(f"Sincronização incremental: {len(lawyers)} advogados")
        
        # Processar advogados individualmente para controle fino
        for lawyer in lawyers:
            try:
                lawyer_dict = dict(lawyer)
                stats = await etl.sync_lawyer_processes(lawyer_dict)
                await etl.update_lawyer_stats(lawyer_dict['id'], stats)
                
                # Pausa entre advogados para não sobrecarregar a API
                await asyncio.sleep(2)
                
            except Exception as e:
                logger.error(f"Erro na sincronização incremental do advogado {lawyer.get('id', 'N/A')}: {e}")
                continue
        
        logger.info("Sincronização incremental concluída")
        
    except Exception as e:
        logger.error(f"Erro na sincronização incremental: {e}")
        raise
    finally:
        etl.close_db()

async def cleanup_old_data():
    """Limpeza de dados antigos e otimização do banco"""
    if not DB_DSN:
        logger.error("DATABASE_URL não configurada")
        return
    
    connection = psycopg2.connect(DB_DSN, cursor_factory=RealDictCursor)
    
    try:
        cursor = connection.cursor()
        
        # Remover casos muito antigos (mais de 2 anos) que podem não ser mais relevantes
        cursor.execute("""
            DELETE FROM lawyer_cases 
            WHERE created_at < NOW() - INTERVAL '2 years'
            AND outcome IS NULL
        """)
        
        deleted_cases = cursor.rowcount
        logger.info(f"Removidos {deleted_cases} casos antigos sem outcome")
        
        # Remover embeddings duplicados (manter apenas os mais recentes)
        cursor.execute("""
            DELETE FROM lawyer_embeddings le1
            WHERE EXISTS (
                SELECT 1 FROM lawyer_embeddings le2
                WHERE le2.lawyer_id = le1.lawyer_id
                AND le2.created_at > le1.created_at
                AND le2.embedding <-> le1.embedding < 0.1
            )
        """)
        
        deleted_embeddings = cursor.rowcount
        logger.info(f"Removidos {deleted_embeddings} embeddings duplicados")
        
        # Atualizar estatísticas das tabelas
        cursor.execute("VACUUM ANALYZE lawyer_cases")
        cursor.execute("VACUUM ANALYZE lawyer_embeddings")
        
        connection.commit()
        logger.info("Limpeza de dados concluída com sucesso")
        
    except Exception as e:
        connection.rollback()
        logger.error(f"Erro na limpeza de dados: {e}")
        raise
    finally:
        connection.close()

if __name__ == "__main__":
    asyncio.run(main()) 
