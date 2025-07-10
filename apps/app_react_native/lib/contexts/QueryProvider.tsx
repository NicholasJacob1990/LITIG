import React from 'react';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';

// Configuração do QueryClient com configurações otimizadas (sem persistência por enquanto)
const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      // Cache por 5 minutos por padrão
      staleTime: 5 * 60 * 1000,
      // Manter dados em cache por 10 minutos
      gcTime: 10 * 60 * 1000,
      // Retry apenas uma vez em caso de erro
      retry: 1,
      // Refetch automático quando a app volta ao foco
      refetchOnWindowFocus: true,
      // Não refetch automático quando reconecta
      refetchOnReconnect: false,
    },
    mutations: {
      // Retry uma vez para mutations
      retry: 1,
    },
  },
});

interface QueryProviderProps {
  children: React.ReactNode;
}

export function QueryProvider({ children }: QueryProviderProps) {
  return (
    <QueryClientProvider client={queryClient}>
      {children}
    </QueryClientProvider>
  );
}

export { queryClient }; 