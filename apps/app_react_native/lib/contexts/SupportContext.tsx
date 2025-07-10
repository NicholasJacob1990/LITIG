import React, { createContext, useState, useEffect, useContext, ReactNode, useCallback } from 'react';
import { SupportTicket, getSupportTickets } from '@/lib/services/support';
import { useAuth } from './AuthContext';

interface SupportContextType {
  tickets: SupportTicket[];
  isLoading: boolean;
  error: Error | null;
  refetchTickets: () => void;
}

const SupportContext = createContext<SupportContextType | undefined>(undefined);

export const SupportProvider = ({ children }: { children: ReactNode }) => {
  const { user } = useAuth();
  const [tickets, setTickets] = useState<SupportTicket[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<Error | null>(null);

  const refetchTickets = useCallback(async () => {
    if (!user?.id) {
      setTickets([]);
      setIsLoading(false);
      return;
    }

    setIsLoading(true);
    setError(null);

    try {
      const data = await getSupportTickets(user.id);
      setTickets(data || []);
    } catch (e) {
      console.error('Error fetching tickets:', e);
      setError(e as Error);
      setTickets([]);
    } finally {
      setIsLoading(false);
    }
  }, [user?.id]);

  useEffect(() => {
    if (user?.id) {
        refetchTickets();
    } else {
        setTickets([]);
        setIsLoading(false);
    }
  }, [user?.id, refetchTickets]);

  return (
    <SupportContext.Provider value={{ tickets, isLoading, error, refetchTickets }}>
      {children}
    </SupportContext.Provider>
  );
};

export const useSupport = () => {
  const context = useContext(SupportContext);
  if (context === undefined) {
    throw new Error('useSupport must be used within a SupportProvider');
  }
  return context;
}; 