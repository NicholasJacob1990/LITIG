# LangGraph Implementation Guide - Sistema LITIG-1

## 1. Visão Geral: Por que LangGraph?

### Problema Atual: Orquestração Manual Complexa

O sistema atual do `IntelligentTriageOrchestrator` contém lógica complexa hardcoded:

```python
# Atual: intelligent_triage_orchestrator.py (Linhas 100-200)
async def start_intelligent_triage(self, user_id: str):
    case_id, first_message = await self.interviewer.start_conversation(user_id)
    
    # Lógica complexa de if/else para determinar próximo passo
    if complexity == "simple":
        result = await self._direct_simple_triage(case_data)
    elif complexity == "medium":
        result = await self._standard_analysis(case_data)
    elif complexity == "complex":
        result = await self._ensemble_analysis(case_data)
        # Chamar LEX-9000 se necessário
        if result.requires_detailed_analysis:
            detailed = await self.lex9000.analyze_complex_case(case_data)
            result.merge(detailed)
    
    # Determinar matches
    matches = await self.match_service.find_matches(result)
    
    # Decisões sobre enhancement LLM
    if len(matches) > 5 and complexity in ["medium", "complex"]:
        enhanced = await self.llm_enhancer.enhance_matches(matches, case_data)
        matches = enhanced
    
    # Notificar usuário
    await self.notify_service.send_results(user_id, result, matches)
```

### Problemas Identificados

1. **Difícil Manutenção**: Adicionar novo passo requer modificar lógica central
2. **Difícil Debug**: Impossível visualizar ou pausar fluxo
3. **Estado Fragmentado**: Estado espalhado entre múltiplos serviços
4. **Falta de Flexibilidade**: Fluxo linear rígido

### Solução: LangGraph

LangGraph transforma essa lógica imperativa em um **grafo declarativo**, onde:
- Cada **nó** representa uma operação específica
- Cada **edge** representa uma transição de estado
- O **estado** é centralizado e versionado
- O **fluxo** é visualizável e debugável

## 2. Conceitos Fundamentais do LangGraph

### 2.1. State (Estado)

```python
from typing import TypedDict, Annotated, List, Optional
import operator

class TriageState(TypedDict):
    # Identificadores
    user_id: str
    case_id: Optional[str]
    
    # Dados de entrada
    conversation_data: Annotated[dict, operator.add]  # Merge automático
    user_preferences: dict
    
    # Análises intermediárias
    complexity_level: str
    basic_triage_result: dict
    lex_analysis: Optional[dict]
    
    # Matching e enhancement
    initial_matches: List[dict]
    enhanced_matches: List[dict]
    match_explanations: List[str]
    
    # Estado de execução
    current_step: str
    error_context: Optional[str]
    notifications_sent: bool
    
    # Métricas
    processing_start_time: float
    step_durations: Annotated[List[dict], operator.add]
```

### 2.2. Nodes (Nós)

Cada nó é uma função que recebe o estado atual e retorna um estado atualizado:

```python
async def start_conversation_node(state: TriageState) -> TriageState:
    """Nó que inicia a conversa inteligente."""
    try:
        case_id, first_message = await interviewer_service.start_conversation(
            state["user_id"]
        )
        
        return {
            **state,
            "case_id": case_id,
            "conversation_data": {"first_message": first_message},
            "current_step": "conversation_started"
        }
    except Exception as e:
        return {
            **state,
            "error_context": f"Erro ao iniciar conversa: {str(e)}",
            "current_step": "error"
        }
```

### 2.3. Conditional Edges (Edges Condicionais)

Determinam o próximo nó baseado no estado atual:

```python
def should_use_lex9000(state: TriageState) -> str:
    """Decide se deve acionar o LEX-9000."""
    if state.get("error_context"):
        return "handle_error"
    
    complexity = state.get("complexity_level", "")
    triage_confidence = state.get("basic_triage_result", {}).get("confidence", 0)
    
    if complexity in ["complex", "very_complex"] or triage_confidence < 0.7:
        return "lex9000_analysis"
    else:
        return "find_matches"

def should_enhance_matches(state: TriageState) -> str:
    """Decide se deve usar LLM enhancement nos matches."""
    if state.get("error_context"):
        return "handle_error"
    
    matches = state.get("initial_matches", [])
    complexity = state.get("complexity_level", "")
    
    # Usar enhancement se há muitos matches OU caso é complexo
    if len(matches) > 5 or complexity in ["medium", "complex"]:
        return "enhance_matches"
    else:
        return "send_notifications"
```

