# Sprint 2: Streaming e Processamento em Background

## 📋 **Checklist de Implementação**

### **Dia 1-4: Streaming de Respostas**

#### **1. Backend - Streaming API**
```python
# backend/routes/intelligent_triage_routes.py
from fastapi.responses import StreamingResponse
import asyncio
import json

@router.post("/continue-stream")
@limiter.limit("60/minute")
async def continue_conversation_stream(
    request: Request,
    payload: ContinueConversationRequest,
    user: dict = Depends(get_current_user)
):
    """
    Continua conversa com streaming de resposta.
    
    Retorna resposta em chunks para melhor UX.
    """
    
    async def generate_response():
        """Gerador de resposta em chunks."""
        try:
            # Iniciar processamento
            case_id = payload.case_id
            user_message = payload.message
            
            # Enviar status inicial
            yield f"data: {json.dumps({'type': 'status', 'message': 'Processando...'})}\n\n"
            
            # Obter resposta da IA com streaming
            async for chunk in intelligent_triage_orchestrator.continue_intelligent_triage_stream(
                case_id, user_message
            ):
                # Enviar chunk da resposta
                yield f"data: {json.dumps(chunk)}\n\n"
                
                # Pequeno delay para não sobrecarregar
                await asyncio.sleep(0.01)
            
            # Finalizar stream
            yield f"data: {json.dumps({'type': 'end'})}\n\n"
            
        except Exception as e:
            # Enviar erro
            error_data = {
                'type': 'error',
                'message': f'Erro: {str(e)}'
            }
            yield f"data: {json.dumps(error_data)}\n\n"
    
    return StreamingResponse(
        generate_response(),
        media_type="text/plain",
        headers={
            "Cache-Control": "no-cache",
            "Connection": "keep-alive",
        }
    )
```

#### **2. Orquestrador com Streaming**
```python
# backend/services/intelligent_triage_orchestrator.py
from typing import AsyncGenerator, Dict, Any

class IntelligentTriageOrchestrator:
    
    async def continue_intelligent_triage_stream(
        self, 
        case_id: str, 
        user_message: str
    ) -> AsyncGenerator[Dict[str, Any], None]:
        """
        Continua triagem com streaming de resposta.
        """
        if case_id not in await self._get_active_orchestrations():
            raise ValueError(f"Orquestração {case_id} não encontrada")
        
        orchestration = await self.state_manager.get_orchestration_state(case_id)
        
        try:
            # Yield status inicial
            yield {
                "type": "status",
                "message": "Analisando sua mensagem...",
                "timestamp": datetime.now().isoformat()
            }
            
            # Processar com IA Entrevistadora (streaming)
            async for chunk in self.interviewer.continue_conversation_stream(
                case_id, user_message
            ):
                yield chunk
            
            # Verificar se conversa foi finalizada
            conversation_status = await self.interviewer.get_conversation_status(case_id)
            
            if conversation_status and conversation_status.get("status") == "completed":
                # Yield status de processamento final
                yield {
                    "type": "status",
                    "message": "Finalizando análise...",
                    "timestamp": datetime.now().isoformat()
                }
                
                # Processar resultado final
                result = await self._process_completed_conversation(case_id)
                orchestration["status"] = "completed"
                orchestration["result"] = result
                
                await self.state_manager.save_orchestration_state(case_id, orchestration)
                
                # Yield resultado final
                yield {
                    "type": "completed",
                    "result": {
                        "case_id": case_id,
                        "strategy_used": result.strategy_used,
                        "complexity_level": result.complexity_level,
                        "confidence_score": result.confidence_score,
                        "flow_type": result.flow_type
                    },
                    "timestamp": datetime.now().isoformat()
                }
            
        except Exception as e:
            orchestration["status"] = "error"
            orchestration["error"] = str(e)
            await self.state_manager.save_orchestration_state(case_id, orchestration)
            
            yield {
                "type": "error",
                "message": f"Erro no processamento: {str(e)}",
                "timestamp": datetime.now().isoformat()
            }
```

