"""
Rotas para gestão de tarefas de casos
"""
from datetime import datetime
from typing import List, Optional

from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel, Field

from auth import get_current_user
from services.task_service import TaskService

router = APIRouter(prefix="/tasks", tags=["tasks"])

# ============================================================================
# DTOs
# ============================================================================


class CreateTaskDTO(BaseModel):
    case_id: str = Field(..., description="ID do caso")
    title: str = Field(..., description="Título da tarefa")
    description: Optional[str] = Field(None, description="Descrição da tarefa")
    assigned_to: Optional[str] = Field(None, description="ID do usuário responsável")
    priority: int = Field(5, description="Prioridade (1-10)")
    due_date: Optional[datetime] = Field(None, description="Data de vencimento")


class UpdateTaskDTO(BaseModel):
    title: Optional[str] = None
    description: Optional[str] = None
    assigned_to: Optional[str] = None
    priority: Optional[int] = None
    due_date: Optional[datetime] = None
    status: Optional[str] = None


class TaskResponse(BaseModel):
    id: str
    case_id: str
    title: str
    description: Optional[str]
    assigned_to: Optional[str]
    priority: int
    due_date: Optional[datetime]
    status: str
    created_by: Optional[str]
    created_at: datetime
    updated_at: datetime


class TaskStatsResponse(BaseModel):
    total_tasks: int
    completed: int
    pending: int
    in_progress: int
    overdue: int
    completion_rate: float
    priority_distribution: dict

# ============================================================================
# Rotas
# ============================================================================


@router.post("/", response_model=TaskResponse)
async def create_task(
    task_data: CreateTaskDTO,
    current_user: dict = Depends(get_current_user)
):
    """
    Criar nova tarefa
    """
    try:
        task_service = TaskService()

        task = await task_service.create_task(
            case_id=task_data.case_id,
            title=task_data.title,
            description=task_data.description,
            assigned_to=task_data.assigned_to,
            priority=task_data.priority,
            due_date=task_data.due_date,
            created_by=current_user["id"]
        )

        return TaskResponse(**task)

    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Erro ao criar tarefa: {str(e)}"
        )


@router.get("/{task_id}", response_model=TaskResponse)
async def get_task(
    task_id: str,
    current_user: dict = Depends(get_current_user)
):
    """
    Buscar tarefa por ID
    """
    try:
        task_service = TaskService()
        task = await task_service.get_task(task_id)

        if not task:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Tarefa não encontrada"
            )

        return TaskResponse(**task)

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Erro ao buscar tarefa: {str(e)}"
        )


@router.put("/{task_id}", response_model=TaskResponse)
async def update_task(
    task_id: str,
    task_data: UpdateTaskDTO,
    current_user: dict = Depends(get_current_user)
):
    """
    Atualizar tarefa
    """
    try:
        task_service = TaskService()

        # Verificar se existe
        task = await task_service.get_task(task_id)
        if not task:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Tarefa não encontrada"
            )

        # Atualizar apenas campos fornecidos
        updates = task_data.dict(exclude_none=True)
        if updates:
            updated_task = await task_service.update_task(task_id, **updates)
            return TaskResponse(**updated_task)

        return TaskResponse(**task)

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Erro ao atualizar tarefa: {str(e)}"
        )


@router.post("/{task_id}/complete")
async def complete_task(
    task_id: str,
    current_user: dict = Depends(get_current_user)
):
    """
    Marcar tarefa como concluída
    """
    try:
        task_service = TaskService()

        await task_service.complete_task(task_id)

        return {"message": "Tarefa marcada como concluída"}

    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Erro ao concluir tarefa: {str(e)}"
        )


@router.post("/{task_id}/assign/{user_id}")
async def assign_task(
    task_id: str,
    user_id: str,
    current_user: dict = Depends(get_current_user)
):
    """
    Atribuir tarefa a um usuário
    """
    try:
        task_service = TaskService()

        await task_service.assign_task(task_id, user_id)

        return {"message": "Tarefa atribuída com sucesso"}

    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Erro ao atribuir tarefa: {str(e)}"
        )


@router.delete("/{task_id}")
async def delete_task(
    task_id: str,
    current_user: dict = Depends(get_current_user)
):
    """
    Remover tarefa
    """
    try:
        task_service = TaskService()

        success = await task_service.delete_task(task_id)

        if success:
            return {"message": "Tarefa removida com sucesso"}
        else:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Erro ao remover tarefa"
            )

    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Erro ao remover tarefa: {str(e)}"
        )


@router.get("/case/{case_id}", response_model=List[TaskResponse])
async def get_case_tasks(
    case_id: str,
    current_user: dict = Depends(get_current_user)
):
    """
    Listar todas as tarefas de um caso
    """
    try:
        task_service = TaskService()
        tasks = await task_service.get_case_tasks(case_id)

        return [TaskResponse(**task) for task in tasks]

    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Erro ao listar tarefas: {str(e)}"
        )


@router.get("/user/me", response_model=List[TaskResponse])
async def get_user_tasks(
    status_filter: Optional[str] = None,
    limit: int = 20,
    offset: int = 0,
    current_user: dict = Depends(get_current_user)
):
    """
    Listar tarefas do usuário
    """
    try:
        task_service = TaskService()
        tasks = await task_service.get_user_tasks(
            user_id=current_user["id"],
            status_filter=status_filter,
            limit=limit,
            offset=offset
        )

        return [TaskResponse(**task) for task in tasks]

    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Erro ao listar tarefas: {str(e)}"
        )


@router.get("/user/me/overdue", response_model=List[TaskResponse])
async def get_overdue_tasks(
    current_user: dict = Depends(get_current_user)
):
    """
    Buscar tarefas em atraso do usuário
    """
    try:
        task_service = TaskService()
        tasks = await task_service.get_overdue_tasks(current_user["id"])

        return [TaskResponse(**task) for task in tasks]

    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Erro ao buscar tarefas em atraso: {str(e)}"
        )


@router.get("/user/me/upcoming", response_model=List[TaskResponse])
async def get_upcoming_tasks(
    days: int = 7,
    current_user: dict = Depends(get_current_user)
):
    """
    Buscar tarefas com vencimento próximo
    """
    try:
        task_service = TaskService()
        tasks = await task_service.get_upcoming_tasks(current_user["id"], days)

        return [TaskResponse(**task) for task in tasks]

    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Erro ao buscar tarefas próximas: {str(e)}"
        )


@router.get("/case/{case_id}/stats", response_model=TaskStatsResponse)
async def get_case_task_stats(
    case_id: str,
    current_user: dict = Depends(get_current_user)
):
    """
    Obter estatísticas das tarefas de um caso
    """
    try:
        task_service = TaskService()
        stats = await task_service.get_task_stats(case_id=case_id)

        return TaskStatsResponse(**stats)

    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Erro ao calcular estatísticas: {str(e)}"
        )


@router.get("/user/me/stats", response_model=TaskStatsResponse)
async def get_user_task_stats(
    current_user: dict = Depends(get_current_user)
):
    """
    Obter estatísticas das tarefas do usuário
    """
    try:
        task_service = TaskService()
        stats = await task_service.get_task_stats(user_id=current_user["id"])

        return TaskStatsResponse(**stats)

    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Erro ao calcular estatísticas: {str(e)}"
        )
