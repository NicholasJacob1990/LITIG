# -*- coding: utf-8 -*-
"""
B2B Chat Routes - Endpoints para chat entre advogados e escritórios
===================================================================

Endpoints específicos para comunicação B2B, incluindo:
- Chat de parcerias entre advogados
- Colaboração entre escritórios
- Gestão de participantes multi-party
- Mensagens com contexto e prioridade
"""

from fastapi import APIRouter, Depends, HTTPException, status, WebSocket, WebSocketDisconnect
from pydantic import BaseModel, Field
from typing import List, Optional, Dict, Any
from datetime import datetime
import json
import logging

from auth import get_current_user
from config import get_supabase_client
from services.b2b_chat_service import create_b2b_chat_service, B2BChatService
from services.plan_validation_service import PlanValidationService

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/b2b-chat", tags=["B2B Chat"])

# =====================================================
# Modelos Pydantic para Request/Response
# =====================================================

class CreatePartnershipChatRequest(BaseModel):
    partnership_id: str = Field(..., description="ID da parceria")
    partnership_type: str = Field(default="collaboration", description="Tipo de parceria")
    auto_invite_participants: bool = Field(default=True, description="Convidar participantes automaticamente")

class CreateFirmCollaborationRequest(BaseModel):
    partner_firm_id: str = Field(..., description="ID do escritório parceiro")
    collaboration_purpose: str = Field(..., description="Propósito da colaboração")
    case_id: Optional[str] = Field(None, description="ID do caso (opcional)")

class AddParticipantsRequest(BaseModel):
    partnership_id: str = Field(..., description="ID da parceria")
    participant_ids: List[str] = Field(..., description="IDs dos novos participantes")

class SendB2BMessageRequest(BaseModel):
    content: str = Field(..., min_length=1, max_length=2000, description="Conteúdo da mensagem")
    message_type: str = Field(default="text", description="Tipo da mensagem")
    message_context: str = Field(default="general", description="Contexto da mensagem")
    priority: str = Field(default="normal", description="Prioridade da mensagem")
    reply_to_message_id: Optional[str] = Field(None, description="ID da mensagem sendo respondida")
    attachment_url: Optional[str] = Field(None, description="URL do anexo")

class B2BChatRoomResponse(BaseModel):
    id: str
    room_type: str
    partnership_id: Optional[str]
    firm_id: Optional[str]
    secondary_firm_id: Optional[str]
    status: str
    created_at: str
    last_message_at: Optional[str]
    unread_count: int
    participants_count: int
    partnership_type: Optional[str]
    creator_name: Optional[str]
    partner_name: Optional[str]

class B2BMessageResponse(BaseModel):
    id: str
    room_id: str
    sender_id: Optional[str]
    sender_name: str
    content: str
    message_type: str
    message_context: str
    priority: str
    reply_to_message_id: Optional[str]
    attachment_url: Optional[str]
    created_at: str
    is_read: bool

# =====================================================
# Dependency Injection
# =====================================================

def get_b2b_chat_service(supabase=Depends(get_supabase_client)) -> B2BChatService:
    """Dependency para injetar o serviço de chat B2B."""
    return create_b2b_chat_service(supabase)

def get_plan_validation_service() -> PlanValidationService:
    """Dependency para injetar o serviço de validação de planos."""
    return PlanValidationService()

# =====================================================
# Endpoints para Criação de Salas
# =====================================================