## 3. Implementação Completa do Workflow

### 3.1. Definição do Grafo

```python
# packages/backend/services/intelligent_triage_orchestrator_v2.py

from langgraph.graph import StateGraph, END
from langgraph.checkpoint.memory import MemorySaver
import time

class IntelligentTriageOrchestratorV2:
    def __init__(self):
        self.workflow = self._build_workflow()
        
        # Serviços dependentes
        self.interviewer = intelligent_interviewer_service
        self.triage_service = triage_service
        self.lex9000_service = lex9000_integration_service
        self.match_service = enhanced_match_service
        self.notification_service = notify_service
        
    def _build_workflow(self) -> StateGraph:
        """Constrói o workflow completo de triagem inteligente."""
        
        # Inicializar grafo com checkpoint para persistência
        workflow = StateGraph(
            TriageState,
            checkpointer=MemorySaver()  # Em produção, usar Redis/PostgreSQL
        )
        
        # ===== ADICIONAR TODOS OS NÓS =====
        workflow.add_node("start_conversation", self._start_conversation_node)
        workflow.add_node("collect_case_details", self._collect_case_details_node)
        workflow.add_node("detect_complexity", self._detect_complexity_node)
        workflow.add_node("basic_triage", self._basic_triage_node)
        workflow.add_node("lex9000_analysis", self._lex9000_analysis_node)
        workflow.add_node("find_initial_matches", self._find_initial_matches_node)
        workflow.add_node("enhance_matches_with_llm", self._enhance_matches_node)
        workflow.add_node("generate_explanations", self._generate_explanations_node)
        workflow.add_node("send_notifications", self._send_notifications_node)
        workflow.add_node("handle_error", self._handle_error_node)
        
        # ===== DEFINIR ENTRY POINT =====
        workflow.set_entry_point("start_conversation")
        
        # ===== EDGES SIMPLES (sempre vai para o próximo) =====
        workflow.add_edge("start_conversation", "collect_case_details")
        workflow.add_edge("collect_case_details", "detect_complexity")
        workflow.add_edge("detect_complexity", "basic_triage")
        
        # ===== EDGE CONDICIONAL: Usar LEX-9000? =====
        workflow.add_conditional_edges(
            "basic_triage",
            self._should_use_lex9000,
            {
                "lex9000_analysis": "lex9000_analysis",
                "find_matches": "find_initial_matches",
                "handle_error": "handle_error"
            }
        )
        
        # LEX-9000 sempre vai para matches depois
        workflow.add_edge("lex9000_analysis", "find_initial_matches")
        
        # ===== EDGE CONDICIONAL: Usar LLM Enhancement? =====
        workflow.add_conditional_edges(
            "find_initial_matches",
            self._should_enhance_matches,
            {
                "enhance_matches": "enhance_matches_with_llm",
                "generate_explanations": "generate_explanations",
                "handle_error": "handle_error"
            }
        )
        
        # Enhancement vai para explicações
        workflow.add_edge("enhance_matches_with_llm", "generate_explanations")
        
        # Explicações sempre vão para notificações
        workflow.add_edge("generate_explanations", "send_notifications")
        
        # ===== FINALIZAÇÕES =====
        workflow.add_edge("send_notifications", END)
        workflow.add_edge("handle_error", END)
        
        return workflow.compile()

    # ===== IMPLEMENTAÇÃO DOS NÓS =====
    
    async def _start_conversation_node(self, state: TriageState) -> TriageState:
        """Nó que inicia a conversa inteligente."""
        start_time = time.time()
        
        try:
            case_id, first_message = await self.interviewer.start_conversation(
                state["user_id"]
            )
            
            duration = time.time() - start_time
            
            return {
                **state,
                "case_id": case_id,
                "conversation_data": {"first_message": first_message, "started_at": start_time},
                "current_step": "conversation_started",
                "step_durations": [{"step": "start_conversation", "duration": duration}]
            }
            
        except Exception as e:
            return {
                **state,
                "error_context": f"Erro ao iniciar conversa: {str(e)}",
                "current_step": "error"
            }

    async def _collect_case_details_node(self, state: TriageState) -> TriageState:
        """Nó que coleta detalhes do caso via conversa."""
        start_time = time.time()
        
        try:
            detailed_data = await self.interviewer.collect_case_details(
                state["case_id"],
                state["conversation_data"]
            )
            
            duration = time.time() - start_time
            
            return {
                **state,
                "conversation_data": {**state["conversation_data"], **detailed_data},
                "current_step": "details_collected",
                "step_durations": [{"step": "collect_details", "duration": duration}]
            }
            
        except Exception as e:
            return {
                **state,
                "error_context": f"Erro na coleta de detalhes: {str(e)}",
                "current_step": "error"
            }

    async def _detect_complexity_node(self, state: TriageState) -> TriageState:
        """Nó que detecta a complexidade do caso."""
        start_time = time.time()
        
        try:
            complexity_result = await self.interviewer.detect_complexity(
                state["conversation_data"]
            )
            
            duration = time.time() - start_time
            
            return {
                **state,
                "complexity_level": complexity_result["level"],
                "conversation_data": {
                    **state["conversation_data"],
                    "complexity_analysis": complexity_result
                },
                "current_step": "complexity_detected",
                "step_durations": [{"step": "detect_complexity", "duration": duration}]
            }
            
        except Exception as e:
            return {
                **state,
                "error_context": f"Erro na detecção de complexidade: {str(e)}",
                "current_step": "error"
            }

    async def _basic_triage_node(self, state: TriageState) -> TriageState:
        """Nó que executa triagem básica."""
        start_time = time.time()
        
        try:
            # Escolher estratégia baseada na complexidade
            complexity = state["complexity_level"]
            
            if complexity == "simple":
                triage_result = await self.triage_service.direct_simple_triage(
                    state["conversation_data"]
                )
            elif complexity == "medium":
                triage_result = await self.triage_service.standard_analysis(
                    state["conversation_data"]
                )
            else:  # complex, very_complex
                triage_result = await self.triage_service.ensemble_analysis(
                    state["conversation_data"]
                )
            
            duration = time.time() - start_time
            
            return {
                **state,
                "basic_triage_result": triage_result,
                "current_step": "basic_triage_completed",
                "step_durations": [{"step": "basic_triage", "duration": duration}]
            }
            
        except Exception as e:
            return {
                **state,
                "error_context": f"Erro na triagem básica: {str(e)}",
                "current_step": "error"
            }

    async def _lex9000_analysis_node(self, state: TriageState) -> TriageState:
        """Nó que executa análise detalhada LEX-9000."""
        start_time = time.time()
        
        try:
            lex_result = await self.lex9000_service.analyze_complex_case(
                state["conversation_data"]
            )
            
            duration = time.time() - start_time
            
            return {
                **state,
                "lex_analysis": lex_result,
                "current_step": "lex9000_completed",
                "step_durations": [{"step": "lex9000_analysis", "duration": duration}]
            }
            
        except Exception as e:
            return {
                **state,
                "error_context": f"Erro no LEX-9000: {str(e)}",
                "current_step": "error"
            }

    async def _find_initial_matches_node(self, state: TriageState) -> TriageState:
        """Nó que encontra matches iniciais de advogados."""
        start_time = time.time()
        
        try:
            # Combinar dados de triagem básica + LEX-9000 (se disponível)
            match_criteria = {
                "triage_result": state["basic_triage_result"],
                "conversation_data": state["conversation_data"]
            }
            
            if state.get("lex_analysis"):
                match_criteria["lex_analysis"] = state["lex_analysis"]
            
            matches = await self.match_service.find_matches(match_criteria)
            
            duration = time.time() - start_time
            
            return {
                **state,
                "initial_matches": matches,
                "current_step": "initial_matches_found",
                "step_durations": [{"step": "find_matches", "duration": duration}]
            }
            
        except Exception as e:
            return {
                **state,
                "error_context": f"Erro na busca de matches: {str(e)}",
                "current_step": "error"
            }

    async def _enhance_matches_node(self, state: TriageState) -> TriageState:
        """Nó que aprimora matches com análise LLM."""
        start_time = time.time()
        
        try:
            enhanced_matches = await self.match_service.enhance_matches_with_llm(
                state["initial_matches"],
                state["conversation_data"],
                state.get("lex_analysis")
            )
            
            duration = time.time() - start_time
            
            return {
                **state,
                "enhanced_matches": enhanced_matches,
                "current_step": "matches_enhanced",
                "step_durations": [{"step": "enhance_matches", "duration": duration}]
            }
            
        except Exception as e:
            # Se falhar, usar matches iniciais
            return {
                **state,
                "enhanced_matches": state["initial_matches"],
                "current_step": "matches_enhancement_failed",
                "step_durations": [{"step": "enhance_matches", "duration": time.time() - start_time, "status": "fallback"}]
            }

    async def _generate_explanations_node(self, state: TriageState) -> TriageState:
        """Nó que gera explicações para os matches."""
        start_time = time.time()
        
        try:
            matches = state.get("enhanced_matches", state.get("initial_matches", []))
            
            explanations = []
            for match in matches[:5]:  # Explicar apenas top 5
                explanation = await self.match_service.generate_match_explanation(
                    match,
                    state["conversation_data"],
                    state.get("lex_analysis")
                )
                explanations.append(explanation)
            
            duration = time.time() - start_time
            
            return {
                **state,
                "match_explanations": explanations,
                "current_step": "explanations_generated",
                "step_durations": [{"step": "generate_explanations", "duration": duration}]
            }
            
        except Exception as e:
            # Se falhar, continuar sem explicações
            return {
                **state,
                "match_explanations": [],
                "current_step": "explanations_failed",
                "step_durations": [{"step": "generate_explanations", "duration": time.time() - start_time, "status": "fallback"}]
            }

    async def _send_notifications_node(self, state: TriageState) -> TriageState:
        """Nó que envia notificações finais."""
        start_time = time.time()
        
        try:
            # Preparar dados para notificação
            notification_data = {
                "case_id": state["case_id"],
                "triage_result": state["basic_triage_result"],
                "matches": state.get("enhanced_matches", state.get("initial_matches", [])),
                "explanations": state.get("match_explanations", []),
                "lex_analysis": state.get("lex_analysis"),
                "processing_summary": {
                    "total_duration": sum(step["duration"] for step in state.get("step_durations", [])),
                    "steps_completed": len(state.get("step_durations", [])),
                    "complexity_level": state["complexity_level"]
                }
            }
            
            await self.notification_service.send_triage_results(
                state["user_id"],
                notification_data
            )
            
            duration = time.time() - start_time
            
            return {
                **state,
                "notifications_sent": True,
                "current_step": "completed",
                "step_durations": [{"step": "send_notifications", "duration": duration}]
            }
            
        except Exception as e:
            return {
                **state,
                "error_context": f"Erro ao enviar notificações: {str(e)}",
                "current_step": "notification_error"
            }

    async def _handle_error_node(self, state: TriageState) -> TriageState:
        """Nó que trata erros do sistema."""
        try:
            # Log do erro
            error_details = {
                "user_id": state["user_id"],
                "case_id": state.get("case_id"),
                "error": state.get("error_context"),
                "current_step": state.get("current_step"),
                "partial_data": {
                    "conversation_data": state.get("conversation_data", {}),
                    "complexity_level": state.get("complexity_level"),
                    "basic_triage_result": state.get("basic_triage_result", {})
                }
            }
            
            # Tentar recuperação parcial
            await self.notification_service.send_error_notification(
                state["user_id"],
                error_details
            )
            
            return {
                **state,
                "current_step": "error_handled",
                "notifications_sent": True
            }
            
        except Exception as e:
            # Erro crítico - apenas log
            logger.critical(f"Erro crítico no sistema de triagem: {e}")
            return {
                **state,
                "current_step": "critical_error"
            }

    # ===== FUNÇÕES DE DECISÃO =====
    
    def _should_use_lex9000(self, state: TriageState) -> str:
        """Decide se deve acionar o LEX-9000."""
        if state.get("error_context"):
            return "handle_error"
        
        complexity = state.get("complexity_level", "")
        triage_result = state.get("basic_triage_result", {})
        confidence = triage_result.get("confidence", 0)
        
        # Usar LEX-9000 se:
        # 1. Caso é complexo OU
        # 2. Confiança da triagem básica é baixa
        if complexity in ["complex", "very_complex"] or confidence < 0.7:
            return "lex9000_analysis"
        else:
            return "find_matches"

    def _should_enhance_matches(self, state: TriageState) -> str:
        """Decide se deve usar LLM enhancement nos matches."""
        if state.get("error_context"):
            return "handle_error"
        
        matches = state.get("initial_matches", [])
        complexity = state.get("complexity_level", "")
        
        # Usar enhancement se:
        # 1. Há muitos matches (> 5) OU
        # 2. Caso é de média/alta complexidade
        if len(matches) > 5 or complexity in ["medium", "complex", "very_complex"]:
            return "enhance_matches"
        else:
            return "generate_explanations"

    # ===== INTERFACE PÚBLICA =====
    
    async def start_intelligent_triage(self, user_id: str) -> Dict[str, Any]:
        """
        Ponto de entrada público - executa o workflow completo.
        """
        # Estado inicial
        initial_state = TriageState(
            user_id=user_id,
            case_id=None,
            conversation_data={},
            user_preferences={},
            complexity_level="",
            basic_triage_result={},
            lex_analysis=None,
            initial_matches=[],
            enhanced_matches=[],
            match_explanations=[],
            current_step="starting",
            error_context=None,
            notifications_sent=False,
            processing_start_time=time.time(),
            step_durations=[]
        )
        
        # Executar o workflow
        config = {"configurable": {"thread_id": f"triage_{user_id}_{int(time.time())}"}}
        final_state = await self.workflow.ainvoke(initial_state, config)
        
        # Retornar resultado estruturado
        return {
            "success": final_state.get("error_context") is None,
            "case_id": final_state.get("case_id"),
            "triage_result": final_state.get("basic_triage_result", {}),
            "lex_analysis": final_state.get("lex_analysis"),
            "matches": final_state.get("enhanced_matches", final_state.get("initial_matches", [])),
            "explanations": final_state.get("match_explanations", []),
            "error": final_state.get("error_context"),
            "processing_summary": {
                "total_duration": sum(step["duration"] for step in final_state.get("step_durations", [])),
                "steps_completed": [step["step"] for step in final_state.get("step_durations", [])],
                "complexity_level": final_state.get("complexity_level")
            }
        }

    async def get_workflow_status(self, thread_id: str) -> Dict[str, Any]:
        """
        Retorna o status atual de um workflow em execução.
        """
        config = {"configurable": {"thread_id": thread_id}}
        
        try:
            # Obter estado atual do checkpoint
            state = await self.workflow.aget_state(config)
            return {
                "current_step": state.values.get("current_step"),
                "progress": len(state.values.get("step_durations", [])),
                "is_running": state.next,
                "error": state.values.get("error_context")
            }
        except Exception as e:
            return {"error": f"Erro ao obter status: {e}"}

    async def pause_workflow(self, thread_id: str) -> bool:
        """
        Pausa um workflow em execução (útil para debugging).
        """
        # LangGraph suporta pausas em nós específicos
        # Implementação dependeria de configuração específica
        pass

    def visualize_workflow(self) -> str:
        """
        Retorna representação visual do workflow.
        """
        try:
            # LangGraph pode gerar diagramas automaticamente
            return self.workflow.get_graph().draw_mermaid()
        except Exception:
            return "Visualização não disponível"
```

