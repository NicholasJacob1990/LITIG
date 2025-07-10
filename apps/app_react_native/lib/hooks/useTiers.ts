import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { 
  getAllTiers, 
  getTierDefaultFees, 
  getLawyersByTiers, 
  getLawyerTier, 
  updateLawyerTier,
  suggestTierByExperience,
  LawyerTier,
  TierDefaultFees 
} from '../services/tiers';

// Query Keys
export const tierKeys = {
  all: ['tiers'] as const,
  lists: () => [...tierKeys.all, 'list'] as const,
  list: () => [...tierKeys.lists()] as const,
  details: () => [...tierKeys.all, 'detail'] as const,
  detail: (id: string) => [...tierKeys.details(), id] as const,
  defaults: (id: string) => [...tierKeys.detail(id), 'defaults'] as const,
  lawyers: (tierNames: string[]) => [...tierKeys.all, 'lawyers', tierNames] as const,
  lawyerTier: (lawyerId: string) => [...tierKeys.all, 'lawyer', lawyerId] as const,
  suggestion: (experience: number) => [...tierKeys.all, 'suggestion', experience] as const,
};

/**
 * Hook para buscar todos os tiers disponíveis
 */
export function useTiers() {
  return useQuery({
    queryKey: tierKeys.list(),
    queryFn: getAllTiers,
    staleTime: 30 * 60 * 1000, // 30 minutos - tiers não mudam frequentemente
    gcTime: 60 * 60 * 1000, // 1 hora
  });
}

/**
 * Hook para buscar valores padrão de um tier específico
 */
export function useTierDefaults(tierId: string) {
  return useQuery({
    queryKey: tierKeys.defaults(tierId),
    queryFn: () => getTierDefaultFees(tierId),
    enabled: !!tierId,
    staleTime: 30 * 60 * 1000, // 30 minutos
    gcTime: 60 * 60 * 1000, // 1 hora
  });
}

/**
 * Hook para buscar advogados por tiers específicos
 */
export function useLawyersByTiers(tierNames: string[]) {
  return useQuery({
    queryKey: tierKeys.lawyers(tierNames),
    queryFn: () => getLawyersByTiers(tierNames),
    enabled: tierNames.length > 0,
    staleTime: 5 * 60 * 1000, // 5 minutos
    gcTime: 10 * 60 * 1000, // 10 minutos
  });
}

/**
 * Hook para buscar o tier de um advogado específico
 */
export function useLawyerTier(lawyerId: string) {
  return useQuery({
    queryKey: tierKeys.lawyerTier(lawyerId),
    queryFn: () => getLawyerTier(lawyerId),
    enabled: !!lawyerId,
    staleTime: 10 * 60 * 1000, // 10 minutos
    gcTime: 30 * 60 * 1000, // 30 minutos
  });
}

/**
 * Hook para sugerir tier baseado na experiência
 */
export function useTierSuggestion(experienceYears: number) {
  return useQuery({
    queryKey: tierKeys.suggestion(experienceYears),
    queryFn: () => suggestTierByExperience(experienceYears),
    enabled: experienceYears >= 0,
    staleTime: 30 * 60 * 1000, // 30 minutos
    gcTime: 60 * 60 * 1000, // 1 hora
  });
}

/**
 * Hook para atualizar o tier de um advogado
 */
export function useUpdateLawyerTier() {
  const queryClient = useQueryClient();
  
  return useMutation({
    mutationFn: ({ lawyerId, tierId }: { lawyerId: string; tierId: string }) =>
      updateLawyerTier(lawyerId, tierId),
    onSuccess: (_, { lawyerId }) => {
      // Invalidar cache do tier do advogado
      queryClient.invalidateQueries({ queryKey: tierKeys.lawyerTier(lawyerId) });
      
      // Invalidar listas de advogados por tier
      queryClient.invalidateQueries({ queryKey: tierKeys.all });
    },
  });
}

/**
 * Hook customizado para obter informações completas de tier para um advogado
 */
export function useLawyerTierInfo(lawyerId: string) {
  const { data: tier, isLoading: tierLoading, error: tierError } = useLawyerTier(lawyerId);
  const { data: defaults, isLoading: defaultsLoading, error: defaultsError } = useTierDefaults(tier?.id || '');

  return {
    tier,
    defaults,
    isLoading: tierLoading || defaultsLoading,
    error: tierError || defaultsError,
    hasData: !!tier && !!defaults,
  };
} 