#### **3. IA Entrevistadora com Streaming**
```python
# backend/services/intelligent_interviewer_service.py
import openai
from typing import AsyncGenerator

class IntelligentInterviewerService:
    
    async def continue_conversation_stream(
        self, 
        case_id: str, 
        user_message: str
    ) -> AsyncGenerator[Dict[str, Any], None]:
        """
        Continua conversa com streaming da resposta da IA.
        """
        # Recuperar estado
        state = await self.state_manager.get_conversation_state(case_id)
        if not state:
            raise ValueError(f"Conversa {case_id} não encontrada")
        
        # Adicionar mensagem do usuário
        state["messages"].append({
            "role": "user",
            "content": user_message,
            "timestamp": datetime.now().isoformat()
        })
        
        # Preparar contexto para IA
        messages = self._prepare_messages_for_ai(state)
        
        # Yield status
        yield {
            "type": "thinking",
            "message": "Analisando seu caso...",
            "timestamp": datetime.now().isoformat()
        }
        
        # Chamar OpenAI com streaming
        full_response = ""
        async for chunk in self._call_openai_stream(messages):
            full_response += chunk
            
            yield {
                "type": "response_chunk",
                "content": chunk,
                "timestamp": datetime.now().isoformat()
            }
        
        # Processar resposta completa
        is_complete = await self._analyze_completion(state, full_response)
        
        # Adicionar resposta completa ao estado
        state["messages"].append({
            "role": "assistant",
            "content": full_response,
            "timestamp": datetime.now().isoformat()
        })
        
        # Atualizar análise de complexidade
        await self._update_complexity_analysis(state, user_message, full_response)
        
        # Salvar estado atualizado
        state["updated_at"] = datetime.now().isoformat()
        if is_complete:
            state["status"] = "completed"
            
        await self.state_manager.save_conversation_state(case_id, state)
        
        # Yield status final
        yield {
            "type": "response_complete",
            "is_conversation_complete": is_complete,
            "complexity_hint": state.get("complexity_level"),
            "confidence": state.get("confidence_score"),
            "timestamp": datetime.now().isoformat()
        }
    
    async def _call_openai_stream(self, messages: List[Dict]) -> AsyncGenerator[str, None]:
        """Chama OpenAI com streaming."""
        try:
            stream = await self.openai_client.chat.completions.create(
                model="gpt-4o",
                messages=messages,
                temperature=0.7,
                max_tokens=1000,
                stream=True
            )
            
            async for chunk in stream:
                if chunk.choices[0].delta.content:
                    yield chunk.choices[0].delta.content
                    
        except Exception as e:
            yield f"[Erro na IA: {str(e)}]"
```

#### **4. Frontend - Processamento de Stream**
```typescript
// lib/services/intelligentTriage.ts
export class IntelligentTriageService {
  
  async *continueConversationStream(
    caseId: string, 
    message: string
  ): AsyncGenerator<StreamChunk, void, unknown> {
    const response = await fetch('/api/v2/triage/continue-stream', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${await this.getToken()}`
      },
      body: JSON.stringify({ case_id: caseId, message })
    });

    if (!response.ok) {
      throw new Error(`HTTP ${response.status}`);
    }

    const reader = response.body?.getReader();
    if (!reader) {
      throw new Error('Stream não suportado');
    }

    const decoder = new TextDecoder();
    let buffer = '';

    try {
      while (true) {
        const { done, value } = await reader.read();
        
        if (done) break;

        buffer += decoder.decode(value, { stream: true });
        
        // Processar linhas completas
        const lines = buffer.split('\n');
        buffer = lines.pop() || '';

        for (const line of lines) {
          if (line.startsWith('data: ')) {
            try {
              const data = JSON.parse(line.slice(6));
              yield data as StreamChunk;
            } catch (e) {
              console.warn('Erro ao parsear chunk:', e);
            }
          }
        }
      }
    } finally {
      reader.releaseLock();
    }
  }
}

