from fastapi import APIRouter, Depends, HTTPException, WebSocket, WebSocketDisconnect
from pydantic import BaseModel, Field
from typing import List, Optional, Dict, Any
from datetime import datetime
import json
import logging
import os
from supabase import create_client, Client
from auth import get_current_user
from collections import defaultdict

# Setup Supabase
SUPABASE_URL = os.getenv("SUPABASE_URL", "https://test.supabase.co")
SUPABASE_SERVICE_KEY = os.getenv("SUPABASE_SERVICE_KEY", "test-service-key")
supabase: Client = create_client(SUPABASE_URL, SUPABASE_SERVICE_KEY)

router = APIRouter(prefix="/chat", tags=["chat"])
logger = logging.getLogger(__name__)

# WebSocket connection manager
class ConnectionManager:
    def __init__(self):
        self.active_connections: Dict[str, WebSocket] = {}
        self.user_rooms: Dict[str, str] = {}  # user_id -> room_id
        
    async def connect(self, websocket: WebSocket, user_id: str, room_id: str):
        await websocket.accept()
        self.active_connections[user_id] = websocket
        self.user_rooms[user_id] = room_id
        logger.info(f"User {user_id} connected to room {room_id}")
        
    def disconnect(self, user_id: str):
        if user_id in self.active_connections:
            del self.active_connections[user_id]
        if user_id in self.user_rooms:
            del self.user_rooms[user_id]
        logger.info(f"User {user_id} disconnected")
        
    async def send_personal_message(self, message: str, user_id: str):
        if user_id in self.active_connections:
            websocket = self.active_connections[user_id]
            await websocket.send_text(message)
            
    async def broadcast_to_room(self, message: str, room_id: str, exclude_user: str = None):
        for user_id, user_room in self.user_rooms.items():
            if user_room == room_id and user_id != exclude_user:
                await self.send_personal_message(message, user_id)

manager = ConnectionManager()

class ChatMessage(BaseModel):
    content: str = Field(..., min_length=1, max_length=1000)
    message_type: str = Field(default="text")
    attachment_url: Optional[str] = None

class ChatMessageResponse(BaseModel):
    id: str
    room_id: str
    sender_id: str
    sender_name: str
    sender_type: str
    content: str
    message_type: str
    attachment_url: Optional[str]
    created_at: str
    is_read: bool

class ChatRoom(BaseModel):
    id: str
    client_id: str
    lawyer_id: str
    case_id: str
    contract_id: Optional[str]
    status: str
    created_at: str
    last_message_at: Optional[str]
    client_name: str
    lawyer_name: str
    case_title: str

@router.websocket("/ws/{room_id}")
async def websocket_endpoint(websocket: WebSocket, room_id: str):
    # Note: For production, implement proper WebSocket authentication
    # This is a simplified version
    await websocket.accept()
    
    try:
        while True:
            data = await websocket.receive_text()
            message_data = json.loads(data)
            
            # Broadcast message to room participants
            await manager.broadcast_to_room(data, room_id)
            
            # Store message in database
            await _store_message(room_id, message_data)
            
    except WebSocketDisconnect:
        logger.info(f"WebSocket disconnected for room {room_id}")

async def _store_message(room_id: str, message_data: dict):
    """Store message in database"""
    try:
        result = supabase.table("chat_messages").insert({
            "room_id": room_id,
            "sender_id": message_data.get("sender_id"),
            "content": message_data.get("content"),
            "message_type": message_data.get("message_type", "text"),
            "attachment_url": message_data.get("attachment_url"),
            "is_read": False
        }).execute()
        
        # Update room last_message_at
        supabase.table("chat_rooms").update({
            "last_message_at": datetime.utcnow().isoformat()
        }).eq("id", room_id).execute()
        
    except Exception as e:
        logger.error(f"Error storing message: {e}")

