import { createClient } from '@supabase/supabase-js';
import { PostgrestError } from '@supabase/supabase-js';

// Configuração do Supabase - com fallbacks para desenvolvimento
const supabaseUrl = process.env.EXPO_PUBLIC_SUPABASE_URL || 'http://localhost:54321';
const supabaseAnonKey = process.env.EXPO_PUBLIC_SUPABASE_ANON_KEY || 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeo-s3C13nNhVOQnJbLUgJdHNTMJJBQYBzk';

// Log para debug (apenas em desenvolvimento)
if (__DEV__) {
  console.log('Supabase URL:', supabaseUrl);
  console.log('Supabase Anon Key:', supabaseAnonKey ? 'Loaded' : 'Missing');
}

const supabase = createClient(supabaseUrl, supabaseAnonKey);

// Tipos para os dados dos advogados
export interface Lawyer {
  id: string;
  name: string;
  oab_number: string;
  primary_area: string;
  specialties: string[];
  avatar_url?: string;
  is_available: boolean;
  rating: number;
  review_count: number;
  lat: number;
  lng: number;
  experience: number;
  response_time: string;
  success_rate: number;
  hourly_rate: number;
  consultation_fee: number;
  next_availability: string;
  languages: string[];
  consultation_types: string[];
  is_approved: boolean;
  bio?: string;
  education?: string[];
  certifications?: string[];
  professional_experience?: string[];
  skills?: string[];
  awards?: string[];
  publications?: string[];
  bar_associations?: string[];
  practice_areas?: string[];
  phone?: string;
  email?: string;
  website?: string;
  linkedin?: string;
  office_address?: string;
  office_hours?: string;
  graduation_year?: number;
  postgraduate_courses?: string[];
  current_cases_count?: number;
  total_cases_count?: number;
  specialization_years?: any;
  professional_summary?: string;
  availability_schedule?: any;
  consultation_methods?: string[];
  emergency_availability?: boolean;
  profile_completion_percentage?: number;
  cv_processed_at?: string;
  profile_updated_at?: string;
  success_status?: 'V' | 'P' | 'N';
  oab_inscription_date?: string;
}

// Interface para os parâmetros da função lawyers_nearby
export interface LawyersNearbyParams {
  _lat: number;
  _lng: number;
  _radius_km: number;
  _area?: string | null;
  _rating_min?: number | null;
  _available?: boolean | null;
  _languages?: string[] | null;
  _consultation_types?: string[] | null;
}

// Interface para o resultado da busca
export interface LawyerSearchResult extends Lawyer {
  distance_km?: number;
}

// Serviço para buscar advogados próximos
export class LawyerService {
  /**
   * Busca advogados próximos usando a função RPC do Supabase
   * Conforme especificado no GPS.md
   */
  static async getLawyersNearby(params: LawyersNearbyParams): Promise<LawyerSearchResult[]> {
    try {
      const { data, error } = await supabase.rpc('lawyers_nearby', {
        _lat: params._lat,
        _lng: params._lng,
        _radius_km: params._radius_km,
        _area: params._area,
        _rating_min: params._rating_min,
        _available: params._available,
      });

      if (error) {
        console.error('Erro ao buscar advogados:', error);
        throw error;
      }

      return data || [];
    } catch (error) {
      console.error('Erro na busca de advogados:', error);
      return [];
    }
  }

  /**
   * Busca advogado por ID
   */
  static async getLawyerById(id: string): Promise<Lawyer | null> {
      const { data, error } = await supabase
        .from('lawyers')
        .select('*')
        .eq('id', id)
        .single();

      if (error) {
      console.error('Error fetching lawyer by ID:', error);
      return null;
    }
    return data;
  }

  /**
   * Atualiza status de disponibilidade do advogado
   */
  static async updateLawyerAvailability(id: string, isAvailable: boolean): Promise<boolean> {
    try {
      const { error } = await supabase
        .from('lawyers')
        .update({ 
          is_available: isAvailable,
          updated_at: new Date().toISOString()
        })
        .eq('id', id);

      if (error) {
        console.error('Erro ao atualizar disponibilidade:', error);
        return false;
      }

      return true;
    } catch (error) {
      console.error('Erro ao atualizar disponibilidade:', error);
      return false;
    }
  }