export interface StreamChunk {
  type: 'status' | 'thinking' | 'response_chunk' | 'response_complete' | 'completed' | 'error';
  message?: string;
  content?: string;
  is_conversation_complete?: boolean;
  complexity_hint?: string;
  confidence?: number;
  result?: any;
  timestamp: string;
}
```

#### **5. UI - Atualização em Tempo Real**
```tsx
// components/IntelligentTriageChat.tsx
import { useState, useCallback } from 'react';
import { IntelligentTriageService } from '@/lib/services/intelligentTriage';

export function IntelligentTriageChat() {
  const [messages, setMessages] = useState<Message[]>([]);
  const [currentResponse, setCurrentResponse] = useState('');
  const [isStreaming, setIsStreaming] = useState(false);
  const [status, setStatus] = useState<string>('');

  const sendMessage = useCallback(async (message: string) => {
    // Adicionar mensagem do usuário
    setMessages(prev => [...prev, { role: 'user', content: message }]);
    
    setIsStreaming(true);
    setCurrentResponse('');
    setStatus('');

    try {
      const triageService = new IntelligentTriageService();
      
      for await (const chunk of triageService.continueConversationStream(caseId, message)) {
        switch (chunk.type) {
          case 'status':
          case 'thinking':
            setStatus(chunk.message || '');
            break;
            
          case 'response_chunk':
            setCurrentResponse(prev => prev + (chunk.content || ''));
            break;
            
          case 'response_complete':
            // Adicionar resposta completa
            setMessages(prev => [...prev, { 
              role: 'assistant', 
              content: currentResponse,
              complexity_hint: chunk.complexity_hint,
              confidence: chunk.confidence
            }]);
            
            setCurrentResponse('');
            setStatus('');
            
            if (chunk.is_conversation_complete) {
              setStatus('Triagem concluída! Processando resultado final...');
            }
            break;
            
          case 'completed':
            setStatus('');
            setIsStreaming(false);
            // Navegar para resultado ou mostrar resultado
            onTriageComplete?.(chunk.result);
            break;
            
          case 'error':
            setStatus(`Erro: ${chunk.message}`);
            setIsStreaming(false);
            break;
        }
      }
    } catch (error) {
      setStatus(`Erro de conexão: ${error.message}`);
      setIsStreaming(false);
    }
  }, [caseId, currentResponse]);

  return (
    <div className="flex flex-col h-full">
      {/* Messages */}
      <div className="flex-1 overflow-y-auto p-4 space-y-4">
        {messages.map((message, index) => (
          <MessageBubble key={index} message={message} />
        ))}
        
        {/* Resposta sendo digitada */}
        {currentResponse && (
          <MessageBubble 
            message={{ role: 'assistant', content: currentResponse }}
            isStreaming={true}
          />
        )}
        
        {/* Status */}
        {status && (
          <div className="text-center text-sm text-gray-500 italic">
            {status}
          </div>
        )}
      </div>
      
      {/* Input */}
      <MessageInput 
        onSend={sendMessage} 
        disabled={isStreaming}
        placeholder={isStreaming ? "Aguarde a resposta..." : "Digite sua mensagem..."}
      />
    </div>
  );
}

