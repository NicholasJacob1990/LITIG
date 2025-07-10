import supabase from '@/lib/supabase';
import * as Google from 'expo-auth-session/providers/google';
import * as WebBrowser from 'expo-web-browser';
import { makeRedirectUri, exchangeCodeAsync } from 'expo-auth-session';

WebBrowser.maybeCompleteAuthSession();

// Tipos para os dados do calendário
export interface CalendarEvent {
  id?: string;
  external_id?: string;
  provider?: 'google' | 'outlook';
  user_id: string;
  case_id?: string;
  title: string;
  description?: string;
  start_time: string;
  end_time: string;
  status?: 'confirmed' | 'tentative' | 'cancelled';
  is_virtual?: boolean;
  video_link?: string;
}

export interface CalendarCredentials {
    user_id: string;
    provider: 'google' | 'outlook';
    access_token: string;
    refresh_token?: string;
    expires_at?: string;
}

/**
 * Busca os eventos de um usuário em um determinado período.
 * @param userId - O ID do usuário.
 * @param startDate - Data de início do período.
 * @param endDate - Data de fim do período.
 */
export const getEvents = async (userId: string, startDate: Date, endDate: Date) => {
  const { data, error } = await supabase
    .from('events')
    .select('*')
    .eq('user_id', userId)
    .gte('start_time', startDate.toISOString())
    .lte('end_time', endDate.toISOString())
    .order('start_time', { ascending: true });

  if (error) {
    console.error('Error fetching events:', error);
    throw error;
  }
  return data;
};

/**
 * Cria um novo evento no banco de dados.
 * @param eventData - Os dados do evento a ser criado.
 */
export const createEvent = async (eventData: CalendarEvent) => {
  const { data, error } = await supabase
    .from('events')
    .insert([eventData])
    .select()
    .single();

  if (error) {
    console.error('Error creating event:', error);
    throw error;
  }
  return data;
};

/**
 * Salva as credenciais do calendário para um usuário.
 * @param credentials - As credenciais a serem salvas.
 */
export const saveCalendarCredentials = async (credentials: CalendarCredentials) => {
    const { data, error } = await supabase
      .from('calendar_credentials')
      .upsert(credentials, { onConflict: 'user_id, provider' })
      .select()
      .single();
  
    if (error) {
      console.error('Error saving calendar credentials:', error);
      throw error;
    }
    return data;
};

/**
 * Busca as credenciais de calendário salvas para um usuário.
 * @param userId - O ID do usuário.
 * @param provider - O provedor ('google' ou 'outlook').
 */
export const getCalendarCredentials = async (userId: string, provider: 'google' | 'outlook') => {
  const { data, error } = await supabase
    .from('calendar_credentials')
    .select('access_token, refresh_token, expires_at')
    .eq('user_id', userId)
    .eq('provider', provider)
    .single();

  if (error && error.code !== 'PGRST116') { // Ignora erro "No rows found"
    console.error('Error fetching calendar credentials:', error);
    throw error;
  }

  return data;
};

/**
 * Busca eventos diretamente da API do Google Calendar.
 * @param accessToken - O token de acesso do Google.
 */
export const fetchGoogleEvents = async (accessToken: string) => {
  try {
    const response = await fetch('https://www.googleapis.com/calendar/v3/calendars/primary/events', {
      headers: {
        Authorization: `Bearer ${accessToken}`,
      },
    });

    if (!response.ok) {
      const errorData = await response.json();
      console.error('Google API Error:', errorData);
      throw new Error('Falha ao buscar eventos do Google.');
    }

    const data = await response.json();
    // A API do Google retorna os eventos em `data.items`.
    // Precisamos mapeá-los para a nossa interface `CalendarEvent`.
    const mappedEvents: CalendarEvent[] = data.items.map((event: any) => ({
      id: event.id, // Usamos o ID do google aqui
      external_id: event.id,
      provider: 'google',
      user_id: '', // O user_id não vem da API, seria preenchido pelo contexto
      title: event.summary,
      description: event.description,
      start_time: event.start.dateTime || event.start.date,
      end_time: event.end.dateTime || event.end.date,
      status: event.status === 'cancelled' ? 'cancelled' : 'confirmed',
      video_link: event.hangoutLink,
    }));
    return mappedEvents;

  } catch (error) {
    console.error('Error fetching from Google Calendar API:', error);
    throw error;
  }
};

/**
 * Hook para gerenciar a autenticação com o Google de forma segura.
 * Lê as credenciais do ambiente.
 */
export const useGoogleAuth = () => {
  const [request, response, promptAsync] = Google.useAuthRequest({
    iosClientId: process.env.EXPO_PUBLIC_GOOGLE_IOS_CLIENT_ID,
    androidClientId: process.env.EXPO_PUBLIC_GOOGLE_ANDROID_CLIENT_ID,
    webClientId: process.env.EXPO_PUBLIC_GOOGLE_WEB_CLIENT_ID,
    scopes: ['https://www.googleapis.com/auth/calendar', 'https://www.googleapis.com/auth/calendar.events'],
  });

  return { request, response, promptAsync };
};

/**
 * Troca o código de autorização por tokens de acesso e refresh.
 * @param code - O código de autorização retornado pelo fluxo OAuth.
 */
export const exchangeCodeForTokens = async (code: string) => {
  const clientId = process.env.EXPO_PUBLIC_GOOGLE_WEB_CLIENT_ID;
  const clientSecret = process.env.GOOGLE_WEB_CLIENT_SECRET;

  if (!clientId || !clientSecret) {
    throw new Error('Credenciais de cliente Web do Google não estão configuradas no ambiente.');
  }

  try {
    const tokenResponse = await exchangeCodeAsync(
      {
        code,
        clientId,
        clientSecret,
        redirectUri: makeRedirectUri(),
      },
      Google.discovery
    );

    return tokenResponse;
  } catch (error) {
    console.error('Error exchanging code for tokens:', error);
    throw error;
  }
};

// Funções para OAuth com Google/Outlook serão adicionadas aqui. 