  /**
   * Busca advogados por área de especialização
   */
  static async getLawyersByArea(area: string): Promise<Lawyer[]> {
    try {
      const { data, error } = await supabase
        .from('lawyers')
        .select('*')
        .ilike('primary_area', `%${area}%`)
        .eq('is_approved', true)
        .order('rating', { ascending: false });

      if (error) {
        console.error('Erro ao buscar advogados por área:', error);
        return [];
      }

      return data || [];
    } catch (error) {
      console.error('Erro ao buscar advogados por área:', error);
      return [];
    }
  }

  /**
   * Busca advogados com filtros avançados
   */
  static async getLawyersWithFilters(filters: {
    areas?: string[];
    languages?: string[];
    consultationTypes?: string[];
    minRating?: number;
    availableOnly?: boolean;
    maxDistance?: number;
    userLat?: number;
    userLng?: number;
  }): Promise<LawyerSearchResult[]> {
    try {
      let query = supabase
        .from('lawyers')
        .select('*')
        .eq('is_approved', true);

      // Aplicar filtros
      if (filters.availableOnly) {
        query = query.eq('is_available', true);
      }

      if (filters.minRating) {
        query = query.gte('rating', filters.minRating);
      }

      if (filters.areas && filters.areas.length > 0) {
        query = query.in('primary_area', filters.areas);
      }

      const { data, error } = await query.order('rating', { ascending: false });

      if (error) {
        console.error('Erro ao buscar advogados com filtros:', error);
        return [];
      }

      let results = data || [];

      // Filtrar por idiomas e tipos de consulta no frontend
      if (filters.languages && filters.languages.length > 0) {
        results = results.filter(lawyer => 
          filters.languages!.some(lang => lawyer.languages.includes(lang))
        );
      }

      if (filters.consultationTypes && filters.consultationTypes.length > 0) {
        results = results.filter(lawyer => 
          filters.consultationTypes!.some(type => lawyer.consultation_types.includes(type))
        );
      }

      // Calcular distâncias se coordenadas fornecidas
      if (filters.userLat && filters.userLng) {
        results = results.map(lawyer => ({
          ...lawyer,
          distance_km: this.calculateDistance(
            filters.userLat!,
            filters.userLng!,
            lawyer.lat,
            lawyer.lng
          )
        }));

        // Ordenar por distância
        results.sort((a, b) => (a.distance_km || 0) - (b.distance_km || 0));

        // Filtrar por distância máxima
        if (filters.maxDistance) {
          results = results.filter(lawyer => (lawyer.distance_km || 0) <= filters.maxDistance!);
        }
      }

      return results;
    } catch (error) {
      console.error('Erro ao buscar advogados com filtros:', error);
      return [];
    }
  }

  /**
   * Calcula distância entre duas coordenadas (Haversine)
   */
  private static calculateDistance(lat1: number, lon1: number, lat2: number, lon2: number): number {
    const R = 6371; // Raio da Terra em km
    const dLat = this.deg2rad(lat2 - lat1);
    const dLon = this.deg2rad(lon2 - lon1);
    const a =
      Math.sin(dLat / 2) * Math.sin(dLat / 2) +
      Math.cos(this.deg2rad(lat1)) *
        Math.cos(this.deg2rad(lat2)) *
        Math.sin(dLon / 2) *
        Math.sin(dLon / 2);
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    return R * c; // Distância em km
  }

  private static deg2rad(deg: number): number {
    return deg * (Math.PI / 180);
  }

