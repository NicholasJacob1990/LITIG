import supabase from '@/lib/supabase';

export interface ServiceScopeData {
  case_id: string;
  service_scope: string;
  defined_at: string;
  defined_by: string;
  lawyer_name?: string;
}

/**
 * Atualiza o escopo do serviço de um caso
 * @param caseId - O ID do caso
 * @param serviceScope - O escopo detalhado do serviço
 * @param lawyerId - O ID do advogado que está definindo o escopo
 */
export const updateServiceScope = async (
  caseId: string,
  serviceScope: string,
  lawyerId: string
): Promise<ServiceScopeData> => {
  const { data, error } = await supabase.rpc('update_service_scope', {
    p_case_id: caseId,
    p_service_scope: serviceScope,
    p_lawyer_id: lawyerId
  });

  if (error) {
    console.error('Error updating service scope:', error);
    throw error;
  }

  return data;
};

/**
 * Busca o escopo do serviço de um caso
 * @param caseId - O ID do caso
 */
export const getServiceScope = async (caseId: string): Promise<ServiceScopeData | null> => {
  const { data, error } = await supabase
    .from('cases')
    .select(`
      id,
      service_scope,
      service_scope_defined_at,
      service_scope_defined_by,
      profiles!service_scope_defined_by (
        full_name
      )
    `)
    .eq('id', caseId)
    .single();

  if (error) {
    console.error('Error fetching service scope:', error);
    throw error;
  }

  if (!data || !data.service_scope) {
    return null;
  }

  return {
    case_id: data.id,
    service_scope: data.service_scope,
    defined_at: data.service_scope_defined_at,
    defined_by: data.service_scope_defined_by,
    lawyer_name: (data.profiles as any)?.full_name
  };
};

/**
 * Verifica se um caso já tem escopo de serviço definido
 * @param caseId - O ID do caso
 */
export const hasServiceScope = async (caseId: string): Promise<boolean> => {
  const { data, error } = await supabase
    .from('cases')
    .select('service_scope')
    .eq('id', caseId)
    .single();

  if (error) {
    console.error('Error checking service scope:', error);
    return false;
  }

  return !!(data?.service_scope && data.service_scope.trim().length > 0);
};

/**
 * Formata a data de definição do escopo
 * @param dateString - A data em formato string
 */
export const formatDefinedDate = (dateString: string): string => {
  return new Date(dateString).toLocaleDateString('pt-BR', {
    day: '2-digit',
    month: 'long',
    year: 'numeric',
    hour: '2-digit',
    minute: '2-digit'
  });
}; 