## 4. Benefícios da Implementação LangGraph

### 4.1. Visualização e Debugging

```python
# O workflow pode ser visualizado automaticamente
mermaid_diagram = orchestrator.visualize_workflow()
print(mermaid_diagram)

# Saída:
graph TD
    start_conversation --> collect_case_details
    collect_case_details --> detect_complexity
    detect_complexity --> basic_triage
    basic_triage --> {should_use_lex9000}
    {should_use_lex9000} --> lex9000_analysis
    {should_use_lex9000} --> find_initial_matches
    lex9000_analysis --> find_initial_matches
    find_initial_matches --> {should_enhance_matches}
    {should_enhance_matches} --> enhance_matches_with_llm
    {should_enhance_matches} --> generate_explanations
    enhance_matches_with_llm --> generate_explanations
    generate_explanations --> send_notifications
    send_notifications --> END
```

### 4.2. Estado Persistente

```python
# O estado é automaticamente persistido entre execuções
async def resume_failed_triage(thread_id: str):
    config = {"configurable": {"thread_id": thread_id}}
    
    # Retomar de onde parou
    result = await orchestrator.workflow.ainvoke(None, config)
    return result
```

### 4.3. Métricas Automáticas

```python
# Cada nó automaticamente registra métricas
def get_performance_metrics(final_state: TriageState):
    steps = final_state["step_durations"]
    
    return {
        "total_time": sum(step["duration"] for step in steps),
        "bottleneck_step": max(steps, key=lambda x: x["duration"])["step"],
        "success_rate": 1.0 if not final_state.get("error_context") else 0.0,
        "steps_completed": len(steps)
    }
```

