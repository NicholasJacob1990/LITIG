"""
Serviço para gerenciar eventos do processo judicial
"""
import uuid
from datetime import datetime
from typing import Any, Dict, List, Optional

from supabase import create_client

from config import settings


class ProcessEventService:
    """
    Serviço para gerenciar eventos do processo judicial
    """

    def __init__(self):
        self.supabase = create_client(
            settings.SUPABASE_URL,
            settings.SUPABASE_SERVICE_KEY
        )

    async def create_event(
        self,
        case_id: str,
        event_date: datetime,
        title: str,
        description: Optional[str] = None,
        document_url: Optional[str] = None
    ) -> Dict[str, Any]:
        """
        Cria novo evento do processo
        """
        try:
            event_data = {
                'id': str(uuid.uuid4()),
                'case_id': case_id,
                'event_date': event_date.isoformat(),
                'title': title,
                'description': description,
                'document_url': document_url,
                'created_at': datetime.now().isoformat(),
                'updated_at': datetime.now().isoformat()
            }

            result = self.supabase.table('process_events').insert(event_data).execute()

            if hasattr(result, 'error') and result.error:
                raise Exception(f"Erro ao criar evento: {result.error}")

            return result.data[0]

        except Exception as e:
            raise Exception(f"Erro ao criar evento: {str(e)}")

    async def get_event(self, event_id: str) -> Optional[Dict[str, Any]]:
        """
        Busca evento por ID
        """
        try:
            result = self.supabase.table('process_events').select(
                '*').eq('id', event_id).single().execute()
            return result.data if result.data else None

        except Exception as e:
            raise Exception(f"Erro ao buscar evento: {str(e)}")

    async def get_case_events(self, case_id: str) -> List[Dict[str, Any]]:
        """
        Busca todos os eventos de um caso
        """
        try:
            result = self.supabase.rpc(
                'get_process_events', {
                    'p_case_id': case_id}).execute()
            return result.data if result.data else []

        except Exception as e:
            raise Exception(f"Erro ao buscar eventos do caso: {str(e)}")

    async def get_case_events_preview(
            self, case_id: str, limit: int = 3) -> List[Dict[str, Any]]:
        """
        Busca preview dos eventos de um caso (limitado)
        """
        try:
            result = self.supabase.table('process_events').select(
                '*').eq('case_id', case_id).order('event_date', desc=True).limit(limit).execute()
            return result.data if result.data else []

        except Exception as e:
            raise Exception(f"Erro ao buscar preview dos eventos: {str(e)}")

    async def update_event(
        self,
        event_id: str,
        **updates
    ) -> Dict[str, Any]:
        """
        Atualiza evento
        """
        try:
            updates['updated_at'] = datetime.now().isoformat()

            result = self.supabase.table('process_events').update(
                updates).eq('id', event_id).execute()

            if hasattr(result, 'error') and result.error:
                raise Exception(f"Erro ao atualizar evento: {result.error}")

            return result.data[0]

        except Exception as e:
            raise Exception(f"Erro ao atualizar evento: {str(e)}")

    async def delete_event(self, event_id: str) -> bool:
        """
        Remove evento
        """
        try:
            result = self.supabase.table(
                'process_events').delete().eq('id', event_id).execute()

            if hasattr(result, 'error') and result.error:
                raise Exception(f"Erro ao remover evento: {result.error}")

            return True

        except Exception as e:
            raise Exception(f"Erro ao remover evento: {str(e)}")

    async def get_recent_events(
            self, case_id: str, days: int = 30) -> List[Dict[str, Any]]:
        """
        Busca eventos recentes de um caso
        """
        try:
            from datetime import timedelta
            cutoff_date = (datetime.now() - timedelta(days=days)).isoformat()

            result = self.supabase.table('process_events').select(
                '*').eq('case_id', case_id).gte('event_date', cutoff_date).order('event_date', desc=True).execute()

            return result.data if result.data else []

        except Exception as e:
            raise Exception(f"Erro ao buscar eventos recentes: {str(e)}")

    async def get_timeline_stats(self, case_id: str) -> Dict[str, Any]:
        """
        Retorna estatísticas da linha do tempo
        """
        try:
            events = await self.get_case_events(case_id)

            if not events:
                return {
                    'total_events': 0,
                    'first_event': None,
                    'last_event': None,
                    'events_with_documents': 0,
                    'duration_days': 0
                }

            events_with_docs = sum(1 for event in events if event.get('document_url'))

            # Ordenar por data para calcular duração
            sorted_events = sorted(events, key=lambda x: x['event_date'])
            first_date = datetime.fromisoformat(
                sorted_events[0]['event_date'].replace('Z', '+00:00'))
            last_date = datetime.fromisoformat(
                sorted_events[-1]['event_date'].replace('Z', '+00:00'))
            duration = (last_date - first_date).days

            return {
                'total_events': len(events),
                'first_event': sorted_events[0]['event_date'],
                'last_event': sorted_events[-1]['event_date'],
                'events_with_documents': events_with_docs,
                'duration_days': duration
            }

        except Exception as e:
            raise Exception(f"Erro ao calcular estatísticas: {str(e)}")

    def format_event_type(self, title: str) -> str:
        """
        Classifica tipo de evento baseado no título
        """
        title_lower = title.lower()

        if 'petição' in title_lower or 'inicial' in title_lower:
            return 'petition'
        elif 'audiência' in title_lower or 'audiencia' in title_lower:
            return 'hearing'
        elif 'decisão' in title_lower or 'sentença' in title_lower:
            return 'decision'
        elif 'recurso' in title_lower:
            return 'appeal'
        elif 'citação' in title_lower:
            return 'citation'
        elif 'documento' in title_lower:
            return 'document'
        else:
            return 'other'

    def get_event_icon(self, title: str) -> str:
        """
        Retorna ícone baseado no tipo de evento
        """
        event_type = self.format_event_type(title)

        icon_map = {
            'petition': 'file-text',
            'hearing': 'users',
            'decision': 'gavel',
            'appeal': 'arrow-up',
            'citation': 'mail',
            'document': 'paperclip',
            'other': 'calendar'
        }

        return icon_map.get(event_type, 'calendar')

    def format_event_date(self, event_date: str) -> str:
        """
        Formata data do evento para exibição
        """
        try:
            date_obj = datetime.fromisoformat(event_date.replace('Z', '+00:00'))
            return date_obj.strftime('%d/%m/%Y')
        except BaseException:
            return event_date
