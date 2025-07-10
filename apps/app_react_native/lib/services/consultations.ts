import supabase from '@/lib/supabase';

export interface ConsultationData {
  id: string;
  case_id: string;
  lawyer_id: string;
  client_id: string;
  scheduled_at: string;
  duration_minutes: number;
  modality: 'video' | 'presencial' | 'telefone';
  plan_type: string;
  status: 'scheduled' | 'completed' | 'cancelled' | 'rescheduled';
  notes?: string;
  meeting_url?: string;
  created_at: string;
  updated_at: string;
  lawyer_name?: string;
  client_name?: string;
}

// Interface para compatibilidade com o formulário
export interface Consultation {
  id?: string;
  case_id: string;
  lawyer_id: string;
  client_id?: string;
  scheduled_date: string;
  duration: number;
  modality: 'presencial' | 'videochamada' | 'telefone';
  plan: 'gratuita' | 'premium' | 'corporativa';
  status: 'agendada' | 'confirmada' | 'concluida' | 'cancelada';
  notes?: string;
  created_at?: string;
  updated_at?: string;
}

/**
 * Busca as consultas de um caso
 * @param caseId - O ID do caso
 */
export const getCaseConsultations = async (caseId: string): Promise<ConsultationData[]> => {
  const { data, error } = await supabase.rpc('get_case_consultations', {
    p_case_id: caseId
  });

  if (error) {
    console.error('Error fetching case consultations:', error);
    throw error;
  }

  return data || [];
};

/**
 * Busca a consulta mais recente de um caso
 * @param caseId - O ID do caso
 */
export const getLatestConsultation = async (caseId: string): Promise<ConsultationData | null> => {
  const consultations = await getCaseConsultations(caseId);
  return consultations.length > 0 ? consultations[0] : null;
};

/**
 * Cria uma nova consulta
 * @param consultationData - Os dados da consulta
 */
export const createConsultation = async (consultationData: Consultation): Promise<ConsultationData> => {
  // Converter dados do formulário para o formato do banco
  const dbData = {
    case_id: consultationData.case_id,
    lawyer_id: consultationData.lawyer_id,
    client_id: consultationData.client_id,
    scheduled_at: consultationData.scheduled_date,
    duration_minutes: consultationData.duration,
    modality: consultationData.modality === 'videochamada' ? 'video' : consultationData.modality,
    plan_type: consultationData.plan,
    status: consultationData.status === 'agendada' ? 'scheduled' : 
             consultationData.status === 'confirmada' ? 'scheduled' :
             consultationData.status === 'concluida' ? 'completed' : 'cancelled',
    notes: consultationData.notes,
  };

  const { data, error } = await supabase
    .from('consultations')
    .insert(dbData)
    .select(`
      id,
      case_id,
      lawyer_id,
      client_id,
      scheduled_at,
      duration_minutes,
      modality,
      plan_type,
      status,
      notes,
      meeting_url,
      created_at,
      updated_at
    `)
    .single();

  if (error) {
    console.error('Error creating consultation:', error);
    throw error;
  }

  return data;
};

/**
 * Atualiza uma consulta
 * @param consultationId - O ID da consulta
 * @param updateData - Os dados a serem atualizados
 */
export const updateConsultation = async (
  consultationId: string,
  updateData: Partial<Consultation>
): Promise<ConsultationData> => {
  // Converter dados do formulário para o formato do banco
  const dbData: any = {};
  
  if (updateData.scheduled_date) dbData.scheduled_at = updateData.scheduled_date;
  if (updateData.duration) dbData.duration_minutes = updateData.duration;
  if (updateData.modality) dbData.modality = updateData.modality === 'videochamada' ? 'video' : updateData.modality;
  if (updateData.plan) dbData.plan_type = updateData.plan;
  if (updateData.status) {
    dbData.status = updateData.status === 'agendada' ? 'scheduled' : 
                   updateData.status === 'confirmada' ? 'scheduled' :
                   updateData.status === 'concluida' ? 'completed' : 'cancelled';
  }
  if (updateData.notes !== undefined) dbData.notes = updateData.notes;

  const { data, error } = await supabase
    .from('consultations')
    .update(dbData)
    .eq('id', consultationId)
    .select(`
      id,
      case_id,
      lawyer_id,
      client_id,
      scheduled_at,
      duration_minutes,
      modality,
      plan_type,
      status,
      notes,
      meeting_url,
      created_at,
      updated_at
    `)
    .single();

  if (error) {
    console.error('Error updating consultation:', error);
    throw error;
  }

  return data;
};

/**
 * Exclui uma consulta
 * @param consultationId - O ID da consulta
 */
export const deleteConsultation = async (consultationId: string): Promise<void> => {
  const { error } = await supabase
    .from('consultations')
    .delete()
    .eq('id', consultationId);

  if (error) {
    console.error('Error deleting consultation:', error);
    throw error;
  }
};

/**
 * Busca todas as consultas de um usuário (cliente ou advogado)
 * @param userId - O ID do usuário
 */
export const getUserConsultations = async (userId: string): Promise<ConsultationData[]> => {
  const { data, error } = await supabase
    .from('consultations')
    .select(`
      id,
      case_id,
      lawyer_id,
      client_id,
      scheduled_at,
      duration_minutes,
      modality,
      plan_type,
      status,
      notes,
      meeting_url,
      created_at,
      updated_at,
      lawyer:profiles!lawyer_id (full_name),
      client:profiles!client_id (full_name)
    `)
    .or(`client_id.eq.${userId},lawyer_id.eq.${userId}`)
    .order('scheduled_at', { ascending: false });

  if (error) {
    console.error('Error fetching user consultations:', error);
    throw error;
  }

  return data?.map(consultation => ({
    ...consultation,
    lawyer_name: (consultation.lawyer as any)?.full_name,
    client_name: (consultation.client as any)?.full_name
  })) || [];
};

/**
 * Formata a modalidade da consulta para exibição
 * @param modality - A modalidade da consulta
 */
export const formatModality = (modality: ConsultationData['modality']): string => {
  switch (modality) {
    case 'video':
      return 'Vídeo';
    case 'presencial':
      return 'Presencial';
    case 'telefone':
      return 'Telefone';
    default:
      return 'Não definido';
  }
};

/**
 * Formata o status da consulta para exibição
 * @param status - O status da consulta
 */
export const formatStatus = (status: ConsultationData['status']): string => {
  switch (status) {
    case 'scheduled':
      return 'Agendada';
    case 'completed':
      return 'Concluída';
    case 'cancelled':
      return 'Cancelada';
    case 'rescheduled':
      return 'Reagendada';
    default:
      return 'Não definido';
  }
};

/**
 * Formata a duração da consulta
 * @param minutes - A duração em minutos
 */
export const formatDuration = (minutes: number): string => {
  if (minutes < 60) {
    return `${minutes} minutos`;
  } else {
    const hours = Math.floor(minutes / 60);
    const remainingMinutes = minutes % 60;
    if (remainingMinutes === 0) {
      return `${hours} hora${hours > 1 ? 's' : ''}`;
    } else {
      return `${hours}h ${remainingMinutes}min`;
    }
  }
}; 