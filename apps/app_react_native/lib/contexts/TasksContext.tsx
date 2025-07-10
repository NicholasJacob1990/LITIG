import React, { createContext, useState, useEffect, useContext, ReactNode, useCallback } from 'react';
import { Task, getTasks } from '@/lib/services/tasks';
import { useAuth } from './AuthContext';

interface TasksContextType {
  tasks: Task[];
  isLoading: boolean;
  error: Error | null;
  refetchTasks: () => void;
}

const TasksContext = createContext<TasksContextType | undefined>(undefined);

export const TasksProvider = ({ children }: { children: ReactNode }) => {
  const { user } = useAuth();
  const [tasks, setTasks] = useState<Task[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<Error | null>(null);

  const refetchTasks = useCallback(async () => {
    if (!user?.id) {
      setTasks([]);
      setIsLoading(false);
      return;
    }

    setIsLoading(true);
    setError(null);

    try {
      const data = await getTasks(user.id);
      setTasks(data || []);
    } catch (e) {
      console.error('Error fetching tasks:', e);
      setError(e as Error);
      setTasks([]);
    } finally {
      setIsLoading(false);
    }
  }, [user?.id]);

  useEffect(() => {
    if (user?.id) {
        refetchTasks();
    } else {
        setTasks([]);
        setIsLoading(false);
    }
  }, [user?.id, refetchTasks]);

  return (
    <TasksContext.Provider value={{ tasks, isLoading, error, refetchTasks }}>
      {children}
    </TasksContext.Provider>
  );
};

export const useTasks = () => {
  const context = useContext(TasksContext);
  if (context === undefined) {
    throw new Error('useTasks must be used within a TasksProvider');
  }
  return context;
}; 