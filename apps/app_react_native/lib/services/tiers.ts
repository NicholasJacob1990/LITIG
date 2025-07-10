import supabase from '@/lib/supabase';

export interface LawyerTier {
  id: string;
  tier_name: string;
  display_name: string;
  description: string;
  consultation_fee: number;
  hourly_rate: number;
  min_experience_years: number;
  max_experience_years?: number;
  created_at: string;
  updated_at: string;
}

export interface TierDefaultFees {
  consultation_fee: number;
  hourly_rate: number;
  tier_name: string;
  display_name: string;
}

/**
 * Busca todos os tiers disponíveis
 */
export const getAllTiers = async (): Promise<LawyerTier[]> => {
  const { data, error } = await supabase
    .from('lawyer_tiers')
    .select('*')
    .order('min_experience_years', { ascending: true });

  if (error) {
    console.error('Error fetching tiers:', error);
    throw new Error('Falha ao buscar tiers de advogados');
  }

  return data || [];
};

/**
 * Busca valores padrão de um tier específico
 */
export const getTierDefaultFees = async (tierId: string): Promise<TierDefaultFees | null> => {
  const { data, error } = await supabase
    .rpc('get_tier_default_fees', { p_tier_id: tierId });

  if (error) {
    console.error('Error fetching tier default fees:', error);
    throw new Error('Falha ao buscar valores padrão do tier');
  }

  return data?.[0] || null;
};

/**
 * Busca advogados por tiers específicos
 */
export const getLawyersByTiers = async (tierNames: string[]): Promise<any[]> => {
  const { data, error } = await supabase
    .rpc('get_lawyers_by_tier', { p_tier_names: tierNames });

  if (error) {
    console.error('Error fetching lawyers by tiers:', error);
    throw new Error('Falha ao buscar advogados por tier');
  }

  return data || [];
};

/**
 * Atualiza o tier de um advogado
 */
export const updateLawyerTier = async (lawyerId: string, tierId: string): Promise<void> => {
  const { error } = await supabase
    .from('lawyers')
    .update({ tier_id: tierId })
    .eq('id', lawyerId);

  if (error) {
    console.error('Error updating lawyer tier:', error);
    throw new Error('Falha ao atualizar tier do advogado');
  }
};

/**
 * Busca o tier de um advogado específico
 */
export const getLawyerTier = async (lawyerId: string): Promise<LawyerTier | null> => {
  const { data, error } = await supabase
    .from('lawyers')
    .select(`
      tier_id,
      lawyer_tiers (
        id,
        tier_name,
        display_name,
        description,
        consultation_fee,
        hourly_rate,
        min_experience_years,
        max_experience_years,
        created_at,
        updated_at
      )
    `)
    .eq('id', lawyerId)
    .single();

  if (error) {
    console.error('Error fetching lawyer tier:', error);
    throw new Error('Falha ao buscar tier do advogado');
  }

  return (data?.lawyer_tiers as unknown as LawyerTier) || null;
};

/**
 * Sugere tier baseado na experiência do advogado
 */
export const suggestTierByExperience = async (experienceYears: number): Promise<LawyerTier | null> => {
  const { data, error } = await supabase
    .from('lawyer_tiers')
    .select('*')
    .lte('min_experience_years', experienceYears)
    .or(`max_experience_years.gte.${experienceYears},max_experience_years.is.null`)
    .order('min_experience_years', { ascending: false })
    .limit(1);

  if (error) {
    console.error('Error suggesting tier by experience:', error);
    throw new Error('Falha ao sugerir tier baseado na experiência');
  }

  return data?.[0] || null;
};

/**
 * Constantes para os tiers disponíveis
 */
export const TIER_NAMES = {
  JUNIOR: 'junior',
  PLENO: 'pleno',
  SENIOR: 'senior',
  ESPECIALISTA: 'especialista'
} as const;

export const TIER_DISPLAY_NAMES = {
  [TIER_NAMES.JUNIOR]: 'Advogado Júnior',
  [TIER_NAMES.PLENO]: 'Advogado Pleno',
  [TIER_NAMES.SENIOR]: 'Advogado Sênior',
  [TIER_NAMES.ESPECIALISTA]: 'Advogado Especialista'
} as const;

export const TIER_DESCRIPTIONS = {
  [TIER_NAMES.JUNIOR]: 'Profissionais com até 3 anos de experiência, ideais para casos de baixa complexidade',
  [TIER_NAMES.PLENO]: 'Profissionais com 4 a 10 anos de experiência, adequados para casos de média complexidade',
  [TIER_NAMES.SENIOR]: 'Profissionais com mais de 10 anos de experiência, especialistas em casos complexos',
  [TIER_NAMES.ESPECIALISTA]: 'Profissionais altamente especializados com reconhecimento no mercado'
} as const; 