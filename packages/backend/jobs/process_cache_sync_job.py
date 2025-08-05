#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
jobs/process_cache_sync_job.py

Job de sincronização automática do cache de processos.
Atualiza dados em background para evitar reconsultas durante uso da aplicação.
"""

import asyncio
import logging
import time
from datetime import datetime, timedelta
from typing import Any, Dict, List, Optional

from config.database import get_database
from services.process_cache_service import process_cache_service
from services.escavador_integration import EscavadorClient
from config.base import ESCAVADOR_API_KEY

logger = logging.getLogger(__name__)

class ProcessCacheSyncJob:
    """
    Job responsável por manter o cache de processos atualizado em background.
    
    Executa as seguintes tarefas:
    1. Identifica processos com cache próximo do vencimento
    2. Atualiza dados do Escavador de forma gradual 
    3. Limpa cache expirado
    4. Monitora taxa de sucesso das sincronizações
    """
    
    def __init__(self):
        self.sync_interval_minutes = 30  # Executa a cada 30 minutos
        self.batch_size = 10  # Processa 10 processos por vez
        self.max_daily_syncs = 200  # Limite diário de sincronizações
        self.priority_threshold_hours = 2  # Sincroniza com prioridade se expirar em 2h
        
    async def run_continuous(self):
        """
        Executa o job continuamente em background.
        Uso: asyncio.create_task(job.run_continuous())
        """
        logger.info("🔄 Iniciando job de sincronização contínua do cache de processos")
        
        while True:
            try:
                await self.run_sync_cycle()
                
                # Aguardar próximo ciclo
                await asyncio.sleep(self.sync_interval_minutes * 60)
                
            except Exception as e:
                logger.error(f"Erro no ciclo de sincronização: {e}")
                # Em caso de erro, aguardar menos tempo antes de tentar novamente
                await asyncio.sleep(300)  # 5 minutos
    
    async def run_sync_cycle(self):
        """
        Executa um ciclo completo de sincronização.
        """
        cycle_start = datetime.now()
        logger.info(f"🔄 Iniciando ciclo de sincronização: {cycle_start}")
        
        try:
            # 1. Verificar se API está disponível
            api_available = await self._check_api_health()
            if not api_available:
                logger.warning("API do Escavador indisponível - pulando sincronização")
                return
            
            # 2. Identificar processos que precisam de atualização
            processes_to_sync = await self._get_processes_for_sync()
            
            if not processes_to_sync:
                logger.info("Nenhum processo precisa de sincronização no momento")
                return
            
            logger.info(f"Encontrados {len(processes_to_sync)} processos para sincronização")
            
            # 3. Sincronizar em lotes para não sobrecarregar API
            sync_results = await self._sync_processes_in_batches(processes_to_sync)
            
            # 4. Limpar cache expirado
            cleaned_items = await self._cleanup_expired_cache()
            
            # 5. Registrar estatísticas
            await self._log_sync_statistics(cycle_start, sync_results, cleaned_items)
            
        except Exception as e:
            logger.error(f"Erro no ciclo de sincronização: {e}")
    
    async def _check_api_health(self) -> bool:
        """Verifica se a API do Escavador está funcionando."""
        if not ESCAVADOR_API_KEY:
            return False
            
        try:
            client = EscavadorClient(api_key=ESCAVADOR_API_KEY)
            
            # Teste simples: buscar status de um processo conhecido
            test_cnj = "0000000-00.0000.0.00.0000"  # CNJ fictício para teste
            
            # Timeout rápido para não atrasar o job
            await asyncio.wait_for(
                client.get_process_update_status(test_cnj), 
                timeout=10.0
            )
            return True
            
        except asyncio.TimeoutError:
            logger.warning("API do Escavador respondendo lentamente")
            return False
        except Exception as e:
            logger.warning(f"API do Escavador indisponível: {e}")
            return False
    
    async def _get_processes_for_sync(self) -> List[Dict[str, Any]]:
        """
        Identifica processos que precisam de sincronização.
        
        Prioridades:
        1. Cache expirando em até 2 horas (alta prioridade)
        2. Cache expirado há menos de 24 horas (média prioridade)  
        3. Processos ativos sem sincronização recente (baixa prioridade)
        """
        try:
            async with get_database() as db:
                # Buscar processos por prioridade
                processes = await db.fetch("""
                    WITH priority_processes AS (
                        -- Alta prioridade: expirando em 2 horas
                        SELECT DISTINCT cnj, 'high' as priority, cache_valid_until, last_api_sync
                        FROM process_status_cache 
                        WHERE cache_valid_until BETWEEN NOW() AND NOW() + INTERVAL '2 hours'
                        AND sync_status != 'failed'
                        
                        UNION ALL
                        
                        -- Média prioridade: expirado há menos de 24h
                        SELECT DISTINCT cnj, 'medium' as priority, cache_valid_until, last_api_sync
                        FROM process_status_cache 
                        WHERE cache_valid_until < NOW() 
                        AND cache_valid_until > NOW() - INTERVAL '24 hours'
                        AND sync_status != 'failed'
                        
                        UNION ALL
                        
                        -- Baixa prioridade: processos ativos sem sync recente
                        SELECT DISTINCT pm.cnj, 'low' as priority, 
                               COALESCE(psc.cache_valid_until, NOW() - INTERVAL '1 day') as cache_valid_until,
                               COALESCE(psc.last_api_sync, NOW() - INTERVAL '7 days') as last_api_sync
                        FROM process_movements pm 
                        LEFT JOIN process_status_cache psc ON pm.cnj = psc.cnj
                        WHERE pm.fetched_from_api_at > NOW() - INTERVAL '7 days'  -- Processos ativos
                        AND (psc.last_api_sync IS NULL OR psc.last_api_sync < NOW() - INTERVAL '6 hours')
                        AND pm.cnj IN (
                            -- Apenas processos de usuários ativos
                            SELECT DISTINCT numero_processo FROM lawyer_cases 
                            WHERE updated_at > NOW() - INTERVAL '30 days'
                        )
                    )
                    SELECT cnj, priority, cache_valid_until, last_api_sync
                    FROM priority_processes 
                    ORDER BY 
                        CASE priority 
                            WHEN 'high' THEN 1 
                            WHEN 'medium' THEN 2 
                            WHEN 'low' THEN 3 
                        END,
                        cache_valid_until ASC
                    LIMIT $1
                """, self.batch_size * 3)  # Buscar mais para poder priorizar
                
                # Verificar limite diário
                today_syncs = await self._get_today_sync_count()
                available_syncs = max(0, self.max_daily_syncs - today_syncs)
                
                if available_syncs == 0:
                    logger.warning("Limite diário de sincronizações atingido")
                    return []
                
                # Limitar ao disponível
                return list(processes[:min(len(processes), available_syncs)])
                
        except Exception as e:
            logger.error(f"Erro ao identificar processos para sync: {e}")
            return []
    
    async def _sync_processes_in_batches(self, processes: List[Dict[str, Any]]) -> Dict[str, int]:
        """
        Sincroniza processos em lotes para não sobrecarregar a API.
        """
        results = {"success": 0, "failed": 0, "skipped": 0}
        
        if not ESCAVADOR_API_KEY:
            logger.error("ESCAVADOR_API_KEY não configurada")
            return results
        
        client = EscavadorClient(api_key=ESCAVADOR_API_KEY)
        
        # Processar em lotes menores
        for i in range(0, len(processes), self.batch_size):
            batch = processes[i:i + self.batch_size]
            
            logger.info(f"Sincronizando lote {i//self.batch_size + 1}: {len(batch)} processos")
            
            # Sincronizar lote com delay entre requisições
            for process in batch:
                cnj = process['cnj']
                
                try:
                    # Forçar refresh para obter dados frescos
                    await client.get_detailed_process_movements(cnj, limit=20, force_refresh=True)
                    
                    # Registrar sucesso no banco
                    await self._update_sync_status(cnj, "success")
                    results["success"] += 1
                    
                    logger.debug(f"✅ Sincronizado com sucesso: {cnj}")
                    
                except Exception as e:
                    logger.warning(f"❌ Erro ao sincronizar {cnj}: {e}")
                    
                    # Registrar falha no banco
                    await self._update_sync_status(cnj, "failed", str(e))
                    results["failed"] += 1
                
                # Delay entre requisições para respeitar rate limit
                await asyncio.sleep(2.0)
            
            # Delay maior entre lotes
            if i + self.batch_size < len(processes):
                logger.info("Aguardando antes do próximo lote...")
                await asyncio.sleep(10.0)
        
        return results
    
    async def _cleanup_expired_cache(self) -> int:
        """Remove dados de cache muito antigos."""
        try:
            async with get_database() as db:
                # Usar função criada na migração
                result = await db.fetchval("SELECT clean_expired_process_cache()")
                
                if result and result > 0:
                    logger.info(f"🧹 Limpeza de cache: {result} registros removidos")
                    
                return result or 0
                
        except Exception as e:
            logger.error(f"Erro na limpeza de cache: {e}")
            return 0
    
    async def _update_sync_status(self, cnj: str, status: str, error_msg: Optional[str] = None):
        """Atualiza status de sincronização no banco."""
        try:
            async with get_database() as db:
                errors_array = [error_msg] if error_msg else []
                
                await db.execute("""
                    UPDATE process_status_cache 
                    SET 
                        sync_status = $2,
                        last_api_sync = NOW(),
                        api_errors = $3,
                        updated_at = NOW()
                    WHERE cnj = $1
                """, cnj, status, errors_array)
                
        except Exception as e:
            logger.error(f"Erro ao atualizar status de sync para {cnj}: {e}")
    
    async def _get_today_sync_count(self) -> int:
        """Conta quantas sincronizações foram feitas hoje."""
        try:
            async with get_database() as db:
                count = await db.fetchval("""
                    SELECT COUNT(*) FROM process_status_cache 
                    WHERE last_api_sync >= CURRENT_DATE 
                    AND sync_status = 'success'
                """)
                return count or 0
                
        except Exception as e:
            logger.error(f"Erro ao contar syncs de hoje: {e}")
            return 0
    
    async def _log_sync_statistics(
        self, 
        cycle_start: datetime, 
        sync_results: Dict[str, int], 
        cleaned_items: int
    ):
        """Registra estatísticas do ciclo de sincronização."""
        cycle_duration = datetime.now() - cycle_start
        
        total_processed = sum(sync_results.values())
        success_rate = (sync_results["success"] / total_processed * 100) if total_processed > 0 else 0
        
        logger.info(f"""
📊 Ciclo de sincronização concluído:
   ⏱️  Duração: {cycle_duration}
   ✅ Sucessos: {sync_results['success']}
   ❌ Falhas: {sync_results['failed']}
   ⏭️  Pulados: {sync_results['skipped']}
   📈 Taxa de sucesso: {success_rate:.1f}%
   🧹 Cache limpo: {cleaned_items} itens
        """.strip())

# Instância global para usar em outros módulos
process_cache_sync_job = ProcessCacheSyncJob()

# Função para iniciar o job (chamada no main.py)
async def start_background_sync():
    """Inicia o job de sincronização em background."""
    if ESCAVADOR_API_KEY:
        logger.info("🚀 Iniciando job de sincronização de cache em background")
        asyncio.create_task(process_cache_sync_job.run_continuous())
    else:
        logger.warning("ESCAVADOR_API_KEY não configurada - job de sincronização desabilitado") 