@router.get("/rooms", response_model=List[ChatRoom])
async def get_chat_rooms(current_user = Depends(get_current_user)):
    """
    Retorna todas as salas de chat para o usuário atual
    """
    try:
        # Determinar campo de filtro baseado no tipo de usuário
        if current_user["user_type"] in ["lawyer_individual", "firm"]:
            user_field = "lawyer_id"
        else:
            user_field = "client_id"
            
        result = supabase.table("chat_rooms") \
            .select("""
                *,
                clients:client_id(name),
                lawyers:lawyer_id(name),
                cases:case_id(title),
                contracts:contract_id(id)
            """) \
            .eq(user_field, current_user["id"]) \
            .order("last_message_at", desc=True) \
            .execute()
            
        rooms = []
        for row in result.data:
            room = ChatRoom(
                id=row["id"],
                client_id=row["client_id"],
                lawyer_id=row["lawyer_id"],
                case_id=row["case_id"],
                contract_id=row["contract_id"],
                status=row["status"],
                created_at=row["created_at"],
                last_message_at=row["last_message_at"],
                client_name=row["clients"]["name"],
                lawyer_name=row["lawyers"]["name"],
                case_title=row["cases"]["title"]
            )
            rooms.append(room)
            
        return rooms
        
    except Exception as e:
        logger.error(f"Error getting chat rooms: {e}")
        raise HTTPException(status_code=500, detail="Erro interno do servidor")

@router.post("/rooms", response_model=dict)
async def create_chat_room(
    client_id: str,
    lawyer_id: str,
    case_id: str,
    contract_id: Optional[str] = None,
    current_user = Depends(get_current_user)
):
    """
    Cria uma nova sala de chat entre cliente e advogado
    """
    try:
        # Verificar se já existe uma sala para este caso
        existing_room = supabase.table("chat_rooms") \
            .select("id") \
            .eq("client_id", client_id) \
            .eq("lawyer_id", lawyer_id) \
            .eq("case_id", case_id) \
            .execute()
            
        if existing_room.data:
            return {
                "success": True,
                "room_id": existing_room.data[0]["id"],
                "message": "Sala de chat já existe"
            }
            
        # Criar nova sala
        room_data = {
            "client_id": client_id,
            "lawyer_id": lawyer_id,
            "case_id": case_id,
            "contract_id": contract_id,
            "status": "active",
            "created_at": datetime.utcnow().isoformat()
        }
        
        result = supabase.table("chat_rooms").insert(room_data).execute()
        
        if not result.data:
            raise HTTPException(
                status_code=500,
                detail="Erro ao criar sala de chat"
            )
            
        return {
            "success": True,
            "room_id": result.data[0]["id"],
            "message": "Sala de chat criada com sucesso"
        }
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error creating chat room: {e}")
        raise HTTPException(status_code=500, detail="Erro interno do servidor")

@router.get("/rooms/{room_id}/messages", response_model=List[ChatMessageResponse])
async def get_chat_messages(
    room_id: str,
    limit: int = 50,
    offset: int = 0,
    current_user = Depends(get_current_user)
):
    """
    Retorna mensagens de uma sala de chat
    """
    try:
        # Verificar se o usuário tem acesso à sala
        room_result = supabase.table("chat_rooms") \
            .select("client_id, lawyer_id") \
            .eq("id", room_id) \
            .execute()
            
        if not room_result.data:
            raise HTTPException(
                status_code=404,
                detail="Sala de chat não encontrada"
            )
            
        room = room_result.data[0]
        if current_user["id"] not in [room["client_id"], room["lawyer_id"]]:
            raise HTTPException(
                status_code=403,
                detail="Sem permissão para acessar esta sala"
            )
            
        # Buscar mensagens
        result = supabase.table("chat_messages") \
            .select("""
                *,
                sender:sender_id(name, user_type)
            """) \
            .eq("room_id", room_id) \
            .order("created_at", desc=True) \
            .limit(limit) \
            .offset(offset) \
            .execute()
            
        messages = []
        for row in result.data:
            message = ChatMessageResponse(
                id=row["id"],
                room_id=row["room_id"],
                sender_id=row["sender_id"],
                sender_name=row["sender"]["name"],
                sender_type=row["sender"]["user_type"],
                content=row["content"],
                message_type=row["message_type"],
                attachment_url=row["attachment_url"],
                created_at=row["created_at"],
                is_read=row["is_read"]
            )
            messages.append(message)
            
        return messages
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error getting chat messages: {e}")
        raise HTTPException(status_code=500, detail="Erro interno do servidor")

