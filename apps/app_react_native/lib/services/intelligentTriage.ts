import { API_URL, getAuthHeaders } from './api';

// ============================================================================
// Tipos e Interfaces
// ============================================================================

export interface StartIntelligentTriageRequest {
  user_id?: string;
}

export interface StartIntelligentTriageResponse {
  case_id: string;
  message: string;
  status: string;
  timestamp: string;
}

export interface ContinueConversationRequest {
  case_id: string;
  message: string;
}

export interface ContinueConversationResponse {
  case_id: string;
  message: string;
  status: 'active' | 'completed';
  complexity_hint?: string;
  confidence?: number;
  result?: any;
  timestamp: string;
}

export interface OrchestrationStatusResponse {
  case_id: string;
  status: 'interviewing' | 'completed' | 'error';
  flow_type: string;
  started_at: number;
  conversation_status?: any;
  current_complexity?: string;
  current_confidence?: number;
  error?: string;
}

export interface TriageResultResponse {
  case_id: string;
  strategy_used: 'simple' | 'failover' | 'ensemble';
  complexity_level: 'low' | 'medium' | 'high';
  confidence_score: number;
  triage_data: any;
  conversation_summary: string;
  processing_time_ms: number;
  flow_type: string;
  analysis_details?: any;
  timestamp: string;
}

export interface ForceCompleteRequest {
  case_id: string;
  reason?: string;
}

export interface SystemStats {
  timestamp: string;
  totals: {
    active_orchestrations: number;
    active_conversations: number;
  };
  by_status: Record<string, number>;
  by_complexity: Record<string, number>;
  system_info: {
    service_version: string;
    architecture: string;
  };
}

// ============================================================================
// Serviço Principal
// ============================================================================

class IntelligentTriageService {
  private baseUrl = `${API_URL}/api/v2/triage`;

  /**
   * Inicia uma nova triagem inteligente conversacional.
   */
  async startIntelligentTriage(request: StartIntelligentTriageRequest = {}): Promise<StartIntelligentTriageResponse> {
    try {
      const headers = await getAuthHeaders();
      const response = await fetch(`${this.baseUrl}/start`, {
        method: 'POST',
        headers,
        body: JSON.stringify(request),
      });

      if (!response.ok) {
        const errorData = await response.json();
        throw new Error(errorData.detail || 'Falha ao iniciar triagem inteligente');
      }

      return await response.json();
    } catch (error) {
      console.error('Erro ao iniciar triagem inteligente:', error);
      throw error;
    }
  }

  /**
   * Continua uma conversa de triagem inteligente.
   */
  async continueConversation(request: ContinueConversationRequest): Promise<ContinueConversationResponse> {
    try {
      const headers = await getAuthHeaders();
      const response = await fetch(`${this.baseUrl}/continue`, {
        method: 'POST',
        headers,
        body: JSON.stringify(request),
      });

      if (!response.ok) {
        const errorData = await response.json();
        throw new Error(errorData.detail || 'Falha ao continuar conversa');
      }

      return await response.json();
    } catch (error) {
      console.error('Erro ao continuar conversa:', error);
      throw error;
    }
  }

  /**
   * Obtém o status atual de uma orquestração.
   */
  async getOrchestrationStatus(caseId: string): Promise<OrchestrationStatusResponse> {
    try {
      const headers = await getAuthHeaders();
      const response = await fetch(`${this.baseUrl}/status/${caseId}`, {
        method: 'GET',
        headers,
      });

      if (!response.ok) {
        const errorData = await response.json();
        throw new Error(errorData.detail || 'Falha ao obter status');
      }

      return await response.json();
    } catch (error) {
      console.error('Erro ao obter status:', error);
      throw error;
    }
  }

  /**
   * Obtém o resultado final de uma triagem completa.
   */
  async getTriageResult(caseId: string): Promise<TriageResultResponse> {
    try {
      const headers = await getAuthHeaders();
      const response = await fetch(`${this.baseUrl}/result/${caseId}`, {
        method: 'GET',
        headers,
      });

      if (!response.ok) {
        const errorData = await response.json();
        throw new Error(errorData.detail || 'Resultado não encontrado');
      }

      return await response.json();
    } catch (error) {
      console.error('Erro ao obter resultado:', error);
      throw error;
    }
  }

