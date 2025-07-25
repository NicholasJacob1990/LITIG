"""
Rotas de API para monitoramento e gerenciamento de tarefas Celery.

Endpoints:
- GET /api/tasks/{task_id} - Status de uma tarefa específica
- GET /api/tasks/stats - Estatísticas gerais das filas
- POST /api/tasks/retry/{task_id} - Reexecutar tarefa falhada
- GET /api/tasks/recent - Tarefas recentes
- DELETE /api/tasks/{task_id} - Cancelar tarefa
"""

from datetime import datetime
from typing import Any, Dict, List, Optional

from fastapi import APIRouter, Depends, HTTPException, Query
from pydantic import BaseModel

from auth import get_current_user
from services.celery_task_service import celery_task_service
# from models import TaskStatusResponse, TaskResultResponse, TaskCleanupResponse  # Classes não encontradas

router = APIRouter(prefix="/api/tasks", tags=["tasks"])


class TaskQueueRequest(BaseModel):
    """Request para enfileirar uma nova tarefa."""
    task_name: str
    args: list = []
    kwargs: dict = {}
    priority: str = "normal"
    queue: str = "default"
    countdown: Optional[int] = None
    metadata: Optional[dict] = None


class TaskRetryRequest(BaseModel):
    """Request para retry de tarefa."""
    countdown: int = 60


class TaskResponse(BaseModel):
    """Response padrão para operações de tarefa."""
    task_id: str
    status: str
    message: Optional[str] = None
    data: Optional[Dict[str, Any]] = None


@router.post("/queue", response_model=TaskResponse)
async def queue_task(
    request: TaskQueueRequest,
    user: dict = Depends(get_current_user)
):
    """
    Enfileira uma nova tarefa para processamento assíncrono.

    Requer autenticação e permissões apropriadas.
    """
    try:
        # Mapear prioridade string para enum
        priority_map = {
            "low": TaskPriority.LOW,
            "normal": TaskPriority.NORMAL,
            "high": TaskPriority.HIGH,
            "critical": TaskPriority.CRITICAL
        }
        priority = priority_map.get(request.priority, TaskPriority.NORMAL)

        # Adicionar informações do usuário aos metadados
        metadata = request.metadata or {}
        metadata["user_id"] = user["id"]
        metadata["user_email"] = user.get("email")

        # Enfileirar tarefa
        task_id = await celery_task_service.queue_task(
            task_name=request.task_name,
            args=request.args,
            kwargs=request.kwargs,
            priority=priority,
            queue=request.queue,
            countdown=request.countdown,
            metadata=metadata
        )

        return TaskResponse(
            task_id=task_id,
            status="queued",
            message=f"Tarefa {request.task_name} enfileirada com sucesso"
        )

    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Erro ao enfileirar tarefa: {str(e)}"
        )


@router.get("/{task_id}", response_model=TaskResponse)
async def get_task_status(
    task_id: str,
    user: dict = Depends(get_current_user)
):
    """
    Obtém o status detalhado de uma tarefa específica.
    """
    task_data = await celery_task_service.celery_task_service.get_task_status(task_id)

    if not task_data:
        raise HTTPException(
            status_code=404,
            detail=f"Tarefa {task_id} não encontrada"
        )

    # Verificar se o usuário tem permissão para ver esta tarefa
    task_user_id = task_data.get("metadata", {}).get("user_id")
    if task_user_id and task_user_id != user["id"] and user.get("role") != "admin":
        raise HTTPException(
            status_code=403,
            detail="Você não tem permissão para visualizar esta tarefa"
        )

    return TaskResponse(
        task_id=task_id,
        status=task_data.get("status", "unknown"),
        data=task_data
    )


@router.get("/stats", response_model=Dict[str, Any])
async def get_queue_stats(
    queue: Optional[str] = Query(None, description="Nome da fila específica"),
    user: dict = Depends(get_current_user)
):
    """
    Obtém estatísticas das filas de tarefas.

    Retorna informações sobre tarefas ativas, agendadas, completadas e falhadas.
    """
    stats = await celery_task_service.get_queue_stats(queue)

    return {
        "queues": stats,
        "timestamp": datetime.now().isoformat()
    }