@router.post("/rooms/{room_id}/messages", response_model=dict)
async def send_message(
    room_id: str,
    message: ChatMessage,
    current_user = Depends(get_current_user)
):
    """
    Envia uma mensagem para uma sala de chat
    """
    try:
        # Verificar se o usuário tem acesso à sala
        room_result = supabase.table("chat_rooms") \
            .select("client_id, lawyer_id") \
            .eq("id", room_id) \
            .execute()
            
        if not room_result.data:
            raise HTTPException(
                status_code=404,
                detail="Sala de chat não encontrada"
            )
            
        room = room_result.data[0]
        if current_user["id"] not in [room["client_id"], room["lawyer_id"]]:
            raise HTTPException(
                status_code=403,
                detail="Sem permissão para enviar mensagens nesta sala"
            )
            
        # Criar mensagem
        message_data = {
            "room_id": room_id,
            "sender_id": current_user["id"],
            "content": message.content,
            "message_type": message.message_type,
            "attachment_url": message.attachment_url,
            "is_read": False
        }
        
        result = supabase.table("chat_messages").insert(message_data).execute()
        
        if not result.data:
            raise HTTPException(
                status_code=500,
                detail="Erro ao enviar mensagem"
            )
            
        # Atualizar timestamp da sala
        supabase.table("chat_rooms").update({
            "last_message_at": datetime.utcnow().isoformat()
        }).eq("id", room_id).execute()
        
        # Enviar via WebSocket (se conectado)
        websocket_data = {
            "id": result.data[0]["id"],
            "room_id": room_id,
            "sender_id": current_user["id"],
            "sender_name": current_user["name"],
            "content": message.content,
            "message_type": message.message_type,
            "attachment_url": message.attachment_url,
            "created_at": result.data[0]["created_at"],
            "is_read": False
        }
        
        await manager.broadcast_to_room(
            json.dumps(websocket_data),
            room_id,
            exclude_user=current_user["id"]
        )
        
        return {
            "success": True,
            "message_id": result.data[0]["id"],
            "message": "Mensagem enviada com sucesso"
        }
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error sending message: {e}")
        raise HTTPException(status_code=500, detail="Erro interno do servidor")

@router.patch("/rooms/{room_id}/messages/{message_id}/read")
async def mark_message_as_read(
    room_id: str,
    message_id: str,
    current_user = Depends(get_current_user)
):
    """
    Marca uma mensagem como lida
    """
    try:
        # Verificar se o usuário tem acesso à sala
        room_result = supabase.table("chat_rooms") \
            .select("client_id, lawyer_id") \
            .eq("id", room_id) \
            .execute()
            
        if not room_result.data:
            raise HTTPException(
                status_code=404,
                detail="Sala de chat não encontrada"
            )
            
        room = room_result.data[0]
        if current_user["id"] not in [room["client_id"], room["lawyer_id"]]:
            raise HTTPException(
                status_code=403,
                detail="Sem permissão para modificar mensagens nesta sala"
            )
            
        # Marcar como lida
        result = supabase.table("chat_messages") \
            .update({"is_read": True}) \
            .eq("id", message_id) \
            .eq("room_id", room_id) \
            .execute()
            
        if not result.data:
            raise HTTPException(
                status_code=404,
                detail="Mensagem não encontrada"
            )
            
        return {
            "success": True,
            "message": "Mensagem marcada como lida"
        }
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error marking message as read: {e}")
        raise HTTPException(status_code=500, detail="Erro interno do servidor")

@router.get("/rooms/{room_id}/unread-count")
async def get_unread_count(
    room_id: str,
    current_user = Depends(get_current_user)
):
    """
    Retorna contagem de mensagens não lidas para o usuário atual
    """
    try:
        # Verificar se o usuário tem acesso à sala
        room_result = supabase.table("chat_rooms") \
            .select("client_id, lawyer_id") \
            .eq("id", room_id) \
            .execute()
            
        if not room_result.data:
            raise HTTPException(
                status_code=404,
                detail="Sala de chat não encontrada"
            )
            
        room = room_result.data[0]
        if current_user["id"] not in [room["client_id"], room["lawyer_id"]]:
            raise HTTPException(
                status_code=403,
                detail="Sem permissão para acessar esta sala"
            )
            
        # Contar mensagens não lidas
        result = supabase.table("chat_messages") \
            .select("id", count="exact") \
            .eq("room_id", room_id) \
            .eq("is_read", False) \
            .neq("sender_id", current_user["id"]) \
            .execute()
            
        return {
            "unread_count": result.count or 0
        }
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error getting unread count: {e}")
        raise HTTPException(status_code=500, detail="Erro interno do servidor")