  /**
   * Cria um novo advogado no banco de dados.
   * Os dados são recebidos do formulário de onboarding.
   */
  static async createLawyer(lawyerData: Partial<Lawyer>): Promise<{ data: Lawyer | null, error: any }> {
    try {
      const { data, error } = await supabase
        .from('lawyers')
        .insert([
          {
            ...lawyerData,
            // Garante que os campos obrigatórios tenham valores padrão se não forem fornecidos
            is_approved: false, // Novos advogados sempre começam como não aprovados
            rating: 0,
            review_count: 0,
          }
        ])
        .select()
        .single();

      if (error) {
        console.error('Erro ao criar advogado:', error);
        return { data: null, error };
      }

      return { data, error: null };
    } catch (error) {
      console.error('Exceção ao criar advogado:', error);
      return { data: null, error };
    }
  }

  static async updateLawyer(id: string, updates: Partial<Lawyer>): Promise<Lawyer | null> {
    const { data, error } = await supabase
      .from('lawyers')
      .update(updates)
      .eq('id', id)
      .select()
      .single();

    if (error) {
      console.error('Erro ao atualizar advogado:', error);
      return null;
    }
    return data;
  }
}

// Configuração para Realtime (opcional)
export const setupRealtime = () => {
  // Inscrever para mudanças na tabela lawyers
  const channel = supabase
    .channel('lawyers_changes')
    .on(
      'postgres_changes',
      {
        event: '*',
        schema: 'public',
        table: 'lawyers'
      },
      (payload) => {
        console.log('Mudança detectada na tabela lawyers:', payload);
        // Aqui você pode emitir eventos para atualizar o mapa em tempo real
      }
    )
    .subscribe();

  return channel;
};

export default supabase;

// Case Management Functions

export const createCase = async (analysisData: any, clientId: string) => {
  if (!clientId) {
    throw new Error('Client ID is required to create a case.');
  }

  if (!analysisData) {
    throw new Error('Analysis data is required to create a case.');
  }

  // Para desenvolvimento: se o clientId é temporário, gera um UUID válido
  let finalClientId = clientId;
  if (clientId.startsWith('temp_user_')) {
    // Gera um UUID válido para usuários temporários
    finalClientId = '00000000-0000-0000-0000-' + clientId.replace('temp_user_', '').padStart(12, '0').substring(0, 12);
  }

  console.log('Tentando criar caso com client_id:', finalClientId);
  console.log('Dados da análise:', JSON.stringify(analysisData, null, 2));

  try {
    const { data, error } = await supabase
      .from('cases')
      .insert([
        { 
          client_id: finalClientId,
          ai_analysis: analysisData,
          status: 'pending_assignment'
        }
      ])
      .select()
      .single();

    if (error) {
      console.error('Error creating case in Supabase:', error);
      console.error('Error details:', JSON.stringify(error, null, 2));
      
      // Fornece mensagens de erro mais específicas
      let errorMessage = 'Failed to create case: ';
      if (error.code === '23505') {
        errorMessage += 'Duplicate case detected.';
      } else if (error.code === '23503') {
        errorMessage += 'Invalid reference data.';
      } else if (error.message) {
        errorMessage += error.message;
      } else {
        errorMessage += 'Unknown database error.';
      }
      
      throw new Error(errorMessage);
    }

    if (!data) {
      throw new Error('No data returned from database after case creation.');
    }

    console.log('Caso criado com sucesso:', data);
    return data;
    
  } catch (dbError) {
    console.error('Database operation failed:', dbError);
    
    // Re-throw com mensagem mais clara se for um erro conhecido
    if (dbError instanceof Error) {
      throw dbError;
    } else {
      throw new Error('Unexpected database error occurred while creating case.');
    }
  }
};

export async function assignLawyerToCase(caseId: string, lawyerId: string) {
  const { data, error } = await supabase
    .from('cases')
    .update({ lawyer_id: lawyerId, status: 'assigned' })
    .eq('id', caseId)
    .select()
    .single();

  if (error) {
    console.error('Error assigning lawyer to case:', error);
    throw new Error('Could not assign lawyer to case.');
  }

  return data;
}

export async function getUserCases(userId: string) {
  const { data, error } = await supabase
    .from('cases')
    .select('id, created_at, ai_analysis')
    .eq('client_id', userId)
    .order('created_at', { ascending: false });

  if (error) {
    console.error('Error fetching user cases:', error);
    throw new Error('Could not fetch user cases.');
  }

  return data;
}