@router.get("/recent", response_model=List[Dict[str, Any]])
async def get_recent_tasks(
    limit: int = Query(10, ge=1, le=100, description="Número máximo de tarefas"),
    queue: Optional[str] = Query(None, description="Filtrar por fila"),
    status: Optional[str] = Query(None, description="Filtrar por status"),
    user: dict = Depends(get_current_user)
):
    """
    Lista as tarefas recentes com filtros opcionais.
    """
    # Mapear status string para enum se fornecido
    task_status = None
    if status:
        try:
            task_status = TaskStatus(status)
        except ValueError:
            raise HTTPException(
                status_code=400,
                detail=f"Status inválido: {status}"
            )

    # Buscar tarefas
    tasks = await celery_task_service.get_recent_tasks(
        limit=limit,
        queue=queue,
        status=task_status
    )

    # Filtrar tarefas do usuário (exceto admin)
    if user.get("role") != "admin":
        tasks = [
            task for task in tasks
            if task.get("metadata", {}).get("user_id") == user["id"]
        ]

    return tasks


@router.post("/retry/{task_id}", response_model=TaskResponse)
async def retry_task(
    task_id: str,
    request: TaskRetryRequest,
    user: dict = Depends(get_current_user)
):
    """
    Reexecuta uma tarefa falhada.
    """
    # Verificar se a tarefa existe e pertence ao usuário
    task_data = await celery_task_service.celery_task_service.get_task_status(task_id)

    if not task_data:
        raise HTTPException(
            status_code=404,
            detail=f"Tarefa {task_id} não encontrada"
        )

    # Verificar permissões
    task_user_id = task_data.get("metadata", {}).get("user_id")
    if task_user_id and task_user_id != user["id"] and user.get("role") != "admin":
        raise HTTPException(
            status_code=403,
            detail="Você não tem permissão para reexecutar esta tarefa"
        )

    # Verificar se a tarefa está em estado que permite retry
    if task_data.get("status") not in [
            TaskStatus.FAILED.value, TaskStatus.CANCELLED.value]:
        raise HTTPException(
            status_code=400,
            detail=f"Tarefa não pode ser reexecutada no status atual: {
                task_data.get('status')}"
        )

    # Executar retry
    new_task_id = await celery_task_service.retry_task(
        task_id=task_id,
        countdown=request.countdown
    )

    if not new_task_id:
        raise HTTPException(
            status_code=500,
            detail="Erro ao reexecutar tarefa"
        )

    return TaskResponse(
        task_id=new_task_id,
        status="queued",
        message=f"Tarefa reexecutada com novo ID: {new_task_id}",
        data={"original_task_id": task_id}
    )


@router.delete("/{task_id}", response_model=TaskResponse)
async def cancel_task(
    task_id: str,
    user: dict = Depends(get_current_user)
):
    """
    Cancela uma tarefa em execução ou na fila.
    """
    # Verificar se a tarefa existe e pertence ao usuário
    task_data = await celery_task_service.celery_task_service.get_task_status(task_id)

    if not task_data:
        raise HTTPException(
            status_code=404,
            detail=f"Tarefa {task_id} não encontrada"
        )

    # Verificar permissões
    task_user_id = task_data.get("metadata", {}).get("user_id")
    if task_user_id and task_user_id != user["id"] and user.get("role") != "admin":
        raise HTTPException(
            status_code=403,
            detail="Você não tem permissão para cancelar esta tarefa"
        )

    # Verificar se a tarefa pode ser cancelada
    if task_data.get("status") in [TaskStatus.SUCCESS.value, TaskStatus.FAILED.value]:
        raise HTTPException(
            status_code=400,
            detail=f"Tarefa já finalizada com status: {task_data.get('status')}"
        )

    # Cancelar tarefa
    success = await celery_task_service.cancel_task(task_id)

    if not success:
        raise HTTPException(
            status_code=500,
            detail="Erro ao cancelar tarefa"
        )

    return TaskResponse(
        task_id=task_id,
        status="cancelled",
        message="Tarefa cancelada com sucesso"
    )


@router.get("/queue/{queue_name}/status", response_model=Dict[str, Any])
async def get_queue_status(
    queue_name: str,
    user: dict = Depends(get_current_user)
):
    """
    Obtém o status detalhado de uma fila específica.
    """
    stats = await celery_task_service.get_queue_stats(queue_name)

    if not stats:
        raise HTTPException(
            status_code=404,
            detail=f"Fila {queue_name} não encontrada"
        )

    return {
        "queue": queue_name,
        "stats": stats.get(queue_name, {}),
        "timestamp": datetime.now().isoformat()
    }