## 5. Testes e Validação

### 5.1. Testes Unitários de Nós

```python
# tests/test_langgraph_nodes.py

import pytest
from services.intelligent_triage_orchestrator_v2 import TriageState

async def test_start_conversation_node():
    """Testa o nó de início de conversa."""
    orchestrator = IntelligentTriageOrchestratorV2()
    
    initial_state = TriageState(
        user_id="test_user_123",
        case_id=None,
        conversation_data={},
        # ... outros campos
    )
    
    result_state = await orchestrator._start_conversation_node(initial_state)
    
    assert result_state["case_id"] is not None
    assert "first_message" in result_state["conversation_data"]
    assert result_state["current_step"] == "conversation_started"

async def test_complexity_detection_node():
    """Testa o nó de detecção de complexidade."""
    orchestrator = IntelligentTriageOrchestratorV2()
    
    test_state = TriageState(
        user_id="test_user",
        case_id="test_case",
        conversation_data={
            "case_description": "Caso trabalhista simples de horas extras",
            "documents": [],
            "urgency_indicators": []
        },
        # ... outros campos
    )
    
    result_state = await orchestrator._detect_complexity_node(test_state)
    
    assert result_state["complexity_level"] in ["simple", "medium", "complex", "very_complex"]
    assert result_state["current_step"] == "complexity_detected"
```

