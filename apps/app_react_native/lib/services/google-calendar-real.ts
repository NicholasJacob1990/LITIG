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
 * Hook para gerenciar a autenticação com o Google de forma real.
 * Conecta com APIs reais do Google Calendar.
 */
export const useRealGoogleAuth = () => {
  const [request, response, promptAsync] = Google.useAuthRequest({
    iosClientId: process.env.EXPO_PUBLIC_GOOGLE_IOS_CLIENT_ID,
    androidClientId: process.env.EXPO_PUBLIC_GOOGLE_ANDROID_CLIENT_ID,
    webClientId: process.env.EXPO_PUBLIC_GOOGLE_WEB_CLIENT_ID,
    scopes: [
      'https://www.googleapis.com/auth/calendar',
      'https://www.googleapis.com/auth/calendar.events',
      'https://www.googleapis.com/auth/calendar.readonly'
    ],
  });

  return { request, response, promptAsync };
};

/**
 * Troca o código de autorização por tokens de acesso e refresh reais.
 */
export const exchangeRealTokens = async (code: string) => {
  const clientId = process.env.EXPO_PUBLIC_GOOGLE_WEB_CLIENT_ID;
  const clientSecret = process.env.GOOGLE_WEB_CLIENT_SECRET;

  if (!clientId || !clientSecret) {
    throw new Error('Credenciais do Google não configuradas. Configure as variáveis de ambiente.');
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
    console.error('Erro ao trocar código por tokens:', error);
    throw new Error('Falha na autenticação com Google. Tente novamente.');
  }
};

/**
 * Busca eventos reais da API do Google Calendar.
 */
export const fetchRealGoogleEvents = async (accessToken: string) => {
  try {
    // Buscar eventos dos próximos 30 dias
    const timeMin = new Date().toISOString();
    const timeMax = new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString();
    
    const response = await fetch(
      `https://www.googleapis.com/calendar/v3/calendars/primary/events?timeMin=${timeMin}&timeMax=${timeMax}&singleEvents=true&orderBy=startTime`,
      {
        headers: {
          'Authorization': `Bearer ${accessToken}`,
          'Content-Type': 'application/json',
        },
      }
    );

    if (!response.ok) {
      if (response.status === 401) {
        throw new Error('Token de acesso expirado. Faça login novamente.');
      }
      const errorData = await response.json();
      console.error('Erro da API Google:', errorData);
      throw new Error('Falha ao buscar eventos do Google Calendar.');
    }

    const data = await response.json();
    
    // Mapear eventos da API do Google para nossa interface
    const mappedEvents: CalendarEvent[] = (data.items || []).map((event: any) => ({
      id: event.id,
      external_id: event.id,
      provider: 'google' as const,
      user_id: '', // Será preenchido pelo contexto
      title: event.summary || 'Evento sem título',
      description: event.description || '',
      start_time: event.start?.dateTime || event.start?.date,
      end_time: event.end?.dateTime || event.end?.date,
      status: event.status === 'cancelled' ? 'cancelled' : 'confirmed',
      is_virtual: !!event.hangoutLink || !!event.conferenceData,
      video_link: event.hangoutLink || event.conferenceData?.entryPoints?.[0]?.uri,
    }));

    return mappedEvents;

  } catch (error) {
    console.error('Erro ao buscar eventos do Google Calendar:', error);
    throw error;
  }
};

/**
 * Cria um evento real no Google Calendar.
 */
