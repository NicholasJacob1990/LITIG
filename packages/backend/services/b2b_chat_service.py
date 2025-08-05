# -*- coding: utf-8 -*-
"""
B2B Chat Service - Serviço especializado para chat entre advogados e escritórios
================================================================================

Gerencia toda a lógica de negócio para comunicação B2B, incluindo:
- Criação de salas de chat de parcerias
- Gestão de participantes em conversas multi-party
- Validação de permissões por tipo de usuário
- Integração com sistema de parcerias
"""

import logging
from typing import Dict, List, Optional, Any, Tuple
from datetime import datetime
from uuid import uuid4
import json

from supabase import Client
from ..schemas.user_types import EntityType, normalize_entity_type
from .plan_validation_service import PlanValidationService
from .notify_service import send_push_notification, send_email_notification

logger = logging.getLogger(__name__)

class B2BChatService:
    """Serviço especializado para chat B2B entre advogados e escritórios."""
    
    def __init__(self, supabase_client: Client):
        self.supabase = supabase_client
        self.plan_validator = PlanValidationService()
    
    async def create_partnership_chat_room(
        self,
        partnership_id: str,
        creator_id: str,
        partner_id: str,
        partnership_type: str = "collaboration",
        auto_invite_participants: bool = True
    ) -> Dict[str, Any]:
        """
        Cria sala de chat para uma parceria específica.
        
        Args:
            partnership_id: ID da parceria
            creator_id: ID do criador da parceria  
            partner_id: ID do parceiro
            partnership_type: Tipo de parceria
            auto_invite_participants: Se deve convidar participantes automaticamente
            
        Returns:
            Dict com dados da sala criada
        """
        try:
            # Validar permissões de ambos os usuários
            await self._validate_b2b_chat_permissions(creator_id)
            await self._validate_b2b_chat_permissions(partner_id)
            
            # Buscar dados da parceria
            partnership_result = self.supabase.table("partnerships") \
                .select("*, creator:creator_id(name, user_type, firm_id), partner:partner_id(name, user_type, firm_id)") \
                .eq("id", partnership_id) \
                .single() \
                .execute()
            
            if not partnership_result.data:
                raise ValueError("Parceria não encontrada")
            
            partnership = partnership_result.data
            
            # Criar sala de chat
            room_data = {
                "room_type": "partnership",
                "partnership_id": partnership_id,
                "lawyer_id": creator_id,
                "partner_lawyer_id": partner_id,
                "firm_id": partnership.get("firm_id"),
                "secondary_firm_id": partnership.get("partner_firm_id"),
                "status": "active",
                "created_at": datetime.utcnow().isoformat()
            }
            
            room_result = self.supabase.table("chat_rooms") \
                .insert(room_data) \
                .execute()
            
            if not room_result.data:
                raise Exception("Erro ao criar sala de chat")
            
            room = room_result.data[0]
            room_id = room["id"]
            
            # Adicionar participantes automaticamente se solicitado
            if auto_invite_participants:
                await self._add_initial_participants(partnership_id, room_id, creator_id, partner_id)
            
            # Enviar notificações
            await self._notify_partnership_chat_created(partnership, room_id)
            
            logger.info(f"Sala de chat B2B criada: {room_id} para parceria {partnership_id}")
            
            return {
                "success": True,
                "room_id": room_id,
                "partnership_id": partnership_id,
                "room_type": "partnership",
                "participants_count": 2,
                "created_at": room["created_at"]
            }
            
        except ValueError as e:
            logger.error(f"Erro de validação ao criar chat B2B: {e}")
            raise
        except Exception as e:
            logger.error(f"Erro ao criar sala de chat B2B: {e}")
            raise Exception(f"Erro interno ao criar chat B2B: {str(e)}")
    
    async def create_firm_collaboration_room(
        self,
        firm_id: str,
        partner_firm_id: str,
        creator_id: str,
        collaboration_purpose: str,
        case_id: Optional[str] = None
    ) -> Dict[str, Any]:
        """
        Cria sala de chat para colaboração entre escritórios.
        """
        try:
            # Validar se usuário pode criar colaborações entre escritórios
            await self._validate_firm_collaboration_permissions(creator_id)
            
            # Criar sala de colaboração
            room_data = {
                "room_type": "firm_collaboration",
                "firm_id": firm_id,
                "secondary_firm_id": partner_firm_id,
                "lawyer_id": creator_id,
                "case_id": case_id,
                "status": "active",
                "created_at": datetime.utcnow().isoformat()
            }
            
            room_result = self.supabase.table("chat_rooms") \
                .insert(room_data) \
                .execute()
            
            room = room_result.data[0]
            room_id = room["id"]
            
            # Adicionar mensagem inicial explicando o propósito
            await self._send_system_message(
                room_id,
                f"💼 Colaboração iniciada entre escritórios.\n"
                f"Propósito: {collaboration_purpose}\n"
                f"Iniciado por: {creator_id}"
            )
            
            logger.info(f"Sala de colaboração entre escritórios criada: {room_id}")
            
            return {
                "success": True,
                "room_id": room_id,
                "collaboration_type": "firm_collaboration",
                "firm_id": firm_id,
                "partner_firm_id": partner_firm_id,
                "case_id": case_id
            }
            
        except Exception as e:
            logger.error(f"Erro ao criar colaboração entre escritórios: {e}")
            raise
    
    async def add_participants_to_partnership_chat(
        self,
        room_id: str,
        partnership_id: str,
        new_participants: List[str],
        inviter_id: str
    ) -> Dict[str, Any]:
        """
        Adiciona novos participantes a uma sala de chat de parceria.
        """
        try:
            # Validar permissões do convidador
            await self._validate_invitation_permissions(inviter_id, partnership_id)
            
            # Verificar limite de participantes
            current_count = await self._get_participants_count(room_id)
            max_participants = await self._get_max_participants_limit(inviter_id)
            
            if max_participants != -1 and (current_count + len(new_participants)) > max_participants:
                raise ValueError(f"Limite de {max_participants} participantes excedido")
            
            # Adicionar cada participante
            added_participants = []
            for participant_id in new_participants:
                # Validar se o participante pode usar chat B2B
                await self._validate_b2b_chat_permissions(participant_id)
                
                # Determinar role do participante
                role = await self._determine_participant_role(participant_id, partnership_id)
                
                # Inserir na tabela de participantes
                participant_data = {
                    "partnership_id": partnership_id,
                    "user_id": participant_id,
                    "role": role,
                    "permissions": self._get_default_permissions(role),
                    "joined_at": datetime.utcnow().isoformat()
                }
                
                result = self.supabase.table("partnership_participants") \
                    .insert(participant_data) \
                    .execute()
                
                if result.data:
                    added_participants.append({
                        "user_id": participant_id,
                        "role": role,
                        "added_at": participant_data["joined_at"]
                    })
            
            # Enviar mensagem de sistema sobre novos participantes
            if added_participants:
                participant_names = await self._get_user_names([p["user_id"] for p in added_participants])
                await self._send_system_message(
                    room_id,
                    f"👥 Novos participantes adicionados: {', '.join(participant_names)}"
                )
            
            return {
                "success": True,
                "added_participants": added_participants,
                "total_participants": current_count + len(added_participants)
            }
            
        except Exception as e:
            logger.error(f"Erro ao adicionar participantes: {e}")
            raise
    
    async def send_b2b_message(
        self,
        room_id: str,
        sender_id: str,
        content: str,
        message_type: str = "text",
        message_context: str = "general",
        priority: str = "normal",
        reply_to_message_id: Optional[str] = None,
        attachment_url: Optional[str] = None
    ) -> Dict[str, Any]:
        """
        Envia mensagem em sala de chat B2B com contexto e prioridade.
        """
        try:
            # Validar permissões para enviar mensagem
            await self._validate_message_permissions(sender_id, room_id)
            
            # Criar mensagem
            message_data = {
                "room_id": room_id,
                "sender_id": sender_id,
                "content": content,
                "message_type": message_type,
                "message_context": message_context,
                "priority": priority,
                "reply_to_message_id": reply_to_message_id,
                "attachment_url": attachment_url,
                "is_read": False,
                "created_at": datetime.utcnow().isoformat()
            }
            
            result = self.supabase.table("chat_messages") \
                .insert(message_data) \
                .execute()
            
            if not result.data:
                raise Exception("Erro ao enviar mensagem")
            
            message = result.data[0]
            
            # Atualizar timestamp da sala
            await self._update_room_last_message(room_id)
            
            # Enviar notificações para outros participantes
            await self._notify_b2b_message(room_id, sender_id, content, priority)
            
            return {
                "success": True,
                "message_id": message["id"],
                "sent_at": message["created_at"],
                "context": message_context,
                "priority": priority
            }
            
        except Exception as e:
            logger.error(f"Erro ao enviar mensagem B2B: {e}")
            raise
    
    async def get_partnership_chat_rooms(
        self,
        user_id: str,
        limit: int = 20,
        offset: int = 0
    ) -> List[Dict[str, Any]]:
        """
        Retorna salas de chat de parcerias para um usuário.
        """
        try:
            # Buscar salas onde o usuário é participante
            result = self.supabase.table("partnership_chat_rooms") \
                .select("*") \
                .or_(f"lawyer_id.eq.{user_id},partner_lawyer_id.eq.{user_id}") \
                .order("last_message_at", desc=True) \
                .limit(limit) \
                .offset(offset) \
                .execute()
            
            rooms = []
            for room in result.data:
                # Enriquecer com dados adicionais
                enriched_room = await self._enrich_room_data(room, user_id)
                rooms.append(enriched_room)
            
            return rooms
            
        except Exception as e:
            logger.error(f"Erro ao buscar salas de chat B2B: {e}")
            raise
    
    # Métodos auxiliares privados
    
    async def _validate_b2b_chat_permissions(self, user_id: str) -> bool:
        """Valida se usuário pode usar chat B2B."""
        user_result = self.supabase.table("users") \
            .select("user_type, plan") \
            .eq("id", user_id) \
            .single() \
            .execute()
        
        if not user_result.data:
            raise ValueError("Usuário não encontrado")
        
        user = user_result.data
        entity_type = normalize_entity_type(user["user_type"])
        plan = user.get("plan", "free_lawyer")
        
        validation = self.plan_validator.validate_feature_access(
            "b2b_chat", entity_type, plan
        )
        
        if not validation["allowed"]:
            raise ValueError(validation["reason"])
        
        return True
    
    async def _validate_firm_collaboration_permissions(self, user_id: str) -> bool:
        """Valida se usuário pode criar colaborações entre escritórios."""
        user_result = self.supabase.table("users") \
            .select("user_type, plan") \
            .eq("id", user_id) \
            .single() \
            .execute()
        
        user = user_result.data
        entity_type = normalize_entity_type(user["user_type"])
        plan = user.get("plan", "free_lawyer")
        
        validation = self.plan_validator.validate_feature_access(
            "firm_collaboration", entity_type, plan
        )
        
        if not validation["allowed"]:
            raise ValueError(validation["reason"])
        
        return True
    
    async def _add_initial_participants(
        self,
        partnership_id: str,
        room_id: str,
        creator_id: str,
        partner_id: str
    ):
        """Adiciona participantes iniciais à parceria."""
        participants = [
            {
                "partnership_id": partnership_id,
                "user_id": creator_id,
                "role": "creator",
                "permissions": json.dumps({
                    "can_message": True,
                    "can_invite": True,
                    "can_archive": True,
                    "can_manage": True
                })
            },
            {
                "partnership_id": partnership_id,
                "user_id": partner_id,
                "role": "partner",
                "permissions": json.dumps({
                    "can_message": True,
                    "can_invite": False,
                    "can_archive": False,
                    "can_manage": False
                })
            }
        ]
        
        self.supabase.table("partnership_participants") \
            .insert(participants) \
            .execute()
    
    async def _send_system_message(self, room_id: str, content: str):
        """Envia mensagem do sistema."""
        message_data = {
            "room_id": room_id,
            "sender_id": None,  # Sistema
            "content": content,
            "message_type": "system",
            "message_context": "general",
            "is_read": False
        }
        
        self.supabase.table("chat_messages") \
            .insert(message_data) \
            .execute()
    
    async def _get_participants_count(self, room_id: str) -> int:
        """Retorna número de participantes na sala."""
        result = self.supabase.table("partnership_participants") \
            .select("id", count="exact") \
            .eq("partnership_id", room_id) \
            .execute()
        
        return result.count or 0
    
    async def _get_max_participants_limit(self, user_id: str) -> int:
        """Retorna limite máximo de participantes para o usuário."""
        user_result = self.supabase.table("users") \
            .select("user_type, plan") \
            .eq("id", user_id) \
            .single() \
            .execute()
        
        user = user_result.data
        entity_type = normalize_entity_type(user["user_type"])
        plan = user.get("plan", "free_lawyer")
        
        restrictions = self.plan_validator._get_plan_restrictions(entity_type, plan)
        return restrictions.get("max_chat_participants", 2)
    
    def _get_default_permissions(self, role: str) -> str:
        """Retorna permissões padrão para um role."""
        permissions_map = {
            "creator": {"can_message": True, "can_invite": True, "can_archive": True, "can_manage": True},
            "partner": {"can_message": True, "can_invite": False, "can_archive": False, "can_manage": False},
            "firm_representative": {"can_message": True, "can_invite": True, "can_archive": False, "can_manage": False},
            "observer": {"can_message": False, "can_invite": False, "can_archive": False, "can_manage": False}
        }
        
        return json.dumps(permissions_map.get(role, permissions_map["observer"]))
    
    async def _notify_partnership_chat_created(self, partnership: Dict, room_id: str):
        """Envia notificações sobre criação de chat de parceria."""
        try:
            title = "💼 Nova Parceria"
            message = f"Chat criado para parceria {partnership.get('partnership_type', 'colaboração')}"
            
            # Notificar criador
            creator = partnership.get("creator", {})
            if creator.get("id"):
                await send_push_notification(
                    creator["id"], title, message, {"room_id": room_id, "type": "partnership_chat"}
                )
            
            # Notificar parceiro
            partner = partnership.get("partner", {})
            if partner.get("id"):
                await send_push_notification(
                    partner["id"], title, message, {"room_id": room_id, "type": "partnership_chat"}
                )
                
        except Exception as e:
            logger.error(f"Erro ao enviar notificações de parceria: {e}")
    
    async def _notify_b2b_message(self, room_id: str, sender_id: str, content: str, priority: str):
        """Envia notificações para mensagens B2B."""
        try:
            # Buscar participantes da sala (exceto remetente)
            participants_result = self.supabase.table("partnership_participants") \
                .select("user_id, users(name, push_token)") \
                .neq("user_id", sender_id) \
                .execute()
            
            # Buscar nome do remetente
            sender_result = self.supabase.table("users") \
                .select("name") \
                .eq("id", sender_id) \
                .single() \
                .execute()
            
            sender_name = sender_result.data.get("name", "Parceiro") if sender_result.data else "Parceiro"
            
            title = f"💬 {sender_name}"
            if priority == "urgent":
                title = f"🚨 URGENTE - {sender_name}"
            elif priority == "high":
                title = f"❗ {sender_name}"
            
            # Truncar mensagem se muito longa
            message_preview = content[:100] + "..." if len(content) > 100 else content
            
            # Enviar para todos os participantes
            for participant in participants_result.data:
                user = participant.get("users", {})
                if user.get("push_token"):
                    await send_push_notification(
                        participant["user_id"],
                        title,
                        message_preview,
                        {"room_id": room_id, "type": "b2b_message", "priority": priority}
                    )
                    
        except Exception as e:
            logger.error(f"Erro ao enviar notificações de mensagem B2B: {e}")
    
    async def _update_room_last_message(self, room_id: str):
        """Atualiza timestamp da última mensagem na sala."""
        self.supabase.table("chat_rooms") \
            .update({"last_message_at": datetime.utcnow().isoformat()}) \
            .eq("id", room_id) \
            .execute()
    
    async def _enrich_room_data(self, room: Dict, user_id: str) -> Dict[str, Any]:
        """Enriquece dados da sala com informações adicionais."""
        # Buscar contagem de mensagens não lidas
        unread_result = self.supabase.table("chat_messages") \
            .select("id", count="exact") \
            .eq("room_id", room["id"]) \
            .eq("is_read", False) \
            .neq("sender_id", user_id) \
            .execute()
        
        room["unread_count"] = unread_result.count or 0
        
        # Buscar última mensagem
        last_message_result = self.supabase.table("chat_messages") \
            .select("content, created_at, sender_id, message_type") \
            .eq("room_id", room["id"]) \
            .order("created_at", desc=True) \
            .limit(1) \
            .execute()
        
        if last_message_result.data:
            room["last_message"] = last_message_result.data[0]
        
        return room
    
    async def _validate_message_permissions(self, user_id: str, room_id: str):
        """Valida se usuário pode enviar mensagem na sala."""
        # Verificar se usuário é participante da sala
        participant_result = self.supabase.table("partnership_participants") \
            .select("permissions") \
            .eq("user_id", user_id) \
            .execute()
        
        if not participant_result.data:
            raise ValueError("Usuário não é participante desta sala")
        
        permissions = json.loads(participant_result.data[0]["permissions"])
        if not permissions.get("can_message", False):
            raise ValueError("Usuário não tem permissão para enviar mensagens")
    
    async def _validate_invitation_permissions(self, inviter_id: str, partnership_id: str):
        """Valida se usuário pode convidar outros para a parceria."""
        participant_result = self.supabase.table("partnership_participants") \
            .select("permissions, role") \
            .eq("user_id", inviter_id) \
            .eq("partnership_id", partnership_id) \
            .single() \
            .execute()
        
        if not participant_result.data:
            raise ValueError("Usuário não é participante desta parceria")
        
        permissions = json.loads(participant_result.data["permissions"])
        if not permissions.get("can_invite", False):
            raise ValueError("Usuário não tem permissão para convidar participantes")
    
    async def _determine_participant_role(self, user_id: str, partnership_id: str) -> str:
        """Determina o role de um novo participante."""
        # Por padrão, novos participantes são observadores
        # Pode ser customizado baseado na lógica de negócio
        return "observer"
    
    async def _get_user_names(self, user_ids: List[str]) -> List[str]:
        """Busca nomes dos usuários."""
        result = self.supabase.table("users") \
            .select("name") \
            .in_("id", user_ids) \
            .execute()
        
        return [user["name"] for user in result.data]


def create_b2b_chat_service(supabase_client: Client) -> B2BChatService:
    """Factory function para criar instância do serviço."""
    return B2BChatService(supabase_client) 