@router.post("/partnership-rooms", response_model=Dict[str, Any])
async def create_partnership_chat_room(
    request: CreatePartnershipChatRequest,
    current_user: dict = Depends(get_current_user),
    b2b_service: B2BChatService = Depends(get_b2b_chat_service)
):
    """
    Cria sala de chat para uma parceria entre advogados.
    
    Requer plano PRO+ para advogados individuais.
    Escritórios têm acesso liberado em todos os planos.
    """
    try:
        # Buscar dados da parceria para validar participantes
        supabase = b2b_service.supabase
        partnership_result = supabase.table("partnerships") \
            .select("creator_id, partner_id") \
            .eq("id", request.partnership_id) \
            .single() \
            .execute()
        
        if not partnership_result.data:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Parceria não encontrada"
            )
        
        partnership = partnership_result.data
        
        # Validar se usuário atual é participante da parceria
        if current_user["id"] not in [partnership["creator_id"], partnership["partner_id"]]:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Usuário não é participante desta parceria"
            )
        
        # Determinar IDs do criador e parceiro
        if current_user["id"] == partnership["creator_id"]:
            creator_id = partnership["creator_id"]
            partner_id = partnership["partner_id"]
        else:
            creator_id = partnership["partner_id"]  
            partner_id = partnership["creator_id"]
        
        # Criar sala de chat
        result = await b2b_service.create_partnership_chat_room(
            partnership_id=request.partnership_id,
            creator_id=creator_id,
            partner_id=partner_id,
            partnership_type=request.partnership_type,
            auto_invite_participants=request.auto_invite_participants
        )
        
        return result
        
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )
    except Exception as e:
        logger.error(f"Erro ao criar sala de chat de parceria: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Erro interno do servidor"
        )

@router.post("/firm-collaboration-rooms", response_model=Dict[str, Any])
async def create_firm_collaboration_room(
    request: CreateFirmCollaborationRequest,
    current_user: dict = Depends(get_current_user),
    b2b_service: B2BChatService = Depends(get_b2b_chat_service),
    plan_validator: PlanValidationService = Depends(get_plan_validation_service)
):
    """
    Cria sala de chat para colaboração entre escritórios.
    
    Requer plano PREMIUM+ para advogados individuais.
    Escritórios têm acesso liberado em todos os planos.
    """
    try:
        # Buscar dados do usuário para validar escritório
        supabase = b2b_service.supabase
        user_result = supabase.table("users") \
            .select("firm_id, user_type") \
            .eq("id", current_user["id"]) \
            .single() \
            .execute()
        
        if not user_result.data or not user_result.data.get("firm_id"):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Usuário deve estar associado a um escritório"
            )
        
        firm_id = user_result.data["firm_id"]
        
        # Criar sala de colaboração
        result = await b2b_service.create_firm_collaboration_room(
            firm_id=firm_id,
            partner_firm_id=request.partner_firm_id,
            creator_id=current_user["id"],
            collaboration_purpose=request.collaboration_purpose,
            case_id=request.case_id
        )
        
        return result
        
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )
    except Exception as e:
        logger.error(f"Erro ao criar colaboração entre escritórios: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Erro interno do servidor"
        )

# =====================================================
# Endpoints para Gestão de Participantes
# =====================================================

@router.post("/rooms/{room_id}/participants", response_model=Dict[str, Any])
async def add_participants_to_chat(
    room_id: str,
    request: AddParticipantsRequest,
    current_user: dict = Depends(get_current_user),
    b2b_service: B2BChatService = Depends(get_b2b_chat_service)
):
    """
    Adiciona participantes a uma sala de chat B2B.
    
    Requer permissão de convite na parceria.
    Sujeito a limites por plano.
    """
    try:
        result = await b2b_service.add_participants_to_partnership_chat(
            room_id=room_id,
            partnership_id=request.partnership_id,
            new_participants=request.participant_ids,
            inviter_id=current_user["id"]
        )
        
        return result
        
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )
    except Exception as e:
        logger.error(f"Erro ao adicionar participantes: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Erro interno do servidor"
        )

@router.get("/rooms/{room_id}/participants", response_model=List[Dict[str, Any]])
async def get_chat_participants(
    room_id: str,
    current_user: dict = Depends(get_current_user),
    b2b_service: B2BChatService = Depends(get_b2b_chat_service)
):
    """
    Lista participantes de uma sala de chat B2B.
    """
    try:
        supabase = b2b_service.supabase
        
        # Buscar parceria associada à sala
        room_result = supabase.table("chat_rooms") \
            .select("partnership_id") \
            .eq("id", room_id) \
            .single() \
            .execute()
        
        if not room_result.data:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Sala de chat não encontrada"
            )
        
        partnership_id = room_result.data["partnership_id"]
        if not partnership_id:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Sala não é de parceria"
            )
        
        # Buscar participantes
        participants_result = supabase.table("partnership_chat_participants") \
            .select("*") \
            .eq("partnership_id", partnership_id) \
            .execute()
        
        return participants_result.data
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Erro ao buscar participantes: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Erro interno do servidor"
        )

