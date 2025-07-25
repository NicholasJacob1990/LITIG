"""
Tarefas Celery para processamento assíncrono de triagem.

Este módulo contém tarefas background para:
- Processamento pesado de triagem
- Análise de documentos
- Geração de embeddings
- Notificações de progresso
"""

import asyncio
import logging
from datetime import datetime
from typing import Any, Dict, List, Optional

from celery import Task

from celery_app import celery_app
from services.celery_task_service import TaskStatus, celery_task_service
from services.intelligent_triage_orchestrator import (
    intelligent_triage_orchestrator,
)
from services.redis_service import redis_service

logger = logging.getLogger(__name__)


class TriageTask(Task):
    """Classe base para tarefas de triagem com callbacks."""

    def on_success(self, retval, task_id, args, kwargs):
        """Callback executado quando a tarefa é bem-sucedida."""
        asyncio.run(self._update_task_success(task_id, retval))

    def on_failure(self, exc, task_id, args, kwargs, einfo):
        """Callback executado quando a tarefa falha."""
        asyncio.run(self._update_task_failure(task_id, str(exc), str(einfo)))

    def on_retry(self, exc, task_id, args, kwargs, einfo):
        """Callback executado quando a tarefa é reexecutada."""
        asyncio.run(self._update_task_retry(task_id, str(exc)))

    async def _update_task_success(self, task_id: str, result: Any):
        """Atualiza o status da tarefa para sucesso."""
        await celery_task_service._update_task_status(
            task_id,
            TaskStatus.SUCCESS,
            result=result
        )
        logger.info(f"Tarefa {task_id} completada com sucesso")

    async def _update_task_failure(self, task_id: str, error: str, traceback: str):
        """Atualiza o status da tarefa para falha."""
        await celery_task_service._update_task_status(
            task_id,
            TaskStatus.FAILED,
            error=f"{error}\n{traceback}"
        )
        logger.error(f"Tarefa {task_id} falhou: {error}")

    async def _update_task_retry(self, task_id: str, reason: str):
        """Atualiza o status da tarefa para retry."""
        await celery_task_service._update_task_status(
            task_id,
            TaskStatus.RETRYING,
            error=f"Retry: {reason}"
        )
        logger.warning(f"Tarefa {task_id} será reexecutada: {reason}")


@celery_app.task(
    name="triage.process_async",
    base=TriageTask,
    bind=True,
    max_retries=3,
    default_retry_delay=60,
    acks_late=True,
    track_started=True
)
def process_triage_async(
    self,
    case_id: str,
    conversation_history: List[Dict[str, Any]],
    user_message: str,
    metadata: Optional[Dict[str, Any]] = None
) -> Dict[str, Any]:
    """
    Processa uma etapa de triagem de forma assíncrona.

    Args:
        case_id: ID do caso
        conversation_history: Histórico da conversa
        user_message: Mensagem do usuário
        metadata: Metadados adicionais

    Returns:
        Resultado do processamento
    """
    try:
        logger.info(
            f"Iniciando processamento assíncrono de triagem para caso {case_id}")

        # Atualizar status para processando
        asyncio.run(celery_task_service._update_task_status(
            self.request.id,
            TaskStatus.RUNNING
        ))

        # Publicar evento de início
        asyncio.run(redis_service.publish(
            f"triage:events:{case_id}",
            {
                "event": "triage_processing",
                "data": {
                    "task_id": self.request.id,
                    "message": "Processando sua solicitação..."
                }
            }
        ))

        # Executar processamento
        result = asyncio.run(
            intelligent_triage_orchestrator.continue_intelligent_triage(
                case_id=case_id,
                user_message=user_message
            )
        )

        # Publicar evento de conclusão
        asyncio.run(redis_service.publish(
            f"triage:events:{case_id}",
            {
                "event": "triage_processed",
                "data": {
                    "task_id": self.request.id,
                    "result": result
                }
            }
        ))

        logger.info(f"Processamento de triagem concluído para caso {case_id}")
        return result

    except Exception as e:
        logger.error(f"Erro no processamento de triagem: {e}")

        # Tentar retry se possível
        if self.request.retries < self.max_retries:
            logger.info(f"Tentando retry {self.request.retries + 1}/{self.max_retries}")
            raise self.retry(exc=e, countdown=60 * (self.request.retries + 1))

        # Publicar evento de erro
        asyncio.run(redis_service.publish(
            f"triage:events:{case_id}",
            {
                "event": "triage_error",
                "data": {
                    "task_id": self.request.id,
                    "error": str(e)
                }
            }
        ))

        raise


