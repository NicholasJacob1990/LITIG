"""
Serviço para gerenciar tarefas de casos
"""
import uuid
from datetime import datetime, timedelta
from typing import Any, Dict, List, Optional

from supabase import create_client

from config import settings


class TaskService:
    """
    Serviço para gerenciar tarefas de casos
    """

    def __init__(self):
        self.supabase = create_client(
            settings.SUPABASE_URL,
            settings.SUPABASE_SERVICE_KEY
        )

    async def create_task(
        self,
        case_id: str,
        title: str,
        description: Optional[str] = None,
        assigned_to: Optional[str] = None,
        priority: int = 5,
        due_date: Optional[datetime] = None,
        created_by: Optional[str] = None
    ) -> Dict[str, Any]:
        """
        Cria nova tarefa
        """
        try:
            task_data = {
                'id': str(uuid.uuid4()),
                'case_id': case_id,
                'title': title,
                'description': description,
                'assigned_to': assigned_to,
                'priority': priority,
                'due_date': due_date.isoformat() if due_date else None,
                'status': 'pending',
                'created_by': created_by,
                'created_at': datetime.now().isoformat(),
                'updated_at': datetime.now().isoformat()
            }

            result = self.supabase.table('tasks').insert(task_data).execute()

            if hasattr(result, 'error') and result.error:
                raise Exception(f"Erro ao criar tarefa: {result.error}")

            return result.data[0]

        except Exception as e:
            raise Exception(f"Erro ao criar tarefa: {str(e)}")

    async def get_task(self, task_id: str) -> Optional[Dict[str, Any]]:
        """
        Busca tarefa por ID
        """
        try:
            result = self.supabase.table('tasks').select(
                '*').eq('id', task_id).single().execute()
            return result.data if result.data else None

        except Exception as e:
            raise Exception(f"Erro ao buscar tarefa: {str(e)}")

    async def get_case_tasks(self, case_id: str) -> List[Dict[str, Any]]:
        """
        Busca todas as tarefas de um caso
        """
        try:
            result = self.supabase.table('tasks').select(
                '*').eq('case_id', case_id).order('priority', desc=True).order('due_date', asc=True).execute()
            return result.data if result.data else []

        except Exception as e:
            raise Exception(f"Erro ao buscar tarefas do caso: {str(e)}")

    async def get_user_tasks(
        self,
        user_id: str,
        status_filter: Optional[str] = None,
        limit: int = 20,
        offset: int = 0
    ) -> List[Dict[str, Any]]:
        """
        Lista tarefas atribuídas ao usuário
        """
        try:
            query = self.supabase.table('tasks').select('*').eq('assigned_to', user_id)

            if status_filter:
                query = query.eq('status', status_filter)

            result = query.order('priority', desc=True).order(
                'due_date', asc=True).range(offset, offset + limit - 1).execute()

            return result.data if result.data else []

        except Exception as e:
            raise Exception(f"Erro ao listar tarefas: {str(e)}")

    async def update_task(
        self,
        task_id: str,
        **updates
    ) -> Dict[str, Any]:
        """
        Atualiza tarefa
        """
        try:
            updates['updated_at'] = datetime.now().isoformat()

            result = self.supabase.table('tasks').update(
                updates).eq('id', task_id).execute()

            if hasattr(result, 'error') and result.error:
                raise Exception(f"Erro ao atualizar tarefa: {result.error}")

            return result.data[0]

        except Exception as e:
            raise Exception(f"Erro ao atualizar tarefa: {str(e)}")

    async def complete_task(self, task_id: str) -> Dict[str, Any]:
        """
        Marca tarefa como concluída
        """
        try:
            return await self.update_task(task_id, status='completed')

        except Exception as e:
            raise Exception(f"Erro ao concluir tarefa: {str(e)}")

    async def assign_task(self, task_id: str, assigned_to: str) -> Dict[str, Any]:
        """
        Atribui tarefa a um usuário
        """
        try:
            return await self.update_task(task_id, assigned_to=assigned_to, status='in_progress')

        except Exception as e:
            raise Exception(f"Erro ao atribuir tarefa: {str(e)}")

    async def delete_task(self, task_id: str) -> bool:
        """
        Remove tarefa
        """
        try:
            result = self.supabase.table('tasks').delete().eq('id', task_id).execute()

            if hasattr(result, 'error') and result.error:
                raise Exception(f"Erro ao remover tarefa: {result.error}")

            return True

        except Exception as e:
            raise Exception(f"Erro ao remover tarefa: {str(e)}")

    async def get_overdue_tasks(
            self, user_id: Optional[str] = None) -> List[Dict[str, Any]]:
        """
        Busca tarefas em atraso
        """
        try:
            now = datetime.now().isoformat()

            query = self.supabase.table('tasks').select(
                '*').lt('due_date', now).neq('status', 'completed')

            if user_id:
                query = query.eq('assigned_to', user_id)

            result = query.order('due_date', asc=True).execute()

            # Atualizar status para overdue
            for task in result.data or []:
                if task['status'] != 'overdue':
                    await self.update_task(task['id'], status='overdue')

            return result.data if result.data else []

        except Exception as e:
            raise Exception(f"Erro ao buscar tarefas em atraso: {str(e)}")

    async def get_upcoming_tasks(
            self, user_id: str, days: int = 7) -> List[Dict[str, Any]]:
        """
        Busca tarefas com vencimento próximo
        """
        try:
            start_date = datetime.now().isoformat()
            end_date = (datetime.now() + timedelta(days=days)).isoformat()

            result = self.supabase.table('tasks').select('*').eq('assigned_to', user_id).gte('due_date', start_date).lte(
                'due_date', end_date).neq('status', 'completed').order('due_date', asc=True).execute()

            return result.data if result.data else []

        except Exception as e:
            raise Exception(f"Erro ao buscar tarefas próximas: {str(e)}")

    async def get_task_stats(
            self, case_id: Optional[str] = None, user_id: Optional[str] = None) -> Dict[str, Any]:
        """
        Retorna estatísticas das tarefas
        """
        try:
            query = self.supabase.table('tasks').select('*')

            if case_id:
                query = query.eq('case_id', case_id)
            if user_id:
                query = query.eq('assigned_to', user_id)

            result = query.execute()
            tasks = result.data or []

            # Calcular estatísticas
            total = len(tasks)
            completed = sum(1 for task in tasks if task['status'] == 'completed')
            pending = sum(1 for task in tasks if task['status'] == 'pending')
            in_progress = sum(1 for task in tasks if task['status'] == 'in_progress')
            overdue = sum(1 for task in tasks if task['status'] == 'overdue')

            # Tarefas por prioridade
            high_priority = sum(1 for task in tasks if task['priority'] >= 8)
            medium_priority = sum(1 for task in tasks if 4 <= task['priority'] < 8)
            low_priority = sum(1 for task in tasks if task['priority'] < 4)

            return {
                'total_tasks': total,
                'completed': completed,
                'pending': pending,
                'in_progress': in_progress,
                'overdue': overdue,
                'completion_rate': round((completed / total * 100), 1) if total > 0 else 0,
                'priority_distribution': {
                    'high': high_priority,
                    'medium': medium_priority,
                    'low': low_priority
                }
            }

        except Exception as e:
            raise Exception(f"Erro ao calcular estatísticas: {str(e)}")

    def get_priority_label(self, priority: int) -> str:
        """
        Retorna label da prioridade
        """
        if priority >= 8:
            return 'Alta'
        elif priority >= 4:
            return 'Média'
        else:
            return 'Baixa'

    def get_priority_color(self, priority: int) -> str:
        """
        Retorna cor da prioridade
        """
        if priority >= 8:
            return 'red'
        elif priority >= 4:
            return 'orange'
        else:
            return 'green'

    def get_status_label(self, status: str) -> str:
        """
        Retorna label do status
        """
        status_map = {
            'pending': 'Pendente',
            'in_progress': 'Em Andamento',
            'completed': 'Concluída',
            'overdue': 'Em Atraso'
        }
        return status_map.get(status, status)

    def get_status_color(self, status: str) -> str:
        """
        Retorna cor do status
        """
        color_map = {
            'pending': 'gray',
            'in_progress': 'blue',
            'completed': 'green',
            'overdue': 'red'
        }
        return color_map.get(status, 'gray')

    def format_due_date(self, due_date: Optional[str]) -> Optional[str]:
        """
        Formata data de vencimento para exibição
        """
        if not due_date:
            return None

        try:
            date_obj = datetime.fromisoformat(due_date.replace('Z', '+00:00'))
            return date_obj.strftime('%d/%m/%Y')
        except BaseException:
            return due_date
