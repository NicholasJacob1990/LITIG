import supabase from '@/lib/supabase';

export interface CaseData {
  id: string;
  status: 'pending_assignment' | 'assigned' | 'in_progress' | 'closed' | 'cancelled';
  ai_analysis?: any;
  client_id: string;
  lawyer_id?: string;
  created_at: string;
  updated_at: string;
  // Campos básicos do caso
  title: string;
  description: string;
  area: string;
  subarea: string;
  priority: 'high' | 'medium' | 'low';
  urgency_hours: number;
  risk_level: 'high' | 'medium' | 'low';
  confidence_score: number;
  estimated_cost: number;
  next_step: string;
  // Escopo do serviço (definido pelo advogado)
  service_scope?: string;
  service_scope_defined_at?: string;
  service_scope_defined_by?: string;
  // Estrutura de honorários
  consultation_fee: number;
  representation_fee: number;
  fee_type: 'fixed' | 'success' | 'hourly' | 'plan' | 'mixed';
  success_percentage?: number;
  hourly_rate?: number;
  plan_type?: string;
  payment_terms?: string;
  // Dados do cliente
  client_name?: string;
  client_type?: 'PF' | 'PJ';
  // Contagem de mensagens
  unread_messages?: number;
  // Dados do advogado
  lawyer_name?: string;
  lawyer_specialty?: string;
  lawyer_avatar?: string;
  lawyer_oab?: string;
  lawyer_rating?: number;
  lawyer_experience_years?: number;
  lawyer_success_rate?: number;
  lawyer_phone?: string;
  lawyer_email?: string;
  lawyer_location?: string;
  // Interfaces para compatibilidade com componentes existentes
  lawyer?: {
    id: string;
    name: string;
    avatar?: string;
    specialty: string;
    oab: string;
    rating: number;
    experience_years: number;
    success_rate: number;
    phone?: string;
    email?: string;
    location?: string;
  };
  client?: {
    name: string;
    avatar?: string;
    type: 'PF' | 'PJ';
  };
}

/**
 * Busca os casos de um usuário usando a função RPC corrigida
 * @param userId - O ID do usuário
 */
export const getUserCases = async (userId: string): Promise<CaseData[]> => {
  if (!userId) return [];

  const { data, error } = await supabase
    .rpc('get_user_cases', { p_user_id: userId });

  if (error) {
    console.error('Error fetching user cases:', error);
    throw error;
  }
  return data || [];
};

/**
 * Busca os casos de um advogado usando a função RPC corrigida
 * @param lawyerId - O ID do advogado
 */
export const getLawyerCases = async (lawyerId: string): Promise<CaseData[]> => {
  const { data, error } = await supabase.rpc('get_user_cases', { p_user_id: lawyerId });

  if (error) {
    console.error('Error fetching lawyer cases:', error);
    throw new Error('Falha ao buscar os casos do advogado.');
  }
  return data || [];
};

/**
 * Busca um caso específico por ID
 * @param caseId - O ID do caso
 */