@celery_app.task(
    name="triage.analyze_documents",
    bind=True,
    max_retries=3,
    default_retry_delay=120
)
def analyze_documents_async(
    self,
    case_id: str,
    document_ids: List[str],
    analysis_type: str = "full"
) -> Dict[str, Any]:
    """
    Analisa documentos de um caso de forma assíncrona.

    Args:
        case_id: ID do caso
        document_ids: Lista de IDs de documentos
        analysis_type: Tipo de análise (full, summary, keywords)

    Returns:
        Resultado da análise
    """
    try:
        logger.info(
            f"Iniciando análise de {
                len(document_ids)} documentos para caso {case_id}")

        results = {}
        total_docs = len(document_ids)

        for idx, doc_id in enumerate(document_ids):
            # Publicar progresso
            progress = (idx + 1) / total_docs * 100
            asyncio.run(redis_service.publish(
                f"triage:events:{case_id}",
                {
                    "event": "document_analysis_progress",
                    "data": {
                        "task_id": self.request.id,
                        "progress": progress,
                        "current_doc": doc_id,
                        "total_docs": total_docs
                    }
                }
            ))

            # Simular análise (substituir com lógica real)
            results[doc_id] = {
                "status": "analyzed",
                "type": analysis_type,
                "extracted_data": {
                    "summary": f"Resumo do documento {doc_id}",
                    "keywords": ["keyword1", "keyword2"],
                    "entities": ["entity1", "entity2"]
                }
            }

            # Pequena pausa para não sobrecarregar
            asyncio.run(asyncio.sleep(0.5))

        logger.info(f"Análise de documentos concluída para caso {case_id}")
        return {
            "case_id": case_id,
            "documents_analyzed": len(document_ids),
            "results": results
        }

    except Exception as e:
        logger.error(f"Erro na análise de documentos: {e}")
        if self.request.retries < self.max_retries:
            raise self.retry(exc=e)
        raise


@celery_app.task(
    name="triage.generate_embeddings",
    bind=True,
    max_retries=2,
    time_limit=300  # 5 minutos
)
def generate_embeddings_async(
    self,
    case_id: str,
    text_content: str,
    model: str = "sentence-transformers"
) -> Dict[str, Any]:
    """
    Gera embeddings para conteúdo textual de forma assíncrona.

    Args:
        case_id: ID do caso
        text_content: Conteúdo textual
        model: Modelo a ser usado

    Returns:
        Embeddings gerados
    """
    try:
        logger.info(f"Gerando embeddings para caso {case_id}")

        # Importar serviço de embeddings
        from services.embedding_service import embedding_service

        # Gerar embeddings
        embeddings = asyncio.run(
            embedding_service.generate_embeddings(text_content)
        )

        # Salvar embeddings no Redis com TTL
        embeddings_key = f"embeddings:{case_id}"
        asyncio.run(redis_service.set_json(
            embeddings_key,
            {
                "embeddings": embeddings.tolist() if hasattr(embeddings, 'tolist') else embeddings,
                "model": model,
                "generated_at": datetime.now().isoformat()
            },
            ttl=86400  # 24 horas
        ))

        logger.info(f"Embeddings gerados e salvos para caso {case_id}")
        return {
            "case_id": case_id,
            "embeddings_key": embeddings_key,
            "model": model,
            "dimensions": len(embeddings) if embeddings else 0
        }

    except Exception as e:
        logger.error(f"Erro ao gerar embeddings: {e}")
        if self.request.retries < self.max_retries:
            raise self.retry(exc=e)
        raise


@celery_app.task(
    name="triage.batch_process",
    bind=True,
    queue="batch",
    time_limit=1800  # 30 minutos
)
def batch_process_cases(
    self,
    case_ids: List[str],
    operation: str,
    options: Optional[Dict[str, Any]] = None
) -> Dict[str, Any]:
    """
    Processa múltiplos casos em lote.

    Args:
        case_ids: Lista de IDs de casos
        operation: Operação a ser executada
        options: Opções adicionais

    Returns:
        Resultado do processamento em lote
    """
    try:
        logger.info(f"Iniciando processamento em lote de {len(case_ids)} casos")

        results = {
            "total": len(case_ids),
            "processed": 0,
            "failed": 0,
            "results": {}
        }

        for idx, case_id in enumerate(case_ids):
            try:
                # Publicar progresso
                progress = (idx + 1) / len(case_ids) * 100
                asyncio.run(redis_service.publish(
                    f"batch:progress:{self.request.id}",
                    {
                        "progress": progress,
                        "current_case": case_id,
                        "processed": idx + 1,
                        "total": len(case_ids)
                    }
                ))

                # Executar operação (exemplo simplificado)
                if operation == "update_status":
                    # Lógica de atualização de status
                    results["results"][case_id] = {"status": "updated"}
                elif operation == "generate_report":
                    # Lógica de geração de relatório
                    results["results"][case_id] = {"report": "generated"}

                results["processed"] += 1

            except Exception as e:
                logger.error(f"Erro ao processar caso {case_id}: {e}")
                results["failed"] += 1
                results["results"][case_id] = {"error": str(e)}

        logger.info(
            f"Processamento em lote concluído: {results['processed']} sucesso, {results['failed']} falhas")
        return results

    except Exception as e:
        logger.error(f"Erro no processamento em lote: {e}")
        raise


# Registrar tarefas para descoberta automática
__all__ = [
    'process_triage_async',
    'analyze_documents_async',
    'generate_embeddings_async',
    'batch_process_cases'
]