### 5.2. Testes de Fluxo Completo

```python
async def test_complete_simple_flow():
    """Testa fluxo completo para caso simples."""
    orchestrator = IntelligentTriageOrchestratorV2()
    
    result = await orchestrator.start_intelligent_triage("test_user_simple")
    
    assert result["success"] is True
    assert result["case_id"] is not None
    assert len(result["matches"]) > 0
    assert "simple" in result["processing_summary"]["complexity_level"]

async def test_complete_complex_flow():
    """Testa fluxo completo para caso complexo."""
    orchestrator = IntelligentTriageOrchestratorV2()
    
    # Mock do interviewer para retornar caso complexo
    with patch('services.intelligent_interviewer_service.detect_complexity') as mock_complexity:
        mock_complexity.return_value = {"level": "complex", "confidence": 0.9}
        
        result = await orchestrator.start_intelligent_triage("test_user_complex")
    
    assert result["success"] is True
    assert result["lex_analysis"] is not None  # LEX-9000 foi chamado
    assert "enhanced_matches" in result or len(result["matches"]) > 0
```

### 5.3. Testes de Fallback e Erro

```python
async def test_error_handling():
    """Testa tratamento de erros no workflow."""
    orchestrator = IntelligentTriageOrchestratorV2()
    
    # Mock que força erro no LEX-9000
    with patch('services.lex9000_integration_service.analyze_complex_case') as mock_lex:
        mock_lex.side_effect = Exception("API indisponível")
        
        result = await orchestrator.start_intelligent_triage("test_user_error")
    
    # Sistema deve continuar funcionando mesmo com erro no LEX-9000
    assert result["lex_analysis"] is None
    assert result["matches"] is not None  # Matches básicos funcionam
    assert result["error"] is not None
```