export const createRealGoogleEvent = async (
  accessToken: string,
  eventData: {
    title: string;
    description?: string;
    startTime: string;
    endTime: string;
    attendees?: string[];
    location?: string;
  }
) => {
  try {
    const googleEvent = {
      summary: eventData.title,
      description: eventData.description,
      start: {
        dateTime: eventData.startTime,
        timeZone: Intl.DateTimeFormat().resolvedOptions().timeZone,
      },
      end: {
        dateTime: eventData.endTime,
        timeZone: Intl.DateTimeFormat().resolvedOptions().timeZone,
      },
      attendees: eventData.attendees?.map(email => ({ email })) || [],
      location: eventData.location,
      conferenceData: {
        createRequest: {
          requestId: `meet-${Date.now()}`,
          conferenceSolutionKey: {
            type: 'hangoutsMeet'
          }
        }
      }
    };

    const response = await fetch(
      'https://www.googleapis.com/calendar/v3/calendars/primary/events?conferenceDataVersion=1',
      {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${accessToken}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(googleEvent),
      }
    );

    if (!response.ok) {
      const errorData = await response.json();
      console.error('Erro ao criar evento:', errorData);
      throw new Error('Falha ao criar evento no Google Calendar.');
    }

    const createdEvent = await response.json();
    return createdEvent;

  } catch (error) {
    console.error('Erro ao criar evento no Google Calendar:', error);
    throw error;
  }
};

/**
 * Atualiza o token de acesso usando o refresh token.
 */
export const refreshGoogleToken = async (refreshToken: string) => {
  const clientId = process.env.EXPO_PUBLIC_GOOGLE_WEB_CLIENT_ID;
  const clientSecret = process.env.GOOGLE_WEB_CLIENT_SECRET;

  if (!clientId || !clientSecret) {
    throw new Error('Credenciais do Google não configuradas.');
  }

  try {
    const response = await fetch('https://oauth2.googleapis.com/token', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: new URLSearchParams({
        client_id: clientId,
        client_secret: clientSecret,
        refresh_token: refreshToken,
        grant_type: 'refresh_token',
      }),
    });

    if (!response.ok) {
      throw new Error('Falha ao renovar token de acesso.');
    }

    const data = await response.json();
    return {
      access_token: data.access_token,
      expires_in: data.expires_in,
      // O refresh_token pode não ser retornado se ainda for válido
      refresh_token: data.refresh_token || refreshToken,
    };

  } catch (error) {
    console.error('Erro ao renovar token:', error);
    throw error;
  }
};

/**
 * Salva as credenciais do calendário no Supabase.
 */
export const saveRealCalendarCredentials = async (credentials: CalendarCredentials) => {
  const { data, error } = await supabase
    .from('calendar_credentials')
    .upsert(credentials, { onConflict: 'user_id, provider' })
    .select()
    .single();

  if (error) {
    console.error('Erro ao salvar credenciais:', error);
    throw error;
  }
  return data;
};

/**
 * Busca as credenciais de calendário salvas para um usuário.
 */
export const getRealCalendarCredentials = async (userId: string, provider: 'google' | 'outlook') => {
  const { data, error } = await supabase
    .from('calendar_credentials')
    .select('access_token, refresh_token, expires_at')
    .eq('user_id', userId)
    .eq('provider', provider)
    .single();

  if (error && error.code !== 'PGRST116') {
    console.error('Erro ao buscar credenciais:', error);
    throw error;
  }

  return data;
};

/**
 * Verifica se o token está expirado e renova se necessário.
 */
export const ensureValidToken = async (userId: string) => {
  const credentials = await getRealCalendarCredentials(userId, 'google');
  
  if (!credentials) {
    throw new Error('Usuário não conectado ao Google Calendar.');
  }

  // Verificar se o token está próximo do vencimento (5 minutos de margem)
  const expiresAt = new Date(credentials.expires_at || 0);
  const now = new Date();
  const fiveMinutesFromNow = new Date(now.getTime() + 5 * 60 * 1000);

  if (expiresAt <= fiveMinutesFromNow && credentials.refresh_token) {
    console.log('Token próximo do vencimento, renovando...');
    
    const newTokens = await refreshGoogleToken(credentials.refresh_token);
    
    // Salvar o novo token
    const newExpiresAt = new Date(now.getTime() + newTokens.expires_in * 1000);
    await saveRealCalendarCredentials({
      user_id: userId,
      provider: 'google',
      access_token: newTokens.access_token,
      refresh_token: newTokens.refresh_token,
      expires_at: newExpiresAt.toISOString(),
    });

    return newTokens.access_token;
  }

  return credentials.access_token;
}; 