function MessageBubble({ message, isStreaming }: { message: Message; isStreaming?: boolean }) {
  return (
    <div className={`flex ${message.role === 'user' ? 'justify-end' : 'justify-start'}`}>
      <div className={`max-w-[80%] rounded-lg p-3 ${
        message.role === 'user' 
          ? 'bg-blue-500 text-white' 
          : 'bg-gray-100 text-gray-900'
      }`}>
        <p className="whitespace-pre-wrap">{message.content}</p>
        
        {/* Indicador de streaming */}
        {isStreaming && (
          <div className="mt-2 flex items-center space-x-1">
            <div className="w-2 h-2 bg-blue-500 rounded-full animate-pulse"></div>
            <div className="w-2 h-2 bg-blue-500 rounded-full animate-pulse delay-100"></div>
            <div className="w-2 h-2 bg-blue-500 rounded-full animate-pulse delay-200"></div>
          </div>
        )}
        
        {/* Metadata */}
        {message.complexity_hint && (
          <div className="mt-2 text-xs opacity-70">
            Complexidade: {message.complexity_hint}
          </div>
        )}
      </div>
    </div>
  );
}
```

### **Dia 5-8: Processamento em Background**

#### **1. Configuração Celery para Triagem**
```python
# backend/celery_config.py
from celery import Celery
import os

celery_app = Celery(
    "litgo5_intelligent_triage",
    broker=os.getenv("CELERY_BROKER_URL", "redis://localhost:6379/1"),
    backend=os.getenv("CELERY_RESULT_BACKEND", "redis://localhost:6379/2"),
    include=[
        "backend.jobs.intelligent_triage_tasks",
        "backend.jobs.automated_reports",
        # ... outras tarefas existentes
    ]
)

# Configuração específica para triagem
celery_app.conf.update(
    # Queues separadas por complexidade
    task_routes={
        'backend.jobs.intelligent_triage_tasks.process_simple_case': {'queue': 'simple_cases'},
        'backend.jobs.intelligent_triage_tasks.process_complex_case': {'queue': 'complex_cases'},
        'backend.jobs.intelligent_triage_tasks.process_ensemble_case': {'queue': 'ensemble_cases'},
    },
    
    # Configurações de retry
    task_default_retry_delay=60,
    task_max_retries=3,
    
    # Configurações de timeout
    task_soft_time_limit=300,  # 5 minutos
    task_time_limit=600,       # 10 minutos
    
    # Configurações de concorrência
    worker_prefetch_multiplier=1,
    task_acks_late=True,
    worker_disable_rate_limits=False,
)
```

#### **2. Tarefas Celery**
```python
# backend/jobs/intelligent_triage_tasks.py
from celery import current_task
from backend.celery_config import celery_app
from backend.services.intelligent_triage_orchestrator import intelligent_triage_orchestrator
from backend.services.conversation_state_manager import conversation_state_manager
import logging

logger = logging.getLogger(__name__)

@celery_app.task(bind=True, name="process_completed_conversation")
def process_completed_conversation_task(self, case_id: str):
    """
    Processa conversa finalizada em background.
    
    Esta tarefa é executada quando uma conversa é marcada como completa
    mas requer processamento adicional (failover ou ensemble).
    """
    try:
        # Atualizar status
        self.update_state(
            state='PROGRESS',
            meta={'status': 'Iniciando processamento...', 'progress': 0}
        )
        
        # Executar processamento
        import asyncio
        result = asyncio.run(
            intelligent_triage_orchestrator._process_completed_conversation_async(case_id)
        )
        
        # Atualizar progresso
        self.update_state(
            state='PROGRESS',
            meta={'status': 'Processamento concluído', 'progress': 100}
        )
        
        return {
            'case_id': case_id,
            'strategy_used': result.strategy_used,
            'complexity_level': result.complexity_level,
            'confidence_score': result.confidence_score,
            'processing_time_ms': result.processing_time_ms,
            'status': 'completed'
        }
        
    except Exception as e:
        logger.error(f"Erro ao processar caso {case_id}: {e}")
        
        self.update_state(
            state='FAILURE',
            meta={'error': str(e), 'case_id': case_id}
        )
        
        raise

@celery_app.task(bind=True, name="process_simple_case")
def process_simple_case_task(self, case_id: str, interviewer_result: dict):
    """Processa caso simples em background."""
    try:
        self.update_state(
            state='PROGRESS',
            meta={'status': 'Processando caso simples...', 'progress': 50}
        )
        
        import asyncio
        result = asyncio.run(
            intelligent_triage_orchestrator._process_simple_flow_async(
                case_id, interviewer_result
            )
        )
        
        return {
            'case_id': case_id,
            'result': result,
            'status': 'completed'
        }
        
    except Exception as e:
        logger.error(f"Erro ao processar caso simples {case_id}: {e}")
        raise