## 6. Migração Gradual

### 6.1. Fase 1: Dual Mode (Semanas 1-2)

```python
class IntelligentTriageOrchestratorDual:
    """Versão que permite escolher entre implementação antiga e nova."""
    
    def __init__(self):
        self.v1_orchestrator = IntelligentTriageOrchestrator()  # Versão atual
        self.v2_orchestrator = IntelligentTriageOrchestratorV2()  # Nova versão
        
    async def start_intelligent_triage(self, user_id: str, use_langgraph: bool = False):
        """Permite escolher qual versão usar."""
        if use_langgraph:
            return await self.v2_orchestrator.start_intelligent_triage(user_id)
        else:
            return await self.v1_orchestrator.start_intelligent_triage(user_id)
```

### 6.2. Fase 2: A/B Testing (Semanas 3-4)

```python
async def start_intelligent_triage_ab_test(user_id: str):
    """Executa A/B test entre versões."""
    
    # Decidir versão baseado no user_id
    use_langgraph = hash(user_id) % 2 == 0
    
    start_time = time.time()
    
    if use_langgraph:
        result = await v2_orchestrator.start_intelligent_triage(user_id)
        version = "langgraph"
    else:
        result = await v1_orchestrator.start_intelligent_triage(user_id)
        version = "legacy"
    
    duration = time.time() - start_time
    
    # Registrar métricas para comparação
    ab_test_metrics.labels(version=version, success=result["success"]).inc()
    ab_test_duration.labels(version=version).observe(duration)
    
    return result
```

