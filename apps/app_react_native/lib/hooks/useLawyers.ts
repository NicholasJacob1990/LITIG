import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { getLawyerPerformance, LawyerKPIs, findMatches, LawyerMatch } from '../services/api';
import supabase, { LawyerSearchResult } from '../supabase';

// Tipos
interface Lawyer {
  id: string;
  nome: string;
  email: string;
  avatar_url?: string;
  primary_area: string;
  tags_expertise: string[];
  geo_latlon: [number, number];
  is_available: boolean;
  rating: number;
  kpi: any;
  kpi_subarea: any;
  kpi_softskill: number;
  created_at: string;
  updated_at: string;
  // Novos campos para sincronização completa
  curriculo_json: {
    anos_experiencia?: number;
    pos_graduacoes?: Array<{
      titulo: string;
      instituicao: string;
      ano: number;
    }>;
    num_publicacoes?: number;
    formacao?: string;
    certificacoes?: string[];
    experiencia_profissional?: string[];
    resumo_profissional?: string;
  };
  oab_numero?: string;
  uf?: string;
  bio?: string;
  telefone?: string;
  review_texts?: string[];
  review_count?: number;
  experience?: number;
  consultation_fee?: number;
  consultation_types?: string[];
  distance_km?: number;
  response_time?: number;
  expertise_areas?: string[];
}

interface LawyerFilters {
  area?: string;
  is_available?: boolean;
  rating_min?: number;
  distance_km?: number;
  coords?: [number, number];
  name?: string;
  preset?: 'fast' | 'expert' | 'balanced' | 'economic';
  complexity?: 'LOW' | 'MEDIUM' | 'HIGH';
  coordinates: {
    latitude: number;
    longitude: number;
  };
  // Novos filtros de valor
  maxConsultationFee?: number;
  maxHourlyRate?: number;
  // Filtro por tiers
  tiers?: string[]; // ['junior', 'pleno', 'senior', 'especialista']
}

// Query Keys
export const lawyerKeys = {
  all: ['lawyers'] as const,
  lists: () => [...lawyerKeys.all, 'list'] as const,
  list: (filters: LawyerFilters) => [...lawyerKeys.lists(), filters] as const,
  details: () => [...lawyerKeys.all, 'detail'] as const,
  detail: (id: string) => [...lawyerKeys.details(), id] as const,
  performance: (id: string) => [...lawyerKeys.detail(id), 'performance'] as const,
  myPerformance: () => [...lawyerKeys.all, 'my-performance'] as const,
};

// Hook para buscar advogados com filtros
export function useLawyers(filters: LawyerFilters) {
  return useQuery({
    queryKey: lawyerKeys.list(filters),
    queryFn: async (): Promise<LawyerMatch[]> => {
      const requestBody = {
        case: {
          title: `Busca na área de ${filters.area || 'Direito'}`,
          description: `Busca por advogado com os seguintes filtros: ${JSON.stringify(filters)}`,
          area: filters.area || 'Civil',
          subarea: 'Geral',
          urgency_hours: 72,
          coordinates: filters.coordinates,
          complexity: filters.complexity || 'MEDIUM',
        },
        top_n: 50,
        preset: filters.preset || 'balanced',
        // Adicionando filtros por tier à requisição
        tiers: filters.tiers,
      };

      const response = await findMatches(requestBody);
      
      return response.lawyers;
    },
    enabled: !!filters.coordinates,
    staleTime: 5 * 60 * 1000,
    gcTime: 10 * 60 * 1000,
  });
}

// Hook para buscar detalhes de um advogado específico
export function useLawyer(id: string) {
  return useQuery({
    queryKey: lawyerKeys.detail(id),
    queryFn: async () => {
      const { data, error } = await supabase
        .from('lawyers')
        .select('*')
        .eq('id', id)
        .single();
      
      if (error) {
        throw new Error(error.message);
      }
      
      return data as Lawyer;
    },
    enabled: !!id,
    staleTime: 5 * 60 * 1000, // 5 minutos
    gcTime: 10 * 60 * 1000, // 10 minutos
  });
}

// Hook para buscar performance do advogado logado
export function useMyLawyerPerformance() {
  return useQuery({
    queryKey: lawyerKeys.myPerformance(),
    queryFn: getLawyerPerformance,
    staleTime: 10 * 60 * 1000, // 10 minutos
    gcTime: 30 * 60 * 1000, // 30 minutos
  });
}

// Hook para buscar performance de um advogado específico
export function useLawyerPerformance(id: string) {
  return useQuery({
    queryKey: lawyerKeys.performance(id),
    queryFn: async () => {
      const { data, error } = await supabase
        .from('lawyers')
        .select('kpi, kpi_subarea, kpi_softskill')
        .eq('id', id)
        .single();
      
      if (error) {
        throw new Error(error.message);
      }
      
      return data as LawyerKPIs;
    },
    enabled: !!id,
    staleTime: 10 * 60 * 1000, // 10 minutos
    gcTime: 30 * 60 * 1000, // 30 minutos
  });
}

// Hook para atualizar perfil do advogado
export function useUpdateLawyer() {
  const queryClient = useQueryClient();
  
  return useMutation({
    mutationFn: async ({ id, updates }: { id: string; updates: Partial<Lawyer> }) => {
      const { data, error } = await supabase
        .from('lawyers')
        .update(updates)
        .eq('id', id)
        .select()
        .single();
      
      if (error) {
        throw new Error(error.message);
      }
      
      return data as Lawyer;
    },
    onSuccess: (updatedLawyer) => {
      // Atualizar o cache do advogado específico
      queryClient.setQueryData(lawyerKeys.detail(updatedLawyer.id), updatedLawyer);
      
      // Invalidar listas que podem conter este advogado
      queryClient.invalidateQueries({ queryKey: lawyerKeys.lists() });
      
      // Se for o próprio advogado, invalidar performance
      queryClient.invalidateQueries({ queryKey: lawyerKeys.myPerformance() });
    },
  });
}

// Hook para atualizar disponibilidade do advogado
export function useUpdateLawyerAvailability() {
  const queryClient = useQueryClient();
  
  return useMutation({
    mutationFn: async ({ id, isAvailable }: { id: string; isAvailable: boolean }) => {
      const { data, error } = await supabase
        .from('lawyers')
        .update({ is_available: isAvailable })
        .eq('id', id)
        .select()
        .single();
      
      if (error) {
        throw new Error(error.message);
      }
      
      return data as Lawyer;
    },
    onSuccess: (updatedLawyer) => {
      // Atualizar o cache do advogado específico
      queryClient.setQueryData(lawyerKeys.detail(updatedLawyer.id), updatedLawyer);
      
      // Invalidar listas que podem conter este advogado
      queryClient.invalidateQueries({ queryKey: lawyerKeys.lists() });
    },
  });
}

// Hook para buscar advogados próximos
export function useNearbyLawyers(coords: [number, number], area: string, radiusKm: number = 50) {
  return useQuery({
    queryKey: ['nearby-lawyers', coords, area, radiusKm],
    queryFn: async () => {
      const { data, error } = await supabase.rpc('find_nearby_lawyers', {
        area,
        lat: coords[0],
        lon: coords[1],
        km: radiusKm,
      });
      
      if (error) {
        throw new Error(error.message);
      }
      
      return data as Lawyer[];
    },
    enabled: !!coords && !!area,
    staleTime: 5 * 60 * 1000, // 5 minutos
    gcTime: 10 * 60 * 1000, // 10 minutos
  });
} 