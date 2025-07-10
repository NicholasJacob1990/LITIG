import React, { createContext, useContext, useState, useEffect, useCallback } from 'react';
import { Alert } from 'react-native';
import { useAuth } from './AuthContext';
import {
  CalendarEvent,
  useRealGoogleAuth,
  exchangeRealTokens,
  fetchRealGoogleEvents,
  saveRealCalendarCredentials,
  getRealCalendarCredentials,
  ensureValidToken,
  createRealGoogleEvent,
} from '@/lib/services/google-calendar-real';

interface RealCalendarContextData {
  events: CalendarEvent[];
  isLoading: boolean;
  isConnected: boolean;
  error: string | null;
  syncWithGoogle: () => Promise<void>;
  createEvent: (eventData: {
    title: string;
    description?: string;
    startTime: string;
    endTime: string;
    attendees?: string[];
    location?: string;
  }) => Promise<void>;
  refetchEvents: () => Promise<void>;
  disconnect: () => Promise<void>;
}

const RealCalendarContext = createContext<RealCalendarContextData>({} as RealCalendarContextData);

export const RealCalendarProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const { user } = useAuth();
  const { request, response, promptAsync } = useRealGoogleAuth();
  
  const [events, setEvents] = useState<CalendarEvent[]>([]);
  const [isLoading, setIsLoading] = useState(false);
  const [isConnected, setIsConnected] = useState(false);
  const [error, setError] = useState<string | null>(null);

  // Verificar se usuário já está conectado ao inicializar
  useEffect(() => {
    if (user?.id) {
      checkConnectionStatus();
    }
  }, [user?.id]);

  // Processar resposta do OAuth
  useEffect(() => {
    if (response?.type === 'success' && user?.id) {
      handleOAuthSuccess(response.params.code);
    } else if (response?.type === 'error') {
      setError('Erro na autenticação com Google: ' + response.params.error_description);
    }
  }, [response, user?.id]);

  /**
   * Verifica se o usuário já está conectado ao Google Calendar
   */
  const checkConnectionStatus = async () => {
    if (!user?.id) return;

    try {
      const credentials = await getRealCalendarCredentials(user.id, 'google');
      setIsConnected(!!credentials);
      
      if (credentials) {
        // Carregar eventos automaticamente se conectado
        await loadEvents();
      }
    } catch (error) {
      console.log('Usuário não conectado ao Google Calendar');
      setIsConnected(false);
    }
  };

  /**
   * Processa o sucesso do OAuth e salva as credenciais
   */
  const handleOAuthSuccess = async (code: string) => {
    if (!user?.id) return;

    setIsLoading(true);
    setError(null);

    try {
      // Trocar código por tokens
      const tokens = await exchangeRealTokens(code);
      
      // Calcular data de expiração
      const expiresAt = new Date(Date.now() + tokens.expires_in * 1000);

      // Salvar credenciais
      await saveRealCalendarCredentials({
        user_id: user.id,
        provider: 'google',
        access_token: tokens.access_token,
        refresh_token: tokens.refresh_token,
        expires_at: expiresAt.toISOString(),
      });

      setIsConnected(true);
      
      // Carregar eventos
      await loadEvents();
      
      Alert.alert('Sucesso', 'Conectado ao Google Calendar com sucesso!');
      
    } catch (error) {
      console.error('Erro ao processar OAuth:', error);
      setError(error instanceof Error ? error.message : 'Erro desconhecido');
      Alert.alert('Erro', 'Falha ao conectar com Google Calendar');
    } finally {
      setIsLoading(false);
    }
  };

  /**
   * Carrega eventos do Google Calendar
   */
  const loadEvents = async () => {
    if (!user?.id) return;

    setIsLoading(true);
    setError(null);

    try {
      // Garantir que temos um token válido
      const accessToken = await ensureValidToken(user.id);
      
      // Buscar eventos
      const googleEvents = await fetchRealGoogleEvents(accessToken);
      
      // Adicionar user_id aos eventos
      const eventsWithUserId = googleEvents.map(event => ({
        ...event,
        user_id: user.id,
      }));

      setEvents(eventsWithUserId);
      
    } catch (error) {
      console.error('Erro ao carregar eventos:', error);
      setError(error instanceof Error ? error.message : 'Erro ao carregar eventos');
      
      if (error instanceof Error && error.message.includes('Token de acesso expirado')) {
        setIsConnected(false);
      }
    } finally {
      setIsLoading(false);
    }
  };

  /**
   * Inicia o processo de sincronização com Google
   */
  const syncWithGoogle = useCallback(async () => {
    if (!request) {
      setError('Configuração OAuth não disponível');
      return;
    }

    if (isConnected) {
      // Se já conectado, apenas recarregar eventos
      await loadEvents();
    } else {
      // Iniciar fluxo OAuth
      setError(null);
      await promptAsync();
    }
  }, [request, isConnected, promptAsync]);

  /**
   * Cria um novo evento no Google Calendar
   */
  const createEvent = useCallback(async (eventData: {
    title: string;
    description?: string;
    startTime: string;
    endTime: string;
    attendees?: string[];
    location?: string;
  }) => {
    if (!user?.id || !isConnected) {
      throw new Error('Usuário não conectado ao Google Calendar');
    }

    setIsLoading(true);
    setError(null);

    try {
      // Garantir token válido
      const accessToken = await ensureValidToken(user.id);
      
      // Criar evento
      await createRealGoogleEvent(accessToken, eventData);
      
      // Recarregar eventos
      await loadEvents();
      
      Alert.alert('Sucesso', 'Evento criado no Google Calendar!');
      
    } catch (error) {
      console.error('Erro ao criar evento:', error);
      setError(error instanceof Error ? error.message : 'Erro ao criar evento');
      throw error;
    } finally {
      setIsLoading(false);
    }
  }, [user?.id, isConnected]);

  /**
   * Recarrega os eventos
   */
  const refetchEvents = useCallback(async () => {
    if (isConnected) {
      await loadEvents();
    }
  }, [isConnected]);

  /**
   * Desconecta do Google Calendar
   */
  const disconnect = useCallback(async () => {
    if (!user?.id) return;

    try {
      // Remover credenciais do banco
      // Nota: Supabase não tem método direto para delete, usamos update com null
      await saveRealCalendarCredentials({
        user_id: user.id,
        provider: 'google',
        access_token: '',
        refresh_token: '',
        expires_at: '',
      });

      setIsConnected(false);
      setEvents([]);
      setError(null);
      
      Alert.alert('Desconectado', 'Desconectado do Google Calendar');
      
    } catch (error) {
      console.error('Erro ao desconectar:', error);
      Alert.alert('Erro', 'Falha ao desconectar do Google Calendar');
    }
  }, [user?.id]);

  const value: RealCalendarContextData = {
    events,
    isLoading,
    isConnected,
    error,
    syncWithGoogle,
    createEvent,
    refetchEvents,
    disconnect,
  };

  return (
    <RealCalendarContext.Provider value={value}>
      {children}
    </RealCalendarContext.Provider>
  );
};

export const useRealCalendar = () => {
  const context = useContext(RealCalendarContext);
  if (!context) {
    throw new Error('useRealCalendar deve ser usado dentro de RealCalendarProvider');
  }
  return context;
}; 