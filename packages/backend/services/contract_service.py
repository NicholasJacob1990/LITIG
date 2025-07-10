"""
Serviço de contratos - Lógica de negócio
"""
import uuid
from datetime import datetime
from typing import Any, Dict, List, Optional

from supabase import create_client

from ..algoritmo_match import AUDIT_LOGGER
from ..config import settings
from ..models import Contract, ContractStatus


class ContractService:
    """
    Serviço para gerenciar contratos
    """

    def __init__(self):
        self.supabase = create_client(
            settings.SUPABASE_URL,
            settings.SUPABASE_SERVICE_KEY
        )

    async def create_contract(
        self,
        case_id: str,
        lawyer_id: str,
        client_id: str,
        fee_model: Dict[str, Any]
    ) -> Contract:
        """
        Cria novo contrato
        """
        try:
            contract_data = {
                'id': str(uuid.uuid4()),
                'case_id': case_id,
                'lawyer_id': lawyer_id,
                'client_id': client_id,
                'status': ContractStatus.PENDING_SIGNATURE,
                'fee_model': fee_model,
                'created_at': datetime.now().isoformat(),
                'updated_at': datetime.now().isoformat()
            }

            result = self.supabase.table('contracts').insert(contract_data).execute()

            if hasattr(result, 'error') and result.error:
                raise Exception(f"Erro ao criar contrato: {result.error}")

            return Contract(**result.data[0])

        except Exception as e:
            raise Exception(f"Erro ao criar contrato: {str(e)}")

    async def get_contract(self, contract_id: str) -> Optional[Contract]:
        """
        Busca contrato por ID
        """
        try:
            result = self.supabase.table('contracts').select(
                '*').eq('id', contract_id).single().execute()

            if result.data:
                return Contract(**result.data)
            return None

        except Exception as e:
            raise Exception(f"Erro ao buscar contrato: {str(e)}")

    async def get_contract_with_details(self, contract_id: str) -> Optional[Contract]:
        """
        Busca contrato com dados relacionados
        """
        try:
            result = self.supabase.rpc(
                'get_user_contracts', {
                    'user_id': None}).execute()

            # Filtrar pelo ID específico
            for contract_data in result.data:
                if contract_data['id'] == contract_id:
                    return Contract(**contract_data)

            return None

        except Exception as e:
            raise Exception(f"Erro ao buscar contrato com detalhes: {str(e)}")

    async def get_user_contracts(
        self,
        user_id: str,
        status_filter: Optional[str] = None,
        limit: int = 20,
        offset: int = 0
    ) -> List[Contract]:
        """
        Busca contratos do usuário
        """
        try:
            result = self.supabase.rpc(
                'get_user_contracts', {
                    'user_id': user_id}).execute()

            contracts = []
            for contract_data in result.data:
                # Aplicar filtro de status se especificado
                if status_filter and contract_data['status'] != status_filter:
                    continue

                contracts.append(Contract(**contract_data))

            # Aplicar paginação
            return contracts[offset:offset + limit]

        except Exception as e:
            raise Exception(f"Erro ao buscar contratos do usuário: {str(e)}")

    async def sign_contract(
        self,
        contract_id: str,
        role: str,
        signature_data: Optional[Dict[str, Any]] = None
    ) -> Contract:
        """Assina contrato e loga o evento 'won' se ambas as partes assinaram."""
        try:
            # Primeiro, busca o estado atual do contrato
            contract_before = await self.get_contract(contract_id)
            if not contract_before:
                raise Exception("Contrato não encontrado.")

            update_data = {'updated_at': datetime.now().isoformat()}

            if role == 'client':
                update_data['signed_client'] = datetime.now().isoformat()
            elif role == 'lawyer':
                update_data['signed_lawyer'] = datetime.now().isoformat()
            else:
                raise Exception(f"Papel inválido: {role}")

            result = self.supabase.table('contracts').update(
                update_data).eq('id', contract_id).single().execute()

            if hasattr(result, 'error') and result.error:
                raise Exception(f"Erro ao assinar contrato: {result.error}")

            contract_after = Contract(**result.data)

            # --- Log de Auditoria para LTR ('won') ---
            # Se o contrato não estava ativo e agora ambas as partes assinaram
            if contract_before.status != ContractStatus.ACTIVE and contract_after.signed_client and contract_after.signed_lawyer:
                # Atualiza o status para ACTIVE
                self.supabase.table('contracts').update(
                    {'status': ContractStatus.ACTIVE}).eq('id', contract_id).execute()
                contract_after.status = ContractStatus.ACTIVE

                AUDIT_LOGGER.info(
                    "feedback",
                    extra={
                        "case": str(contract_after.case_id),
                        "lawyer": str(contract_after.lawyer_id),
                        "label": "won",
                    }
                )

            return contract_after

        except Exception as e:
            raise Exception(f"Erro ao assinar contrato: {str(e)}")

    async def cancel_contract(self, contract_id: str) -> Contract:
        """Cancela contrato e loga o evento 'lost'."""
        try:
            contract_to_cancel = await self.get_contract(contract_id)
            if not contract_to_cancel:
                raise Exception("Contrato não encontrado para cancelamento.")

            update_data = {
                'status': ContractStatus.CANCELLED,
                'updated_at': datetime.now().isoformat()
            }

            result = self.supabase.table('contracts').update(
                update_data).eq('id', contract_id).single().execute()

            if hasattr(result, 'error') and result.error:
                raise Exception(f"Erro ao cancelar contrato: {result.error}")

            # --- Log de Auditoria para LTR ('lost') ---
            AUDIT_LOGGER.info(
                "feedback",
                extra={
                    "case": str(contract_to_cancel.case_id),
                    "lawyer": str(contract_to_cancel.lawyer_id),
                    "label": "lost",
                }
            )

            return Contract(**result.data[0])

        except Exception as e:
            raise Exception(f"Erro ao cancelar contrato: {str(e)}")

    async def update_contract_doc_url(self, contract_id: str, doc_url: str) -> Contract:
        """
        Atualiza URL do documento do contrato
        """
        try:
            update_data = {
                'doc_url': doc_url,
                'updated_at': datetime.now().isoformat()
            }

            result = self.supabase.table('contracts').update(
                update_data).eq('id', contract_id).execute()

            if hasattr(result, 'error') and result.error:
                raise Exception(f"Erro ao atualizar URL do documento: {result.error}")

            return Contract(**result.data[0])

        except Exception as e:
            raise Exception(f"Erro ao atualizar URL do documento: {str(e)}")

    async def get_case(self, case_id: str) -> Optional[Dict[str, Any]]:
        """
        Busca dados do caso
        """
        try:
            result = self.supabase.table('cases').select(
                '*').eq('id', case_id).single().execute()
            return result.data if result.data else None

        except Exception as e:
            raise Exception(f"Erro ao buscar caso: {str(e)}")

    async def get_interested_offer(
            self, case_id: str, lawyer_id: str) -> Optional[Dict[str, Any]]:
        """
        Busca oferta interessada do advogado para o caso
        """
        try:
            result = self.supabase.table('offers').select(
                '*').eq('case_id', case_id).eq('lawyer_id', lawyer_id).eq('status', 'interested').single().execute()
            return result.data if result.data else None

        except Exception as e:
            # Não é erro crítico se não encontrar
            return None

    async def get_active_contract_for_case(self, case_id: str) -> Optional[Contract]:
        """
        Busca contrato ativo para o caso
        """
        try:
            result = self.supabase.table('contracts').select(
                '*').eq('case_id', case_id).in_('status', ['pending-signature', 'active']).execute()

            if result.data:
                return Contract(**result.data[0])
            return None

        except Exception as e:
            raise Exception(f"Erro ao buscar contrato ativo: {str(e)}")

    async def get_contract_stats(self) -> Dict[str, Any]:
        """
        Estatísticas de contratos
        """
        try:
            # Total de contratos por status
            result = self.supabase.table('contracts').select('status').execute()

            stats = {
                'total': len(result.data),
                'by_status': {},
                'recent_activity': []
            }

            # Contar por status
            for contract in result.data:
                status = contract['status']
                stats['by_status'][status] = stats['by_status'].get(status, 0) + 1

            # Atividade recente (últimos 30 dias)
            recent_result = self.supabase.table('contracts').select(
                '*').gte('created_at', datetime.now().replace(day=1).isoformat()).order('created_at', desc=True).limit(10).execute()

            stats['recent_activity'] = recent_result.data

            return stats

        except Exception as e:
            raise Exception(f"Erro ao buscar estatísticas: {str(e)}")

    async def close_expired_contracts(self) -> int:
        """
        Fecha contratos expirados (job de limpeza)
        """
        try:
            # Contratos pending há mais de 30 dias
            expired_date = datetime.now().replace(day=1).isoformat()

            result = self.supabase.table('contracts').update({
                'status': ContractStatus.CANCELLED,
                'updated_at': datetime.now().isoformat()
            }).eq('status', ContractStatus.PENDING_SIGNATURE).lt('created_at', expired_date).execute()

            return len(result.data) if result.data else 0

        except Exception as e:
            raise Exception(f"Erro ao fechar contratos expirados: {str(e)}")