  /**
   * Força a finalização de uma conversa em andamento.
   */
  async forceCompleteConversation(request: ForceCompleteRequest): Promise<TriageResultResponse> {
    try {
      const headers = await getAuthHeaders();
      const response = await fetch(`${this.baseUrl}/force-complete`, {
        method: 'POST',
        headers,
        body: JSON.stringify(request),
      });

      if (!response.ok) {
        const errorData = await response.json();
        throw new Error(errorData.detail || 'Falha ao forçar finalização');
      }

      return await response.json();
    } catch (error) {
      console.error('Erro ao forçar finalização:', error);
      throw error;
    }
  }

  /**
   * Remove uma orquestração da memória.
   */
  async cleanupOrchestration(caseId: string): Promise<void> {
    try {
      const headers = await getAuthHeaders();
      const response = await fetch(`${this.baseUrl}/cleanup/${caseId}`, {
        method: 'DELETE',
        headers,
      });

      if (!response.ok) {
        const errorData = await response.json();
        throw new Error(errorData.detail || 'Falha ao limpar orquestração');
      }
    } catch (error) {
      console.error('Erro ao limpar orquestração:', error);
      throw error;
    }
  }

  /**
   * Verifica a saúde do sistema.
   */
  async healthCheck(): Promise<any> {
    try {
      const response = await fetch(`${this.baseUrl}/health`, {
        method: 'GET',
      });

      if (!response.ok) {
        throw new Error('Sistema não está saudável');
      }

      return await response.json();
    } catch (error) {
      console.error('Erro no health check:', error);
      throw error;
    }
  }

  /**
   * Obtém estatísticas do sistema.
   */
  async getSystemStats(): Promise<SystemStats> {
    try {
      const headers = await getAuthHeaders();
      const response = await fetch(`${this.baseUrl}/stats`, {
        method: 'GET',
        headers,
      });

      if (!response.ok) {
        const errorData = await response.json();
        throw new Error(errorData.detail || 'Falha ao obter estatísticas');
      }

      return await response.json();
    } catch (error) {
      console.error('Erro ao obter estatísticas:', error);
      throw error;
    }
  }

  // ============================================================================
  // Métodos de Conveniência
  // ============================================================================

  /**
   * Inicia uma conversa completa e retorna um objeto para gerenciar o fluxo.
   */
  async createConversationManager(userId?: string): Promise<ConversationManager> {
    const startResponse = await this.startIntelligentTriage({ user_id: userId });
    return new ConversationManager(startResponse.case_id, this);
  }

  /**
   * Aguarda a finalização de uma conversa com polling.
   */
  async waitForCompletion(
    caseId: string, 
    options: {
      maxWaitTime?: number;
      pollInterval?: number;
      onStatusUpdate?: (status: OrchestrationStatusResponse) => void;
    } = {}
  ): Promise<TriageResultResponse> {
    const {
      maxWaitTime = 300000, // 5 minutos
      pollInterval = 2000,   // 2 segundos
      onStatusUpdate
    } = options;

    const startTime = Date.now();
    
    while (Date.now() - startTime < maxWaitTime) {
      try {
        const status = await this.getOrchestrationStatus(caseId);
        
        if (onStatusUpdate) {
          onStatusUpdate(status);
        }

        if (status.status === 'completed') {
          return await this.getTriageResult(caseId);
        }

        if (status.status === 'error') {
          throw new Error(`Erro na orquestração: ${status.error}`);
        }

        // Aguardar próximo poll
        await new Promise(resolve => setTimeout(resolve, pollInterval));
      } catch (error) {
        console.error('Erro durante polling:', error);
        throw error;
      }
    }

    throw new Error('Timeout aguardando finalização da conversa');
  }
}

// ============================================================================
// Gerenciador de Conversa
// ============================================================================

export class ConversationManager {
  private caseId: string;
  private service: IntelligentTriageService;
  private isCompleted: boolean = false;
  private result: TriageResultResponse | null = null;

  constructor(caseId: string, service: IntelligentTriageService) {
    this.caseId = caseId;
    this.service = service;
  }

  /**
   * Envia uma mensagem e obtém resposta.
   */
  async sendMessage(message: string): Promise<ContinueConversationResponse> {
    if (this.isCompleted) {
      throw new Error('Conversa já foi finalizada');
    }

    const response = await this.service.continueConversation({
      case_id: this.caseId,
      message
    });

    if (response.status === 'completed') {
      this.isCompleted = true;
      this.result = response.result;
    }

    return response;
  }

