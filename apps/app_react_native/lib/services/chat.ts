import supabase from '@/lib/supabase';
import { RealtimeChannel } from '@supabase/supabase-js';

export interface MessageData {
  id: string;
  case_id: string;
  user_id: string;
  content: string;
  read: boolean;
  created_at: string;
  sender?: {
    name: string;
    avatar?: string;
    role: 'client' | 'lawyer' | 'admin';
  };
}

export interface ChatData {
  id: string;
  case_id: string;
  participants: string[];
  last_message?: string;
  last_message_at?: string;
  created_at: string;
  updated_at: string;
}

export interface PreHiringChat {
  id: string;
  created_at: string;
  updated_at: string;
  lawyer: {
    id: string;
    full_name: string;
    avatar_url: string;
  };
  last_message?: {
    content: string;
    created_at: string;
  }
}

export interface PreHiringMessage {
  id: string;
  chat_id: string;
  sender_id: string;
  content: string;
  created_at: string;
  sender?: {
    full_name: string;
    avatar_url: string;
  };
}

/**
 * Busca as mensagens de um caso
 * @param caseId - O ID do caso
 * @param limit - Número máximo de mensagens (padrão: 50)
 */
export const getCaseMessages = async (
  caseId: string, 
  limit: number = 50
): Promise<MessageData[]> => {
  const { data, error } = await supabase
    .from('messages')
    .select(`
      id,
      case_id,
      user_id,
      content,
      read,
      created_at,
      profiles (
        full_name,
        avatar_url,
        role
      )
    `)
    .eq('case_id', caseId)
    .order('created_at', { ascending: false })
    .limit(limit);

  if (error) {
    console.error('Error fetching case messages:', error);
    throw error;
  }

  return data?.map(msg => {
    const profile = Array.isArray(msg.profiles) ? msg.profiles[0] : msg.profiles;
    return {
      ...msg,
      sender: profile ? {
        name: profile.full_name,
        avatar: profile.avatar_url,
        role: profile.role
      } : undefined
    }
  }) || [];
};

/**
 * Envia uma mensagem para um caso
 * @param caseId - O ID do caso
 * @param userId - O ID do usuário que está enviando
 * @param content - O conteúdo da mensagem
 */
export const sendMessage = async (
  caseId: string,
  userId: string,
  content: string
): Promise<MessageData> => {
  const { data, error } = await supabase
    .from('messages')
    .insert({
      case_id: caseId,
      user_id: userId,
      content,
      read: false,
      created_at: new Date().toISOString()
    })
    .select(`
      id,
      case_id,
      user_id,
      content,
      read,
      created_at,
      profiles (
        full_name,
        avatar_url,
        role
      )
    `)
    .single();

  if (error) {
    console.error('Error sending message:', error);
    throw error;
  }

  const profile = Array.isArray(data.profiles) ? data.profiles[0] : data.profiles;
  return {
    ...data,
    sender: profile ? {
      name: profile.full_name,
      avatar: profile.avatar_url,
      role: profile.role
    } : undefined
  };
};

/**
 * Marca mensagens como lidas
 * @param caseId - O ID do caso
 * @param userId - O ID do usuário que está lendo
 */
export const markMessagesAsRead = async (
  caseId: string,
  userId: string
): Promise<void> => {
  const { error } = await supabase
    .from('messages')
    .update({ read: true })
    .eq('case_id', caseId)
    .neq('user_id', userId) // Não marcar como lida as próprias mensagens
    .eq('read', false);

  if (error) {
    console.error('Error marking messages as read:', error);
    throw error;
  }
};

/**
 * Busca o número de mensagens não lidas de um caso
 * @param caseId - O ID do caso
 * @param userId - O ID do usuário atual
 */
export const getUnreadMessagesCount = async (
  caseId: string,
  userId: string
): Promise<number> => {
  const { count, error } = await supabase
    .from('messages')
    .select('*', { count: 'exact', head: true })
    .eq('case_id', caseId)
    .neq('user_id', userId) // Mensagens de outros usuários
    .eq('read', false);

  if (error) {
    console.error('Error getting unread messages count:', error);
    throw error;
  }

  return count || 0;
};

/**
 * Busca todos os chats de um usuário
 * @param userId - O ID do usuário
 */
