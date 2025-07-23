"""
Serviço para gerenciar consultas jurídicas
"""
import uuid
from datetime import datetime
from typing import Any, Dict, List, Optional

from supabase import create_client

from config import settings


class ConsultationService:
    """
    Serviço para gerenciar consultas jurídicas
    """

    def __init__(self):
        self.supabase = create_client(
            settings.SUPABASE_URL,
            settings.SUPABASE_SERVICE_KEY
        )

    async def create_consultation(
        self,
        case_id: str,
        lawyer_id: str,
        client_id: str,
        scheduled_at: datetime,
        duration_minutes: int = 45,
        modality: str = 'video',
        plan_type: str = 'Por Ato',
        notes: Optional[str] = None,
        meeting_url: Optional[str] = None
    ) -> Dict[str, Any]:
        """
        Cria nova consulta
        """
        try:
            consultation_data = {
                'id': str(uuid.uuid4()),
                'case_id': case_id,
                'lawyer_id': lawyer_id,
                'client_id': client_id,
                'scheduled_at': scheduled_at.isoformat(),
                'duration_minutes': duration_minutes,
                'modality': modality,
                'plan_type': plan_type,
                'status': 'scheduled',
                'notes': notes,
                'meeting_url': meeting_url,
                'created_at': datetime.now().isoformat(),
                'updated_at': datetime.now().isoformat()
            }

            result = self.supabase.table('consultations').insert(
                consultation_data).execute()

            if hasattr(result, 'error') and result.error:
                raise Exception(f"Erro ao criar consulta: {result.error}")

            return result.data[0]

        except Exception as e:
            raise Exception(f"Erro ao criar consulta: {str(e)}")

    async def get_consultation(self, consultation_id: str) -> Optional[Dict[str, Any]]:
        """
        Busca consulta por ID
        """
        try:
            result = self.supabase.table('consultations').select(
                '*').eq('id', consultation_id).single().execute()
            return result.data if result.data else None

        except Exception as e:
            raise Exception(f"Erro ao buscar consulta: {str(e)}")

    async def get_case_consultations(self, case_id: str) -> List[Dict[str, Any]]:
        """
        Busca todas as consultas de um caso
        """
        try:
            result = self.supabase.rpc(
                'get_case_consultations', {
                    'p_case_id': case_id}).execute()
            return result.data if result.data else []

        except Exception as e:
            raise Exception(f"Erro ao buscar consultas do caso: {str(e)}")

    async def get_latest_consultation(self, case_id: str) -> Optional[Dict[str, Any]]:
        """
        Busca a consulta mais recente de um caso
        """
        try:
            result = self.supabase.table('consultations').select(
                '*').eq('case_id', case_id).order('scheduled_at', desc=True).limit(1).execute()
            return result.data[0] if result.data else None

        except Exception as e:
            raise Exception(f"Erro ao buscar última consulta: {str(e)}")

    async def update_consultation(
        self,
        consultation_id: str,
        **updates
    ) -> Dict[str, Any]:
        """
        Atualiza consulta
        """
        try:
            updates['updated_at'] = datetime.now().isoformat()

            result = self.supabase.table('consultations').update(
                updates).eq('id', consultation_id).execute()

            if hasattr(result, 'error') and result.error:
                raise Exception(f"Erro ao atualizar consulta: {result.error}")

            return result.data[0]

        except Exception as e:
            raise Exception(f"Erro ao atualizar consulta: {str(e)}")

    async def cancel_consultation(self, consultation_id: str) -> Dict[str, Any]:
        """
        Cancela consulta
        """
        try:
            return await self.update_consultation(consultation_id, status='cancelled')

        except Exception as e:
            raise Exception(f"Erro ao cancelar consulta: {str(e)}")

    async def complete_consultation(
            self, consultation_id: str, notes: Optional[str] = None) -> Dict[str, Any]:
        """
        Marca consulta como concluída
        """
        try:
            updates = {'status': 'completed'}
            if notes:
                updates['notes'] = notes

            return await self.update_consultation(consultation_id, **updates)

        except Exception as e:
            raise Exception(f"Erro ao concluir consulta: {str(e)}")

    async def get_user_consultations(
        self,
        user_id: str,
        status_filter: Optional[str] = None,
        limit: int = 20,
        offset: int = 0
    ) -> List[Dict[str, Any]]:
        """
        Lista consultas do usuário
        """
        try:
            query = self.supabase.table('consultations').select(
                '*').or_(f'client_id.eq.{user_id},lawyer_id.eq.{user_id}')

            if status_filter:
                query = query.eq('status', status_filter)

            result = query.order('scheduled_at', desc=True).range(
                offset, offset + limit - 1).execute()

            return result.data if result.data else []

        except Exception as e:
            raise Exception(f"Erro ao listar consultas: {str(e)}")

    def format_modality(self, modality: str) -> str:
        """
        Formata modalidade para exibição
        """
        modality_map = {
            'video': 'Videochamada',
            'presencial': 'Presencial',
            'telefone': 'Telefone'
        }
        return modality_map.get(modality, modality)

    def format_duration(self, duration_minutes: int) -> str:
        """
        Formata duração para exibição
        """
        if duration_minutes < 60:
            return f"{duration_minutes} min"
        else:
            hours = duration_minutes // 60
            minutes = duration_minutes % 60
            if minutes == 0:
                return f"{hours}h"
            else:
                return f"{hours}h {minutes}min"