  /**
   * Obtém o status atual da conversa.
   */
  async getStatus(): Promise<OrchestrationStatusResponse> {
    return await this.service.getOrchestrationStatus(this.caseId);
  }

  /**
   * Força a finalização da conversa.
   */
  async forceComplete(reason: string = 'user_request'): Promise<TriageResultResponse> {
    const result = await this.service.forceCompleteConversation({
      case_id: this.caseId,
      reason
    });

    this.isCompleted = true;
    this.result = result;
    
    return result;
  }

  /**
   * Obtém o resultado final (se disponível).
   */
  async getResult(): Promise<TriageResultResponse | null> {
    if (this.result) {
      return this.result;
    }

    if (this.isCompleted) {
      try {
        this.result = await this.service.getTriageResult(this.caseId);
        return this.result;
      } catch (error) {
        console.error('Erro ao obter resultado:', error);
        return null;
      }
    }

    return null;
  }

  /**
   * Limpa a conversa da memória.
   */
  async cleanup(): Promise<void> {
    await this.service.cleanupOrchestration(this.caseId);
  }

  // Getters
  get id(): string {
    return this.caseId;
  }

  get completed(): boolean {
    return this.isCompleted;
  }
}

// ============================================================================
// Instância Singleton
// ============================================================================

export const intelligentTriageService = new IntelligentTriageService();

// ============================================================================
// Hooks de Conveniência (para React)
// ============================================================================

export interface UseIntelligentTriageOptions {
  onComplete?: (result: TriageResultResponse) => void;
  onError?: (error: Error) => void;
  onStatusUpdate?: (status: OrchestrationStatusResponse) => void;
}

/**
 * Hook para usar triagem inteligente em componentes React.
 */
export function useIntelligentTriage(options: UseIntelligentTriageOptions = {}) {
  const [manager, setManager] = useState<ConversationManager | null>(null);
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<Error | null>(null);
  const [messages, setMessages] = useState<Array<{role: 'user' | 'assistant', content: string}>>([]);

  const startConversation = async (userId?: string) => {
    try {
      setIsLoading(true);
      setError(null);
      
      const newManager = await intelligentTriageService.createConversationManager(userId);
      setManager(newManager);
      
      // Primeira mensagem da IA já vem no start
      const status = await newManager.getStatus();
      if (status.conversation_status?.messages) {
        setMessages(status.conversation_status.messages);
      }
      
    } catch (err) {
      const error = err instanceof Error ? err : new Error('Erro desconhecido');
      setError(error);
      options.onError?.(error);
    } finally {
      setIsLoading(false);
    }
  };

  const sendMessage = async (message: string) => {
    if (!manager) return;

    try {
      setIsLoading(true);
      setError(null);
      
      // Adicionar mensagem do usuário
      setMessages(prev => [...prev, { role: 'user', content: message }]);
      
      const response = await manager.sendMessage(message);
      
      // Adicionar resposta da IA
      setMessages(prev => [...prev, { role: 'assistant', content: response.message }]);
      
      if (response.status === 'completed' && response.result) {
        options.onComplete?.(response.result);
      }
      
    } catch (err) {
      const error = err instanceof Error ? err : new Error('Erro desconhecido');
      setError(error);
      options.onError?.(error);
    } finally {
      setIsLoading(false);
    }
  };

  const forceComplete = async (reason?: string) => {
    if (!manager) return null;

    try {
      setIsLoading(true);
      const result = await manager.forceComplete(reason);
      options.onComplete?.(result);
      return result;
    } catch (err) {
      const error = err instanceof Error ? err : new Error('Erro desconhecido');
      setError(error);
      options.onError?.(error);
      return null;
    } finally {
      setIsLoading(false);
    }
  };

  const cleanup = async () => {
    if (manager) {
      await manager.cleanup();
      setManager(null);
      setMessages([]);
    }
  };

  return {
    manager,
    isLoading,
    error,
    messages,
    startConversation,
    sendMessage,
    forceComplete,
    cleanup,
    isActive: manager && !manager.completed
  };
}

// Importar useState se estiver em um ambiente React
let useState: any;
try {
  useState = require('react').useState;
} catch (e) {
  // Não está em ambiente React, ignorar
} 