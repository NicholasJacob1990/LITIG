from fastapi import APIRouter, HTTPException, Depends
from pydantic import BaseModel
from typing import Dict, Any, Optional
import requests
import os
from datetime import datetime, timedelta
import jwt
from supabase import create_client, Client
try:
    from config import get_settings
    settings = get_settings()
except ImportError:
    # Fallback para desenvolvimento
    class MockSettings:
        def __init__(self):
            self.SUPABASE_URL = "http://localhost:54321"
            self.SUPABASE_SERVICE_KEY = "mock_key"
    settings = MockSettings()
supabase: Client = create_client(settings.SUPABASE_URL, settings.SUPABASE_SERVICE_KEY)

router = APIRouter(prefix="/api/video-calls", tags=["video-calls"])

# Modelos Pydantic
class CreateRoomRequest(BaseModel):
    room_name: str
    client_id: str
    lawyer_id: str
    case_id: str
    enable_recording: bool = False
    max_participants: int = 2

class RoomResponse(BaseModel):
    room_url: str
    room_name: str
    expires_at: str
    participants: list[str]

class JoinRoomRequest(BaseModel):
    room_url: str
    user_id: str

# Configuração Daily.co
DAILY_API_KEY = os.getenv("DAILY_API_KEY", "")
DAILY_API_URL = "https://api.daily.co/v1"

def get_daily_headers():
    """Headers para autenticação na API do Daily.co"""
    return {
        "Content-Type": "application/json",
        "Authorization": f"Bearer {DAILY_API_KEY}"
    }

@router.post("/rooms", response_model=RoomResponse)
async def create_room(request: CreateRoomRequest):
    """
    Cria uma nova sala de videochamada no Daily.co
    """
    try:
        # Verificar se os usuários existem
        users_response = supabase.table("users").select("id, name").in_("id", [request.client_id, request.lawyer_id]).execute()
        
        if len(users_response.data) != 2:
            raise HTTPException(status_code=400, detail="Usuários não encontrados")
        
        # Verificar se o caso existe
        case_response = supabase.table("cases").select("id, title").eq("id", request.case_id).execute()
        
        if not case_response.data:
            raise HTTPException(status_code=400, detail="Caso não encontrado")
        
        # Criar sala no Daily.co
        room_config = {
            "name": request.room_name,
            "privacy": "private",
            "properties": {
                "max_participants": request.max_participants,
                "enable_recording": request.enable_recording,
                "enable_chat": True,
                "enable_screenshare": True,
                "start_video_off": False,
                "start_audio_off": False,
                "exp": int((datetime.now() + timedelta(hours=2)).timestamp())  # Expira em 2 horas
            }
        }
        
        response = requests.post(
            f"{DAILY_API_URL}/rooms",
            headers=get_daily_headers(),
            json=room_config
        )
        
        if response.status_code != 200:
            raise HTTPException(status_code=500, detail="Erro ao criar sala no Daily.co")
        
        room_data = response.json()
        room_url = room_data["url"]
        
        # Salvar sala no banco de dados
        video_call_data = {
            "room_name": request.room_name,
            "room_url": room_url,
            "client_id": request.client_id,
            "lawyer_id": request.lawyer_id,
            "case_id": request.case_id,
            "status": "created",
            "created_at": datetime.now().isoformat(),
            "expires_at": (datetime.now() + timedelta(hours=2)).isoformat()
        }
        
        supabase.table("video_calls").insert(video_call_data).execute()
        
        return RoomResponse(
            room_url=room_url,
            room_name=request.room_name,
            expires_at=video_call_data["expires_at"],
            participants=[request.client_id, request.lawyer_id]
        )
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Erro interno: {str(e)}")

@router.post("/rooms/{room_name}/join")
async def join_room(room_name: str, request: JoinRoomRequest):
    """
    Gera token de acesso para entrar em uma sala
    """
    try:
        # Verificar se a sala existe
        room_response = supabase.table("video_calls").select("*").eq("room_name", room_name).execute()
        
        if not room_response.data:
            raise HTTPException(status_code=404, detail="Sala não encontrada")
        
        room_data = room_response.data[0]
        
        # Verificar se o usuário tem permissão para entrar
        if request.user_id not in [room_data["client_id"], room_data["lawyer_id"]]:
            raise HTTPException(status_code=403, detail="Acesso negado")
        
        # Verificar se a sala não expirou
        expires_at = datetime.fromisoformat(room_data["expires_at"])
        if datetime.now() > expires_at:
            raise HTTPException(status_code=410, detail="Sala expirada")
        
        # Gerar token Daily.co
        payload = {
            "room_name": room_name,
            "user_id": request.user_id,
            "is_owner": True,
            "exp": int((datetime.now() + timedelta(hours=2)).timestamp())
        }
        
        token = jwt.encode(payload, DAILY_API_KEY, algorithm="HS256")
        
        # Atualizar status da sala
        supabase.table("video_calls").update({
            "status": "active",
            "joined_at": datetime.now().isoformat()
        }).eq("room_name", room_name).execute()
        
        return {
            "token": token,
            "room_url": room_data["room_url"],
            "expires_at": room_data["expires_at"]
        }
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Erro interno: {str(e)}")

@router.post("/rooms/{room_name}/end")
async def end_room(room_name: str):
    """
    Encerra uma sala de videochamada
    """
    try:
        # Verificar se a sala existe
        room_response = supabase.table("video_calls").select("*").eq("room_name", room_name).execute()
        
        if not room_response.data:
            raise HTTPException(status_code=404, detail="Sala não encontrada")
        
        room_data = room_response.data[0]
        
        # Encerrar sala no Daily.co
        response = requests.delete(
            f"{DAILY_API_URL}/rooms/{room_name}",
            headers=get_daily_headers()
        )
        
        # Atualizar status no banco
        supabase.table("video_calls").update({
            "status": "ended",
            "ended_at": datetime.now().isoformat()
        }).eq("room_name", room_name).execute()
        
        return {"message": "Sala encerrada com sucesso"}
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Erro interno: {str(e)}")

@router.get("/rooms/{room_name}/status")
async def get_room_status(room_name: str):
    """
    Obtém o status de uma sala
    """
    try:
        room_response = supabase.table("video_calls").select("*").eq("room_name", room_name).execute()
        
        if not room_response.data:
            raise HTTPException(status_code=404, detail="Sala não encontrada")
        
        return room_response.data[0]
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Erro interno: {str(e)}")

@router.get("/user/{user_id}/rooms")
async def get_user_rooms(user_id: str):
    """
    Lista salas do usuário
    """
    try:
        rooms_response = supabase.table("video_calls").select("*").or_(
            f"client_id.eq.{user_id},lawyer_id.eq.{user_id}"
        ).order("created_at", desc=True).execute()
        
        return rooms_response.data
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Erro interno: {str(e)}")
        ).order("created_at", desc=True).execute()
        
        return rooms_response.data
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Erro interno: {str(e)}")
        ).order("created_at", desc=True).execute()
        
        return rooms_response.data
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Erro interno: {str(e)}")