export const getCaseById = async (caseId: string): Promise<CaseData | null> => {
  const { data, error } = await supabase
    .from('cases')
    .select(`
      id,
      status,
      ai_analysis,
      client_id,
      lawyer_id,
      created_at,
      updated_at,
      title,
      description,
      area,
      subarea,
      priority,
      urgency_hours,
      risk_level,
      confidence_score,
      estimated_cost,
      next_step,
      service_scope,
      service_scope_defined_at,
      service_scope_defined_by,
      consultation_fee,
      representation_fee,
      fee_type,
      success_percentage,
      hourly_rate,
      plan_type,
      payment_terms,
      profiles!cases_client_id_fkey (
        full_name,
        avatar_url,
        user_type
      ),
      profiles!cases_lawyer_id_fkey (
        full_name,
        avatar_url,
        specialization,
        oab_number,
        rating,
        experience_years,
        success_rate,
        phone,
        email,
        location
      )
    `)
    .eq('id', caseId)
    .single();

  if (error) {
    console.error('Error fetching case by ID:', error);
    throw error;
  }

  if (!data) return null;

  // Transformar os dados para o formato esperado
  const profiles = data.profiles as any[];
  const clientProfile = profiles?.[0]; // Primeiro perfil é do cliente
  const lawyerProfile = profiles?.[1]; // Segundo perfil é do advogado

  return {
    ...data,
    client_name: clientProfile?.full_name,
    client_type: clientProfile?.user_type,
    lawyer_name: lawyerProfile?.full_name,
    lawyer_specialty: lawyerProfile?.specialization,
    lawyer_avatar: lawyerProfile?.avatar_url,
    lawyer_oab: lawyerProfile?.oab_number,
    lawyer_rating: lawyerProfile?.rating,
    lawyer_experience_years: lawyerProfile?.experience_years,
    lawyer_success_rate: lawyerProfile?.success_rate,
    lawyer_phone: lawyerProfile?.phone,
    lawyer_email: lawyerProfile?.email,
    lawyer_location: lawyerProfile?.location,
    // Criar objetos para compatibilidade
    client: clientProfile ? {
      name: clientProfile.full_name,
      avatar: clientProfile.avatar_url,
      type: clientProfile.user_type
    } : undefined,
    lawyer: lawyerProfile ? {
      id: data.lawyer_id,
      name: lawyerProfile.full_name,
      avatar: lawyerProfile.avatar_url,
      specialty: lawyerProfile.specialization,
      oab: lawyerProfile.oab_number,
      rating: lawyerProfile.rating,
      experience_years: lawyerProfile.experience_years,
      success_rate: lawyerProfile.success_rate,
      phone: lawyerProfile.phone,
      email: lawyerProfile.email,
      location: lawyerProfile.location
    } : undefined
  };
};

/**
 * Atualiza o status de um caso
 * @param caseId - O ID do caso
 * @param status - O novo status
 */
export const updateCaseStatus = async (
  caseId: string, 
  status: CaseData['status']
): Promise<void> => {
  const { error } = await supabase
    .from('cases')
    .update({ status, updated_at: new Date().toISOString() })
    .eq('id', caseId);

  if (error) {
    console.error('Error updating case status:', error);
    throw error;
  }
};

/**
 * Busca a análise de IA de um caso
 * @param caseId - O ID do caso
 */
export const getAIAnalysis = async (caseId: string): Promise<any> => {
  const { data, error } = await supabase
    .from('cases')
    .select('ai_analysis')
    .eq('id', caseId)
    .single();

  if (error) {
    console.error('Error fetching AI analysis:', error);
    throw error;
  }

  return data?.ai_analysis;
};

/**
 * Atualiza a análise de IA de um caso
 * @param caseId - O ID do caso
 * @param analysis - A análise de IA
 */
export const updateAIAnalysis = async (
  caseId: string, 
  analysis: any
): Promise<void> => {
  const { error } = await supabase
    .from('cases')
    .update({ ai_analysis: analysis, updated_at: new Date().toISOString() })
    .eq('id', caseId);

  if (error) {
    console.error('Error updating AI analysis:', error);
    throw error;
  }
};

/**
 * Busca estatísticas de casos de um usuário
 * @param userId - O ID do usuário
 */
export const getCaseStats = async (userId: string) => {
  const { data, error } = await supabase
    .from('cases')
    .select('status')
    .or(`client_id.eq.${userId},lawyer_id.eq.${userId}`);

  if (error) {
    console.error('Error fetching case stats:', error);
    throw error;
  }

  const stats = {
    total: data.length,
    pending_assignment: data.filter(c => c.status === 'pending_assignment').length,
    assigned: data.filter(c => c.status === 'assigned').length,
    in_progress: data.filter(c => c.status === 'in_progress').length,
    closed: data.filter(c => c.status === 'closed').length,
    cancelled: data.filter(c => c.status === 'cancelled').length,
  };

  return stats;
};

export const updateCase = async (caseId: string, updates: Partial<CaseData>) => {
  const { data, error } = await supabase
    .from('cases')
    .update(updates)
    .eq('id', caseId)
    .select()
    .single();

  if (error) {
    console.error('Error updating case:', error);
    throw new Error('Falha ao atualizar o caso.');
  }

  return data;
}; 