# =====================================================
# Endpoints para Mensagens
# =====================================================

@router.post("/rooms/{room_id}/messages", response_model=Dict[str, Any])
async def send_b2b_message(
    room_id: str,
    request: SendB2BMessageRequest,
    current_user: dict = Depends(get_current_user),
    b2b_service: B2BChatService = Depends(get_b2b_chat_service)
):
    """
    Envia mensagem em sala de chat B2B.
    
    Suporta diferentes contextos: general, proposal, negotiation, contract, work_update, billing.
    Suporta prioridades: low, normal, high, urgent.
    """
    try:
        result = await b2b_service.send_b2b_message(
            room_id=room_id,
            sender_id=current_user["id"],
            content=request.content,
            message_type=request.message_type,
            message_context=request.message_context,
            priority=request.priority,
            reply_to_message_id=request.reply_to_message_id,
            attachment_url=request.attachment_url
        )
        
        return result
        
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )
    except Exception as e:
        logger.error(f"Erro ao enviar mensagem B2B: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Erro interno do servidor"
        )

@router.get("/rooms/{room_id}/messages", response_model=List[B2BMessageResponse])
async def get_b2b_messages(
    room_id: str,
    limit: int = 50,
    offset: int = 0,
    context_filter: Optional[str] = None,
    current_user: dict = Depends(get_current_user),
    b2b_service: B2BChatService = Depends(get_b2b_chat_service)
):
    """
    Retorna mensagens de uma sala de chat B2B.
    
    Opcionalmente filtra por contexto (general, proposal, etc.).
    """
    try:
        # Validar acesso à sala
        supabase = b2b_service.supabase
        
        # Verificar se usuário tem acesso à sala
        room_result = supabase.table("chat_rooms") \
            .select("partnership_id, lawyer_id, partner_lawyer_id") \
            .eq("id", room_id) \
            .single() \
            .execute()
        
        if not room_result.data:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Sala de chat não encontrada"
            )
        
        room = room_result.data
        
        # Verificar se usuário é participante
        if current_user["id"] not in [room.get("lawyer_id"), room.get("partner_lawyer_id")]:
            # Verificar se é participante via partnership_participants
            participant_result = supabase.table("partnership_participants") \
                .select("id") \
                .eq("partnership_id", room["partnership_id"]) \
                .eq("user_id", current_user["id"]) \
                .execute()
            
            if not participant_result.data:
                raise HTTPException(
                    status_code=status.HTTP_403_FORBIDDEN,
                    detail="Sem permissão para acessar esta sala"
                )
        
        # Buscar mensagens
        query = supabase.table("chat_messages") \
            .select("""
                *,
                sender:sender_id(name),
                reply_to:reply_to_message_id(content, sender_id)
            """) \
            .eq("room_id", room_id) \
            .order("created_at", desc=True) \
            .limit(limit) \
            .offset(offset)
        
        if context_filter:
            query = query.eq("message_context", context_filter)
        
        messages_result = query.execute()
        
        # Formatar resposta
        messages = []
        for msg in messages_result.data:
            message = B2BMessageResponse(
                id=msg["id"],
                room_id=msg["room_id"],
                sender_id=msg["sender_id"],
                sender_name=msg.get("sender", {}).get("name", "Sistema") if msg["sender_id"] else "Sistema",
                content=msg["content"],
                message_type=msg["message_type"],
                message_context=msg["message_context"],
                priority=msg["priority"],
                reply_to_message_id=msg["reply_to_message_id"],
                attachment_url=msg["attachment_url"],
                created_at=msg["created_at"],
                is_read=msg["is_read"]
            )
            messages.append(message)
        
        return messages
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Erro ao buscar mensagens B2B: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Erro interno do servidor"
        )

# =====================================================
# Endpoints para Listagem de Salas
# =====================================================

