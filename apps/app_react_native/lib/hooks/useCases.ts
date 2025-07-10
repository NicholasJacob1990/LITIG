import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { getCasesWithMatches, getPersistedMatches, createCase, CaseWithMatches, MatchResponse } from '../services/api';
import supabase from '../supabase';

// Tipos
interface Case {
  id: string;
  title: string;
  description: string;
  status: string;
  area: string;
  subarea: string;
  urgency_h: number;
  client_id: string;
  lawyer_id?: string;
  created_at: string;
  updated_at: string;
}

interface CaseFilters {
  status?: string;
  area?: string;
  lawyer_id?: string;
  client_id?: string;
}

// Query Keys
export const caseKeys = {
  all: ['cases'] as const,
  lists: () => [...caseKeys.all, 'list'] as const,
  list: (filters: CaseFilters) => [...caseKeys.lists(), filters] as const,
  details: () => [...caseKeys.all, 'detail'] as const,
  detail: (id: string) => [...caseKeys.details(), id] as const,
  stats: () => [...caseKeys.all, 'stats'] as const,
  matches: (id: string) => [...caseKeys.detail(id), 'matches'] as const,
  withMatches: () => [...caseKeys.all, 'with-matches'] as const,
};

// Hook para buscar casos com contagem de matches
export function useCasesWithMatches() {
  return useQuery({
    queryKey: caseKeys.withMatches(),
    queryFn: getCasesWithMatches,
    staleTime: 2 * 60 * 1000, // 2 minutos
    gcTime: 5 * 60 * 1000, // 5 minutos
  });
}

// Hook para buscar casos com filtros usando Supabase
export function useCases(filters: CaseFilters = {}) {
  return useQuery({
    queryKey: caseKeys.list(filters),
    queryFn: async () => {
      let query = supabase.from('cases').select('*');
      
      if (filters.status) {
        query = query.eq('status', filters.status);
      }
      if (filters.area) {
        query = query.eq('area', filters.area);
      }
      if (filters.lawyer_id) {
        query = query.eq('lawyer_id', filters.lawyer_id);
      }
      if (filters.client_id) {
        query = query.eq('client_id', filters.client_id);
      }
      
      const { data, error } = await query;
      
      if (error) {
        throw new Error(error.message);
      }
      
      return data;
    },
    staleTime: 2 * 60 * 1000, // 2 minutos
    gcTime: 5 * 60 * 1000, // 5 minutos
  });
}

// Hook para buscar detalhes de um caso específico
export function useCase(id: string) {
  return useQuery({
    queryKey: caseKeys.detail(id),
    queryFn: async () => {
      const { data, error } = await supabase
        .from('cases')
        .select('*')
        .eq('id', id)
        .single();
      
      if (error) {
        throw new Error(error.message);
      }
      
      return data;
    },
    enabled: !!id,
    staleTime: 5 * 60 * 1000, // 5 minutos
    gcTime: 10 * 60 * 1000, // 10 minutos
  });
}

// Hook para buscar matches de um caso
export function useCaseMatches(caseId: string) {
  return useQuery({
    queryKey: caseKeys.matches(caseId),
    queryFn: () => getPersistedMatches(caseId),
    enabled: !!caseId,
    staleTime: 5 * 60 * 1000, // 5 minutos
    gcTime: 10 * 60 * 1000, // 10 minutos
  });
}

// Hook para buscar estatísticas de casos
export function useCaseStats() {
  return useQuery({
    queryKey: caseKeys.stats(),
    queryFn: async () => {
      const { data, error } = await supabase.rpc('get_case_statistics');
      
      if (error) {
        throw new Error(error.message);
      }
      
      return data;
    },
    staleTime: 10 * 60 * 1000, // 10 minutos
    gcTime: 30 * 60 * 1000, // 30 minutos
  });
}

// Hook para criar um novo caso
export function useCreateCase() {
  const queryClient = useQueryClient();
  
  return useMutation({
    mutationFn: async (newCase: Omit<Case, 'id' | 'created_at' | 'updated_at'>) => {
      const { data, error } = await supabase
        .from('cases')
        .insert(newCase)
        .select()
        .single();
      
      if (error) {
        throw new Error(error.message);
      }
      
      return data;
    },
    onSuccess: (newCase) => {
      // Invalidar e refetch listas de casos
      queryClient.invalidateQueries({ queryKey: caseKeys.lists() });
      queryClient.invalidateQueries({ queryKey: caseKeys.stats() });
      queryClient.invalidateQueries({ queryKey: caseKeys.withMatches() });
      
      // Adicionar o novo caso ao cache
      queryClient.setQueryData(caseKeys.detail(newCase.id), newCase);
    },
  });
}

// Hook para atualizar um caso
export function useUpdateCase() {
  const queryClient = useQueryClient();
  
  return useMutation({
    mutationFn: async ({ id, updates }: { id: string; updates: Partial<Case> }) => {
      const { data, error } = await supabase
        .from('cases')
        .update(updates)
        .eq('id', id)
        .select()
        .single();
      
      if (error) {
        throw new Error(error.message);
      }
      
      return data;
    },
    onSuccess: (updatedCase) => {
      // Atualizar o cache do caso específico
      queryClient.setQueryData(caseKeys.detail(updatedCase.id), updatedCase);
      
      // Invalidar listas que podem conter este caso
      queryClient.invalidateQueries({ queryKey: caseKeys.lists() });
      queryClient.invalidateQueries({ queryKey: caseKeys.stats() });
      queryClient.invalidateQueries({ queryKey: caseKeys.withMatches() });
    },
  });
}

// Hook para deletar um caso
export function useDeleteCase() {
  const queryClient = useQueryClient();
  
  return useMutation({
    mutationFn: async (id: string) => {
      const { error } = await supabase
        .from('cases')
        .delete()
        .eq('id', id);
      
      if (error) {
        throw new Error(error.message);
      }
      
      return id;
    },
    onSuccess: (deletedId) => {
      // Remover do cache
      queryClient.removeQueries({ queryKey: caseKeys.detail(deletedId) });
      
      // Invalidar listas
      queryClient.invalidateQueries({ queryKey: caseKeys.lists() });
      queryClient.invalidateQueries({ queryKey: caseKeys.stats() });
      queryClient.invalidateQueries({ queryKey: caseKeys.withMatches() });
    },
  });
}

// Hook para buscar casos do usuário logado
export function useMyCases() {
  return useQuery({
    queryKey: ['my-cases'],
    queryFn: async () => {
      const { data: { user } } = await supabase.auth.getUser();
      
      if (!user) {
        throw new Error('Usuário não autenticado');
      }
      
      const { data, error } = await supabase
        .from('cases')
        .select('*')
        .eq('client_id', user.id)
        .order('created_at', { ascending: false });
      
      if (error) {
        throw new Error(error.message);
      }
      
      return data;
    },
    staleTime: 1 * 60 * 1000, // 1 minuto
    gcTime: 5 * 60 * 1000, // 5 minutos
  });
} 