// CV Analysis Functions

/**
 * Salva a análise de CV no banco de dados
 */
export async function saveCVAnalysis(lawyerId: string, cvUrl: string, analysis: any) {
  try {
    const { data, error } = await supabase
      .from('lawyers')
      .update({
        cv_url: cvUrl,
        cv_analysis: analysis,
        cv_processed_at: new Date().toISOString(),
        // Atualizar campos do perfil com base na análise
        name: analysis.personalInfo?.name || undefined,
        email: analysis.personalInfo?.email || undefined,
        phone: analysis.personalInfo?.phone || undefined,
        bio: analysis.professionalSummary || undefined,
        experience: analysis.totalExperience || 0,
        education: analysis.education?.map((edu: any) => `${edu.degree} - ${edu.institution} (${edu.year || 'N/A'})`) || [],
        certifications: analysis.certifications?.map((cert: any) => `${cert.name} - ${cert.issuer} (${cert.year || 'N/A'})`) || [],
        professional_experience: analysis.experience?.map((exp: any) => 
          `${exp.position} na ${exp.company} (${exp.startDate} - ${exp.endDate || 'Atual'}): ${exp.description}`
        ) || [],
        skills: analysis.skills || [],
        languages: analysis.languages || ['Português'],
        practice_areas: analysis.practiceAreas || [],
        oab_number: analysis.oabNumber || undefined,
        bar_associations: analysis.barAssociations || [],
        awards: analysis.awards || [],
        publications: analysis.publications || [],
        specialization_years: analysis.specializationYears || {},
        consultation_fee: analysis.consultationFee || 0,
        hourly_rate: analysis.hourlyRate || 0,
        availability_schedule: analysis.availabilitySchedule ? { description: analysis.availabilitySchedule } : undefined,
        emergency_availability: analysis.emergencyAvailability || false,
        consultation_methods: analysis.consultationMethods || ['online', 'presencial'],
        professional_summary: analysis.professionalSummary || undefined,
        website: analysis.personalInfo?.website || undefined,
        linkedin: analysis.personalInfo?.linkedin || undefined,
        office_address: analysis.personalInfo?.address || undefined,
        // Calcular porcentagem de completude do perfil
        profile_completion_percentage: null, // Será calculado pelo trigger
        profile_updated_at: new Date().toISOString()
      })
      .eq('id', lawyerId)
      .select()
      .single();

    if (error) {
      console.error('Erro ao salvar análise de CV:', error);
      throw new Error('Erro ao salvar análise de CV no banco de dados');
    }

    // Calcular porcentagem de completude
    const { data: completionData, error: completionError } = await supabase
      .rpc('calculate_profile_completion', { lawyer_id: lawyerId });

    if (!completionError && completionData !== null) {
      await supabase
        .from('lawyers')
        .update({ profile_completion_percentage: completionData })
        .eq('id', lawyerId);
    }

    return data;
  } catch (error) {
    console.error('Erro ao salvar análise de CV:', error);
    throw error;
  }
}

/**
 * Busca análise de CV de um advogado
 */
export async function getCVAnalysis(lawyerId: string) {
  try {
    const { data, error } = await supabase
      .from('lawyers')
      .select('cv_url, cv_analysis, cv_processed_at')
      .eq('id', lawyerId)
      .single();

    if (error) {
      console.error('Erro ao buscar análise de CV:', error);
      return null;
    }

    return data;
  } catch (error) {
    console.error('Erro ao buscar análise de CV:', error);
    return null;
  }
}

/**
 * Atualiza perfil do advogado baseado na análise de CV
 */
