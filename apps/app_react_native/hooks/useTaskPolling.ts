import { useState, useEffect, useRef } from 'react';
import { getAuthHeaders } from '@/lib/services/api'; // Supondo que a função getAuthHeaders seja exportada

const API_URL = process.env.EXPO_PUBLIC_API_URL || 'http://127.0.0.1:8080/api';

type TaskStatus = 'pending' | 'completed' | 'failed' | 'accepted';

interface TaskResult {
  status: TaskStatus;
  result?: any;
  error?: string;
}

export function useTaskPolling(taskId: string | null) {
  const [taskResult, setTaskResult] = useState<TaskResult | null>(null);
  const [isLoading, setIsLoading] = useState<boolean>(false);
  const [error, setError] = useState<string | null>(null);
  
  const pollingRef = useRef<number | null>(null);

  useEffect(() => {
    if (!taskId) {
      return;
    }

    const pollStatus = async () => {
      setIsLoading(true);
      setError(null);
      
      try {
        const headers = await getAuthHeaders();
        const response = await fetch(`${API_URL}/triage/status/${taskId}`, { headers });

        if (!response.ok) {
          throw new Error('Falha ao buscar status da tarefa.');
        }

        const data: TaskResult = await response.json();

        if (data.status === 'completed' || data.status === 'failed') {
          setTaskResult(data);
          setIsLoading(false);
          if (pollingRef.current) {
            clearInterval(pollingRef.current);
          }
        }
      } catch (err: any) {
        setError(err.message);
        setIsLoading(false);
        if (pollingRef.current) {
          clearInterval(pollingRef.current);
        }
      }
    };

    // Inicia o polling imediatamente e depois a cada 3 segundos
    pollStatus();
    pollingRef.current = setInterval(pollStatus, 3000);

    // Limpa o intervalo quando o componente é desmontado ou o taskId muda
    return () => {
      if (pollingRef.current) {
        clearInterval(pollingRef.current);
      }
    };
  }, [taskId]);

  return { taskResult, isLoading, error };
} 