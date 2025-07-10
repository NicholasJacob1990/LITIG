import supabase from '@/lib/supabase';

export interface ProcessEventData {
  id: string;
  event_date: string;
  title: string;
  description?: string;
  document_url?: string;
}

export interface ProcessEvent {
  id?: string;
  case_id: string;
  event_date: string;
  event_type: 'peticao' | 'decisao' | 'audiencia' | 'despacho' | 'sentenca' | 'recurso' | 'outro';
  title: string;
  description?: string;
  document_url?: string;
  created_by: string;
  created_at?: string;
  updated_at?: string;
}

/**
 * Busca todos os eventos processuais de um caso
 * @param caseId - O ID do caso
 */
export const getProcessEvents = async (caseId: string): Promise<ProcessEventData[]> => {
  const { data, error } = await supabase.rpc('get_process_events', {
    p_case_id: caseId
  });

  if (error) {
    console.error('Error fetching process events:', error);
    throw error;
  }

  return data || [];
};

/**
 * Busca os eventos processuais mais recentes de um caso
 * @param caseId - O ID do caso
 * @param limit - O número de eventos a serem retornados
 */
export const getLatestProcessEvents = async (caseId: string, limit: number = 3): Promise<ProcessEventData[]> => {
  const allEvents = await getProcessEvents(caseId);
  return allEvents.slice(0, limit);
};

/**
 * Cria um novo evento processual
 * @param eventData - Os dados do evento
 */
export const createProcessEvent = async (eventData: ProcessEvent): Promise<ProcessEvent> => {
  const { data, error } = await supabase
    .from('process_events')
    .insert([eventData])
    .select()
    .single();

  if (error) {
    console.error('Error creating process event:', error);
    throw error;
  }

  return data;
};

/**
 * Atualiza um evento processual existente
 * @param eventId - O ID do evento
 * @param eventData - Os dados atualizados
 */
export const updateProcessEvent = async (eventId: string, eventData: Partial<ProcessEvent>): Promise<ProcessEvent> => {
  const { data, error } = await supabase
    .from('process_events')
    .update(eventData)
    .eq('id', eventId)
    .select()
    .single();

  if (error) {
    console.error('Error updating process event:', error);
    throw error;
  }

  return data;
};

/**
 * Deleta um evento processual
 * @param eventId - O ID do evento
 */
export const deleteProcessEvent = async (eventId: string): Promise<void> => {
  const { error } = await supabase
    .from('process_events')
    .delete()
    .eq('id', eventId);

  if (error) {
    console.error('Error deleting process event:', error);
    throw error;
  }
}; 