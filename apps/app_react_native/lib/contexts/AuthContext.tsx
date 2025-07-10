import React, { createContext, useState, useEffect, useContext, useMemo } from 'react';
import { Session, User } from '@supabase/supabase-js';
import supabase from '../supabase';

type UserRole = 'client' | 'lawyer' | null;

interface AuthContextType {
  user: User | null;
  session: Session | null;
  role: UserRole;
  isLoading: boolean;
  signOut: () => Promise<void>;
}

const AuthContext = createContext<AuthContextType>({
  user: null,
  session: null,
  role: null,
  isLoading: true,
  signOut: async () => {},
});

// Função simples para comparar objetos sem lodash
const isEqual = (obj1: any, obj2: any): boolean => {
  if (obj1 === obj2) return true;
  if (obj1 === null || obj2 === null) return false;
  if (obj1 === undefined || obj2 === undefined) return false;
  return JSON.stringify(obj1) === JSON.stringify(obj2);
};

export const AuthProvider = ({ children }: { children: React.ReactNode }) => {
  const [user, setUser] = useState<User | null>(null);
  const [session, setSession] = useState<Session | null>(null);
  const [role, setRole] = useState<UserRole>(null);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    const getInitialSession = async () => {
      try {
        console.log('AuthProvider: Iniciando verificação de sessão...');
        const { data: { session: initialSession }, error } = await supabase.auth.getSession();
        
        if (error) {
          console.error('AuthProvider: Erro ao obter sessão:', error);
        } else {
          console.log('AuthProvider: Sessão obtida:', initialSession ? 'Usuário logado' : 'Nenhum usuário');
        }
        
        setSession(initialSession);
        setUser(initialSession?.user ?? null);
        setRole(initialSession?.user?.user_metadata?.role || null);
        console.log('AuthProvider: Estado inicial definido, isLoading = false');
        setIsLoading(false);
      } catch (error) {
        console.error('AuthProvider: Erro na verificação de sessão:', error);
        // Mesmo com erro, definir isLoading como false para não travar o app
        setIsLoading(false);
      }
    };

    // Timeout de segurança para garantir que o loading seja resolvido
    const timeoutId = setTimeout(() => {
      console.log('AuthProvider: Timeout atingido, forçando isLoading = false');
      setIsLoading(false);
    }, 5000); // 5 segundos

    getInitialSession().finally(() => {
      clearTimeout(timeoutId);
    });

    const { data: authListener } = supabase.auth.onAuthStateChange((_event, newSession) => {
      console.log('AuthProvider: Mudança de estado de auth:', _event);
      setSession(prevSession => {
        if (!isEqual(prevSession, newSession)) {
          return newSession;
        }
        return prevSession;
      });
      setUser(prevUser => {
        if (!isEqual(prevUser, newSession?.user ?? null)) {
          return newSession?.user ?? null;
        }
        return prevUser;
      });
      setRole(newSession?.user?.user_metadata?.role || null);
    });

    return () => {
      clearTimeout(timeoutId);
      authListener.subscription.unsubscribe();
    };
  }, []);

  const signOut = async () => {
    await supabase.auth.signOut();
  };

  const value = useMemo(() => ({
    user,
    session,
    role,
    isLoading,
    signOut,
  }), [user, session, role, isLoading]);

  console.log('AuthProvider: Renderizando com isLoading =', isLoading);

  return (
    <AuthContext.Provider value={value}>
      {children}
    </AuthContext.Provider>
  );
};

export const useAuth = () => {
  const context = useContext(AuthContext);
  if (context === undefined) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
}; 