### 6.3. Fase 3: Migration Complete (Semanas 5-6)

```python
# Substituir completamente a implementação antiga
class IntelligentTriageOrchestrator(IntelligentTriageOrchestratorV2):
    """Versão final - apenas LangGraph."""
    pass
```

## 7. Monitoramento e Observabilidade

### 7.1. Métricas Específicas do LangGraph

```python
# Métricas customizadas para workflows
workflow_executions = Counter(
    'langgraph_workflow_executions_total',
    'Total workflow executions',
    ['workflow_name', 'status', 'complexity']
)

workflow_duration = Histogram(
    'langgraph_workflow_duration_seconds',
    'Workflow execution time',
    ['workflow_name', 'complexity']
)

node_executions = Counter(
    'langgraph_node_executions_total',
    'Individual node executions',
    ['workflow_name', 'node_name', 'status']
)

state_transitions = Counter(
    'langgraph_state_transitions_total',
    'State transitions between nodes',
    ['workflow_name', 'from_node', 'to_node']
)
```

### 7.2. Dashboard de Workflow

```python
@router.get("/ai/workflows/dashboard")
async def get_workflow_dashboard():
    """Dashboard específico para workflows LangGraph."""
    
    return {
        "active_workflows": await get_active_workflow_count(),
        "avg_completion_time": await get_avg_workflow_duration(),
        "success_rate_by_complexity": await get_success_rate_by_complexity(),
        "bottleneck_nodes": await get_bottleneck_nodes(),
        "most_common_paths": await get_most_common_workflow_paths(),
        "error_breakdown": await get_workflow_error_breakdown()
    }
```

## 8. Conclusão

A implementação do LangGraph no sistema LITIG-1 oferece:

1. **Flexibilidade**: Fácil adição/remoção de etapas no workflow
2. **Observabilidade**: Visibilidade completa do fluxo de execução
3. **Robustez**: Tratamento robusto de erros e estados parciais
4. **Manutenibilidade**: Código declarativo mais fácil de entender
5. **Debugging**: Capacidade de pausar e inspecionar execução
6. **Performance**: Estado persistente e otimizações automáticas

A migração gradual permite validação contínua e minimiza riscos, garantindo que os benefícios sejam realizados sem impactar a operação atual. 
 