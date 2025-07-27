#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Job para Enriquecimento em Massa de Perfis de Advogados
======================================================

🆕 V2.1: Background Job Optimization
- Usa :floor routing para mínimo custo
- Processamento batch otimizado
- Rate limiting inteligente
- Web search para reputação atualizada

Executa enriquecimento de perfis em lote com prioridade de custo.
"""

import asyncio
import logging
import time
from typing import List, Dict, Any, Optional
from datetime import datetime

# Imports
try:
    from services.lawyer_profile_analysis_service_v2 import LawyerProfileAnalysisServiceV2
except ImportError:
    from ..services.lawyer_profile_analysis_service_v2 import LawyerProfileAnalysisServiceV2

try:
    from celery_app import celery_app
except ImportError:
    try:
        from ..celery_app import celery_app
    except ImportError:
        # Mock para validação
        class MockCeleryApp:
            def task(self, *args, **kwargs):
                def decorator(f):
                    return f
                return decorator
        celery_app = MockCeleryApp()

logger = logging.getLogger(__name__)


class LawyerProfileEnrichmentJob:
    """
    🆕 V2.1: Job para enriquecimento em massa de perfis de advogados.
    
    Otimizado para custo com :floor routing e web search controlado.
    """
    
    def __init__(self):
        self.profile_service = LawyerProfileAnalysisServiceV2()
        self.batch_size = 10  # Processar em lotes pequenos
        self.rate_limit_delay = 3  # 3 segundos entre requests para não sobrecarregar
        
    async def enrich_profiles_batch(
        self, 
        lawyer_ids: List[str],
        enable_web_search: bool = True,
        search_depth: str = "quick"  # "quick" para jobs batch
    ) -> Dict[str, Any]:
        """
        🆕 V2.1: Enriquece perfis em lote com prioridade de custo.
        
        Args:
            lawyer_ids: Lista de IDs de advogados
            enable_web_search: Habilita web search (controlado para batch)
            search_depth: Profundidade da busca ("quick" para economia)
        
        Returns:
            Resultado do enriquecimento batch
        """
        start_time = time.time()
        results = []
        errors = []
        
        logger.info(f"🔄 Iniciando enriquecimento batch de {len(lawyer_ids)} perfis")
        
        for i, lawyer_id in enumerate(lawyer_ids):
            try:
                # Obter dados do advogado
                lawyer_data = await self._get_lawyer_data(lawyer_id)
                if not lawyer_data:
                    errors.append(f"Dados não encontrados para lawyer_id: {lawyer_id}")
                    continue
                
                # 🆕 V2.1: Usar web search com profundidade "quick" para economia
                # Priority="cost" usa automaticamente :floor routing
                enriched_profile = await self.profile_service.analyze_lawyer_profile(
                    lawyer_data=lawyer_data,
                    enable_reputation_search=enable_web_search,
                    search_depth=search_depth  # "quick" = últimos 6 meses apenas
                )
                
                results.append({
                    "lawyer_id": lawyer_id,
                    "enrichment_success": True,
                    "online_reputation_score": enriched_profile.online_reputation_data.get("score", 0.0) if enriched_profile.online_reputation_data else 0.0,
                    "web_search_used": enriched_profile.processing_metadata.get("web_search_used", False),
                    "processing_time_ms": enriched_profile.processing_metadata.get("processing_time_ms", 0),
                    "model_used": enriched_profile.model_used,
                    "fallback_level": enriched_profile.fallback_level
                })
                
                logger.info(f"✅ Enriquecimento {i+1}/{len(lawyer_ids)}: {lawyer_id} - Score: {enriched_profile.online_reputation_data.get('score', 'N/A') if enriched_profile.online_reputation_data else 'N/A'}")
                
                # 🆕 V2.1: Rate limiting para não sobrecarregar APIs
                if i < len(lawyer_ids) - 1:  # Não fazer delay no último
                    await asyncio.sleep(self.rate_limit_delay)
                
            except Exception as e:
                error_msg = f"Erro ao enriquecer perfil {lawyer_id}: {str(e)}"
                logger.error(error_msg)
                errors.append(error_msg)
                
                # Continuar processamento mesmo com erros
                results.append({
                    "lawyer_id": lawyer_id,
                    "enrichment_success": False,
                    "error": str(e)
                })
        
        processing_time = time.time() - start_time
        
        # Estatísticas do batch
        successful = sum(1 for r in results if r.get("enrichment_success", False))
        failed = len(results) - successful
        avg_processing_time = sum(r.get("processing_time_ms", 0) for r in results if r.get("processing_time_ms")) / max(successful, 1)
        
        batch_result = {
            "batch_summary": {
                "total_processed": len(lawyer_ids),
                "successful": successful,
                "failed": failed,
                "success_rate": successful / len(lawyer_ids) if lawyer_ids else 0,
                "total_processing_time": processing_time,
                "avg_processing_time_ms": avg_processing_time,
                "web_search_enabled": enable_web_search,
                "search_depth": search_depth,
                "rate_limit_delay": self.rate_limit_delay
            },
            "results": results,
            "errors": errors
        }
        
        logger.info(f"🎯 Batch concluído: {successful}/{len(lawyer_ids)} sucessos ({batch_result['batch_summary']['success_rate']*100:.1f}%)")
        
        return batch_result
    
    async def enrich_all_active_lawyers(
        self,
        batch_size: int = 50,
        search_depth: str = "quick"
    ) -> Dict[str, Any]:
        """
        🆕 V2.1: Enriquece todos os advogados ativos em batches.
        
        Processa todos os advogados ativos da plataforma em lotes otimizados.
        
        Args:
            batch_size: Tamanho do batch para processamento
            search_depth: Profundidade da busca ("quick", "standard", "deep")
        
        Returns:
            Resultado consolidado do enriquecimento global
        """
        try:
            # TODO: Implementar query real para obter IDs de advogados ativos
            # Por enquanto, usar IDs mock
            all_lawyer_ids = [f"lawyer_{i}" for i in range(100)]  # Mock: 100 advogados
            
            results = []
            total_batches = (len(all_lawyer_ids) + batch_size - 1) // batch_size
            
            logger.info(f"🚀 Enriquecimento global V2.1: {len(all_lawyer_ids)} advogados em {total_batches} batches")
            
            for i in range(0, len(all_lawyer_ids), batch_size):
                batch_ids = all_lawyer_ids[i:i + batch_size]
                batch_num = (i // batch_size) + 1
                
                logger.info(f"🔄 Processando batch {batch_num}/{total_batches}")
                
                # Executar batch
                batch_result = await self.enrich_profiles_batch(
                    lawyer_ids=batch_ids,
                    enable_web_search=True,
                    search_depth=search_depth
                )
                
                results.append({
                    "batch_number": batch_num,
                    "batch_size": len(batch_ids),
                    "batch_result": batch_result
                })
                
                # Delay entre batches para não sobrecarregar
                await asyncio.sleep(10)
            
            # Consolidar resultados
            total_processed = sum(r["batch_result"]["batch_summary"]["total_processed"] for r in results)
            total_successful = sum(r["batch_result"]["batch_summary"]["successful"] for r in results)
            
            return {
                "global_summary": {
                    "total_batches": total_batches,
                    "total_lawyers_processed": total_processed,
                    "total_successful": total_successful,
                    "global_success_rate": total_successful / total_processed if total_processed > 0 else 0,
                    "search_depth_used": search_depth,
                    "optimization": "floor_routing_v2.1"
                },
                "batch_results": results
            }
            
        except Exception as e:
            logger.error(f"❌ Erro no enriquecimento global: {e}")
            return {"error": str(e)}
    
    async def _get_lawyer_data(self, lawyer_id: str) -> Optional[Dict[str, Any]]:
        """
        Obtém dados do advogado do banco de dados.
        
        Args:
            lawyer_id: ID do advogado
        
        Returns:
            Dados do advogado ou None se não encontrado
        """
        try:
            # TODO: Implementar query real ao banco
            # Por enquanto, retornar dados mock para teste
            return {
                "id": lawyer_id,
                "nome": f"Advogado {lawyer_id}",
                "oab": f"OAB{lawyer_id}",
                "escritorio": f"Escritório {lawyer_id}",
                "areas_atuacao": ["Civil", "Trabalhista"],
                "experiencia_anos": 5
            }
        except Exception as e:
            logger.error(f"Erro ao obter dados do lawyer_id {lawyer_id}: {e}")
            return None


# 🆕 V2.1: Celery Tasks para Enriquecimento de Perfis

@celery_app.task(name="enrich_lawyer_profiles_batch", bind=True)
def enrich_lawyer_profiles_batch_task(
    self,
    lawyer_ids: List[str],
    enable_web_search: bool = True,
    search_depth: str = "quick"
) -> Dict[str, Any]:
    """
    🆕 V2.1: Task Celery para enriquecimento em lote de perfis.
    
    Otimizada com :floor routing para mínimo custo em background jobs.
    """
    logger.info(f"🚀 Iniciando enriquecimento batch V2.1 para {len(lawyer_ids)} advogados")
    
    try:
        # Executar job assíncrono em thread separada
        loop = asyncio.new_event_loop()
        asyncio.set_event_loop(loop)
        
        job = LawyerProfileEnrichmentJob()
        result = loop.run_until_complete(
            job.enrich_profiles_batch(
                lawyer_ids=lawyer_ids,
                enable_web_search=enable_web_search,
                search_depth=search_depth
            )
        )
        
        logger.info(f"✅ Batch concluído: {result['batch_summary']['successful']}/{result['batch_summary']['total_processed']} sucessos")
        return result
        
    except Exception as e:
        logger.error(f"❌ Erro no batch task: {e}")
        return {"error": str(e), "task_id": self.request.id}
    finally:
        loop.close()


@celery_app.task(name="enrich_all_active_lawyers", bind=True)
def enrich_all_active_lawyers_task(
    self,
    batch_size: int = 50,
    search_depth: str = "quick"
) -> Dict[str, Any]:
    """
    🆕 V2.1: Task Celery para enriquecimento global de todos os advogados ativos.
    
    Processamento em batches otimizado com :floor routing.
    """
    logger.info(f"🌐 Iniciando enriquecimento global V2.1 (batch_size={batch_size})")
    
    try:
        # Executar job assíncrono em thread separada
        loop = asyncio.new_event_loop()
        asyncio.set_event_loop(loop)
        
        job = LawyerProfileEnrichmentJob()
        result = loop.run_until_complete(
            job.enrich_all_active_lawyers(
                batch_size=batch_size,
                search_depth=search_depth
            )
        )
        
        logger.info(f"✅ Enriquecimento global concluído: {result['global_summary']['total_successful']}/{result['global_summary']['total_lawyers_processed']} sucessos")
        return result
        
    except Exception as e:
        logger.error(f"❌ Erro no global task: {e}")
        return {"error": str(e), "task_id": self.request.id}
    finally:
        loop.close()


# 🆕 V2.1: Função de conveniência para execução manual

async def run_enrichment_demo():
    """
    Demo da funcionalidade de enriquecimento V2.1.
    """
    job = LawyerProfileEnrichmentJob()
    
    # Testar com alguns IDs de exemplo
    demo_ids = ["lawyer_1", "lawyer_2", "lawyer_3"]
    
    print("🚀 Executando demo de enriquecimento V2.1...")
    
    result = await job.enrich_profiles_batch(
        lawyer_ids=demo_ids,
        enable_web_search=True,
        search_depth="quick"
    )
    
    print("📊 Resultado do demo:")
    print(f"✅ Sucessos: {result['batch_summary']['successful']}/{result['batch_summary']['total_processed']}")
    print(f"⏱️  Tempo total: {result['batch_summary']['total_processing_time']:.2f}s")
    print(f"🌐 Web search habilitado: {result['batch_summary']['web_search_enabled']}")
    
    return result


if __name__ == "__main__":
    # Executar demo se chamado diretamente
    asyncio.run(run_enrichment_demo()) 