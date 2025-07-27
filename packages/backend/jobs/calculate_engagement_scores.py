#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Calculate Engagement Scores Job
===============================

Job para calcular o Índice de Engajamento na Plataforma (IEP) 
de todos os advogados de forma batch e periódica.
"""

import asyncio
import logging
import sys
from datetime import datetime, timedelta
from typing import List, Dict, Any
from pathlib import Path
from celery import shared_task

# Adicionar path do backend
backend_dir = Path(__file__).parent.parent
sys.path.insert(0, str(backend_dir))

try:
    from services.engagement_index_service import EngagementIndexService
    from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
    from sqlalchemy.orm import sessionmaker
    from sqlalchemy import text
    import os
except ImportError as e:
    print(f"Erro de importação: {e}")
    sys.exit(1)

logger = logging.getLogger(__name__)

# Configuração do banco de dados
DATABASE_URL = os.getenv("DATABASE_URL", "postgresql+asyncpg://localhost/litig")
engine = create_async_engine(DATABASE_URL, echo=False)
AsyncSessionLocal = sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)


class EngagementScoreJob:
    """Job para calcular scores de engajamento."""
    
    def __init__(self):
        self.logger = logging.getLogger(__name__)
        self.batch_size = int(os.getenv("IEP_BATCH_SIZE", "50"))
        self.max_parallel = int(os.getenv("IEP_MAX_PARALLEL", "5"))
    
    async def run_full_calculation(self) -> Dict[str, Any]:
        """
        Executa cálculo completo de IEP para todos os advogados.
        
        Returns:
            Dict com estatísticas da execução
        """
        
        start_time = datetime.utcnow()
        self.logger.info("🚀 Iniciando cálculo batch do IEP")
        
        async with AsyncSessionLocal() as db:
            try:
                # 1. Buscar todos os advogados ativos
                lawyer_ids = await self._get_active_lawyers(db)
                total_lawyers = len(lawyer_ids)
                
                if not lawyer_ids:
                    self.logger.warning("Nenhum advogado encontrado para cálculo de IEP")
                    return {"status": "no_lawyers", "total_lawyers": 0}
                
                self.logger.info(f"📊 Calculando IEP para {total_lawyers} advogados")
                
                # 2. Processar em batches
                engagement_service = EngagementIndexService(db)
                
                processed = 0
                successful = 0
                failed = 0
                scores_distribution = {"high": 0, "medium": 0, "low": 0}
                
                # Dividir em batches
                batches = [
                    lawyer_ids[i:i + self.batch_size] 
                    for i in range(0, len(lawyer_ids), self.batch_size)
                ]
                
                for batch_num, batch in enumerate(batches, 1):
                    self.logger.info(f"📦 Processando batch {batch_num}/{len(batches)} ({len(batch)} advogados)")
                    
                    try:
                        # Processar batch
                        batch_results = await engagement_service.calculate_batch_scores(batch)
                        
                        # Contabilizar resultados
                        for lawyer_id, score in batch_results.items():
                            processed += 1
                            if score > 0:
                                successful += 1
                                # Classificar score
                                if score >= 0.7:
                                    scores_distribution["high"] += 1
                                elif score >= 0.4:
                                    scores_distribution["medium"] += 1
                                else:
                                    scores_distribution["low"] += 1
                            else:
                                failed += 1
                        
                        self.logger.info(f"   ✅ Batch {batch_num} processado: {len(batch_results)} scores calculados")
                        
                        # Pequena pausa entre batches para não sobrecarregar
                        await asyncio.sleep(0.5)
                        
                    except Exception as e:
                        self.logger.error(f"❌ Erro no batch {batch_num}: {e}")
                        failed += len(batch)
                
                # 3. Calcular estatísticas finais
                end_time = datetime.utcnow()
                duration = (end_time - start_time).total_seconds()
                
                # 4. Atualizar metadados do job
                await self._save_job_metadata(db, {
                    "total_lawyers": total_lawyers,
                    "processed": processed,
                    "successful": successful,
                    "failed": failed,
                    "duration_seconds": duration,
                    "scores_distribution": scores_distribution,
                    "executed_at": start_time.isoformat(),
                    "completed_at": end_time.isoformat()
                })
                
                self.logger.info(f"🎯 IEP calculation completed:")
                self.logger.info(f"   📊 Total: {total_lawyers}")
                self.logger.info(f"   ✅ Successful: {successful}")
                self.logger.info(f"   ❌ Failed: {failed}")
                self.logger.info(f"   ⏱️  Duration: {duration:.1f}s")
                self.logger.info(f"   📈 High scores (≥0.7): {scores_distribution['high']}")
                self.logger.info(f"   📊 Medium scores (0.4-0.7): {scores_distribution['medium']}")
                self.logger.info(f"   📉 Low scores (<0.4): {scores_distribution['low']}")
                
                return {
                    "status": "completed",
                    "total_lawyers": total_lawyers,
                    "processed": processed,
                    "successful": successful,
                    "failed": failed,
                    "duration_seconds": duration,
                    "scores_distribution": scores_distribution
                }
                
            except Exception as e:
                self.logger.error(f"❌ Erro crítico no cálculo do IEP: {e}")
                return {
                    "status": "error",
                    "error": str(e),
                    "duration_seconds": (datetime.utcnow() - start_time).total_seconds()
                }
    
    async def run_incremental_calculation(self, days_threshold: int = 7) -> Dict[str, Any]:
        """
        Executa cálculo incremental apenas para advogados que precisam de atualização.
        
        Args:
            days_threshold: Recalcular se última atualização foi há mais de X dias
        
        Returns:
            Dict com estatísticas da execução
        """
        
        start_time = datetime.utcnow()
        cutoff_date = start_time - timedelta(days=days_threshold)
        
        self.logger.info(f"🔄 Iniciando cálculo incremental do IEP (threshold: {days_threshold} dias)")
        
        async with AsyncSessionLocal() as db:
            try:
                # Buscar advogados que precisam de atualização
                query = text("""
                    SELECT id FROM lawyers 
                    WHERE engagement_updated_at IS NULL 
                       OR engagement_updated_at < :cutoff_date
                    ORDER BY COALESCE(engagement_updated_at, '1900-01-01') ASC
                """)
                
                result = await db.execute(query, {"cutoff_date": cutoff_date})
                lawyer_ids = [row.id for row in result.fetchall()]
                
                if not lawyer_ids:
                    self.logger.info("✅ Todos os advogados estão com IEP atualizado")
                    return {"status": "up_to_date", "total_lawyers": 0}
                
                self.logger.info(f"📊 Atualizando IEP para {len(lawyer_ids)} advogados desatualizados")
                
                # Processar incremental
                engagement_service = EngagementIndexService(db)
                batch_results = await engagement_service.calculate_batch_scores(lawyer_ids)
                
                # Estatísticas
                successful = sum(1 for score in batch_results.values() if score > 0)
                failed = len(lawyer_ids) - successful
                
                duration = (datetime.utcnow() - start_time).total_seconds()
                
                self.logger.info(f"✅ IEP incremental completed: {successful} successful, {failed} failed in {duration:.1f}s")
                
                return {
                    "status": "completed",
                    "mode": "incremental",
                    "total_lawyers": len(lawyer_ids),
                    "successful": successful,
                    "failed": failed,
                    "duration_seconds": duration
                }
                
            except Exception as e:
                self.logger.error(f"❌ Erro no cálculo incremental: {e}")
                return {
                    "status": "error",
                    "mode": "incremental",
                    "error": str(e)
                }
    
    async def _get_active_lawyers(self, db: AsyncSession) -> List[str]:
        """Busca IDs de todos os advogados ativos."""
        
        query = text("""
            SELECT id FROM lawyers 
            WHERE status = 'active' 
               OR status IS NULL
            ORDER BY created_at DESC
        """)
        
        result = await db.execute(query)
        return [row.id for row in result.fetchall()]
    
    async def _save_job_metadata(self, db: AsyncSession, metadata: Dict[str, Any]) -> None:
        """Salva metadados da execução do job."""
        
        try:
            query = text("""
                INSERT INTO job_execution_logs 
                (job_name, metadata, executed_at, status)
                VALUES ('calculate_engagement_scores', :metadata, CURRENT_TIMESTAMP, :status)
            """)
            
            await db.execute(query, {
                "metadata": metadata,
                "status": metadata.get("status", "completed")
            })
            await db.commit()
            
        except Exception as e:
            self.logger.error(f"Erro ao salvar metadata do job: {e}")


@shared_task(name="calculate_engagement_scores.calculate_iep_task")
def calculate_iep_task() -> Dict[str, Any]:
    """
    Task Celery para cálculo diário do Índice de Engajamento na Plataforma (IEP).
    
    Executa o cálculo completo do IEP para todos os advogados e atualiza
    a coluna interaction_score na tabela lawyers.
    
    Returns:
        Dict com estatísticas da execução
    """
    from datetime import datetime
    
    start_time = datetime.now()
    
    try:
        logger.info("📈 Iniciando cálculo diário do IEP (Índice de Engajamento)")
        
        # Importar serviço
        from services.engagement_index_service import EngagementIndexService
        
        # Inicializar job de cálculo  
        from jobs.calculate_engagement_scores import EngagementScoreJob
        
        engagement_job = EngagementScoreJob()
        
        # Executar cálculo completo
        result = engagement_job.run_full_calculation()
        
        duration = (datetime.now() - start_time).total_seconds()
        
        logger.info(f"✅ IEP calculado com sucesso em {duration:.1f}s")
        logger.info(f"   Advogados processados: {result.get('processed_lawyers', 0)}")
        logger.info(f"   Score médio: {result.get('average_iep', 0):.3f}")
        
        return {
            "status": "success",
            "processed_lawyers": result.get("processed_lawyers", 0),
            "average_iep": result.get("average_iep", 0),
            "execution_time_seconds": duration,
            "timestamp": datetime.now().isoformat()
        }
        
    except Exception as e:
        duration = (datetime.now() - start_time).total_seconds()
        
        logger.error(f"❌ Erro no cálculo do IEP: {e}")
        
        return {
            "status": "error", 
            "error": str(e),
            "execution_time_seconds": duration,
            "timestamp": datetime.now().isoformat()
        }


async def main():
    """Função principal para execução do job."""
    
    # Configurar logging
    logging.basicConfig(
        level=logging.INFO,
        format='%(asctime)s - %(levelname)s - %(message)s'
    )
    
    print("🚀 LITIG - Engagement Score Calculation Job")
    print("=" * 50)
    
    job = EngagementScoreJob()
    
    # Determinar modo de execução
    mode = os.getenv("IEP_MODE", "incremental")  # full, incremental
    
    if mode == "full":
        print("📊 Modo: Cálculo completo (todos os advogados)")
        result = await job.run_full_calculation()
    else:
        print("🔄 Modo: Cálculo incremental (apenas desatualizados)")
        threshold_days = int(os.getenv("IEP_THRESHOLD_DAYS", "7"))
        result = await job.run_incremental_calculation(threshold_days)
    
    print("\n📋 RESULTADO:")
    print(f"   Status: {result['status']}")
    if result.get("total_lawyers"):
        print(f"   Advogados: {result['total_lawyers']}")
        print(f"   Sucessos: {result.get('successful', 0)}")
        print(f"   Falhas: {result.get('failed', 0)}")
        print(f"   Duração: {result.get('duration_seconds', 0):.1f}s")
    
    if result.get("scores_distribution"):
        dist = result["scores_distribution"]
        print(f"   📈 Scores altos: {dist.get('high', 0)}")
        print(f"   📊 Scores médios: {dist.get('medium', 0)}")
        print(f"   📉 Scores baixos: {dist.get('low', 0)}")
    
    # Códigos de saída
    if result["status"] == "completed":
        print("\n✅ Job executado com sucesso!")
        sys.exit(0)
    elif result["status"] == "up_to_date":
        print("\n✅ Todos os scores estão atualizados!")
        sys.exit(0)
    else:
        print(f"\n❌ Job falhou: {result.get('error', 'Erro desconhecido')}")
        sys.exit(1)


if __name__ == "__main__":
    asyncio.run(main()) 