import supabase from '@/lib/supabase';
import { getCaseById } from './cases';

// Tipos para o serviço de vídeo
export interface VideoRoom {
  id: string;
  name: string;
  url: string;
  created_at: string;
  expires_at: string;
  config: any;
}

export interface VideoSession {
  id: string;
  case_id: string;
  room_id: string;
  client_id: string;
  lawyer_id: string;
  status: 'scheduled' | 'in_progress' | 'completed' | 'cancelled';
  started_at?: string;
  ended_at?: string;
  duration_minutes?: number;
  recording_url?: string;
}

export interface VideoSessionData {
  roomUrl: string;
  clientToken: string;
  lawyerToken: string;
  session: VideoSession | null;
}

interface DailyRoom {
  id: string;
  name: string;
  api_created: boolean;
  privacy: 'public' | 'private';
  url: string;
  created_at: string;
  config: {
    start_video_off?: boolean;
    start_audio_off?: boolean;
    max_participants?: number;
    exp?: number;
  };
}

const DAILY_API_KEY = process.env.EXPO_PUBLIC_DAILY_API_KEY;
const DAILY_API_URL = 'https://api.daily.co/v1';

export const getOrCreateVideoRoom = async (caseId: string): Promise<DailyRoom> => {
  if (!DAILY_API_KEY) throw new Error('A chave da API do Daily.co não está configurada.');
  const roomName = caseId;
  
  try {
    const getRoomResponse = await fetch(`${DAILY_API_URL}/rooms/${roomName}`, {
      method: 'GET',
      headers: { 'Authorization': `Bearer ${DAILY_API_KEY}` },
    });
    if (getRoomResponse.ok) return await getRoomResponse.json();
    if (getRoomResponse.status !== 404) throw new Error(`Falha ao verificar a sala: ${getRoomResponse.statusText}`);
  } catch (error) {
    console.warn('Não foi possível obter a sala, tentando criar uma nova. Erro:', error);
  }

  const createRoomResponse = await fetch(`${DAILY_API_URL}/rooms`, {
    method: 'POST',
    headers: { 'Authorization': `Bearer ${DAILY_API_KEY}`, 'Content-Type': 'application/json' },
    body: JSON.stringify({
      name: roomName,
      privacy: 'private',
      properties: {
        exp: Math.floor(Date.now() / 1000) + (3600 * 24 * 30),
        enable_chat: true,
        enable_recording: 'cloud',
        start_video_off: true,
        start_audio_off: true,
      },
    }),
  });

  if (!createRoomResponse.ok) {
    const errorBody = await createRoomResponse.text();
    throw new Error(`Falha ao criar a sala no Daily.co: ${errorBody}`);
  }
  
  const newRoom = await createRoomResponse.json();
  await supabase.from('cases').update({ video_consultation_url: newRoom.url }).eq('id', caseId);
  return newRoom;
};

export const joinVideoRoom = async (roomName: string, userId: string): Promise<{ token: string }> => {
  if (!DAILY_API_KEY) throw new Error('A chave da API do Daily.co não está configurada.');

  const response = await fetch(`${DAILY_API_URL}/meeting-tokens`, {
    method: 'POST',
    headers: { 'Authorization': `Bearer ${DAILY_API_KEY}`, 'Content-Type': 'application/json' },
    body: JSON.stringify({
      properties: {
        room_name: roomName,
        user_id: userId,
        user_name: `Usuário ${userId.substring(0, 6)}`,
        exp: Math.floor(Date.now() / 1000) + 3600,
      },
    }),
  });

  if (!response.ok) {
    const errorBody = await response.text();
    throw new Error(`Falha ao obter o token da reunião: ${errorBody}`);
  }
  return response.json();
};

export const startVideoSession = async (caseId: string): Promise<VideoSessionData> => {
  try {
    const caseData = await getCaseById(caseId);
    if (!caseData || !caseData.client_id || !caseData.lawyer_id) {
      throw new Error('Cliente ou advogado não encontrado no caso.');
    }
    const { client_id, lawyer_id } = caseData;
    const room = await getOrCreateVideoRoom(caseId);
    const [clientToken, lawyerToken] = await Promise.all([
      joinVideoRoom(room.name, client_id),
      joinVideoRoom(room.name, lawyer_id),
    ]);
    const { data: session, error: sessionError } = await supabase
      .from('video_sessions')
      .insert({
        case_id: caseId,
        room_id: room.id,
        client_id: client_id,
        lawyer_id: lawyer_id,
        status: 'scheduled',
      })
      .select()
      .single();

    if (sessionError) {
      console.warn('Não foi possível registrar a sessão de vídeo no banco de dados:', sessionError.message);
    }
    return {
      roomUrl: room.url,
      clientToken: clientToken.token,
      lawyerToken: lawyerToken.token,
      session: session as VideoSession || null,
    };
  } catch (error) {
    console.error('Erro ao iniciar a sessão de vídeo:', error);
    if (error instanceof Error) throw new Error(`Falha ao iniciar a sessão de vídeo: ${error.message}`);
    throw new Error('Ocorreu um erro desconhecido ao iniciar a videochamada.');
  }
};

export const getVideoSessionsByCase = async (caseId: string): Promise<VideoSession[]> => {
  const { data, error } = await supabase
    .from('video_sessions')
    .select('*')
    .eq('case_id', caseId)
    .order('created_at', { ascending: false });

  if (error) {
    console.error('Error fetching video sessions:', error);
    throw new Error('Erro ao buscar sessões de vídeo.');
  }
  return data;
}; 