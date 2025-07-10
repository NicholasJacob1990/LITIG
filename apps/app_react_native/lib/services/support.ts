import supabase from '@/lib/supabase';

// Tipos para os dados de suporte
export interface SupportTicket {
    id?: string;
    created_at?: string;
    creator_id: string;
    case_id?: string;
    subject: string;
    description?: string;
    status?: 'open' | 'in_progress' | 'closed' | 'on_hold';
    priority?: 'low' | 'medium' | 'high' | 'critical';
    last_viewed_at?: string;
    updated_at?: string;
}

export interface SupportMessage {
    id?: string;
    created_at?: string;
    ticket_id: string;
    sender_id: string;
    content: string;
    attachment_url?: string;
    attachment_name?: string;
    attachment_mime_type?: string;
}

export interface SupportRating {
    id?: string;
    ticket_id: string;
    stars: number;
    comment?: string;
    created_at?: string;
}

export interface AttachmentUpload {
    file: File; // Para web - no mobile será convertido para File antes
    ticketId: string;
    userId: string;
}

/**
 * Faz upload de um arquivo para o Supabase Storage
 * @param attachment - Dados do arquivo e contexto
 */
export const uploadAttachment = async (attachment: AttachmentUpload) => {
    const { file, ticketId, userId } = attachment;
    
    // Gerar nome único para o arquivo
    const timestamp = Date.now();
    const fileName = `${timestamp}_${file.name}`;
    const filePath = `${userId}/${ticketId}/${fileName}`;

    // Upload para o bucket support_attachments
    const { data, error } = await supabase.storage
        .from('support_attachments')
        .upload(filePath, file);

    if (error) {
        console.error('Error uploading file:', error);
        throw error;
    }

    // Obter URL pública do arquivo
    const { data: urlData } = supabase.storage
        .from('support_attachments')
        .getPublicUrl(filePath);

    return {
        path: filePath,
        url: urlData.publicUrl,
        name: file.name,
        type: file.type || 'application/octet-stream'
    };
};

/**
 * Remove um arquivo do Supabase Storage
 * @param filePath - Caminho do arquivo no storage
 */
export const deleteAttachment = async (filePath: string) => {
    const { error } = await supabase.storage
        .from('support_attachments')
        .remove([filePath]);

    if (error) {
        console.error('Error deleting file:', error);
        throw error;
    }
};

/**
 * Busca todos os tickets de suporte criados por um usuário.
 * @param creatorId - O ID do usuário que criou os tickets.
 */
export const getSupportTickets = async (creatorId: string) => {
  const { data, error } = await supabase
    .from('support_tickets')
    .select('*')
    .eq('creator_id', creatorId)
    .order('created_at', { ascending: false });

  if (error) {
    console.error('Error fetching support tickets:', error);
    throw error;
  }
  return data;
};

/**
 * Cria um novo ticket de suporte.
 * @param ticketData - Os dados do ticket.
 */
export const createSupportTicket = async (ticketData: SupportTicket) => {
  const { data, error } = await supabase
    .from('support_tickets')
    .insert([ticketData])
    .select()
    .single();

  if (error) {
    console.error('Error creating support ticket:', error);
    throw error;
  }
  return data;
};

/**
 * Atualiza o status de um ticket de suporte.
 * @param ticketId - O ID do ticket.
 * @param newStatus - O novo status do ticket.
 */
export const updateTicketStatus = async (
  ticketId: string, 
  newStatus: 'open' | 'in_progress' | 'closed' | 'on_hold'
) => {
  const { error } = await supabase.rpc('update_ticket_status', {
    ticket_id: ticketId,
    new_status: newStatus
  });

  if (error) {
    console.error('Error updating ticket status:', error);
    throw error;
  }
};

/**
 * Atualiza a prioridade de um ticket de suporte.
 * @param ticketId - O ID do ticket.
 * @param newPriority - A nova prioridade do ticket.
 */
export const updateTicketPriority = async (
  ticketId: string, 
  newPriority: 'low' | 'medium' | 'high' | 'critical'
) => {
  const { error } = await supabase.rpc('update_ticket_priority', {
    ticket_id: ticketId,
    new_priority: newPriority
  });

  if (error) {
    console.error('Error updating ticket priority:', error);
    throw error;
  }
};

/**
 * Marca um ticket como lido.
 * @param ticketId - O ID do ticket.
 */
export const markTicketRead = async (ticketId: string) => {
  const { error } = await supabase.rpc('mark_ticket_read', {
    ticket_id: ticketId
  });

  if (error) {
    console.error('Error marking ticket as read:', error);
    throw error;
  }
};

/**
 * Avalia um ticket fechado.
 * @param ticketId - O ID do ticket.
 * @param stars - Número de estrelas (1-5).
 * @param comment - Comentário opcional.
 */
export const rateTicket = async (ticketId: string, stars: number, comment?: string) => {
  const { error } = await supabase.rpc('rate_ticket', {
    ticket_id: ticketId,
    stars,
    comment
  });

  if (error) {
    console.error('Error rating ticket:', error);
    throw error;
  }
};

/**
 * Busca as mensagens de um ticket de suporte específico.
 * @param ticketId - O ID do ticket.
 */
export const getSupportMessages = async (ticketId: string) => {
  const { data, error } = await supabase
    .from('support_messages')
    .select(`
      *,
      sender:profiles (full_name, avatar_url)
    `)
    .eq('ticket_id', ticketId)
    .order('created_at', { ascending: true });

  if (error) {
    console.error('Error fetching support messages:', error);
    throw error;
  }
  return data;
};

/**
 * Envia uma nova mensagem em um ticket.
 * @param messageData - Os dados da mensagem.
 */
export const sendSupportMessage = async (messageData: SupportMessage) => {
    const { data, error } = await supabase
      .from('support_messages')
      .insert([messageData])
      .select()
      .single();
  
    if (error) {
      console.error('Error sending support message:', error);
      throw error;
    }
    return data;
}; 