export const getUserChats = async (userId: string): Promise<ChatData[]> => {
  const { data, error } = await supabase
    .from('cases')
    .select(`
      id,
      created_at,
      updated_at,
      messages (
        content,
        created_at,
        user_id
      )
    `)
    .or(`client_id.eq.${userId},lawyer_id.eq.${userId}`)
    .order('updated_at', { ascending: false });

  if (error) {
    console.error('Error fetching user chats:', error);
    throw error;
  }

  return data?.map(caseData => ({
    id: caseData.id,
    case_id: caseData.id,
    participants: [], // Pode ser expandido para incluir os participantes
    last_message: caseData.messages?.[0]?.content,
    last_message_at: caseData.messages?.[0]?.created_at,
    created_at: caseData.created_at,
    updated_at: caseData.updated_at
  })) || [];
};

/**
 * Subscreve a mudanças em tempo real nas mensagens de um caso
 * @param caseId - O ID do caso
 * @param callback - Função chamada quando há nova mensagem
 */
export const subscribeToCaseMessages = (
  caseId: string,
  callback: (message: MessageData) => void
) => {
  const subscription = supabase
    .channel(`case_messages_${caseId}`)
    .on(
      'postgres_changes',
      {
        event: 'INSERT',
        schema: 'public',
        table: 'messages',
        filter: `case_id=eq.${caseId}`
      },
      (payload) => {
        callback(payload.new as MessageData);
      }
    )
    .subscribe();

  return subscription;
};

/**
 * Remove subscrição de mensagens de um caso
 * @param subscription - A subscrição a ser removida
 */
export const unsubscribeFromCaseMessages = (subscription: RealtimeChannel) => {
  supabase.removeChannel(subscription);
};

/**
 * Inicia ou busca um chat existente com um advogado.
 * @param lawyerId - O ID do advogado com quem se quer conversar.
 */
export const getOrCreatePreHiringChat = async (lawyerId: string): Promise<PreHiringChat> => {
  const { data, error } = await supabase.rpc('get_or_create_pre_hiring_chat', {
    p_lawyer_id: lawyerId,
  });

  if (error) {
    console.error('Error getting or creating pre-hiring chat:', error);
    throw error;
  }
  return data;
};

/**
 * Busca as mensagens de um chat pré-contratação.
 * @param chatId - O ID do chat.
 */
export const getPreHiringMessages = async (chatId: string): Promise<PreHiringMessage[]> => {
  const { data, error } = await supabase
    .from('pre_hiring_messages')
    .select('*, sender:profiles(id, full_name, avatar_url)')
    .eq('chat_id', chatId)
    .order('created_at', { ascending: true });

  if (error) {
    console.error('Error fetching pre-hiring messages:', error);
    throw error;
  }
  return data?.map(m => ({
    ...m,
    sender: m.sender || undefined
  })) || [];
};

/**
 * Envia uma nova mensagem em um chat pré-contratação.
 * @param chatId - O ID do chat.
 * @param content - O conteúdo da mensagem.
 */
export const sendPreHiringMessage = async (chatId: string, content: string): Promise<PreHiringMessage> => {
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error("Usuário não autenticado");

    const { data, error } = await supabase
      .from('pre_hiring_messages')
      .insert({
        chat_id: chatId,
        content: content,
        sender_id: user.id
      })
      .select()
      .single();
  
    if (error) {
      console.error('Error sending pre-hiring message:', error);
      throw error;
    }
    return data;
};

/**
 * Busca a lista de todos os chats (de casos e pré-contratação) do usuário.
 */
export const getChatList = async (): Promise<PreHiringChat[]> => {
    const { data, error } = await supabase.rpc('get_user_chat_list');

    if (error) {
        console.error('Error fetching chat list:', error);
        throw error;
    }
    return data || [];
};

/**
 * Cria uma inscrição em tempo real para um canal de chat.
 * @param chatId - O ID do chat.
 * @param onNewMessage - Callback a ser executado quando uma nova mensagem chegar.
 */
export const subscribeToChat = (
  chatId: string,
  onNewMessage: (message: PreHiringMessage) => void
): RealtimeChannel => {
  const channel = supabase
    .channel(`pre-hiring-chat-${chatId}`)
    .on<PreHiringMessage>(
      'postgres_changes',
      {
        event: 'INSERT',
        schema: 'public',
        table: 'pre_hiring_messages',
        filter: `chat_id=eq.${chatId}`,
      },
      (payload) => {
        onNewMessage(payload.new);
      }
    )
    .subscribe();

  return channel;
};

/**
 * Remove a inscrição de um canal de chat.
 */
export const unsubscribeFromChat = (channel: RealtimeChannel) => {
    if (channel) {
        supabase.removeChannel(channel);
    }
}