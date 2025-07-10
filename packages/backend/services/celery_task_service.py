"""
CeleryTaskService - Gerenciamento centralizado de tarefas Celery

Este serviço fornece uma interface unificada para:
- Criação e enfileiramento de tarefas
- Tracking de status
- Gestão de prioridades
- Configuração de retry
- Monitoramento e métricas
"""

import json
import logging
from datetime import datetime, timedelta
from enum import Enum
from typing import Any, Callable, Dict, List, Optional

from celery import Task, states
from celery.result import AsyncResult

from backend.celery_app import celery_app
from backend.services.redis_service import redis_service

logger = logging.getLogger(__name__)


class TaskPriority(Enum):
    """Níveis de prioridade para tarefas."""
    LOW = 0
    NORMAL = 5
    HIGH = 7
    CRITICAL = 9


class TaskStatus(Enum):
    """Status possíveis de uma tarefa."""
    QUEUED = "queued"
    RUNNING = "running"
    SUCCESS = "success"
    FAILED = "failed"
    RETRYING = "retrying"
    CANCELLED = "cancelled"


class CeleryTaskService:
    """Serviço centralizado para gerenciamento de tarefas Celery."""

    def __init__(self):
        self.celery = celery_app
        self.redis = redis_service
        self.task_prefix = "task:status:"
        self.metrics_prefix = "task:metrics:"

    async def queue_task(
        self,
        task_name: str,
        args: tuple = (),
        kwargs: dict = None,
        priority: TaskPriority = TaskPriority.NORMAL,
        queue: str = "default",
        countdown: Optional[int] = None,
        eta: Optional[datetime] = None,
        expires: Optional[int] = None,
        retry_config: Optional[Dict[str, Any]] = None,
        metadata: Optional[Dict[str, Any]] = None
    ) -> str:
        """
        Enfileira uma tarefa para processamento assíncrono.

        Args:
            task_name: Nome da tarefa registrada no Celery
            args: Argumentos posicionais para a tarefa
            kwargs: Argumentos nomeados para a tarefa
            priority: Prioridade da tarefa
            queue: Fila onde a tarefa será enfileirada
            countdown: Segundos para aguardar antes de executar
            eta: Data/hora específica para executar
            expires: Tempo em segundos até a tarefa expirar
            retry_config: Configuração de retry personalizada
            metadata: Metadados adicionais para tracking

        Returns:
            task_id: ID único da tarefa
        """
        kwargs = kwargs or {}

        # Configurar opções de execução
        apply_options = {
            "queue": queue,
            "priority": priority.value,
            "countdown": countdown,
            "eta": eta,
            "expires": expires,
        }

        # Configurar retry se especificado
        if retry_config:
            apply_options.update({
                "retry": True,
                "retry_policy": retry_config
            })

        # Enviar tarefa
        try:
            task = self.celery.send_task(
                task_name,
                args=args,
                kwargs=kwargs,
                **{k: v for k, v in apply_options.items() if v is not None}
            )

            # Salvar status inicial no Redis
            await self._save_task_status(
                task_id=task.id,
                status=TaskStatus.QUEUED,
                task_name=task_name,
                queue=queue,
                priority=priority,
                metadata=metadata
            )

            # Incrementar métricas
            await self._increment_metric("tasks_queued", queue)

            logger.info(f"Tarefa {task_name} enfileirada com ID {task.id}")
            return task.id

        except Exception as e:
            logger.error(f"Erro ao enfileirar tarefa {task_name}: {e}")
            raise

    async def get_task_status(self, task_id: str) -> Optional[Dict[str, Any]]:
        """
        Obtém o status detalhado de uma tarefa.

        Args:
            task_id: ID da tarefa

        Returns:
            Dicionário com status e informações da tarefa
        """
        # Buscar status no Redis
        redis_key = f"{self.task_prefix}{task_id}"
        task_data = await self.redis.get_json(redis_key)

        if not task_data:
            # Tentar buscar direto do Celery
            result = AsyncResult(task_id, app=self.celery)
            if result.state:
                task_data = {
                    "task_id": task_id,
                    "status": self._map_celery_state(result.state),
                    "result": result.result if result.successful() else None,
                    "error": str(result.info) if result.failed() else None,
                    "traceback": result.traceback if result.failed() else None,
                }

        return task_data

    async def cancel_task(self, task_id: str) -> bool:
        """
        Cancela uma tarefa em execução ou na fila.

        Args:
            task_id: ID da tarefa

        Returns:
            True se cancelada com sucesso
        """
        try:
            result = AsyncResult(task_id, app=self.celery)
            result.revoke(terminate=True)

            # Atualizar status no Redis
            await self._update_task_status(task_id, TaskStatus.CANCELLED)

            logger.info(f"Tarefa {task_id} cancelada")
            return True

        except Exception as e:
            logger.error(f"Erro ao cancelar tarefa {task_id}: {e}")
            return False

    async def retry_task(self, task_id: str, countdown: int = 60) -> Optional[str]:
        """
        Reexecuta uma tarefa falhada.

        Args:
            task_id: ID da tarefa original
            countdown: Segundos para aguardar antes de reexecutar

        Returns:
            ID da nova tarefa ou None se falhar
        """
        # Buscar dados da tarefa original
        task_data = await self.get_task_status(task_id)
        if not task_data:
            logger.error(f"Tarefa {task_id} não encontrada para retry")
            return None

        # Reenviar tarefa
        new_task_id = await self.queue_task(
            task_name=task_data.get("task_name"),
            args=task_data.get("args", ()),
            kwargs=task_data.get("kwargs", {}),
            priority=TaskPriority(task_data.get("priority", TaskPriority.NORMAL.value)),
            queue=task_data.get("queue", "default"),
            countdown=countdown,
            metadata={
                **task_data.get("metadata", {}),
                "retry_of": task_id,
                "retry_count": task_data.get("metadata", {}).get("retry_count", 0) + 1
            }
        )

        return new_task_id

    async def get_queue_stats(self, queue_name: str = None) -> Dict[str, Any]:
        """
        Obtém estatísticas de uma fila ou todas as filas.

        Args:
            queue_name: Nome da fila (None para todas)

        Returns:
            Dicionário com estatísticas
        """
        stats = {}

        # Obter informações do Celery
        inspect = self.celery.control.inspect()

        # Tarefas ativas
        active = inspect.active()
        if active:
            for worker, tasks in active.items():
                for task in tasks:
                    task_queue = task.get(
                        "delivery_info", {}).get(
                        "routing_key", "default")
                    if not queue_name or task_queue == queue_name:
                        stats.setdefault(task_queue, {"active": 0})
                        stats[task_queue]["active"] += 1

        # Tarefas agendadas
        scheduled = inspect.scheduled()
        if scheduled:
            for worker, tasks in scheduled.items():
                for task in tasks:
                    task_queue = task.get(
                        "delivery_info", {}).get(
                        "routing_key", "default")
                    if not queue_name or task_queue == queue_name:
                        stats.setdefault(task_queue, {"scheduled": 0})
                        stats[task_queue]["scheduled"] += 1

        # Adicionar métricas do Redis
        for queue in stats:
            metrics_key = f"{self.metrics_prefix}{queue}"
            metrics = await self.redis.get_json(metrics_key) or {}
            stats[queue].update({
                "total_queued": metrics.get("tasks_queued", 0),
                "total_completed": metrics.get("tasks_completed", 0),
                "total_failed": metrics.get("tasks_failed", 0),
                "avg_duration": metrics.get("avg_duration", 0),
            })

        return stats

    async def get_recent_tasks(
        self,
        limit: int = 10,
        queue: Optional[str] = None,
        status: Optional[TaskStatus] = None
    ) -> List[Dict[str, Any]]:
        """
        Obtém tarefas recentes com filtros opcionais.

        Args:
            limit: Número máximo de tarefas
            queue: Filtrar por fila
            status: Filtrar por status

        Returns:
            Lista de tarefas
        """
        # Buscar chaves de tarefas no Redis
        pattern = f"{self.task_prefix}*"
        task_keys = await self.redis.get_keys_pattern(pattern)

        tasks = []
        for key in task_keys[:limit * 2]:  # Buscar mais para aplicar filtros
            task_data = await self.redis.get_json(key)
            if task_data:
                # Aplicar filtros
                if queue and task_data.get("queue") != queue:
                    continue
                if status and task_data.get("status") != status.value:
                    continue

                tasks.append(task_data)
                if len(tasks) >= limit:
                    break

        # Ordenar por timestamp (mais recentes primeiro)
        tasks.sort(key=lambda x: x.get("created_at", ""), reverse=True)

        return tasks[:limit]

    # Métodos privados auxiliares

    async def _save_task_status(
        self,
        task_id: str,
        status: TaskStatus,
        task_name: str,
        queue: str,
        priority: TaskPriority,
        metadata: Optional[Dict[str, Any]] = None
    ):
        """Salva o status inicial da tarefa no Redis."""
        redis_key = f"{self.task_prefix}{task_id}"
        task_data = {
            "task_id": task_id,
            "task_name": task_name,
            "status": status.value,
            "queue": queue,
            "priority": priority.value,
            "created_at": datetime.now().isoformat(),
            "updated_at": datetime.now().isoformat(),
            "metadata": metadata or {}
        }

        # Salvar com TTL de 7 dias
        await self.redis.set_json(redis_key, task_data, ttl=7 * 24 * 3600)

    async def _update_task_status(
        self,
        task_id: str,
        status: TaskStatus,
        result: Any = None,
        error: str = None
    ):
        """Atualiza o status de uma tarefa existente."""
        redis_key = f"{self.task_prefix}{task_id}"
        task_data = await self.redis.get_json(redis_key)

        if task_data:
            task_data.update({
                "status": status.value,
                "updated_at": datetime.now().isoformat(),
            })

            if result is not None:
                task_data["result"] = result
            if error:
                task_data["error"] = error

            # Se completada, calcular duração
            if status in [TaskStatus.SUCCESS, TaskStatus.FAILED]:
                created_at = datetime.fromisoformat(task_data["created_at"])
                duration = (datetime.now() - created_at).total_seconds()
                task_data["duration"] = duration

                # Atualizar métricas
                await self._update_metrics(task_data["queue"], status, duration)

            await self.redis.set_json(redis_key, task_data, ttl=7 * 24 * 3600)

    async def _increment_metric(self, metric_name: str, queue: str):
        """Incrementa uma métrica específica."""
        metrics_key = f"{self.metrics_prefix}{queue}"
        metrics = await self.redis.get_json(metrics_key) or {}
        metrics[metric_name] = metrics.get(metric_name, 0) + 1
        await self.redis.set_json(metrics_key, metrics)

    async def _update_metrics(self, queue: str, status: TaskStatus, duration: float):
        """Atualiza métricas de performance."""
        metrics_key = f"{self.metrics_prefix}{queue}"
        metrics = await self.redis.get_json(metrics_key) or {}

        # Incrementar contadores
        if status == TaskStatus.SUCCESS:
            metrics["tasks_completed"] = metrics.get("tasks_completed", 0) + 1
        elif status == TaskStatus.FAILED:
            metrics["tasks_failed"] = metrics.get("tasks_failed", 0) + 1

        # Atualizar média de duração
        total_tasks = metrics.get("tasks_completed", 0) + metrics.get("tasks_failed", 0)
        if total_tasks > 0:
            current_avg = metrics.get("avg_duration", 0)
            metrics["avg_duration"] = (
                (current_avg * (total_tasks - 1)) + duration) / total_tasks

        await self.redis.set_json(metrics_key, metrics)

    def _map_celery_state(self, celery_state: str) -> str:
        """Mapeia estados do Celery para TaskStatus."""
        state_mapping = {
            states.PENDING: TaskStatus.QUEUED.value,
            states.STARTED: TaskStatus.RUNNING.value,
            states.SUCCESS: TaskStatus.SUCCESS.value,
            states.FAILURE: TaskStatus.FAILED.value,
            states.RETRY: TaskStatus.RETRYING.value,
            states.REVOKED: TaskStatus.CANCELLED.value,
        }
        return state_mapping.get(celery_state, TaskStatus.QUEUED.value)


# Instância global do serviço
celery_task_service = CeleryTaskService()