@celery_app.task(bind=True, name="process_complex_case")
def process_complex_case_task(self, case_id: str, interviewer_result: dict):
    """Processa caso complexo em background."""
    try:
        self.update_state(
            state='PROGRESS',
            meta={'status': 'Executando análise ensemble...', 'progress': 25}
        )
        
        import asyncio
        result = asyncio.run(
            intelligent_triage_orchestrator._process_ensemble_flow_async(
                case_id, interviewer_result
            )
        )
        
        self.update_state(
            state='PROGRESS',
            meta={'status': 'Análise concluída', 'progress': 100}
        )
        
        return {
            'case_id': case_id,
            'result': result,
            'status': 'completed'
        }
        
    except Exception as e:
        logger.error(f"Erro ao processar caso complexo {case_id}: {e}")
        raise

@celery_app.task(name="cleanup_expired_conversations")
def cleanup_expired_conversations_task():
    """Limpa conversas expiradas periodicamente."""
    try:
        import asyncio
        result = asyncio.run(
            conversation_state_manager.cleanup_expired_conversations()
        )
        
        logger.info(f"Limpeza concluída: {result}")
        return result
        
    except Exception as e:
        logger.error(f"Erro na limpeza: {e}")
        raise
```

#### **3. Modificação dos Endpoints**
```python
# backend/routes/intelligent_triage_routes.py
from backend.jobs.intelligent_triage_tasks import process_completed_conversation_task

@router.post("/continue", response_model=ContinueConversationResponse)
@limiter.limit("60/minute")
async def continue_conversation(
    request: Request,
    payload: ContinueConversationRequest,
    user: dict = Depends(get_current_user)
):
    """
    Continua conversa com processamento inteligente.
    
    Para casos simples: resposta imediata
    Para casos complexos: processamento em background
    """
    try:
        # Continuar conversa normalmente
        result = await intelligent_triage_orchestrator.continue_intelligent_triage(
            payload.case_id, payload.message
        )
        
        if result["status"] == "completed":
            # Verificar se precisa de processamento adicional
            interviewer_result = await intelligent_triage_orchestrator.interviewer.get_triage_result(
                payload.case_id
            )
            
            if interviewer_result.strategy_used in ["failover", "ensemble"]:
                # Iniciar processamento em background
                task = process_completed_conversation_task.delay(payload.case_id)
                
                # Atualizar estado com task_id
                orchestration = await intelligent_triage_orchestrator.state_manager.get_orchestration_state(
                    payload.case_id
                )
                orchestration["background_task_id"] = task.id
                orchestration["status"] = "processing_background"
                
                await intelligent_triage_orchestrator.state_manager.save_orchestration_state(
                    payload.case_id, orchestration
                )
                
                return ContinueConversationResponse(
                    case_id=payload.case_id,
                    message=result["message"],
                    status="processing_background",
                    result={
                        "message": "Sua triagem foi finalizada! Estamos processando uma análise detalhada.",
                        "task_id": task.id,
                        "estimated_time": "30-60 segundos"
                    }
                )
        
        return ContinueConversationResponse(**result)
        
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Erro ao continuar conversa: {str(e)}"
        )