export async function updateLawyerProfileFromCV(lawyerId: string, cvAnalysis: any) {
  try {
    const updateData: any = {};

    // Mapear dados da análise para os campos do banco
    if (cvAnalysis.personalInfo) {
      if (cvAnalysis.personalInfo.name) updateData.name = cvAnalysis.personalInfo.name;
      if (cvAnalysis.personalInfo.email) updateData.email = cvAnalysis.personalInfo.email;
      if (cvAnalysis.personalInfo.phone) updateData.phone = cvAnalysis.personalInfo.phone;
      if (cvAnalysis.personalInfo.website) updateData.website = cvAnalysis.personalInfo.website;
      if (cvAnalysis.personalInfo.linkedin) updateData.linkedin = cvAnalysis.personalInfo.linkedin;
      if (cvAnalysis.personalInfo.address) updateData.office_address = cvAnalysis.personalInfo.address;
    }

    if (cvAnalysis.professionalSummary) {
      updateData.bio = cvAnalysis.professionalSummary;
      updateData.professional_summary = cvAnalysis.professionalSummary;
    }

    if (cvAnalysis.totalExperience) updateData.experience = cvAnalysis.totalExperience;
    if (cvAnalysis.oabNumber) updateData.oab_number = cvAnalysis.oabNumber;
    if (cvAnalysis.consultationFee) updateData.consultation_fee = cvAnalysis.consultationFee;
    if (cvAnalysis.hourlyRate) updateData.hourly_rate = cvAnalysis.hourlyRate;
    if (cvAnalysis.emergencyAvailability !== undefined) updateData.emergency_availability = cvAnalysis.emergencyAvailability;

    // Arrays
    if (cvAnalysis.skills) updateData.skills = cvAnalysis.skills;
    if (cvAnalysis.languages) updateData.languages = cvAnalysis.languages;
    if (cvAnalysis.practiceAreas) updateData.practice_areas = cvAnalysis.practiceAreas;
    if (cvAnalysis.barAssociations) updateData.bar_associations = cvAnalysis.barAssociations;
    if (cvAnalysis.awards) updateData.awards = cvAnalysis.awards;
    if (cvAnalysis.publications) updateData.publications = cvAnalysis.publications;
    if (cvAnalysis.consultationMethods) updateData.consultation_methods = cvAnalysis.consultationMethods;

    // Processar educação
    if (cvAnalysis.education) {
      updateData.education = cvAnalysis.education.map((edu: any) => 
        `${edu.degree} - ${edu.institution} (${edu.year || 'N/A'})`
      );
    }

    // Processar certificações
    if (cvAnalysis.certifications) {
      updateData.certifications = cvAnalysis.certifications.map((cert: any) => 
        `${cert.name} - ${cert.issuer} (${cert.year || 'N/A'})`
      );
    }

    // Processar experiência profissional
    if (cvAnalysis.experience) {
      updateData.professional_experience = cvAnalysis.experience.map((exp: any) => 
        `${exp.position} na ${exp.company} (${exp.startDate} - ${exp.endDate || 'Atual'}): ${exp.description}`
      );
    }

    // JSON fields
    if (cvAnalysis.specializationYears) updateData.specialization_years = cvAnalysis.specializationYears;
    if (cvAnalysis.availabilitySchedule) {
      updateData.availability_schedule = { description: cvAnalysis.availabilitySchedule };
    }

    updateData.profile_updated_at = new Date().toISOString();

    const { data, error } = await supabase
      .from('lawyers')
      .update(updateData)
      .eq('id', lawyerId)
      .select()
      .single();

    if (error) {
      console.error('Erro ao atualizar perfil do advogado:', error);
      throw new Error('Erro ao atualizar perfil do advogado');
    }

    return data;
  } catch (error) {
    console.error('Erro ao atualizar perfil do advogado:', error);
    throw error;
  }
}

/**
 * Verifica se o advogado tem CV processado
 */
export async function hasProcessedCV(lawyerId: string): Promise<boolean> {
  try {
    const { data, error } = await supabase
      .from('lawyers')
      .select('cv_processed_at')
      .eq('id', lawyerId)
      .single();

    if (error) {
      console.error('Erro ao verificar CV processado:', error);
      return false;
    }

    return data?.cv_processed_at !== null;
  } catch (error) {
    console.error('Erro ao verificar CV processado:', error);
    return false;
  }
} 