@router.get("/rooms", response_model=List[B2BChatRoomResponse])
async def get_b2b_chat_rooms(
    limit: int = 20,
    offset: int = 0,
    room_type: Optional[str] = None,
    current_user: dict = Depends(get_current_user),
    b2b_service: B2BChatService = Depends(get_b2b_chat_service)
):
    """
    Lista salas de chat B2B do usuário.
    
    Filtra por tipo: partnership, firm_collaboration, b2b_negotiation.
    """
    try:
        rooms = await b2b_service.get_partnership_chat_rooms(
            user_id=current_user["id"],
            limit=limit,
            offset=offset
        )
        
        # Filtrar por tipo se especificado
        if room_type:
            rooms = [room for room in rooms if room.get("room_type") == room_type]
        
        # Formatar resposta
        formatted_rooms = []
        for room in rooms:
            formatted_room = B2BChatRoomResponse(
                id=room["id"],
                room_type=room["room_type"],
                partnership_id=room.get("partnership_id"),
                firm_id=room.get("firm_id"),
                secondary_firm_id=room.get("secondary_firm_id"),
                status=room["status"],
                created_at=room["created_at"],
                last_message_at=room.get("last_message_at"),
                unread_count=room.get("unread_count", 0),
                participants_count=room.get("participants_count", 2),
                partnership_type=room.get("partnership_type"),
                creator_name=room.get("creator_name"),
                partner_name=room.get("partner_name")
            )
            formatted_rooms.append(formatted_room)
        
        return formatted_rooms
        
    except Exception as e:
        logger.error(f"Erro ao buscar salas B2B: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Erro interno do servidor"
        )

# =====================================================
# Endpoints de Utilidade
# =====================================================

@router.get("/permissions")
async def get_b2b_chat_permissions(
    current_user: dict = Depends(get_current_user),
    plan_validator: PlanValidationService = Depends(get_plan_validation_service)
):
    """
    Retorna permissões de chat B2B para o usuário atual.
    """
    try:
        # Buscar dados do usuário
        from config import get_supabase_client
        supabase = get_supabase_client()
        
        user_result = supabase.table("users") \
            .select("user_type, plan") \
            .eq("id", current_user["id"]) \
            .single() \
            .execute()
        
        if not user_result.data:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Usuário não encontrado"
            )
        
        user = user_result.data
        from schemas.user_types import normalize_entity_type
        entity_type = normalize_entity_type(user["user_type"])
        plan = user.get("plan", "free_lawyer")
        
        # Validar cada funcionalidade B2B
        features = [
            "b2b_chat",
            "partnership_chat", 
            "firm_collaboration",
            "multi_participant_chat"
        ]
        
        permissions = {}
        for feature in features:
            validation = plan_validator.validate_feature_access(feature, entity_type, plan)
            permissions[feature] = {
                "allowed": validation["allowed"],
                "reason": validation.get("reason"),
                "suggested_plan": validation.get("suggested_plan")
            }
        
        # Buscar limites específicos
        restrictions = plan_validator._get_plan_restrictions(entity_type, plan)
        permissions["limits"] = {
            "max_chat_participants": restrictions.get("max_chat_participants", 2),
            "chat_file_sharing": restrictions.get("chat_file_sharing", False),
            "chat_delegation": restrictions.get("chat_delegation", False),
            "chat_analytics": restrictions.get("chat_analytics", False)
        }
        
        return {
            "user_type": entity_type,
            "plan": plan,
            "permissions": permissions
        }
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Erro ao buscar permissões B2B: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Erro interno do servidor"
        )

# =====================================================
# WebSocket para Chat B2B em Tempo Real
# =====================================================

@router.websocket("/ws/{room_id}")
async def websocket_b2b_chat(
    websocket: WebSocket,
    room_id: str,
    # user_id: str = Query(..., description="ID do usuário")  # Em produção, extrair do token
):
    """
    WebSocket para chat B2B em tempo real.
    
    NOTA: Em produção, implementar autenticação WebSocket adequada.
    """
    await websocket.accept()
    
    try:
        while True:
            # Receber mensagem do WebSocket
            data = await websocket.receive_text()
            message_data = json.loads(data)
            
            # TODO: Validar permissões e enviar mensagem via serviço B2B
            # TODO: Broadcast para outros participantes da sala
            
            # Por enquanto, apenas echo
            await websocket.send_text(f"Echo B2B: {data}")
            
    except WebSocketDisconnect:
        logger.info(f"WebSocket B2B desconectado para sala {room_id}")
    except Exception as e:
        logger.error(f"Erro no WebSocket B2B: {e}")
        await websocket.close() 