@router.get("/task-status/{task_id}")
@limiter.limit("120/minute")
async def get_task_status(
    request: Request,
    task_id: str,
    user: dict = Depends(get_current_user)
):
    """
    Obtém status de uma tarefa em background.
    """
    try:
        from backend.celery_config import celery_app
        
        task = celery_app.AsyncResult(task_id)
        
        if task.state == 'PENDING':
            return {
                "task_id": task_id,
                "status": "pending",
                "message": "Tarefa aguardando processamento..."
            }
        elif task.state == 'PROGRESS':
            return {
                "task_id": task_id,
                "status": "processing",
                "progress": task.info.get('progress', 0),
                "message": task.info.get('status', 'Processando...')
            }
        elif task.state == 'SUCCESS':
            return {
                "task_id": task_id,
                "status": "completed",
                "result": task.result
            }
        elif task.state == 'FAILURE':
            return {
                "task_id": task_id,
                "status": "failed",
                "error": str(task.info)
            }
        
        return {
            "task_id": task_id,
            "status": task.state.lower(),
            "message": f"Status: {task.state}"
        }
        
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Erro ao obter status da tarefa: {str(e)}"
        )
```

#### **4. Frontend - Polling Inteligente**
```typescript
// lib/services/backgroundTasks.ts
export class BackgroundTaskService {
  private pollingIntervals: Map<string, NodeJS.Timeout> = new Map();
  
  async pollTaskStatus(
    taskId: string,
    onUpdate: (status: TaskStatus) => void,
    onComplete: (result: any) => void,
    onError: (error: string) => void
  ): Promise<void> {
    // Limpar polling anterior se existir
    this.stopPolling(taskId);
    
    let attempts = 0;
    const maxAttempts = 120; // 2 minutos máximo
    
    const poll = async () => {
      try {
        const response = await fetch(`/api/v2/triage/task-status/${taskId}`, {
          headers: {
            'Authorization': `Bearer ${await this.getToken()}`
          }
        });
        
        if (!response.ok) {
          throw new Error(`HTTP ${response.status}`);
        }
        
        const status = await response.json();
        onUpdate(status);
        
        if (status.status === 'completed') {
          onComplete(status.result);
          this.stopPolling(taskId);
          return;
        }
        
        if (status.status === 'failed') {
          onError(status.error || 'Erro desconhecido');
          this.stopPolling(taskId);
          return;
        }
        
        // Continuar polling
        attempts++;
        if (attempts < maxAttempts) {
          // Polling adaptativo: mais rápido no início, mais lento depois
          const delay = attempts < 10 ? 1000 : attempts < 30 ? 2000 : 5000;
          
          const timeoutId = setTimeout(poll, delay);
          this.pollingIntervals.set(taskId, timeoutId);
        } else {
          onError('Timeout: processamento demorou mais que o esperado');
          this.stopPolling(taskId);
        }
        
      } catch (error) {
        onError(`Erro de conexão: ${error.message}`);
        this.stopPolling(taskId);
      }
    };
    
    // Iniciar polling
    poll();
  }
  
  stopPolling(taskId: string): void {
    const timeoutId = this.pollingIntervals.get(taskId);
    if (timeoutId) {
      clearTimeout(timeoutId);
      this.pollingIntervals.delete(taskId);
    }
  }
  
  stopAllPolling(): void {
    this.pollingIntervals.forEach((timeoutId) => clearTimeout(timeoutId));
    this.pollingIntervals.clear();
  }
}

export interface TaskStatus {
  task_id: string;
  status: 'pending' | 'processing' | 'completed' | 'failed';
  progress?: number;
  message?: string;
  result?: any;
  error?: string;
}
```

#### **5. UI - Processamento em Background**
```tsx
// components/BackgroundProcessingIndicator.tsx
import { useState, useEffect } from 'react';
import { BackgroundTaskService } from '@/lib/services/backgroundTasks';

export function BackgroundProcessingIndicator({ 
  taskId, 
  onComplete, 
  onError 
}: {
  taskId: string;
  onComplete: (result: any) => void;
  onError: (error: string) => void;
}) {
  const [status, setStatus] = useState<TaskStatus>({
    task_id: taskId,
    status: 'pending',
    message: 'Iniciando processamento...'
  });
  
  useEffect(() => {
    const taskService = new BackgroundTaskService();
    
    taskService.pollTaskStatus(
      taskId,
      (newStatus) => setStatus(newStatus),
      (result) => onComplete(result),
      (error) => onError(error)
    );
    
    return () => taskService.stopPolling(taskId);
  }, [taskId]);
  
  return (
    <div className="bg-blue-50 border border-blue-200 rounded-lg p-4">
      <div className="flex items-center space-x-3">
        {/* Spinner */}
        <div className="animate-spin rounded-full h-6 w-6 border-b-2 border-blue-600"></div>
        
        <div className="flex-1">
          <h3 className="font-medium text-blue-900">
            Processando Análise Detalhada
          </h3>
          <p className="text-sm text-blue-700">
            {status.message || 'Aguarde enquanto analisamos seu caso...'}
          </p>
          
          {/* Barra de progresso */}
          {status.progress !== undefined && (
            <div className="mt-2 bg-blue-200 rounded-full h-2">
              <div 
                className="bg-blue-600 h-2 rounded-full transition-all duration-300"
                style={{ width: `${status.progress}%` }}
              />
            </div>
          )}
        </div>
        
        <div className="text-sm text-blue-600 font-medium">
          {status.progress ? `${status.progress}%` : ''}
        </div>
      </div>
      
      <div className="mt-3 text-xs text-blue-600">
        💡 Você pode fechar esta tela. Notificaremos quando estiver pronto!
      </div>
    </div>
  );
}
```

### **Dia 9-10: Testes e Otimização**

#### **1. Testes de Streaming**
```python
# tests/test_streaming.py
import pytest
import asyncio
from backend.services.intelligent_triage_orchestrator import intelligent_triage_orchestrator

@pytest.mark.asyncio
async def test_streaming_response():
    """Testa streaming de resposta."""
    # Iniciar conversa
    result = await intelligent_triage_orchestrator.start_intelligent_triage("test_user")
    case_id = result["case_id"]
    
    # Testar streaming
    chunks = []
    async for chunk in intelligent_triage_orchestrator.continue_intelligent_triage_stream(
        case_id, "Mensagem de teste"
    ):
        chunks.append(chunk)
    
    # Verificar se recebeu chunks
    assert len(chunks) > 0
    
    # Verificar tipos de chunks
    chunk_types = [chunk["type"] for chunk in chunks]
    assert "status" in chunk_types or "thinking" in chunk_types
    assert "response_chunk" in chunk_types
    assert "response_complete" in chunk_types
    
    # Cleanup
    await conversation_state_manager.delete_conversation_state(case_id)

@pytest.mark.asyncio
async def test_background_processing():
    """Testa processamento em background."""
    from backend.jobs.intelligent_triage_tasks import process_completed_conversation_task
    
    # Criar caso que requer processamento complexo
    result = await intelligent_triage_orchestrator.start_intelligent_triage("test_user")
    case_id = result["case_id"]
    
    # Simular conversa complexa
    await intelligent_triage_orchestrator.continue_intelligent_triage(
        case_id, "Caso trabalhista complexo com múltiplas questões..."
    )
    
    # Executar tarefa em background
    task_result = process_completed_conversation_task.delay(case_id)
    
    # Aguardar resultado
    result = task_result.get(timeout=60)
    
    # Verificar resultado
    assert result["status"] == "completed"
    assert "strategy_used" in result
    
    # Cleanup
    await conversation_state_manager.delete_conversation_state(case_id)
```

## 🎯 **Critérios de Sucesso Sprint 2**

- [ ] ✅ Streaming funciona em 95% dos casos
- [ ] ✅ Tempo de primeira resposta < 500ms
- [ ] ✅ Análises complexas processam em background
- [ ] ✅ UI atualiza em tempo real
- [ ] ✅ Polling inteligente funciona
- [ ] ✅ Fallback para modo síncrono
- [ ] ✅ Celery configurado e funcionando
- [ ] ✅ Testes passando

**Resultado esperado**: Experiência do usuário dramaticamente melhorada com respostas instantâneas e processamento otimizado. 